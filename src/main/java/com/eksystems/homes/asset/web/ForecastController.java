package com.eksystems.homes.asset.web;

import com.eksystems.homes.assistant.service.GeminiService;
import com.eksystems.homes.asset.service.ForecastService;
import com.eksystems.homes.login.vo.LoginVO;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.http.HttpSession;
import java.util.Map;
import java.util.concurrent.Callable;

@Controller
@RequestMapping("/asset/forecast")
public class ForecastController {

    private final ForecastService forecastService;
    private final GeminiService   geminiService;

    public ForecastController(ForecastService forecastService, GeminiService geminiService) {
        this.forecastService = forecastService;
        this.geminiService   = geminiService;
    }

    @GetMapping
    public String forecastPage() {
        return "asset/forecast";
    }

    @GetMapping("/data")
    @ResponseBody
    public Map<String, Object> forecastData(
            @RequestParam(required = false) String untilYymm,
            @RequestParam(required = false, defaultValue = "90,95,100,105,110") String weights,
            HttpSession session) {

        LoginVO loginVO = (LoginVO) session.getAttribute("LoginVO");
        int months = parseMonths(untilYymm);
        int[] parsedWeights = parseWeights(weights);
        return forecastService.calcForecast(loginVO.getFamilyId(), months, parsedWeights);
    }

    /** 단순 AI 분석 — Callable로 비동기 처리 (Tomcat 스레드 블로킹 방지) */
    @PostMapping("/analyze")
    @ResponseBody
    public Callable<Map<String, Object>> analyze(@RequestBody Map<String, Object> aiContext) {
        return () -> {
            try {
                String result = geminiService.analyzeAssetForecast(aiContext);
                return Map.of("success", true, "text", result);
            } catch (Exception e) {
                return Map.of("success", false, "text", "분석 중 오류가 발생했습니다: " + e.getMessage());
            }
        };
    }

    private int parseMonths(String untilYymm) {
        if (untilYymm == null || untilYymm.isBlank()) return 12;
        try {
            java.time.LocalDate now   = java.time.LocalDate.now().withDayOfMonth(1);
            java.time.LocalDate until = java.time.LocalDate.parse(untilYymm + "-01");
            long m = java.time.temporal.ChronoUnit.MONTHS.between(now, until);
            return (int) Math.min(Math.max(m, 1), 120);
        } catch (Exception e) { return 12; }
    }

    private int[] parseWeights(String weights) {
        if (weights == null || weights.isBlank()) return new int[]{90, 95, 100, 105, 110};
        try {
            String[] parts = weights.split(",");
            int[] result = new int[parts.length];
            for (int i = 0; i < parts.length; i++) {
                result[i] = Math.min(Math.max(Integer.parseInt(parts[i].trim()), 1), 500);
            }
            return result;
        } catch (Exception e) { return new int[]{90, 95, 100, 105, 110}; }
    }
}
