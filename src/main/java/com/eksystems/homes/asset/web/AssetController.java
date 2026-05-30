package com.eksystems.homes.asset.web;

import com.eksystems.homes.asset.service.AssetService;
import com.eksystems.homes.asset.service.CostCenterService;
import com.eksystems.homes.asset.vo.AssetSummaryVO;
import com.eksystems.homes.asset.vo.AssetVO;
import com.eksystems.homes.asset.vo.CostCenterVO;
import com.eksystems.homes.asset.vo.LoanVO;
import com.eksystems.homes.login.vo.LoginVO;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import jakarta.servlet.http.HttpSession;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

@Controller
@RequestMapping("/asset")
public class AssetController {

    private final AssetService      assetService;
    private final CostCenterService costCenterService;

    public AssetController(AssetService assetService, CostCenterService costCenterService) {
        this.assetService      = assetService;
        this.costCenterService = costCenterService;
    }

    // ── 자산원장 목록 ─────────────────────────────────────
    @GetMapping("/ledger")
    public String ledgerList(@RequestParam(required = false) String disposeYn,
                             Model model,
                             HttpSession session) {
        LoginVO loginVO = (LoginVO) session.getAttribute("LoginVO");
        String familyId = loginVO.getFamilyId();

        List<AssetVO> assetList = assetService.getAssetList(familyId, disposeYn);
        AssetSummaryVO summary   = assetService.getAssetSummary(familyId);

        model.addAttribute("assetList",  assetList);
        model.addAttribute("summary",    summary);
        model.addAttribute("disposeYn",  disposeYn);
        return "asset/ledger";
    }

    // ── 자산원장 등록/수정 폼 ─────────────────────────────
    @GetMapping("/ledger/form")
    public String ledgerForm(@RequestParam(required = false) Long assetSeq,
                             Model model,
                             HttpSession session) {
        LoginVO loginVO  = (LoginVO) session.getAttribute("LoginVO");
        List<AssetVO> typeList = assetService.getAssetTypeList();

        AssetVO asset = new AssetVO();
        if (assetSeq != null) {
            asset = assetService.getAssetDetail(loginVO.getFamilyId(), assetSeq);
            if (asset == null) return "redirect:/asset/ledger";
        }

        // 비용센터 연동 여부 확인 (유동자산 체크박스 초기값)
        CostCenterVO linkedCc = null;
        if (assetSeq != null) {
            linkedCc = costCenterService.findBySourceAsset(loginVO.getFamilyId(), assetSeq);
        }

        model.addAttribute("asset",    asset);
        model.addAttribute("typeList", typeList);
        model.addAttribute("linkedCc", linkedCc);
        return "asset/ledgerForm";
    }

    // ── 자산원장 저장 ─────────────────────────────────────
    @PostMapping("/ledger/save")
    public String ledgerSave(@RequestParam(required = false) Long    assetSeq,
                             @RequestParam String assetNm,
                             @RequestParam String assetType,
                             @RequestParam String liquidYn,
                             @RequestParam String amountStr,
                             @RequestParam(required = false) String memo,
                             @RequestParam(required = false) String expectedRateStr,
                             @RequestParam(defaultValue = "1") String rateCycleNumStr,
                             @RequestParam(defaultValue = "YEAR") String rateCycleUnit,
                             @RequestParam(defaultValue = "N") String disposeYn,
                             @RequestParam(required = false) String disposeYmd,
                             @RequestParam(required = false) String disposeReason,
                             @RequestParam(defaultValue = "N") String registerAsCostCenter,
                             HttpSession session) {
        LoginVO loginVO = (LoginVO) session.getAttribute("LoginVO");

        AssetVO vo = new AssetVO();
        vo.setAssetSeq(assetSeq);
        vo.setFamilyId(loginVO.getFamilyId());
        vo.setAssetNm(assetNm);
        vo.setAssetType(assetType);
        vo.setLiquidYn(liquidYn);
        vo.setAmount(parseAmount(amountStr));
        vo.setMemo(memo);
        vo.setExpectedRate(parseRate(expectedRateStr));
        vo.setRateCycleNum(parseInteger(rateCycleNumStr) != null ? parseInteger(rateCycleNumStr) : 1);
        vo.setRateCycleUnit(rateCycleUnit != null && !rateCycleUnit.isBlank() ? rateCycleUnit : "YEAR");
        vo.setDisposeYn(disposeYn);
        vo.setDisposeYmd(parseDate(disposeYmd));
        vo.setDisposeReason(disposeReason);

        assetService.saveAsset(vo, loginVO.getUserId());

        // 비용센터 체크박스 처리 (유동자산일 때만)
        if ("Y".equals(liquidYn)) {
            if ("Y".equals(registerAsCostCenter)) {
                costCenterService.syncFromAsset(vo, loginVO.getUserId());
            } else {
                // 체크 해제 시 연동 비용센터 삭제
                if (assetSeq != null) {
                    costCenterService.unlinkFromAsset(loginVO.getFamilyId(), assetSeq, loginVO.getUserId());
                }
            }
        }

        return "redirect:/asset/ledger";
    }

    // ── 자산원장 삭제 (AJAX) ──────────────────────────────
    @PostMapping("/ledger/delete")
    @ResponseBody
    public Map<String, Object> ledgerDelete(@RequestParam Long assetSeq,
                                            HttpSession session) {
        Map<String, Object> res = new HashMap<>();
        LoginVO loginVO = (LoginVO) session.getAttribute("LoginVO");
        if (loginVO == null) {
            res.put("success", false); res.put("message", "세션이 만료되었습니다."); return res;
        }
        try {
            assetService.deleteAsset(loginVO.getFamilyId(), assetSeq, loginVO.getUserId());
            res.put("success", true);
        } catch (IllegalStateException e) {
            res.put("success", false); res.put("message", e.getMessage());
        } catch (Exception e) {
            res.put("success", false); res.put("message", "삭제에 실패했습니다: " + e.getMessage());
        }
        return res;
    }

    // ── 대출원장 목록 ─────────────────────────────────────
    @GetMapping("/loan")
    public String loanList(@RequestParam(required = false) String closeYn,
                           Model model,
                           HttpSession session) {
        LoginVO loginVO = (LoginVO) session.getAttribute("LoginVO");
        String familyId = loginVO.getFamilyId();

        List<LoanVO> loanList   = assetService.getLoanList(familyId, closeYn);
        AssetSummaryVO summary  = assetService.getAssetSummary(familyId);

        model.addAttribute("loanList", loanList);
        model.addAttribute("summary",  summary);
        model.addAttribute("closeYn",  closeYn);
        return "asset/loan";
    }

    // ── 대출원장 등록/수정 폼 ─────────────────────────────
    @GetMapping("/loan/form")
    public String loanForm(@RequestParam(required = false) Long loanSeq,
                           Model model,
                           HttpSession session) {
        LoginVO loginVO = (LoginVO) session.getAttribute("LoginVO");

        LoanVO loan = new LoanVO();
        if (loanSeq != null) {
            loan = assetService.getLoanDetail(loginVO.getFamilyId(), loanSeq);
            if (loan == null) return "redirect:/asset/loan";
        }

        model.addAttribute("loan", loan);
        return "asset/loanForm";
    }

    // ── 대출원장 저장 ─────────────────────────────────────
    @PostMapping("/loan/save")
    public String loanSave(@RequestParam(required = false) Long    loanSeq,
                           @RequestParam String loanNm,
                           @RequestParam String loanAmountStr,
                           @RequestParam String currentBalanceStr,
                           @RequestParam(required = false) String interestRateStr,
                           @RequestParam(required = false) String loanMonthsStr,
                           @RequestParam(required = false) String startYmd,
                           @RequestParam(required = false) String endYmd,
                           @RequestParam(required = false) String memo,
                           @RequestParam(defaultValue = "N") String closeYn,
                           @RequestParam(required = false) String closeYmd,
                           @RequestParam(required = false) String closeReason,
                           HttpSession session) {
        LoginVO loginVO = (LoginVO) session.getAttribute("LoginVO");

        LoanVO vo = new LoanVO();
        vo.setLoanSeq(loanSeq);
        vo.setFamilyId(loginVO.getFamilyId());
        vo.setLoanNm(loanNm);
        vo.setLoanAmount(parseAmount(loanAmountStr));
        vo.setCurrentBalance(parseAmount(currentBalanceStr));
        vo.setInterestRate(parseRate(interestRateStr));
        vo.setLoanMonths(parseInteger(loanMonthsStr));
        vo.setStartYmd(parseDate(startYmd));
        vo.setEndYmd(parseDate(endYmd));
        vo.setMemo(memo);
        vo.setCloseYn(closeYn);
        vo.setCloseYmd(parseDate(closeYmd));
        vo.setCloseReason(closeReason);

        assetService.saveLoan(vo, loginVO.getUserId());
        return "redirect:/asset/loan";
    }

    // ── 대출원장 삭제 (AJAX) ──────────────────────────────
    @PostMapping("/loan/delete")
    @ResponseBody
    public Map<String, Object> loanDelete(@RequestParam Long loanSeq,
                                          HttpSession session) {
        Map<String, Object> res = new HashMap<>();
        LoginVO loginVO = (LoginVO) session.getAttribute("LoginVO");
        if (loginVO == null) {
            res.put("success", false); res.put("message", "세션이 만료되었습니다."); return res;
        }
        try {
            assetService.deleteLoan(loginVO.getFamilyId(), loanSeq, loginVO.getUserId());
            res.put("success", true);
        } catch (Exception e) {
            res.put("success", false); res.put("message", "삭제에 실패했습니다: " + e.getMessage());
        }
        return res;
    }

    // ── 파싱 헬퍼 ────────────────────────────────────────
    private Long parseAmount(String s) {
        if (s == null || s.isBlank()) return 0L;
        try { return Long.parseLong(s.replaceAll("[^0-9]", "")); }
        catch (NumberFormatException e) { return 0L; }
    }

    private BigDecimal parseRate(String s) {
        if (s == null || s.isBlank()) return null;
        try { return new BigDecimal(s.trim()); }
        catch (NumberFormatException e) { return null; }
    }

    private Integer parseInteger(String s) {
        if (s == null || s.isBlank()) return null;
        try { return Integer.parseInt(s.trim()); }
        catch (NumberFormatException e) { return null; }
    }

    private LocalDate parseDate(String s) {
        if (s == null || s.isBlank()) return null;
        try { return LocalDate.parse(s.trim()); }
        catch (Exception e) { return null; }
    }
}
