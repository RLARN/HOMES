package com.eksystems.homes.main.web;

import com.eksystems.homes.assistant.service.GeminiService;
import com.eksystems.homes.login.vo.LoginVO;
import com.eksystems.homes.scm.service.ScmService;
import com.eksystems.homes.scm.vo.ScmVO;
import jakarta.servlet.http.HttpSession;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import java.util.List;

@Controller
public class MainController {

    private final ScmService scmService;
    private final GeminiService geminiService;
    
    public MainController(ScmService scmService, GeminiService geminiService) {
        this.scmService = scmService;
        this.geminiService = geminiService;
    }

    @GetMapping({"/", "/main"})
    public String main(HttpSession session, Model model) {

    	LoginVO loginUser = (LoginVO) session.getAttribute("LoginVO");
    	
        // 필요하면 여기서 조건 세팅 (예: 로그인 사용자 기준)
        ScmVO cond = new ScmVO();
        cond.setFamilyId(loginUser.getFamilyId());
        cond.setRegId(loginUser.getUserId());
        // LoginVO loginVO = (LoginVO) session.getAttribute("LoginVO");
        // if (loginVO != null) cond.setRegId(loginVO.getUserId());

        List<ScmVO> requestList = scmService.getDepositRequestList(cond);

        long requestedTotal = requestList.stream()
                .mapToLong(v -> v.getAmount() == null ? 0L : v.getAmount())
                .sum();

        long requestedStandbyCount = requestList.stream()
                .filter(v -> "STANDBY".equals(v.getReqStatus()))
                .count();
        
        model.addAttribute("requestedTotal", requestedTotal);
        model.addAttribute("requestedStandbyCount", requestedStandbyCount);
        model.addAttribute("dailyQuote", geminiService.generateDailyQuote(loginUser.getUserNm()));

        return "main/main";
    }
}
