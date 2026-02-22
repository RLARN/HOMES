package com.eksystems.homes.login.web;

import com.eksystems.homes.login.service.LoginService;
import com.eksystems.homes.login.vo.LoginVO;
import jakarta.servlet.http.HttpSession;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

@Controller
public class LoginController {

    private static final String SESSION_LOGIN_KEY = "LoginVO";

    private final LoginService loginService;

    public LoginController(LoginService loginService) {
        this.loginService = loginService;
    }

    @GetMapping("/login")
    public String loginPage(HttpSession session) {
        // ✅ 이미 로그인 되어 있으면 메인으로
        if (session.getAttribute(SESSION_LOGIN_KEY) != null) {
            return "redirect:/main";
        }
        return "login/login";
    }

    @PostMapping("/loginProcess")
    @ResponseBody
    public boolean loginProcess(
            @RequestParam String familyId,
            @RequestParam String userId,
            @RequestParam String userPwd,
            HttpSession session) {

        LoginVO loginUser = loginService.getLogin(session, familyId, userId, userPwd);
        System.out.println("[LOGIN] loginUser=" + loginUser);
        System.out.println("[LOGIN] session=" + session.getId());

        if (loginUser != null) {
            session.setAttribute("LoginVO", loginUser); // ✅ 여기
            return true;
        }

        return false;      // ❌ 비밀번호 틀림
    }

    /**
     * ✅ 로그아웃
     * - 세션 전체 무효화(권장)
     * - 로그인 페이지로 이동
     */
    @GetMapping("/logout")
    public String logout(HttpSession session) {
        try {
            session.invalidate(); // ✅ 세션 통째로 삭제
        } catch (Exception ignored) { }
        return "redirect:/login";
    }

    /**
     * (선택) AJAX 로그아웃이 필요하면 이걸로 쓰면 됨
     */
    @PostMapping("/logoutProcess")
    @ResponseBody
    public boolean logoutProcess(HttpSession session) {
        try {
            session.invalidate();
            return true;
        } catch (Exception e) {
            return false;
        }
    }
}
