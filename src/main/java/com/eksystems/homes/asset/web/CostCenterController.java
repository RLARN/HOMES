package com.eksystems.homes.asset.web;

import com.eksystems.homes.asset.service.CashFlowService;
import com.eksystems.homes.asset.service.CostCenterService;
import com.eksystems.homes.asset.vo.CostCenterStatusVO;
import com.eksystems.homes.asset.vo.CostCenterVO;
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
@RequestMapping("/asset/costcenter")
public class CostCenterController {

    private final CostCenterService costCenterService;
    private final CashFlowService   cashFlowService;
    private final com.eksystems.homes.asset.service.SnapshotService snapshotService;

    public CostCenterController(CostCenterService costCenterService,
                                CashFlowService cashFlowService,
                                com.eksystems.homes.asset.service.SnapshotService snapshotService) {
        this.costCenterService = costCenterService;
        this.cashFlowService   = cashFlowService;
        this.snapshotService   = snapshotService;
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
        // 수입원 선택용
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

    // ── 비용센터 현황 ──────────────────────────────────────
    @GetMapping("/status")
    public String status(@RequestParam(required = false) String fromYymm,
                         @RequestParam(required = false) String toYymm,
                         Model model, HttpSession session) {
        String familyId = login(session).getFamilyId();

        // 기본값: 이번달 1개월
        String thisMonth = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMM"));
        if (fromYymm == null || fromYymm.isBlank()) fromYymm = thisMonth;
        if (toYymm   == null || toYymm.isBlank())   toYymm   = thisMonth;

        // 단일 월이고 HST가 있으면 HST 기반, 없으면 실시간
        boolean singleMonth = fromYymm.equals(toYymm);
        boolean hasHst      = singleMonth && snapshotService.hasSnapshot(familyId, fromYymm);

        List<CostCenterStatusVO> statusList;
        if (hasHst) {
            // HST 기반: 스냅샷된 값 그대로 사용 (months=1 고정)
            statusList = snapshotService.getCostCenterHst(familyId, fromYymm);
            for (CostCenterStatusVO s : statusList) {
                s.setTotalIncomeAmt(s.getIncomeMonthlyAmt()  != null ? s.getIncomeMonthlyAmt()  : 0L);
                s.setTotalExpenseAmt(s.getExpenseMonthlyAmt() != null ? s.getExpenseMonthlyAmt() : 0L);
                s.setBalance(s.getTotalIncomeAmt() - s.getTotalExpenseAmt());
            }
        } else {
            // 실시간 조회 (기간 합산)
            statusList = costCenterService.getStatusList(familyId, fromYymm, toYymm);
        }

        long grandIncome  = statusList.stream().mapToLong(s -> s.getTotalIncomeAmt()  != null ? s.getTotalIncomeAmt()  : 0L).sum();
        long grandExpense = statusList.stream().mapToLong(s -> s.getTotalExpenseAmt() != null ? s.getTotalExpenseAmt() : 0L).sum();

        String dispFrom = fromYymm.substring(0,4) + "년 " + fromYymm.substring(4,6) + "월";
        String dispTo   = toYymm.substring(0,4)   + "년 " + toYymm.substring(4,6)   + "월";

        model.addAttribute("statusList",   statusList);
        model.addAttribute("grandIncome",  grandIncome);
        model.addAttribute("grandExpense", grandExpense);
        model.addAttribute("grandBalance", grandIncome - grandExpense);
        model.addAttribute("fromYymm",     fromYymm);
        model.addAttribute("toYymm",       toYymm);
        model.addAttribute("dispFrom",     dispFrom);
        model.addAttribute("dispTo",       dispTo);
        model.addAttribute("hasHst",       hasHst);
        return "asset/costCenterStatus";
    }

    private LoginVO login(HttpSession session) {
        return (LoginVO) session.getAttribute("LoginVO");
    }
}
