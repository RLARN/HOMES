package com.eksystems.homes;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

import jakarta.servlet.http.HttpServletRequest;

@Controller
public class ErrorController {

	@GetMapping("/error")
    public String handleError(HttpServletRequest request) {
        // 여기서 status 분기해도 되고, 지금은 공통 에러 페이지
        return "error"; // 👉 /WEB-INF/jsp/error.jsp
    }
}
