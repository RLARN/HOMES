package com.eksystems.homes.financial.web;

import com.eksystems.homes.asset.service.AssetService;
import com.eksystems.homes.asset.service.CashFlowService;
import com.eksystems.homes.asset.service.CostCenterService;
import com.eksystems.homes.asset.service.SnapshotService;
import com.eksystems.homes.asset.vo.AssetSummaryVO;
import com.eksystems.homes.asset.vo.AssetVO;
import com.eksystems.homes.asset.vo.CashFlowPlanVO;
import com.eksystems.homes.asset.vo.CostCenterStatusVO;
import com.eksystems.homes.asset.vo.LoanVO;
import com.eksystems.homes.living.service.LivingService;
import com.eksystems.homes.living.vo.LivingExpenseSummaryVO;
import com.eksystems.homes.living.vo.LivingIncomeMstVO;
import com.eksystems.homes.living.vo.ManualCashflowVO;
import com.eksystems.homes.login.vo.LoginVO;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

import jakarta.servlet.http.HttpSession;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Controller
@RequestMapping("/financial")
public class FinancialController {

    private final AssetService      assetService;
    private final CashFlowService   cashFlowService;
    private final CostCenterService costCenterService;
    private final SnapshotService   snapshotService;
    private final LivingService     livingService;

    public FinancialController(AssetService assetService,
                               CashFlowService cashFlowService,
                               CostCenterService costCenterService,
                               SnapshotService snapshotService,
                               LivingService livingService) {
        this.assetService      = assetService;
        this.cashFlowService   = cashFlowService;
        this.costCenterService = costCenterService;
        this.snapshotService   = snapshotService;
        this.livingService     = livingService;
    }

    @GetMapping("/statement")
    public String statement(
            @RequestParam(defaultValue = "monthly") String mode,
            @RequestParam(required = false) String period,
            @RequestParam(defaultValue = "live") String viewMode,
            Model model, HttpSession session) {

        LoginVO login   = (LoginVO) session.getAttribute("LoginVO");
        String familyId = login.getFamilyId();
        LocalDate now   = LocalDate.now();

        if (period == null || period.isBlank()) {
            period = "annual".equals(mode)
                    ? String.valueOf(now.getYear())
                    : now.format(DateTimeFormatter.ofPattern("yyyyMM"));
        }

        String fromYymm, toYymm, dispPeriod;
        int months;

        if ("annual".equals(mode)) {
            fromYymm   = period + "01";
            toYymm     = period + "12";
            months     = 12;
            dispPeriod = period + "년";
        } else {
            fromYymm   = period;
            toYymm     = period;
            months     = 1;
            dispPeriod = period.substring(0, 4) + "년 " + period.substring(4, 6) + "월";
        }

        // 전표처리 존재 여부 (월간만 해당)
        boolean hasSnapshot = "monthly".equals(mode) && snapshotService.hasSnapshot(familyId, period);
        // 전표처리본이 없으면 강제로 live
        if (!hasSnapshot) viewMode = "live";
        boolean useSnapshot = hasSnapshot && "snapshot".equals(viewMode);

        // ── [핵심] 비용센터별 손익 ────────────────────────────
        List<CostCenterStatusVO> ccList;
        if (useSnapshot) {
            ccList = snapshotService.getCostCenterHst(familyId, period);
            for (CostCenterStatusVO s : ccList) {
                long inc = s.getIncomeMonthlyAmt()  != null ? s.getIncomeMonthlyAmt()  : 0L;
                long exp = s.getExpenseMonthlyAmt() != null ? s.getExpenseMonthlyAmt() : 0L;
                s.setTotalIncomeAmt(inc);
                s.setTotalExpenseAmt(exp);
                s.setBalance(inc - exp);
            }
        } else {
            ccList = costCenterService.getStatusList(familyId, fromYymm, toYymm);
        }

        // 수기 현금흐름 (INCOME + EXPENSE) 전체 — CC_SEQ 기준 그룹핑 (MANUAL_CASHFLOW_MST)
        List<ManualCashflowVO> allManualEntries = livingService.getManualCfListByRange(familyId, fromYymm, toYymm);
        List<ManualCashflowVO> incomeEntries    = allManualEntries.stream()
                .filter(i -> "INCOME".equals(i.getFlowType())).toList();
        List<ManualCashflowVO> expenseEntries   = allManualEntries.stream()
                .filter(i -> "EXPENSE".equals(i.getFlowType())).toList();

        Map<Long, Long> manualIncomeByCC = incomeEntries.stream()
                .collect(Collectors.groupingBy(
                        ManualCashflowVO::getCcSeq,
                        Collectors.summingLong(i -> i.getActualAmt() != null ? i.getActualAmt() : 0L)
                ));
        Map<Long, Long> manualExpenseByCC = expenseEntries.stream()
                .collect(Collectors.groupingBy(
                        ManualCashflowVO::getCcSeq,
                        Collectors.summingLong(i -> i.getActualAmt() != null ? i.getActualAmt() : 0L)
                ));

        // 비용센터 손익 계산 (months 적용, 수기 지출도 반영)
        // snapshot 모드: totalIncome/Expense 이미 세팅됨, 수기 항목도 합산
        long ccIncomeTotal  = 0L;
        long ccExpenseTotal = 0L;
        for (CostCenterStatusVO cc : ccList) {
            long base_inc = useSnapshot
                    ? (cc.getTotalIncomeAmt()  != null ? cc.getTotalIncomeAmt()  : 0L)
                    : (cc.getIncomeMonthlyAmt()  != null ? cc.getIncomeMonthlyAmt()  : 0L) * months;
            long base_exp = useSnapshot
                    ? (cc.getTotalExpenseAmt() != null ? cc.getTotalExpenseAmt() : 0L)
                    : (cc.getExpenseMonthlyAmt() != null ? cc.getExpenseMonthlyAmt() : 0L) * months;
            long manualInc = manualIncomeByCC.getOrDefault(cc.getCcSeq(), 0L);
            long manualExp = manualExpenseByCC.getOrDefault(cc.getCcSeq(), 0L);

            cc.setTotalIncomeAmt(base_inc + manualInc);
            cc.setTotalExpenseAmt(base_exp + manualExp);
            cc.setBalance(base_inc + manualInc - base_exp - manualExp);

            ccIncomeTotal  += base_inc + manualInc;
            ccExpenseTotal += base_exp + manualExp;
        }
        long ccNetBalance = ccIncomeTotal - ccExpenseTotal;

        // ── CC별 상세 항목 (정기지출·생활비·수기) ─────────────
        List<CashFlowPlanVO> expensePlansAll = cashFlowService.getPlanList(familyId, "EXPENSE", "Y");
        List<CashFlowPlanVO> savingPlansAll  = cashFlowService.getPlanList(familyId, "SAVING",  "Y");
        List<CashFlowPlanVO> investPlansAll  = cashFlowService.getPlanList(familyId, "INVEST",  "Y");

        // SOURCE_PLAN_SEQ → CC_SEQ 역방향 맵 (AUTO CC는 플랜에 costCenterSeq가 없을 수 있음)
        Map<Long, Long> sourcePlanToCcSeq = ccList.stream()
                .filter(cc -> cc.getSourcePlanSeq() != null)
                .collect(Collectors.toMap(
                        cc -> cc.getSourcePlanSeq(),
                        cc -> cc.getCcSeq(),
                        (a, b) -> a));

        // CC_SEQ 기준 정기지출 그룹핑 (EXPENSE+SAVING+INVEST 통합)
        // costCenterSeq 직접 지정된 것 + AUTO CC의 sourcePlanSeq로 연결된 것 모두 포함
        Map<Long, List<CashFlowPlanVO>> plansByCC = new java.util.HashMap<>();
        java.util.stream.Stream.concat(
                java.util.stream.Stream.concat(expensePlansAll.stream(), savingPlansAll.stream()),
                investPlansAll.stream()
        ).forEach(p -> {
            Long ccSeq = null;
            if (p.getCostCenterSeq() != null && "CC".equals(p.getCostCenterType())) {
                ccSeq = p.getCostCenterSeq();
            } else if (p.getPlanSeq() != null && sourcePlanToCcSeq.containsKey(p.getPlanSeq())) {
                ccSeq = sourcePlanToCcSeq.get(p.getPlanSeq());
            }
            if (ccSeq != null) {
                plansByCC.computeIfAbsent(ccSeq, k -> new java.util.ArrayList<>()).add(p);
            }
        });

        // CC_SEQ 기준 생활비 항목 그룹핑
        Map<Long, List<com.eksystems.homes.living.vo.LivingBudgetItemVO>> livingByCC =
                livingService.getAllItemList(familyId).stream()
                        .filter(i -> i.getCcSeq() != null)
                        .collect(Collectors.groupingBy(
                                com.eksystems.homes.living.vo.LivingBudgetItemVO::getCcSeq));

        // CC_SEQ 기준 수기 수입/지출 그룹핑
        Map<Long, List<ManualCashflowVO>> manualIncListByCC = incomeEntries.stream()
                .collect(Collectors.groupingBy(ManualCashflowVO::getCcSeq));
        Map<Long, List<ManualCashflowVO>> manualExpListByCC = expenseEntries.stream()
                .collect(Collectors.groupingBy(ManualCashflowVO::getCcSeq));

        // ── [참고] 재무상태표 ─────────────────────────────────
        List<AssetVO>  assetList = assetService.getAssetList(familyId, "N");
        List<LoanVO>   loanList  = assetService.getLoanList(familyId, "N");
        AssetSummaryVO summary   = assetService.getAssetSummary(familyId);

        // ── [참고] 정기수입/지출 목록 ─────────────────────────
        List<CashFlowPlanVO> incomePlans  = cashFlowService.getPlanList(familyId, "INCOME",  "Y");
        List<CashFlowPlanVO> expensePlans = expensePlansAll;
        List<CashFlowPlanVO> savingPlans  = savingPlansAll;
        List<CashFlowPlanVO> investPlans  = investPlansAll;

        // ── [참고] 생활비 예산 vs 실적 ───────────────────────
        List<LivingExpenseSummaryVO> livingExpenses =
                livingService.getExpenseSummaryByRange(familyId, fromYymm, toYymm);

        model.addAttribute("mode",           mode);
        model.addAttribute("period",         period);
        model.addAttribute("viewMode",       viewMode);
        model.addAttribute("hasSnapshot",    hasSnapshot);
        model.addAttribute("useSnapshot",    useSnapshot);
        model.addAttribute("dispPeriod",     dispPeriod);
        model.addAttribute("months",         months);
        // 비용센터 손익 (핵심)
        model.addAttribute("ccList",             ccList);
        model.addAttribute("incomeEntries",      incomeEntries);
        model.addAttribute("expenseEntries",     expenseEntries);
        model.addAttribute("manualIncomeByCC",   manualIncomeByCC);
        model.addAttribute("manualExpenseByCC",  manualExpenseByCC);
        model.addAttribute("manualIncListByCC",  manualIncListByCC);
        model.addAttribute("manualExpListByCC",  manualExpListByCC);
        model.addAttribute("plansByCC",          plansByCC);
        model.addAttribute("livingByCC",         livingByCC);
        model.addAttribute("ccIncomeTotal",      ccIncomeTotal);
        model.addAttribute("ccExpenseTotal",     ccExpenseTotal);
        model.addAttribute("ccNetBalance",       ccNetBalance);
        // 재무상태표 (참고)
        model.addAttribute("assetList",      assetList);
        model.addAttribute("loanList",       loanList);
        model.addAttribute("summary",        summary);
        // 정기수입/지출 (참고)
        model.addAttribute("incomePlans",    incomePlans);
        model.addAttribute("expensePlans",   expensePlans);
        model.addAttribute("savingPlans",    savingPlans);
        model.addAttribute("investPlans",    investPlans);
        // 생활비 (참고)
        model.addAttribute("livingExpenses", livingExpenses);

        return "financial/statement";
    }
}
