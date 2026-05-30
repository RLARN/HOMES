package com.eksystems.homes.living.web;

import com.eksystems.homes.asset.service.CashFlowService;
import com.eksystems.homes.asset.service.CostCenterService;
import com.eksystems.homes.asset.vo.CostCenterVO;
import com.eksystems.homes.living.service.LivingService;
import com.eksystems.homes.living.vo.*;
import com.eksystems.homes.living.vo.ManualCashflowVO;
import com.eksystems.homes.login.vo.LoginVO;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.http.HttpSession;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;

@Controller
@RequestMapping("/living")
public class LivingController {

    private final LivingService     livingService;
    private final CashFlowService   cashFlowService;
    private final CostCenterService costCenterService;

    public LivingController(LivingService livingService, CashFlowService cashFlowService,
                            CostCenterService costCenterService) {
        this.livingService     = livingService;
        this.cashFlowService   = cashFlowService;
        this.costCenterService = costCenterService;
    }

    // ─────────────────────────────────────────────────────
    // 기준정보설정
    // ─────────────────────────────────────────────────────

    @GetMapping("/budget")
    public String budgetSetting(Model model, HttpSession session) {
        String familyId = login(session).getFamilyId();
        List<LivingBudgetCatVO> catList = livingService.getCatListWithItems(familyId);

        long grandTotal = catList.stream()
                .mapToLong(c -> c.getTotalBudgetAmt() != null ? c.getTotalBudgetAmt() : 0L)
                .sum();

        // 비용센터 목록 (수입원 선택용)
        List<CostCenterVO> costCenterList = costCenterService.getList(familyId, "Y");

        // 항목에 연결된 비용센터들의 월 금액 합계 (수입 합계)
        long incomeTotal = catList.stream()
                .flatMap(c -> c.getItems().stream())
                .filter(i -> i.getCcSeq() != null)
                .mapToLong(i -> {
                    // ccSeq에 해당하는 비용센터 월 금액 조회
                    return costCenterList.stream()
                            .filter(cc -> cc.getCcSeq().equals(i.getCcSeq()))
                            .mapToLong(cc -> cc.getMonthlyAmt() != null ? cc.getMonthlyAmt() : 0L)
                            .sum();
                })
                .sum();

        // 이번달 수입 수기 등록 목록
        String thisMonth = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMM"));
        List<LivingIncomeMstVO> incomeEntries = livingService.getIncomeList(familyId, thisMonth);
        long incomeEntryTotal = incomeEntries.stream()
                .mapToLong(i -> i.getActualAmt() != null ? i.getActualAmt() : 0L)
                .sum();

        model.addAttribute("catList",          catList);
        model.addAttribute("grandTotal",        grandTotal);
        model.addAttribute("costCenterList",    costCenterList);
        model.addAttribute("incomeTotal",       incomeTotal);
        model.addAttribute("balance",           incomeTotal - grandTotal);
        model.addAttribute("incomeEntries",     incomeEntries);
        model.addAttribute("incomeEntryTotal",  incomeEntryTotal);
        model.addAttribute("thisMonth",         thisMonth);
        // 레거시 수입원 목록도 유지 (다른 화면에서 사용할 수 있으므로)
        model.addAttribute("incomeList", cashFlowService.getIncomePlansForCostCenter(familyId));
        return "living/budgetSetting";
    }

    /** 카테고리 저장 (AJAX) */
    @PostMapping("/budget/cat/save")
    @ResponseBody
    public Map<String, Object> saveCat(@RequestBody LivingBudgetCatVO vo, HttpSession session) {
        try {
            LoginVO login = login(session);
            vo.setFamilyId(login.getFamilyId());
            livingService.saveCat(vo, login.getUserId());
            return Map.of("success", true);
        } catch (Exception e) {
            return Map.of("success", false, "message", e.getMessage());
        }
    }

    /** 카테고리 삭제 (AJAX) */
    @PostMapping("/budget/cat/delete")
    @ResponseBody
    public Map<String, Object> deleteCat(@RequestBody Map<String, Object> body, HttpSession session) {
        try {
            LoginVO login = login(session);
            Long catSeq = Long.valueOf(body.get("catSeq").toString());
            LivingBudgetCatVO vo = new LivingBudgetCatVO();
            vo.setCatSeq(catSeq);
            vo.setFamilyId(login.getFamilyId());
            vo.setUseYn("N");
            livingService.saveCat(vo, login.getUserId());
            return Map.of("success", true);
        } catch (Exception e) {
            return Map.of("success", false, "message", e.getMessage());
        }
    }

    /** 항목 저장 (AJAX) */
    @PostMapping("/budget/item/save")
    @ResponseBody
    public Map<String, Object> saveItem(@RequestBody LivingBudgetItemVO vo, HttpSession session) {
        try {
            LoginVO login = login(session);
            vo.setFamilyId(login.getFamilyId());
            livingService.saveItem(vo, login.getUserId());
            return Map.of("success", true);
        } catch (Exception e) {
            return Map.of("success", false, "message", e.getMessage());
        }
    }

    /** 항목 삭제 (AJAX) */
    @PostMapping("/budget/item/delete")
    @ResponseBody
    public Map<String, Object> deleteItem(@RequestBody Map<String, Object> body, HttpSession session) {
        try {
            LoginVO login = login(session);
            Long itemSeq = Long.valueOf(body.get("itemSeq").toString());
            livingService.deleteItem(login.getFamilyId(), itemSeq, login.getUserId());
            return Map.of("success", true);
        } catch (Exception e) {
            return Map.of("success", false, "message", e.getMessage());
        }
    }

    // ─────────────────────────────────────────────────────
    // 수입 수기 등록
    // ─────────────────────────────────────────────────────

    // ─────────────────────────────────────────────────────
    // 수기 현금흐름 관리 (INCOME / EXPENSE)
    // ─────────────────────────────────────────────────────

    @GetMapping("/cashflow")
    public String cashflowPage(@RequestParam(required = false) String yymm,
                               Model model, HttpSession session) {
        LoginVO login   = login(session);
        String familyId = login.getFamilyId();
        if (yymm == null || yymm.isBlank()) {
            yymm = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMM"));
        }
        List<ManualCashflowVO> list = livingService.getManualCfList(familyId, yymm);
        List<CostCenterVO> ccList   = costCenterService.getList(familyId, "Y");

        long incomeTotal  = list.stream().filter(i -> "INCOME".equals(i.getFlowType()))
                .mapToLong(i -> i.getActualAmt() != null ? i.getActualAmt() : 0L).sum();
        long expenseTotal = list.stream().filter(i -> "EXPENSE".equals(i.getFlowType()))
                .mapToLong(i -> i.getActualAmt() != null ? i.getActualAmt() : 0L).sum();

        String dispYymm = yymm.substring(0, 4) + "년 " + yymm.substring(4, 6) + "월";

        model.addAttribute("cashflowList",  list);
        model.addAttribute("costCenterList", ccList);
        model.addAttribute("yymm",          yymm);
        model.addAttribute("dispYymm",      dispYymm);
        model.addAttribute("incomeTotal",   incomeTotal);
        model.addAttribute("expenseTotal",  expenseTotal);
        model.addAttribute("netBalance",    incomeTotal - expenseTotal);
        return "living/cashflow";
    }

    /** 수기 현금흐름 저장 (AJAX) */
    @PostMapping("/cashflow/save")
    @ResponseBody
    public Map<String, Object> saveCashflow(@RequestBody ManualCashflowVO vo, HttpSession session) {
        try {
            LoginVO login = login(session);
            vo.setFamilyId(login.getFamilyId());
            livingService.saveManualCf(vo, login.getUserId());
            return Map.of("success", true);
        } catch (Exception e) {
            return Map.of("success", false, "message", e.getMessage());
        }
    }

    /** 수기 현금흐름 삭제 (AJAX) */
    @PostMapping("/cashflow/delete")
    @ResponseBody
    public Map<String, Object> deleteCashflow(@RequestBody Map<String, Object> body, HttpSession session) {
        try {
            LoginVO login = login(session);
            Long cfSeq = Long.valueOf(body.get("cfSeq").toString());
            livingService.deleteManualCf(login.getFamilyId(), cfSeq);
            return Map.of("success", true);
        } catch (Exception e) {
            return Map.of("success", false, "message", e.getMessage());
        }
    }

    // ─────────────────────────────────────────────────────
    // 수입 수기 등록 (생활비 기준정보 페이지용)
    // ─────────────────────────────────────────────────────

    /** 수입 저장 (AJAX) */
    @PostMapping("/income/save")
    @ResponseBody
    public Map<String, Object> saveIncome(@RequestBody LivingIncomeMstVO vo, HttpSession session) {
        try {
            LoginVO login = login(session);
            vo.setFamilyId(login.getFamilyId());
            livingService.saveIncome(vo, login.getUserId());
            return Map.of("success", true);
        } catch (Exception e) {
            return Map.of("success", false, "message", e.getMessage());
        }
    }

    /** 수입 삭제 (AJAX) */
    @PostMapping("/income/delete")
    @ResponseBody
    public Map<String, Object> deleteIncome(@RequestBody Map<String, Object> body, HttpSession session) {
        try {
            LoginVO login = login(session);
            Long incomeSeq = Long.valueOf(body.get("incomeSeq").toString());
            livingService.deleteIncome(login.getFamilyId(), incomeSeq);
            return Map.of("success", true);
        } catch (Exception e) {
            return Map.of("success", false, "message", e.getMessage());
        }
    }

    // ─────────────────────────────────────────────────────
    // 생활비 관리 (월별 목록)
    // ─────────────────────────────────────────────────────

    @GetMapping("/expense")
    public String expenseList(Model model, HttpSession session) {
        String familyId = login(session).getFamilyId();
        List<LivingExpenseMstVO> expenseList = livingService.getExpenseList(familyId);

        // 이번달 YYYYMM
        String thisMonth = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMM"));
        model.addAttribute("expenseList", expenseList);
        model.addAttribute("thisMonth",   thisMonth);
        return "living/expenseList";
    }

    /** 월별 실적 입력 화면 */
    @GetMapping("/expense/{yymm}")
    public String expenseDetail(@PathVariable String yymm, Model model, HttpSession session) {
        LoginVO login    = login(session);
        String familyId  = login.getFamilyId();

        LivingExpenseMstVO mst = livingService.getOrCreateExpense(familyId, yymm, login.getUserId());
        List<LivingExpenseDtlVO> dtlList = livingService.getExpenseDtlList(familyId, mst.getExpSeq());

        // 카테고리별 그룹핑 (JSP에서 처리 쉽도록 catList도 전달)
        List<LivingBudgetCatVO> catList = livingService.getCatListWithItems(familyId);

        // 예산 합계 / 실제 합계
        long totalBudget = dtlList.stream().mapToLong(d -> d.getBudgetAmt() != null ? d.getBudgetAmt() : 0L).sum();
        long totalActual = dtlList.stream().mapToLong(d -> d.getActualAmt() != null ? d.getActualAmt() : 0L).sum();

        // 표시용 년월 문자열
        String dispYymm = yymm.substring(0, 4) + "년 " + yymm.substring(4, 6) + "월";

        model.addAttribute("mst",         mst);
        model.addAttribute("dtlList",     dtlList);
        model.addAttribute("catList",     catList);
        model.addAttribute("totalBudget", totalBudget);
        model.addAttribute("totalActual", totalActual);
        model.addAttribute("dispYymm",    dispYymm);
        model.addAttribute("yymm",        yymm);
        return "living/expenseDetail";
    }

    /** 항목별 실제 금액 저장 (AJAX) */
    @PostMapping("/expense/dtl/save")
    @ResponseBody
    public Map<String, Object> saveDtl(@RequestBody LivingExpenseDtlVO vo, HttpSession session) {
        try {
            LoginVO login = login(session);
            livingService.saveExpenseDtl(vo, login.getUserId());
            return Map.of("success", true);
        } catch (Exception e) {
            return Map.of("success", false, "message", e.getMessage());
        }
    }

    /** 전체 일괄 저장 (AJAX) */
    @PostMapping("/expense/dtl/saveAll")
    @ResponseBody
    public Map<String, Object> saveAllDtl(@RequestBody Map<String, Object> body, HttpSession session) {
        try {
            LoginVO login = login(session);
            Long expSeq = Long.valueOf(body.get("expSeq").toString());

            @SuppressWarnings("unchecked")
            List<Map<String, Object>> items = (List<Map<String, Object>>) body.get("items");

            List<LivingExpenseDtlVO> dtlList = items.stream().map(m -> {
                LivingExpenseDtlVO d = new LivingExpenseDtlVO();
                d.setItemSeq(Long.valueOf(m.get("itemSeq").toString()));
                d.setActualAmt(Long.valueOf(m.get("actualAmt").toString()));
                if (m.get("memo") != null) d.setMemo(m.get("memo").toString());
                return d;
            }).toList();

            livingService.saveAllExpenseDtl(expSeq, dtlList, login.getUserId());
            return Map.of("success", true);
        } catch (Exception e) {
            return Map.of("success", false, "message", e.getMessage());
        }
    }

    private LoginVO login(HttpSession session) {
        return (LoginVO) session.getAttribute("LoginVO");
    }
}
