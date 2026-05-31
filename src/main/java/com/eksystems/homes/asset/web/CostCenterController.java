package com.eksystems.homes.asset.web;

import com.eksystems.homes.assistant.service.GeminiService;
import com.eksystems.homes.asset.service.CashFlowService;
import com.eksystems.homes.asset.service.CostCenterService;
import com.eksystems.homes.asset.service.SnapshotService;
import com.eksystems.homes.asset.vo.CostCenterStatusVO;
import com.eksystems.homes.asset.vo.CostCenterVO;
import com.eksystems.homes.living.service.LivingService;
import com.eksystems.homes.living.vo.LivingIncomeMstVO;
import com.eksystems.homes.login.vo.LoginVO;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.http.HttpSession;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.Callable;
import java.util.stream.Collectors;

@Controller
@RequestMapping("/asset/costcenter")
public class CostCenterController {

    private final CostCenterService costCenterService;
    private final CashFlowService   cashFlowService;
    private final SnapshotService   snapshotService;
    private final LivingService     livingService;
    private final GeminiService     geminiService;
    private final ObjectMapper      objectMapper;

    public CostCenterController(CostCenterService costCenterService,
                                CashFlowService cashFlowService,
                                SnapshotService snapshotService,
                                LivingService livingService,
                                GeminiService geminiService,
                                ObjectMapper objectMapper) {
        this.costCenterService = costCenterService;
        this.cashFlowService   = cashFlowService;
        this.snapshotService   = snapshotService;
        this.livingService     = livingService;
        this.geminiService     = geminiService;
        this.objectMapper      = objectMapper;
    }

    // ── 목록 ──────────────────────────────────────────────
    @GetMapping
    public String list(@RequestParam(required = false) String useYn,
                       @RequestParam(required = false) String error,
                       Model model, HttpSession session) {
        String familyId = login(session).getFamilyId();
        List<CostCenterVO> list = costCenterService.getList(familyId, useYn);

        long totalAmt = list.stream()
                .filter(c -> "Y".equals(c.getUseYn()))
                .mapToLong(c -> c.getMonthlyAmt() != null ? c.getMonthlyAmt() : 0L)
                .sum();

        model.addAttribute("ccList",    list);
        model.addAttribute("totalAmt",  totalAmt);
        model.addAttribute("useYn",     useYn);
        model.addAttribute("error",     error);
        model.addAttribute("incomeList", cashFlowService.getIncomePlansForCostCenter(familyId));
        return "asset/costCenter";
    }

    // ── 저장 (AJAX) ───────────────────────────────────────
    @PostMapping("/save")
    @ResponseBody
    public Map<String, Object> save(@RequestBody CostCenterVO vo, HttpSession session) {
        try {
            LoginVO login = login(session);
            vo.setFamilyId(login.getFamilyId());
            if (vo.getCcType() == null || vo.getCcType().isBlank()) vo.setCcType("MANUAL");
            costCenterService.save(vo, login.getUserId());
            return Map.of("success", true);
        } catch (Exception e) {
            return Map.of("success", false, "message", e.getMessage());
        }
    }

    // ── 삭제 (AJAX) ───────────────────────────────────────
    @PostMapping("/delete")
    @ResponseBody
    public Map<String, Object> delete(@RequestBody Map<String, Object> body, HttpSession session) {
        try {
            LoginVO login = login(session);
            Long ccSeq = Long.valueOf(body.get("ccSeq").toString());
            costCenterService.delete(login.getFamilyId(), ccSeq, login.getUserId());
            return Map.of("success", true);
        } catch (IllegalStateException e) {
            return Map.of("success", false, "message", e.getMessage());
        } catch (Exception e) {
            return Map.of("success", false, "message", "삭제 중 오류가 발생했습니다.");
        }
    }

    // ── 수지계정 현황 ──────────────────────────────────────
    @GetMapping("/status")
    public String status(@RequestParam(required = false) String fromYymm,
                         @RequestParam(required = false) String toYymm,
                         Model model, HttpSession session) throws JsonProcessingException {
        String familyId = login(session).getFamilyId();

        String thisMonth = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMM"));
        if (fromYymm == null || fromYymm.isBlank()) fromYymm = thisMonth;
        if (toYymm   == null || toYymm.isBlank())   toYymm   = thisMonth;

        boolean singleMonth = fromYymm.equals(toYymm);
        boolean hasHst;
        List<CostCenterStatusVO> statusList;

        if (singleMonth) {
            // 단일 월: 스냅샷 있으면 HST, 없으면 실시간
            hasHst = snapshotService.hasSnapshot(familyId, fromYymm);
            if (hasHst) {
                statusList = snapshotService.getCostCenterHst(familyId, fromYymm);
                for (CostCenterStatusVO s : statusList) {
                    long inc = s.getIncomeMonthlyAmt()  != null ? s.getIncomeMonthlyAmt()  : 0L;
                    long exp = s.getExpenseMonthlyAmt() != null ? s.getExpenseMonthlyAmt() : 0L;
                    s.setTotalIncomeAmt(inc);
                    s.setTotalExpenseAmt(exp);
                    s.setBalance(inc - exp);
                }
            } else {
                statusList = costCenterService.getStatusList(familyId, fromYymm, toYymm);
            }
        } else {
            // 멀티 월: 월별로 스냅샷 우선 집계
            List<String> months = listMonths(fromYymm, toYymm);
            long hstCount = months.stream()
                    .filter(ym -> snapshotService.hasSnapshot(familyId, ym))
                    .count();
            hasHst = hstCount > 0;
            statusList = buildMultiMonthStatus(familyId, months);
        }

        // ── 정기지출 계획 항목 하위 주입 ────────────────────────
        var expPlanMap = costCenterService.getExpensePlanMapByCC(familyId);
        statusList.forEach(s -> s.setExpensePlans(
                expPlanMap.getOrDefault(s.getCcSeq(), Collections.emptyList())));

        // ── 수기 현금흐름 조회 및 합산 ───────────────────────────
        List<LivingIncomeMstVO> allManual = livingService.getIncomeListByRange(familyId, fromYymm, toYymm);

        // CC_SEQ 기준 수기 수입/지출 합계 맵
        Map<Long, Long> manualIncByCC = allManual.stream()
                .filter(m -> "INCOME".equals(m.getFlowType()))
                .collect(Collectors.groupingBy(LivingIncomeMstVO::getCcSeq,
                        Collectors.summingLong(m -> m.getActualAmt() != null ? m.getActualAmt() : 0L)));
        Map<Long, Long> manualExpByCC = allManual.stream()
                .filter(m -> !"INCOME".equals(m.getFlowType()))
                .collect(Collectors.groupingBy(LivingIncomeMstVO::getCcSeq,
                        Collectors.summingLong(m -> m.getActualAmt() != null ? m.getActualAmt() : 0L)));

        // CC_SEQ 기준 수기 항목 목록 맵 (하위 표시용)
        Map<Long, List<LivingIncomeMstVO>> manualByCC = allManual.stream()
                .collect(Collectors.groupingBy(LivingIncomeMstVO::getCcSeq));

        // 수기 금액을 totalIncome/Expense 에 합산 + manualEntries 주입
        for (CostCenterStatusVO s : statusList) {
            long manualInc = manualIncByCC.getOrDefault(s.getCcSeq(), 0L);
            long manualExp = manualExpByCC.getOrDefault(s.getCcSeq(), 0L);
            s.setTotalIncomeAmt((s.getTotalIncomeAmt()  != null ? s.getTotalIncomeAmt()  : 0L) + manualInc);
            s.setTotalExpenseAmt((s.getTotalExpenseAmt() != null ? s.getTotalExpenseAmt() : 0L) + manualExp);
            s.setBalance(s.getTotalIncomeAmt() - s.getTotalExpenseAmt());
            s.setManualEntries(manualByCC.getOrDefault(s.getCcSeq(), Collections.emptyList()));
        }

        long grandIncome  = statusList.stream().mapToLong(s -> s.getTotalIncomeAmt()  != null ? s.getTotalIncomeAmt()  : 0L).sum();
        long grandExpense = statusList.stream().mapToLong(s -> s.getTotalExpenseAmt() != null ? s.getTotalExpenseAmt() : 0L).sum();

        String dispFrom = fromYymm.substring(0, 4) + "년 " + fromYymm.substring(4, 6) + "월";
        String dispTo   = toYymm.substring(0, 4)   + "년 " + toYymm.substring(4, 6)   + "월";

        model.addAttribute("statusList",   statusList);
        model.addAttribute("grandIncome",  grandIncome);
        model.addAttribute("grandExpense", grandExpense);
        model.addAttribute("grandBalance", grandIncome - grandExpense);
        model.addAttribute("fromYymm",     fromYymm);
        model.addAttribute("toYymm",       toYymm);
        model.addAttribute("dispFrom",     dispFrom);
        model.addAttribute("dispTo",       dispTo);
        model.addAttribute("hasHst",       hasHst);
        model.addAttribute("aiContextJson", objectMapper.writeValueAsString(
                buildStatusAiContext(fromYymm, toYymm, dispFrom, dispTo, hasHst,
                        statusList, grandIncome, grandExpense)));
        return "asset/costCenterStatus";
    }

    @PostMapping("/status/analyze")
    @ResponseBody
    public Callable<Map<String, Object>> analyzeStatus(@RequestBody Map<String, Object> aiContext) {
        return () -> {
            try {
                String result = geminiService.analyzeFinancialReport(aiContext);
                return Map.of("success", true, "text", result);
            } catch (Exception e) {
                return Map.of("success", false, "text", "분석 중 오류가 발생했습니다: " + e.getMessage());
            }
        };
    }

    private Map<String, Object> buildStatusAiContext(String fromYymm,
                                                     String toYymm,
                                                     String dispFrom,
                                                     String dispTo,
                                                     boolean hasHst,
                                                     List<CostCenterStatusVO> statusList,
                                                     long grandIncome,
                                                     long grandExpense) {
        Map<String, Object> ctx = new LinkedHashMap<>();
        ctx.put("reportTitle", "수지계정현황 분석 리포트");
        ctx.put("reportType", "costCenterStatus");
        ctx.put("generatedAt", LocalDate.now().toString());
        ctx.put("period", Map.of(
                "fromYymm", fromYymm,
                "toYymm", toYymm,
                "display", dispFrom + " ~ " + dispTo,
                "snapshotBased", hasHst
        ));

        long grandBalance = grandIncome - grandExpense;
        double expenseRate = grandIncome > 0 ? Math.round(grandExpense * 1000.0 / grandIncome) / 10.0 : 0.0;
        ctx.put("summary", Map.of(
                "totalIncome", grandIncome,
                "totalExpense", grandExpense,
                "balance", grandBalance,
                "expenseRatePct", expenseRate,
                "costCenterCount", statusList.size()
        ));

        List<Map<String, Object>> centers = statusList.stream()
                .map(s -> {
                    long income = s.getTotalIncomeAmt() != null ? s.getTotalIncomeAmt() : 0L;
                    long expense = s.getTotalExpenseAmt() != null ? s.getTotalExpenseAmt() : 0L;
                    long balance = s.getBalance() != null ? s.getBalance() : income - expense;

                    Map<String, Object> row = new LinkedHashMap<>();
                    row.put("ccSeq", s.getCcSeq());
                    row.put("name", s.getCcNm());
                    row.put("type", s.getCcType());
                    row.put("incomePlanName", s.getIncomePlanNm());
                    row.put("income", income);
                    row.put("expense", expense);
                    row.put("balance", balance);
                    row.put("expenseSharePct", grandExpense > 0
                            ? Math.round(expense * 1000.0 / grandExpense) / 10.0 : 0.0);
                    row.put("regularExpenseItems", s.getExpensePlans() == null ? List.of()
                            : s.getExpensePlans().stream().limit(8).map(p -> Map.of(
                                    "name", p.getPlanNm() == null ? "" : p.getPlanNm(),
                                    "flowType", p.getFlowType() == null ? "" : p.getFlowType(),
                                    "amount", p.getAmount() == null ? 0L : p.getAmount()
                            )).toList());
                    row.put("manualEntries", s.getManualEntries() == null ? List.of()
                            : s.getManualEntries().stream().limit(8).map(m -> Map.of(
                                    "title", m.getTitle() == null ? "" : m.getTitle(),
                                    "flowType", m.getFlowType() == null ? "" : m.getFlowType(),
                                    "amount", m.getActualAmt() == null ? 0L : m.getActualAmt(),
                                    "yymm", m.getIncomeYymm() == null ? "" : m.getIncomeYymm()
                            )).toList());
                    return row;
                })
                .toList();
        ctx.put("costCenters", centers);
        ctx.put("topExpenseCenters", centers.stream()
                .sorted((a, b) -> Long.compare(((Number) b.get("expense")).longValue(), ((Number) a.get("expense")).longValue()))
                .limit(5)
                .toList());
        ctx.put("negativeBalanceCenters", centers.stream()
                .filter(v -> ((Number) v.get("balance")).longValue() < 0)
                .toList());
        return ctx;
    }

    // ── 멀티 월 집계: 월별로 스냅샷 우선, 없으면 실시간 계획(×1) ──
    private List<CostCenterStatusVO> buildMultiMonthStatus(String familyId, List<String> months) {
        // ccSeq 순서 유지: LinkedHashMap
        Map<Long, CostCenterStatusVO> accumulated = new LinkedHashMap<>();

        for (String ym : months) {
            List<CostCenterStatusVO> monthData;

            if (snapshotService.hasSnapshot(familyId, ym)) {
                // 스냅샷 데이터 사용
                monthData = snapshotService.getCostCenterHst(familyId, ym);
                for (CostCenterStatusVO s : monthData) {
                    long inc = s.getIncomeMonthlyAmt()  != null ? s.getIncomeMonthlyAmt()  : 0L;
                    long exp = s.getExpenseMonthlyAmt() != null ? s.getExpenseMonthlyAmt() : 0L;
                    s.setTotalIncomeAmt(inc);
                    s.setTotalExpenseAmt(exp);
                }
            } else {
                // 스냅샷 없는 달: 현재 계획 × 1개월
                monthData = costCenterService.getStatusList(familyId, ym, ym);
            }

            for (CostCenterStatusVO s : monthData) {
                if (s.getCcSeq() == null) continue;

                CostCenterStatusVO acc = accumulated.computeIfAbsent(s.getCcSeq(), k -> {
                    CostCenterStatusVO v = new CostCenterStatusVO();
                    v.setCcSeq(s.getCcSeq());
                    v.setCcNm(s.getCcNm());
                    v.setCcType(s.getCcType());
                    v.setIncomePlanNm(s.getIncomePlanNm());
                    v.setIncomeMonthlyAmt(s.getIncomeMonthlyAmt());
                    v.setExpenseMonthlyAmt(s.getExpenseMonthlyAmt());
                    v.setTotalIncomeAmt(0L);
                    v.setTotalExpenseAmt(0L);
                    return v;
                });

                acc.setTotalIncomeAmt(acc.getTotalIncomeAmt()
                        + (s.getTotalIncomeAmt()  != null ? s.getTotalIncomeAmt()  : 0L));
                acc.setTotalExpenseAmt(acc.getTotalExpenseAmt()
                        + (s.getTotalExpenseAmt() != null ? s.getTotalExpenseAmt() : 0L));
            }
        }

        List<CostCenterStatusVO> result = new ArrayList<>(accumulated.values());
        result.forEach(s -> s.setBalance(s.getTotalIncomeAmt() - s.getTotalExpenseAmt()));
        return result;
    }

    // ── YYYYMM 범위 내 월 목록 ────────────────────────────
    private List<String> listMonths(String fromYymm, String toYymm) {
        List<String> months = new ArrayList<>();
        try {
            LocalDate from = LocalDate.of(
                    Integer.parseInt(fromYymm.substring(0, 4)),
                    Integer.parseInt(fromYymm.substring(4, 6)), 1);
            LocalDate to = LocalDate.of(
                    Integer.parseInt(toYymm.substring(0, 4)),
                    Integer.parseInt(toYymm.substring(4, 6)), 1);
            DateTimeFormatter fmt = DateTimeFormatter.ofPattern("yyyyMM");
            while (!from.isAfter(to)) {
                months.add(from.format(fmt));
                from = from.plusMonths(1);
            }
        } catch (Exception e) {
            months.add(fromYymm);
        }
        return months;
    }

    private LoginVO login(HttpSession session) {
        return (LoginVO) session.getAttribute("LoginVO");
    }
}
