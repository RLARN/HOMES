package com.eksystems.homes.asset.web;

import com.eksystems.homes.asset.service.AssetService;
import com.eksystems.homes.asset.service.CashFlowService;
import com.eksystems.homes.asset.service.CostCenterService;
import com.eksystems.homes.asset.vo.CashFlowPlanVO;
import com.eksystems.homes.asset.vo.CashFlowTypeVO;
import com.eksystems.homes.living.service.LivingService;
import com.eksystems.homes.login.vo.LoginVO;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.http.HttpSession;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@Controller
@RequestMapping("/asset")
public class CashFlowController {

    private static final String INCOME  = "INCOME";
    private static final String EXPENSE = "EXPENSE";

    private final CashFlowService   cashFlowService;
    private final AssetService      assetService;
    private final CostCenterService costCenterService;
    private final LivingService     livingService;

    public CashFlowController(CashFlowService cashFlowService,
                              AssetService assetService,
                              CostCenterService costCenterService,
                              LivingService livingService) {
        this.cashFlowService   = cashFlowService;
        this.assetService      = assetService;
        this.costCenterService = costCenterService;
        this.livingService     = livingService;
    }

    // ── 정기수입 목록 ─────────────────────────────────────
    @GetMapping("/income")
    public String incomeList(@RequestParam(required = false) String useYn,
                             Model model, HttpSession session) {
        return planList(INCOME, useYn, "asset/income", model, session);
    }

    // ── 정기수입 폼 ───────────────────────────────────────
    @GetMapping("/income/form")
    public String incomeForm(@RequestParam(required = false) Long planSeq,
                             Model model, HttpSession session) {
        return planForm(INCOME, planSeq, "asset/incomeForm", model, session);
    }

    // ── 정기수입 저장 ─────────────────────────────────────
    @PostMapping("/income/save")
    public String incomeSave(CashFlowPlanVO vo,
                             @RequestParam String amountStr,
                             HttpSession session) {
        LoginVO loginVO = login(session);
        vo.setFamilyId(loginVO.getFamilyId());
        vo.setFlowType(INCOME);
        vo.setAmount(parseAmount(amountStr));
        cashFlowService.savePlan(vo, loginVO.getUserId());
        return "redirect:/asset/income";
    }

    // ── 정기수입 삭제 ─────────────────────────────────────
    @PostMapping("/income/delete")
    public String incomeDelete(@RequestParam Long planSeq,
                               jakarta.servlet.http.HttpServletRequest req,
                               HttpSession session) {
        LoginVO loginVO = login(session);
        try {
            cashFlowService.deleteIncomePlan(loginVO.getFamilyId(), planSeq, loginVO.getUserId());
        } catch (IllegalStateException e) {
            // 사용 중 → 에러 메시지를 쿼리 파라미터로 전달
            return "redirect:/asset/income?error=" + java.net.URLEncoder.encode(e.getMessage(), java.nio.charset.StandardCharsets.UTF_8);
        }
        return "redirect:/asset/income";
    }

    // ── 정기수입 사용여부 토글 (AJAX) ─────────────────────
    @PostMapping("/income/toggle")
    @ResponseBody
    public Map<String, Object> incomeToggle(@RequestParam Long planSeq, HttpSession session) {
        return toggle(planSeq, session);
    }

    // ── 정기지출 목록 ─────────────────────────────────────
    @GetMapping("/expense")
    public String expenseList(@RequestParam(required = false) String useYn,
                              Model model, HttpSession session) {
        return planList(EXPENSE, useYn, "asset/expense", model, session);
    }

    // ── 정기지출 폼 ───────────────────────────────────────
    @GetMapping("/expense/form")
    public String expenseForm(@RequestParam(required = false) Long planSeq,
                              Model model, HttpSession session) {
        return planForm(EXPENSE, planSeq, "asset/expenseForm", model, session);
    }

    // ── 정기지출 저장 ─────────────────────────────────────
    @PostMapping("/expense/save")
    public String expenseSave(CashFlowPlanVO vo,
                              @RequestParam String amountStr,
                              HttpSession session) {
        LoginVO loginVO = login(session);
        vo.setFamilyId(loginVO.getFamilyId());
        // flowType은 폼에서 직접 선택 (EXPENSE/SAVING/INVEST)
        vo.setAmount(parseAmount(amountStr));
        cashFlowService.savePlan(vo, loginVO.getUserId());
        return "redirect:/asset/expense";
    }

    // ── 정기지출 삭제 ─────────────────────────────────────
    @PostMapping("/expense/delete")
    public String expenseDelete(@RequestParam Long planSeq, HttpSession session) {
        LoginVO loginVO = login(session);
        // deletePlan 내부에서 AUTO 비용센터 연동 삭제까지 처리
        cashFlowService.deletePlan(loginVO.getFamilyId(), planSeq, loginVO.getUserId());
        return "redirect:/asset/expense";
    }

    // ── 정기지출 사용여부 토글 (AJAX) ─────────────────────
    @PostMapping("/expense/toggle")
    @ResponseBody
    public Map<String, Object> expenseToggle(@RequestParam Long planSeq, HttpSession session) {
        return toggle(planSeq, session);
    }

    // ── 공통 헬퍼 ────────────────────────────────────────

    private String planList(String flowCategory, String useYn,
                            String viewName, Model model, HttpSession session) {
        String familyId = login(session).getFamilyId();
        List<CashFlowPlanVO> planList = cashFlowService.getPlanList(familyId, flowCategory, useYn);

        long totalAmount = planList.stream()
                .filter(p -> "Y".equals(p.getUseYn()))
                .mapToLong(p -> p.getAmount() != null ? p.getAmount() : 0L)
                .sum();

        model.addAttribute("planList",    planList);
        model.addAttribute("totalAmount", totalAmount);
        model.addAttribute("useYn",       useYn);
        model.addAttribute("flowCategory", flowCategory);
        return viewName;
    }

    private String planForm(String flowCategory, Long planSeq,
                            String viewName, Model model, HttpSession session) {
        LoginVO loginVO = login(session);
        List<CashFlowTypeVO> typeList = cashFlowService.getTypeList(flowCategory);

        CashFlowPlanVO plan = new CashFlowPlanVO();
        plan.setUseYn("Y");
        plan.setCycleNum(1);
        plan.setCycleUnit("MONTH");

        if (planSeq != null) {
            CashFlowPlanVO found = cashFlowService.getPlanDetail(loginVO.getFamilyId(), planSeq);
            if (found != null) plan = found;
        }

        model.addAttribute("plan",         plan);
        model.addAttribute("typeList",     typeList);
        model.addAttribute("flowCategory", flowCategory);

        // 정기지출 폼: 비용센터, 생활비 항목 선택용 데이터 추가
        if (EXPENSE.equals(flowCategory)) {
            model.addAttribute("costCenterList",  costCenterService.getList(loginVO.getFamilyId(), "Y"));
            model.addAttribute("loanList",        assetService.getLoanList(loginVO.getFamilyId(), "N"));
            model.addAttribute("livingCatList",   livingService.getCatListWithItems(loginVO.getFamilyId()));
        }

        return viewName;
    }

    private Map<String, Object> toggle(Long planSeq, HttpSession session) {
        LoginVO loginVO = login(session);
        try {
            CashFlowPlanVO detail = cashFlowService.getPlanDetail(loginVO.getFamilyId(), planSeq);
            if (detail == null) return Map.of("success", false, "message", "항목을 찾을 수 없습니다.");
            cashFlowService.toggleUseYn(loginVO.getFamilyId(), planSeq, detail.getUseYn(), loginVO.getUserId());
            String next = "Y".equals(detail.getUseYn()) ? "N" : "Y";
            return Map.of("success", true, "useYn", next);
        } catch (Exception e) {
            return Map.of("success", false, "message", e.getMessage());
        }
    }

    private LoginVO login(HttpSession session) {
        return (LoginVO) session.getAttribute("LoginVO");
    }

    private Long parseAmount(String s) {
        if (s == null || s.isBlank()) return 0L;
        try { return Long.parseLong(s.replaceAll("[^0-9]", "")); }
        catch (NumberFormatException e) { return 0L; }
    }

    private LocalDate parseDate(String s) {
        if (s == null || s.isBlank()) return null;
        try { return LocalDate.parse(s.trim()); } catch (Exception e) { return null; }
    }
}
