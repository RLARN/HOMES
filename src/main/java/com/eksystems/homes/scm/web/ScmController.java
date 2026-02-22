package com.eksystems.homes.scm.web;

import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.eksystems.homes.login.vo.LoginVO;
import com.eksystems.homes.scm.service.ScmService;
import com.eksystems.homes.scm.vo.ScmVO;

import jakarta.servlet.http.HttpSession;

@Controller
@RequestMapping("/scm")
public class ScmController {

    private final ScmService scmService;

    public ScmController(ScmService scmService) {
        this.scmService = scmService;
    }
    
    /**
     * 작성 화면 + 리스트
     * URL: /scm/purchase/purchaseRequest
     */
    @GetMapping("/purchase/purchaseRequest")
    public String purchaseRequestWrite() {
        return "scm/purchase/purchaseRequest";
    }
    
    /**
     * 작성 화면 + 리스트
     * URL: /scm/purchase/purchaseRequest
     */
    @GetMapping("/deposit/depositRequest")
    public String depositRequestWrite(
    		@RequestParam(required = false) String q,
    		@RequestParam(required = false) String status,
    		Model model,
    		HttpSession session
    		) {
    	
    	LoginVO loginUser = (LoginVO) session.getAttribute("LoginVO");
    	ScmVO scmVO = new ScmVO();
    	scmVO.setFamilyId(loginUser.getFamilyId());
		List<ScmVO> requestList = scmService.getDepositRequestList(scmVO);
    	model.addAttribute("requestList", requestList);
    	return "scm/deposit/depositRequest";
    }

    /**
     * 저장(상신) - AJAX용(JSON 반환)
     * URL: /scm/deposit/depositRequest/saveAjax
     */
    @PostMapping("/deposit/depositRequest/saveAjax")
    @ResponseBody
    public Map<String, Object> saveDepositRequestAjax(
            @RequestParam("storeInfo") String storeInfo,
            @RequestParam("amount") String amount,
            @RequestParam(value = "reqDesc", required = false) String reqDesc,
            HttpSession session
    ) {
        Map<String, Object> res = new HashMap<>();

        try {
            LoginVO loginUser = (LoginVO) session.getAttribute("LoginVO");
            if (loginUser == null) {
                res.put("success", false);
                res.put("message", "세션이 만료되었습니다. 다시 로그인해 주세요.");
                return res;
            }

            String requesterId = loginUser.getUserId();
            String familyId = loginUser.getFamilyId();

            // amount는 프론트에서 숫자만 보내도 되지만, 서버에서도 안전하게 처리
            long amountValue = Long.parseLong(amount.replaceAll("[^0-9]", ""));

            scmService.createDepositRequest(session, familyId, storeInfo, amountValue, reqDesc, requesterId);

            res.put("success", true);
            res.put("message", "입금요청이 상신되었습니다.");
            return res;

        } catch (Exception e) {
            res.put("success", false);
            res.put("message", "저장 실패: " + e.getMessage());
            return res;
        }
    }

    @ResponseBody
    @GetMapping("/deposit/depositRequest/detailJson")
    public Map<String, Object> detailJson(@RequestParam("id") Long depReqSeq, HttpSession session) {
        LoginVO loginUser = (LoginVO) session.getAttribute("LoginVO");
        if (loginUser == null) {
            throw new RuntimeException("NO_SESSION");
        }

        // ✅ 보안: 가족ID로 소유권 제한
        String familyId = loginUser.getFamilyId();

        ScmVO vo = scmService.getDepositRequestDetail(familyId, depReqSeq);
        if (vo == null) {
            throw new RuntimeException("NOT_FOUND");
        }

        Map<String, Object> res = new HashMap<>();
        res.put("depReqSeq", vo.getDepReqSeq());
        res.put("reqStatus", vo.getReqStatus());
        res.put("amount", String.format("%,d", vo.getAmount()));
        res.put("reqDesc", vo.getReqDesc());
        res.put("purItemSeq", vo.getPurItemSeq());
        res.put("storeInfo", vo.getStoreInfo());
        res.put("regId", vo.getRegId());

        // 날짜는 JSP/JS에서 쓰기 쉽게 문자열로
        if (vo.getRegDt() != null) {	
            res.put("regDt", vo.getRegDt().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm")));
        } else {
            res.put("regDt", "");
        }

        return res;
    }
}
