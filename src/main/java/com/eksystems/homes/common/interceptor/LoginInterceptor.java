package com.eksystems.homes.common.interceptor;

import com.eksystems.homes.login.vo.LoginVO;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.springframework.web.servlet.HandlerInterceptor;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

public class LoginInterceptor implements HandlerInterceptor {

    private static final String SESSION_LOGIN_KEY = "LoginVO"; // ✅ 로그인 저장 키와 동일하게

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {

        String ctx = request.getContextPath();
        String uri = request.getRequestURI();

        // 1) 정적/기본 경로 패스
        if (uri.startsWith(ctx + "/css")
                || uri.startsWith(ctx + "/js")
                || uri.startsWith(ctx + "/assets")
                || uri.equals(ctx + "/favicon.ico")
                || uri.equals(ctx + "/sw.js")
                || uri.equals(ctx + "/manifest.json")) {
            return true;
        }

     // AJAX(JSON) 요청은 패스
        String accept = request.getHeader("Accept");
        if (accept != null && accept.contains("application/json")) {
            return true;
        }

        
        // 2) 로그인/에러는 무조건 패스 (여기서 루프 차단)
        if (uri.equals(ctx + "/login") || uri.startsWith(ctx + "/login/")
                || uri.equals(ctx + "/logout")
                || uri.equals(ctx + "/error") || uri.startsWith(ctx + "/error/")) {
            return true;
        }

        // 3) 세션 체크
        HttpSession session = request.getSession(false);

        LoginVO loginUser = null;
        if (session != null) {
            Object obj = session.getAttribute(SESSION_LOGIN_KEY); // ✅ "LoginVO"
            if (obj instanceof LoginVO) {
                loginUser = (LoginVO) obj;
            }
        }

        System.out.println("[INT] uri=" + uri
                + ", session=" + (session == null ? "null" : session.getId())
                + ", loginUser=" + (loginUser == null ? "null" : loginUser.getUserId()));

        if (loginUser != null) {
            return true;
        }

        // 4) 원래 가려던 경로(컨텍스트 제외) 저장
        String target = uri;
        if (target.startsWith(ctx)) target = target.substring(ctx.length());
        if (target.isBlank()) target = "/main";

        String redirect = URLEncoder.encode(target, StandardCharsets.UTF_8);
        response.sendRedirect(ctx + "/login?redirect=" + redirect);
        return false;
    }
}
