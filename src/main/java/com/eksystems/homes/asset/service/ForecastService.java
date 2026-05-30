package com.eksystems.homes.asset.service;

import com.eksystems.homes.asset.mapper.AssetMapper;
import com.eksystems.homes.asset.mapper.CashFlowMapper;
import com.eksystems.homes.asset.mapper.SnapshotMapper;
import com.eksystems.homes.asset.vo.AssetChangeSummaryVO;
import com.eksystems.homes.asset.vo.AssetSummaryVO;
import com.eksystems.homes.asset.vo.AssetVO;
import com.eksystems.homes.asset.vo.CashFlowPlanVO;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.*;

@Service
public class ForecastService {

    private static final DateTimeFormatter FMT    = DateTimeFormatter.ofPattern("yyyy-MM");
    private static final DateTimeFormatter YYMM   = DateTimeFormatter.ofPattern("yyyyMM");

    private final AssetMapper    assetMapper;
    private final CashFlowMapper cashFlowMapper;
    private final SnapshotMapper snapshotMapper;

    public ForecastService(AssetMapper assetMapper, CashFlowMapper cashFlowMapper, SnapshotMapper snapshotMapper) {
        this.assetMapper    = assetMapper;
        this.cashFlowMapper = cashFlowMapper;
        this.snapshotMapper = snapshotMapper;
    }

    // ══════════════════════════════════════════════════════════════
    // public API
    // ══════════════════════════════════════════════════════════════

    public Map<String, Object> calcForecast(String familyId, int forecastMonths, int[] weights) {

        // ── 1. 현재 자산 요약 ──────────────────────────────────
        AssetSummaryVO summary      = assetMapper.selectAssetSummary(familyId);
        long           totalAsset   = summary != null ? safe(summary.getTotalAssetAmount()) : 0L;
        long           totalLoan    = summary != null ? safe(summary.getTotalLoanBalance())  : 0L;
        long           currentNetAsset = totalAsset - totalLoan;

        // ── 2. 활성 현금흐름 계획 ──────────────────────────────
        List<CashFlowPlanVO> plans    = cashFlowMapper.selectActivePlansForForecast(familyId);
        List<AssetVO>        rateAssets = assetMapper.selectAssetsForForecast(familyId);

        // ── 3. 전표처리 이력 (ASSET_HST + CASHFLOW_PLAN_HST 집계) ─
        List<AssetChangeSummaryVO> hstList = snapshotMapper.selectAssetChangeSummary(familyId);

        // ── 4. 전표처리 기반 실적 지표 ────────────────────────
        long   actualAvgMoM    = 0;   // 실제 월평균 순자산 변동
        long   actualAvgIncome = 0;
        long   actualAvgExpense= 0;
        double savingRateAvg   = 0;
        List<String> hstLabels    = new ArrayList<>();
        List<Long>   hstNetAssets = new ArrayList<>();
        List<Long>   hstMoM       = new ArrayList<>();
        List<Double> hstSavingRates = new ArrayList<>();

        if (!hstList.isEmpty()) {
            for (int i = 0; i < hstList.size(); i++) {
                AssetChangeSummaryVO h = hstList.get(i);
                String yymm = h.getHstYymm();
                hstLabels.add(yymm.substring(0, 4) + "." + yymm.substring(4, 6));
                hstNetAssets.add(h.getNetAssetAmt());

                long mom = (i == 0) ? 0L : h.getNetAssetAmt() - hstList.get(i - 1).getNetAssetAmt();
                hstMoM.add(mom);

                long inc = h.getMonthlyIncome();
                long exp = h.getMonthlyExpense();
                double sr = inc > 0 ? Math.round((inc - exp) * 1000.0 / inc) / 10.0 : 0.0;
                hstSavingRates.add(sr);
            }
            if (hstList.size() >= 2) {
                long totalMoM = 0;
                long totInc = 0, totExp = 0;
                for (int i = 1; i < hstList.size(); i++) {
                    totalMoM += hstList.get(i).getNetAssetAmt() - hstList.get(i - 1).getNetAssetAmt();
                    totInc   += hstList.get(i).getMonthlyIncome();
                    totExp   += hstList.get(i).getMonthlyExpense();
                }
                int cnt = hstList.size() - 1;
                actualAvgMoM    = totalMoM / cnt;
                actualAvgIncome = totInc   / cnt;
                actualAvgExpense= totExp   / cnt;
                double totalSr = hstSavingRates.stream().skip(1).mapToDouble(Double::doubleValue).sum();
                savingRateAvg = Math.round(totalSr / cnt * 10) / 10.0;
            }
        }

        // ── 5. 계획 기반 월별 현금흐름 계산 ───────────────────
        LocalDate today      = LocalDate.now();
        LocalDate firstMonth = today.withDayOfMonth(1);

        long[] planIncome   = new long[forecastMonths + 1];
        long[] planExpense  = new long[forecastMonths + 1];
        long[] planAssetGain = new long[forecastMonths + 1];

        for (int m = 1; m <= forecastMonths; m++) {
            LocalDate month = firstMonth.plusMonths(m);
            for (CashFlowPlanVO plan : plans) {
                long fires  = firesInMonth(plan, month);
                long amount = safe(plan.getAmount()) * fires;
                if ("INCOME".equals(plan.getFlowType())) planIncome[m]  += amount;
                else                                      planExpense[m] += amount;
            }
            for (AssetVO asset : rateAssets) {
                planAssetGain[m] += monthlyAssetGain(asset, month);
            }
        }

        long sumPlanIncome   = Arrays.stream(planIncome).sum();
        long sumPlanExpense  = Arrays.stream(planExpense).sum();
        long sumPlanAssetGain= Arrays.stream(planAssetGain).sum();
        long planAvgIncome   = forecastMonths > 0 ? sumPlanIncome   / forecastMonths : 0;
        long planAvgExpense  = forecastMonths > 0 ? sumPlanExpense  / forecastMonths : 0;
        long planAvgAssetGain= forecastMonths > 0 ? sumPlanAssetGain/ forecastMonths : 0;
        long planAvgMoM      = planAvgIncome + planAvgAssetGain - planAvgExpense;

        // ── 6. 실적 보정 비율 (전표처리 이력이 2개월 이상이면 적용) ─
        // baseMonthlyNet[m] = planMonthlyNet[m] * actualityRatio
        double actualityRatio;
        if (hstList.size() >= 2 && planAvgMoM != 0) {
            actualityRatio = (double) actualAvgMoM / (double) planAvgMoM;
            // 비율을 0.3 ~ 3.0 사이로 클램프 (이상값 방지)
            actualityRatio = Math.min(3.0, Math.max(0.3, actualityRatio));
        } else {
            actualityRatio = 1.0; // 이력 없으면 계획 그대로 사용
        }

        // ── 7. 월별 기준(100%) 순변동 계산 (실적 보정 적용) ───
        long[] baseMoM = new long[forecastMonths + 1]; // [0] 미사용
        for (int m = 1; m <= forecastMonths; m++) {
            long planNet = planIncome[m] + planAssetGain[m] - planExpense[m];
            baseMoM[m] = Math.round(planNet * actualityRatio);
        }

        // ── 8. 레이블 ──────────────────────────────────────────
        List<String> labels = new ArrayList<>();
        labels.add(firstMonth.format(FMT) + " (현재)");
        for (int m = 1; m <= forecastMonths; m++) {
            labels.add(firstMonth.plusMonths(m).format(FMT));
        }

        // ── 9. 시나리오별 누적 순자산 ─────────────────────────
        String[] defaultColors = {"#ef4444","#f97316","#3b82f6","#10b981","#8b5cf6",
                                  "#14b8a6","#f59e0b","#ec4899","#6366f1","#64748b"};
        List<Map<String, Object>> scenarios = new ArrayList<>();

        for (int wi = 0; wi < weights.length; wi++) {
            int weight = weights[wi];
            String color = defaultColors[wi % defaultColors.length];
            boolean isBase = (weight == 100);

            List<Long> data = new ArrayList<>();
            data.add(currentNetAsset);
            long cumulative = currentNetAsset;
            for (int m = 1; m <= forecastMonths; m++) {
                cumulative += baseMoM[m] * weight / 100;
                data.add(cumulative);
            }

            Map<String, Object> sc = new LinkedHashMap<>();
            sc.put("label",           weight + "%");
            sc.put("weight",          weight);
            sc.put("data",            data);
            sc.put("borderColor",     color);
            sc.put("backgroundColor", color + "22");
            sc.put("tension",         0.3);
            sc.put("fill",            isBase);
            sc.put("borderWidth",     isBase ? 3 : 1.5);
            sc.put("borderDash",      isBase ? new int[]{} : new int[]{5, 4});
            scenarios.add(sc);
        }

        // ── 10. 월별 breakdown (100% 기준) ────────────────────
        List<Map<String, Object>> breakdown = new ArrayList<>();
        long cumBase = currentNetAsset;
        for (int m = 1; m <= forecastMonths; m++) {
            LocalDate month = firstMonth.plusMonths(m);
            long net   = baseMoM[m];
            cumBase   += net;

            Map<String, Object> row = new LinkedHashMap<>();
            row.put("month",        month.format(FMT));
            row.put("income",       Math.round(planIncome[m]    * actualityRatio));
            row.put("assetGain",    Math.round(planAssetGain[m] * actualityRatio));
            row.put("expense",      Math.round(planExpense[m]   * actualityRatio));
            row.put("net",          net);
            row.put("cumulative",   cumBase);
            breakdown.add(row);
        }

        // ── 11. 항목별 요약 ────────────────────────────────────
        List<Map<String, Object>> planSummary = buildPlanSummary(plans, firstMonth, forecastMonths);

        // ── 12. 자산 증감률 요약 ───────────────────────────────
        List<Map<String, Object>> assetRateSummary = buildAssetRateSummary(rateAssets, forecastMonths);

        // ── 13. 인사이트 ───────────────────────────────────────
        List<String> insights = buildInsights(
                currentNetAsset, hstList, actualAvgMoM, planAvgMoM,
                actualityRatio, weights, scenarios, forecastMonths);

        // ── 14. AI 컨텍스트 ────────────────────────────────────
        Map<String, Object> aiContext = buildAiContext(
                familyId, forecastMonths, weights,
                currentNetAsset, totalAsset, totalLoan,
                hstList, actualAvgMoM, actualAvgIncome, actualAvgExpense, savingRateAvg,
                planAvgMoM, planAvgIncome, planAvgExpense, planAvgAssetGain,
                actualityRatio, scenarios, planSummary, assetRateSummary);

        // ── 15. 결과 조립 ──────────────────────────────────────
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("labels",            labels);
        result.put("scenarios",         scenarios);
        result.put("breakdown",         breakdown);
        result.put("planSummary",       planSummary);
        result.put("assetRateSummary",  assetRateSummary);
        result.put("insights",          insights);
        result.put("aiContext",         aiContext);

        // 현재 상태
        result.put("currentNetAsset",   currentNetAsset);
        result.put("totalAsset",        totalAsset);
        result.put("totalLoan",         totalLoan);

        // 계획 지표
        result.put("planAvgIncome",     planAvgIncome);
        result.put("planAvgExpense",    planAvgExpense);
        result.put("planAvgAssetGain",  planAvgAssetGain);
        result.put("planAvgMoM",        planAvgMoM);

        // 실적 지표
        result.put("actualAvgMoM",      actualAvgMoM);
        result.put("actualAvgIncome",   actualAvgIncome);
        result.put("actualAvgExpense",  actualAvgExpense);
        result.put("savingRateAvg",     savingRateAvg);
        result.put("actualityRatio",    Math.round(actualityRatio * 100.0) / 100.0);
        result.put("hstCount",          hstList.size());

        // 이력 차트 데이터
        result.put("hstLabels",        hstLabels);
        result.put("hstNetAssets",     hstNetAssets);
        result.put("hstMoM",           hstMoM);
        result.put("hstSavingRates",   hstSavingRates);

        return result;
    }

    // ══════════════════════════════════════════════════════════════
    // 인사이트 문장 생성
    // ══════════════════════════════════════════════════════════════

    private List<String> buildInsights(long currentNetAsset, List<AssetChangeSummaryVO> hstList,
                                       long actualAvgMoM, long planAvgMoM, double actualityRatio,
                                       int[] weights, List<Map<String, Object>> scenarios, int months) {
        List<String> list = new ArrayList<>();

        if (hstList.size() >= 2) {
            list.add("전표처리 이력 " + hstList.size() + "개월 기준, 실제 월평균 순자산 변동: "
                    + fmtWon(actualAvgMoM) + "원");

            double ratioPct = Math.round((actualityRatio - 1.0) * 1000) / 10.0;
            if (Math.abs(ratioPct) > 5) {
                list.add("실적이 계획 대비 " + (ratioPct > 0 ? "+" : "") + ratioPct + "% 수준 → 예측에 보정 적용됨");
            } else {
                list.add("실적과 계획의 차이가 ±5% 이내로 계획과 거의 일치합니다.");
            }
        } else {
            list.add("전표처리 이력이 없어 정기수입/지출 계획 기준으로 예측합니다. 전표처리를 진행하면 더 정확한 예측이 가능합니다.");
        }

        // 100% 시나리오 결말
        scenarios.stream().filter(s -> (int)s.get("weight") == 100).findFirst().ifPresent(base -> {
            List<Long> data = (List<Long>) base.get("data");
            if (!data.isEmpty()) {
                long finalNet = data.get(data.size() - 1);
                long gain = finalNet - currentNetAsset;
                list.add("기준(100%) 시나리오 " + months + "개월 후 순자산: "
                        + fmtWon(finalNet) + "원 (변동: " + (gain >= 0 ? "+" : "") + fmtWon(gain) + "원)");
            }
        });

        return list;
    }

    // ══════════════════════════════════════════════════════════════
    // AI 컨텍스트 빌더
    // ══════════════════════════════════════════════════════════════

    private Map<String, Object> buildAiContext(
            String familyId, int forecastMonths, int[] weights,
            long currentNetAsset, long totalAsset, long totalLoan,
            List<AssetChangeSummaryVO> hstList,
            long actualAvgMoM, long actualAvgIncome, long actualAvgExpense, double savingRateAvg,
            long planAvgMoM, long planAvgIncome, long planAvgExpense, long planAvgAssetGain,
            double actualityRatio,
            List<Map<String, Object>> scenarios,
            List<Map<String, Object>> planSummary,
            List<Map<String, Object>> assetRateSummary) {

        Map<String, Object> ctx = new LinkedHashMap<>();
        ctx.put("reportTitle", "자산변동 예측 리포트");
        ctx.put("generatedAt", LocalDate.now().toString());
        ctx.put("forecastMonths", forecastMonths);

        Map<String, Object> current = new LinkedHashMap<>();
        current.put("totalAsset",    totalAsset);
        current.put("totalLoan",     totalLoan);
        current.put("netAsset",      currentNetAsset);
        ctx.put("currentState", current);

        Map<String, Object> hst = new LinkedHashMap<>();
        hst.put("dataMonths",     hstList.size());
        hst.put("avgMonthlyChange", actualAvgMoM);
        hst.put("avgIncome",      actualAvgIncome);
        hst.put("avgExpense",     actualAvgExpense);
        hst.put("savingRateAvg",  savingRateAvg);
        ctx.put("historicalActual", hst);

        Map<String, Object> plan = new LinkedHashMap<>();
        plan.put("avgMonthlyIncome",   planAvgIncome);
        plan.put("avgMonthlyExpense",  planAvgExpense);
        plan.put("avgMonthlyAssetGain",planAvgAssetGain);
        plan.put("avgMonthlyNet",      planAvgMoM);
        plan.put("actualityRatio",     Math.round(actualityRatio * 100.0) / 100.0);
        ctx.put("planBaseline", plan);

        List<Map<String, Object>> scSummary = new ArrayList<>();
        for (Map<String, Object> sc : scenarios) {
            List<Long> data = (List<Long>) sc.get("data");
            if (data == null || data.isEmpty()) continue;
            long finalNet = data.get(data.size() - 1);
            Map<String, Object> s = new LinkedHashMap<>();
            s.put("weight",       sc.get("weight"));
            s.put("finalNetAsset", finalNet);
            s.put("totalGain",    finalNet - currentNetAsset);
            scSummary.add(s);
        }
        ctx.put("scenarioResults", scSummary);

        // 수입/지출 항목 요약 (AI용)
        List<Map<String, Object>> incItems  = planSummary.stream()
                .filter(p -> "INCOME".equals(p.get("flowType")))
                .map(p -> Map.of("name", p.get("planNm"), "totalAmount", p.get("totalAmount")))
                .collect(java.util.stream.Collectors.toList());
        List<Map<String, Object>> expItems  = planSummary.stream()
                .filter(p -> !"INCOME".equals(p.get("flowType")))
                .map(p -> Map.of("name", p.get("planNm"), "totalAmount", p.get("totalAmount")))
                .collect(java.util.stream.Collectors.toList());
        ctx.put("incomeItems",  incItems);
        ctx.put("expenseItems", expItems);
        ctx.put("assetRateItems", assetRateSummary);

        ctx.put("analysisPromptHint",
                "위 데이터를 분석하여 가계 재정 건전성, 저축률, 자산 증가 속도, 리스크 요인, "
                + "개선 제안을 한국어로 설명해주세요. 실적 보정 비율이 1.0보다 크면 계획 초과 달성, "
                + "작으면 미달 의미입니다.");
        return ctx;
    }

    // ══════════════════════════════════════════════════════════════
    // 현금흐름 사이클 계산
    // ══════════════════════════════════════════════════════════════

    private long firesInMonth(CashFlowPlanVO plan, LocalDate month) {
        LocalDate planStart = plan.getStartYmd() != null
                ? plan.getStartYmd().withDayOfMonth(1)
                : LocalDate.of(2000, 1, 1);
        LocalDate planEnd = plan.getEndYmd();
        if (planEnd != null && month.isAfter(planEnd.withDayOfMonth(planEnd.lengthOfMonth()))) return 0;
        if (month.isBefore(planStart)) return 0;

        int    cycleNum  = plan.getCycleNum()  != null && plan.getCycleNum()  > 0 ? plan.getCycleNum()  : 1;
        String cycleUnit = plan.getCycleUnit() != null ? plan.getCycleUnit() : "MONTH";

        return switch (cycleUnit) {
            case "MONTH" -> {
                long elapsed = ChronoUnit.MONTHS.between(planStart, month);
                yield (elapsed >= 0 && elapsed % cycleNum == 0) ? 1 : 0;
            }
            case "YEAR" -> {
                int trigMonth = plan.getCycleBaseMonth() != null
                        ? plan.getCycleBaseMonth() : planStart.getMonthValue();
                if (month.getMonthValue() != trigMonth) yield 0;
                long elapsedMonths = ChronoUnit.MONTHS.between(planStart, month);
                if (elapsedMonths < 0) yield 0;
                yield (elapsedMonths / 12 % cycleNum == 0) ? 1 : 0;
            }
            case "DAY" -> (long) Math.max(1, Math.floor((double) month.lengthOfMonth() / cycleNum));
            default    -> 0;
        };
    }

    // ══════════════════════════════════════════════════════════════
    // 자산 증감률 월환산
    // ══════════════════════════════════════════════════════════════

    private long monthlyAssetGain(AssetVO asset, LocalDate month) {
        BigDecimal rate = asset.getExpectedRate();
        if (rate == null || rate.compareTo(BigDecimal.ZERO) == 0) return 0;
        long   amount   = safe(asset.getAmount());
        int    cycleNum = asset.getRateCycleNum()  != null && asset.getRateCycleNum()  > 0 ? asset.getRateCycleNum()  : 1;
        String unit     = asset.getRateCycleUnit() != null ? asset.getRateCycleUnit() : "YEAR";
        double gainPerCycle = amount * rate.doubleValue() / 100.0;
        double monthly = switch (unit) {
            case "YEAR"  -> gainPerCycle / (12.0 * cycleNum);
            case "MONTH" -> gainPerCycle / cycleNum;
            case "DAY"   -> gainPerCycle * 30.0 / cycleNum;
            default      -> gainPerCycle / 12.0;
        };
        return Math.round(monthly);
    }

    // ══════════════════════════════════════════════════════════════
    // 요약 빌더
    // ══════════════════════════════════════════════════════════════

    private List<Map<String, Object>> buildPlanSummary(List<CashFlowPlanVO> plans,
                                                        LocalDate firstMonth, int months) {
        List<Map<String, Object>> list = new ArrayList<>();
        for (CashFlowPlanVO plan : plans) {
            long totalFires = 0;
            for (int m = 1; m <= months; m++) {
                totalFires += firesInMonth(plan, firstMonth.plusMonths(m));
            }
            if (totalFires == 0) continue;
            Map<String, Object> row = new LinkedHashMap<>();
            row.put("planNm",     plan.getPlanNm());
            row.put("planTypeNm", plan.getPlanTypeNm());
            row.put("flowType",   plan.getFlowType());
            row.put("amount",     safe(plan.getAmount()));
            row.put("totalFires", totalFires);
            row.put("totalAmount",safe(plan.getAmount()) * totalFires);
            row.put("cycleNum",   plan.getCycleNum());
            row.put("cycleUnit",  plan.getCycleUnit());
            list.add(row);
        }
        return list;
    }

    private List<Map<String, Object>> buildAssetRateSummary(List<AssetVO> assets, int months) {
        List<Map<String, Object>> list = new ArrayList<>();
        for (AssetVO asset : assets) {
            long monthly = monthlyAssetGain(asset, LocalDate.now());
            Map<String, Object> row = new LinkedHashMap<>();
            row.put("assetNm",       asset.getAssetNm());
            row.put("assetType",     asset.getAssetType());
            row.put("amount",        safe(asset.getAmount()));
            row.put("expectedRate",  asset.getExpectedRate());
            row.put("rateCycleNum",  asset.getRateCycleNum());
            row.put("rateCycleUnit", asset.getRateCycleUnit());
            row.put("monthlyGain",   monthly);
            row.put("totalGain",     monthly * months);
            list.add(row);
        }
        return list;
    }

    // ══════════════════════════════════════════════════════════════
    // 유틸
    // ══════════════════════════════════════════════════════════════

    private long safe(Long v) { return v != null ? v : 0L; }

    private String fmtWon(long v) {
        long abs = Math.abs(v);
        String sign = v < 0 ? "-" : "";
        if (abs >= 100_000_000L) return sign + String.format("%.1f억", abs / 1e8);
        if (abs >= 10_000L)      return sign + (abs / 10_000L) + "만";
        return sign + String.format("%,d", abs);
    }
}
