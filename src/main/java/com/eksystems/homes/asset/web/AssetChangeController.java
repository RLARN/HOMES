package com.eksystems.homes.asset.web;

import com.eksystems.homes.assistant.service.GeminiService;
import com.eksystems.homes.asset.service.SnapshotService;
import com.eksystems.homes.asset.vo.AssetChangeSummaryVO;
import com.eksystems.homes.asset.vo.AssetTypeMonthVO;
import com.eksystems.homes.login.vo.LoginVO;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import jakarta.servlet.http.HttpSession;
import java.time.LocalDate;
import java.util.*;
import java.util.concurrent.Callable;
import java.util.stream.Collectors;

@Controller
@RequestMapping("/asset/change")
public class AssetChangeController {

    private final SnapshotService snapshotService;
    private final ObjectMapper    objectMapper;
    private final GeminiService   geminiService;

    public AssetChangeController(SnapshotService snapshotService, ObjectMapper objectMapper, GeminiService geminiService) {
        this.snapshotService = snapshotService;
        this.objectMapper    = objectMapper;
        this.geminiService   = geminiService;
    }

    @GetMapping
    public String assetChange(Model model, HttpSession session) throws JsonProcessingException {
        LoginVO login    = (LoginVO) session.getAttribute("LoginVO");
        String familyId  = login.getFamilyId();

        List<AssetChangeSummaryVO> summaryList   = snapshotService.getAssetChangeSummary(familyId);
        List<AssetTypeMonthVO>     typeMonthList  = snapshotService.getAssetTypeMonthly(familyId);

        // ── KPI: 최신월 데이터 ──────────────────────────────
        AssetChangeSummaryVO latest = summaryList.isEmpty() ? null
                : summaryList.get(summaryList.size() - 1);
        AssetChangeSummaryVO prev   = summaryList.size() < 2 ? null
                : summaryList.get(summaryList.size() - 2);

        long momChange = (latest != null && prev != null)
                ? latest.getNetAssetAmt() - prev.getNetAssetAmt() : 0L;

        // ── 차트용 JSON 빌드 ─────────────────────────────────
        List<String> labels = summaryList.stream()
                .map(s -> s.getHstYymm().substring(0, 4) + "." + s.getHstYymm().substring(4, 6))
                .collect(Collectors.toList());

        // 순자산 트렌드
        List<Long> totalAssets  = summaryList.stream().map(AssetChangeSummaryVO::getTotalAssetAmt).collect(Collectors.toList());
        List<Long> totalLoans   = summaryList.stream().map(AssetChangeSummaryVO::getTotalLoanBalance).collect(Collectors.toList());
        List<Long> netAssets    = summaryList.stream().map(AssetChangeSummaryVO::getNetAssetAmt).collect(Collectors.toList());
        List<Long> liquidAssets = summaryList.stream().map(AssetChangeSummaryVO::getLiquidAssetAmt).collect(Collectors.toList());
        List<Long> fixedAssets  = summaryList.stream().map(AssetChangeSummaryVO::getFixedAssetAmt).collect(Collectors.toList());
        List<Long> incomes      = summaryList.stream().map(AssetChangeSummaryVO::getMonthlyIncome).collect(Collectors.toList());
        List<Long> expenses     = summaryList.stream().map(AssetChangeSummaryVO::getMonthlyExpense).collect(Collectors.toList());

        // MoM 순자산 증감
        List<Long> momList = new ArrayList<>();
        for (int i = 0; i < summaryList.size(); i++) {
            if (i == 0) { momList.add(0L); continue; }
            momList.add(summaryList.get(i).getNetAssetAmt() - summaryList.get(i - 1).getNetAssetAmt());
        }

        // 자산유형 목록 (전체 기간 등장한 유형)
        List<String> assetTypes = typeMonthList.stream()
                .map(AssetTypeMonthVO::getAssetTypeNm)
                .distinct()
                .collect(Collectors.toList());

        // 유형별 월별 금액 맵: typeNm → [label순 amount]
        Map<String, List<Long>> typeDataMap = new LinkedHashMap<>();
        for (String typeNm : assetTypes) {
            Map<String, Long> byMonth = typeMonthList.stream()
                    .filter(v -> typeNm.equals(v.getAssetTypeNm()))
                    .collect(Collectors.toMap(
                            v -> v.getHstYymm().substring(0, 4) + "." + v.getHstYymm().substring(4, 6),
                            AssetTypeMonthVO::getTotalAmount,
                            Long::sum));
            List<Long> amounts = labels.stream()
                    .map(lbl -> byMonth.getOrDefault(lbl, 0L))
                    .collect(Collectors.toList());
            typeDataMap.put(typeNm, amounts);
        }

        // 최신월 유형별 파이 (도넛)
        Map<String, Long> latestTypePie = new LinkedHashMap<>();
        if (latest != null) {
            String latestYymm = latest.getHstYymm();
            typeMonthList.stream()
                    .filter(v -> latestYymm.equals(v.getHstYymm()))
                    .forEach(v -> latestTypePie.merge(v.getAssetTypeNm(), v.getTotalAmount(), Long::sum));
        }

        model.addAttribute("summaryList",    summaryList);
        model.addAttribute("latest",         latest);
        model.addAttribute("prev",           prev);
        model.addAttribute("momChange",      momChange);
        model.addAttribute("labelsJson",     objectMapper.writeValueAsString(labels));
        model.addAttribute("totalAssetsJson", objectMapper.writeValueAsString(totalAssets));
        model.addAttribute("totalLoansJson", objectMapper.writeValueAsString(totalLoans));
        model.addAttribute("netAssetsJson",  objectMapper.writeValueAsString(netAssets));
        model.addAttribute("liquidJson",     objectMapper.writeValueAsString(liquidAssets));
        model.addAttribute("fixedJson",      objectMapper.writeValueAsString(fixedAssets));
        model.addAttribute("incomesJson",    objectMapper.writeValueAsString(incomes));
        model.addAttribute("expensesJson",   objectMapper.writeValueAsString(expenses));
        model.addAttribute("momJson",        objectMapper.writeValueAsString(momList));
        model.addAttribute("typeDataJson",   objectMapper.writeValueAsString(typeDataMap));
        model.addAttribute("latestPieJson",  objectMapper.writeValueAsString(latestTypePie));
        model.addAttribute("hasData",        !summaryList.isEmpty());
        model.addAttribute("aiContextJson",  objectMapper.writeValueAsString(
                buildAssetChangeAiContext(summaryList, typeDataMap, latestTypePie, momList,
                        latest, prev, momChange)));

        return "asset/assetChange";
    }

    @PostMapping("/analyze")
    @ResponseBody
    public Callable<Map<String, Object>> analyzeAssetChange(@RequestBody Map<String, Object> aiContext) {
        return () -> {
            try {
                String result = geminiService.analyzeFinancialReport(aiContext);
                return Map.of("success", true, "text", result);
            } catch (Exception e) {
                return Map.of("success", false, "text", "분석 중 오류가 발생했습니다: " + e.getMessage());
            }
        };
    }

    private Map<String, Object> buildAssetChangeAiContext(List<AssetChangeSummaryVO> summaryList,
                                                          Map<String, List<Long>> typeDataMap,
                                                          Map<String, Long> latestTypePie,
                                                          List<Long> momList,
                                                          AssetChangeSummaryVO latest,
                                                          AssetChangeSummaryVO prev,
                                                          long momChange) {
        Map<String, Object> ctx = new LinkedHashMap<>();
        ctx.put("reportTitle", "자산변동현황 분석 리포트");
        ctx.put("reportType", "assetChangeStatus");
        ctx.put("generatedAt", LocalDate.now().toString());
        ctx.put("dataMonths", summaryList.size());

        if (latest != null) {
            long totalAsset = latest.getTotalAssetAmt();
            long loan = latest.getTotalLoanBalance();
            long net = latest.getNetAssetAmt();
            double debtRatio = totalAsset > 0 ? Math.round(loan * 1000.0 / totalAsset) / 10.0 : 0.0;
            double liquidRatio = totalAsset > 0 ? Math.round(latest.getLiquidAssetAmt() * 1000.0 / totalAsset) / 10.0 : 0.0;
            ctx.put("latest", Map.of(
                    "hstYymm", latest.getHstYymm(),
                    "totalAsset", totalAsset,
                    "totalLoan", loan,
                    "netAsset", net,
                    "liquidAsset", latest.getLiquidAssetAmt(),
                    "fixedAsset", latest.getFixedAssetAmt(),
                    "monthlyIncome", latest.getMonthlyIncome(),
                    "monthlyExpense", latest.getMonthlyExpense(),
                    "debtRatioPct", debtRatio,
                    "liquidRatioPct", liquidRatio
            ));
        }

        if (prev != null) {
            ctx.put("previous", Map.of(
                    "hstYymm", prev.getHstYymm(),
                    "netAsset", prev.getNetAssetAmt(),
                    "totalAsset", prev.getTotalAssetAmt(),
                    "totalLoan", prev.getTotalLoanBalance()
            ));
        }

        long avgMom = momList.size() > 1
                ? Math.round(momList.stream().skip(1).mapToLong(Long::longValue).average().orElse(0.0))
                : 0L;
        ctx.put("movementSummary", Map.of(
                "latestMoM", momChange,
                "averageMoM", avgMom,
                "positiveMonths", momList.stream().filter(v -> v > 0).count(),
                "negativeMonths", momList.stream().filter(v -> v < 0).count()
        ));

        List<Map<String, Object>> monthly = new ArrayList<>();
        for (int i = 0; i < summaryList.size(); i++) {
            AssetChangeSummaryVO s = summaryList.get(i);
            monthly.add(Map.of(
                    "hstYymm", s.getHstYymm(),
                    "totalAsset", s.getTotalAssetAmt(),
                    "totalLoan", s.getTotalLoanBalance(),
                    "netAsset", s.getNetAssetAmt(),
                    "liquidAsset", s.getLiquidAssetAmt(),
                    "fixedAsset", s.getFixedAssetAmt(),
                    "monthlyIncome", s.getMonthlyIncome(),
                    "monthlyExpense", s.getMonthlyExpense(),
                    "momNetAsset", momList.get(i)
            ));
        }
        ctx.put("monthlyTrend", monthly);
        ctx.put("assetTypeTrend", typeDataMap);
        ctx.put("latestAssetTypeMix", latestTypePie);
        return ctx;
    }
}
