package com.eksystems.homes.assistant.service;

import com.eksystems.homes.asset.mapper.AssetMapper;
import com.eksystems.homes.asset.mapper.CashFlowMapper;
import com.eksystems.homes.asset.service.ForecastService;
import com.eksystems.homes.asset.vo.AssetSummaryVO;
import com.eksystems.homes.asset.vo.AssetVO;
import com.eksystems.homes.asset.vo.CashFlowPlanVO;
import com.eksystems.homes.asset.vo.LoanVO;
import com.eksystems.homes.assistant.vo.ChatResponse;
import com.eksystems.homes.note.service.NoteService;
import com.eksystems.homes.note.vo.NoteVO;
import com.eksystems.homes.scm.service.ScmService;
import com.eksystems.homes.scm.vo.ScmVO;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.*;
import java.util.function.Consumer;

@Service
public class GeminiService {

    private static final Logger log = LoggerFactory.getLogger(GeminiService.class);

    private static final Map<String, String> TOOL_LABELS = Map.ofEntries(
            // ── 검색 ──────────────────────────────────────────────────
            Map.entry("global_search",          "통합 검색"),
            // ── 입금요청 ──────────────────────────────────────────────
            Map.entry("list_deposit_requests",  "입금요청 목록 조회"),
            Map.entry("get_deposit_detail",     "입금요청 상세 조회"),
            Map.entry("insert_deposit_request", "입금요청 등록"),
            Map.entry("approve_deposit",        "입금요청 결재 처리"),
            Map.entry("delete_deposit",         "입금요청 삭제"),
            // ── 공유메모 ──────────────────────────────────────────────
            Map.entry("insert_note",            "공유메모 등록"),
            Map.entry("update_note",            "공유메모 수정"),
            // ── 자산관리 ──────────────────────────────────────────────
            Map.entry("get_asset_summary",      "자산 요약 조회"),
            Map.entry("get_asset_forecast",     "자산변동 예측 분석")
    );

    @Value("${assistant.provider:gemini}")
    private String provider;

    @Value("${gemini.api.key:}")
    private String geminiApiKey;

    @Value("${gemini.model:gemini-2.5-flash}")
    private String geminiModel;

    @Value("${ollama.base-url:http://localhost:11434}")
    private String ollamaBaseUrl;

    @Value("${ollama.model:gemma4}")
    private String ollamaModel;

    private final ScmService      scmService;
    private final NoteService     noteService;
    private final AssetMapper     assetMapper;
    private final CashFlowMapper  cashFlowMapper;
    private final ForecastService forecastService;
    private final ObjectMapper om = new ObjectMapper();
    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build();

    public GeminiService(ScmService scmService, NoteService noteService,
                         AssetMapper assetMapper, CashFlowMapper cashFlowMapper,
                         ForecastService forecastService) {
        this.scmService      = scmService;
        this.noteService     = noteService;
        this.assetMapper     = assetMapper;
        this.cashFlowMapper  = cashFlowMapper;
        this.forecastService = forecastService;
    }

    public ChatResponse chat(String userMessage,
                             List<Map<String, Object>> history,
                             String familyId, String userId, String userAuth,
                             Consumer<Map<String, Object>> onProgress) throws Exception {

        List<Map<String, Object>> messages = normalizeHistory(history);
        messages.add(msg("user", userMessage));
        List<String> toolsUsed = new ArrayList<>();

        emit(onProgress, "status", modelLabel() + " 가 요청을 분석 중입니다.");

        for (int i = 0; i < 6; i++) {
            String raw = callModel(messages, familyId, userAuth);
            Map<String, Object> decision = parseDecision(raw);

            String reply = str(decision.get("reply"));
            String tool = str(decision.get("tool"));

            if (tool.isBlank()) {
                if (reply.isBlank()) reply = raw;
                messages.add(msg("assistant", reply));
                emitDone(onProgress, reply, messages, toolsUsed);
                return new ChatResponse(reply, messages, toolsUsed);
            }

            @SuppressWarnings("unchecked")
            Map<String, Object> args = decision.get("args") instanceof Map
                    ? (Map<String, Object>) decision.get("args")
                    : Map.of();

            String label = TOOL_LABELS.getOrDefault(tool, tool);
            toolsUsed.add(tool);
            emitTool(onProgress, "tool_start", label, tool);

            Object result = executeTool(tool, args, familyId, userId, userAuth, onProgress);
            if (result instanceof Map<?, ?> resultMap && resultMap.containsKey("error")) {
                emitToolError(onProgress, label, tool, str(resultMap.get("error")));
            } else {
                emitTool(onProgress, "tool_end", label, tool);
            }

            messages.add(msg("assistant", toJson(Map.of("tool", tool, "args", args))));
            messages.add(msg("tool", toJson(Map.of("tool", tool, "result", result))));
        }

        String fallback = "처리 단계가 너무 길어져 중단했습니다. 요청을 조금 더 구체적으로 나눠서 말해주세요.";
        emitDone(onProgress, fallback, messages, toolsUsed);
        return new ChatResponse(fallback, messages, toolsUsed);
    }

    /**
     * 자산 예측 컨텍스트를 받아 단순 분석 텍스트를 반환 (tool/history 없이 단발 호출).
     */
    public String analyzeAssetForecast(Map<String, Object> aiContext) throws Exception {
        String prompt = buildForecastPrompt(aiContext);
        // num_predict를 낮게 유지 — 핵심만 짧게 받음

        if ("ollama".equalsIgnoreCase(provider)) {
            Map<String, Object> body = new LinkedHashMap<>();
            body.put("model", ollamaModel);
            body.put("stream", false);
            body.put("messages", List.of(
                    msg("system", "너는 가계 재정을 분석해주는 친근한 AI 어시스턴트야."),
                    msg("user", prompt)
            ));
            body.put("options", Map.of("temperature", 0.7, "num_predict", 3000));

            HttpResponse<String> res = postJson(trimSlash(ollamaBaseUrl) + "/api/chat", body, Duration.ofSeconds(240));
            if (res.statusCode() != 200)
                throw new RuntimeException("Ollama HTTP " + res.statusCode() + ": " + shortBody(res.body()));

            log.debug("[FORECAST-AI] ollama raw: {}", res.body().length() > 300 ? res.body().substring(0, 300) : res.body());
            Map<String, Object> json = om.readValue(res.body(), new TypeReference<>() {});
            @SuppressWarnings("unchecked")
            Map<String, Object> message = (Map<String, Object>) json.get("message");
            String content = message == null ? "" : str(message.get("content"));
            return stripThinkTags(content);
        }

        // Gemini
        if (geminiApiKey == null || geminiApiKey.isBlank())
            throw new IllegalStateException("gemini.api.key가 설정되지 않았습니다.");

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("contents", List.of(Map.of(
                "role", "user",
                "parts", List.of(Map.of("text", prompt))
        )));
        body.put("generationConfig", Map.of("temperature", 0.7, "maxOutputTokens", 8192));

        String url = "https://generativelanguage.googleapis.com/v1beta/models/"
                + geminiModel + ":generateContent?key=" + geminiApiKey;

        HttpResponse<String> res = postJson(url, body, Duration.ofSeconds(90));
        if (res.statusCode() != 200)
            throw new RuntimeException("Gemini HTTP " + res.statusCode() + ": " + shortBody(res.body()));

        Map<String, Object> json = om.readValue(res.body(), new TypeReference<>() {});
        List<?> candidates = (List<?>) json.get("candidates");
        if (candidates == null || candidates.isEmpty()) return "";
        @SuppressWarnings("unchecked")
        Map<String, Object> candidate = (Map<String, Object>) candidates.get(0);
        @SuppressWarnings("unchecked")
        Map<String, Object> content = (Map<String, Object>) candidate.get("content");
        if (content == null) return "";
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> parts = (List<Map<String, Object>>) content.get("parts");
        if (parts == null) return "";
        return parts.stream().map(p -> str(p.get("text"))).reduce("", String::concat);
    }

    @SuppressWarnings("unchecked")
    private String buildForecastPrompt(Map<String, Object> ctx) {
        StringBuilder sb = new StringBuilder();
        sb.append("우리 가족 재정 데이터야. 아래 내용을 바탕으로 다음 항목을 한국어로 분석해줘.\n");
        sb.append("① 현재 재정 건전성 평가 (저축률·부채비율 포함)\n");
        sb.append("② 실적과 계획의 차이 분석 (보정 비율 기준)\n");
        sb.append("③ 시나리오별 미래 전망 (낙관/기준/비관 비교)\n");
        sb.append("④ 주요 리스크 요인\n");
        sb.append("⑤ 실천 가능한 개선 조언 2~3가지\n");
        sb.append("각 항목별로 구체적인 수치를 언급하며 친근하게 설명해줘.\n\n");

        // 현재 상태
        Map<String,Object> cur = (Map<String,Object>) ctx.get("currentState");
        if (cur != null) {
            sb.append("[현재 자산 현황]\n");
            sb.append("- 총자산: ").append(wons(cur.get("totalAsset"))).append("\n");
            sb.append("- 총대출: ").append(wons(cur.get("totalLoan"))).append("\n");
            sb.append("- 순자산: ").append(wons(cur.get("netAsset"))).append("\n\n");
        }

        // 실적
        Map<String,Object> hst = (Map<String,Object>) ctx.get("historicalActual");
        if (hst != null) {
            sb.append("[전표처리 실적 (").append(hst.get("dataMonths")).append("개월)]\n");
            sb.append("- 월평균 순자산 변동: ").append(wons(hst.get("avgMonthlyChange"))).append("\n");
            sb.append("- 월평균 수입: ").append(wons(hst.get("avgIncome"))).append("\n");
            sb.append("- 월평균 지출: ").append(wons(hst.get("avgExpense"))).append("\n");
            sb.append("- 평균 저축률: ").append(hst.get("savingRateAvg")).append("%\n\n");
        }

        // 계획 기준선
        Map<String,Object> plan = (Map<String,Object>) ctx.get("planBaseline");
        if (plan != null) {
            sb.append("[정기 계획 기준]\n");
            sb.append("- 월 수입계획: ").append(wons(plan.get("avgMonthlyIncome"))).append("\n");
            sb.append("- 월 지출계획: ").append(wons(plan.get("avgMonthlyExpense"))).append("\n");
            sb.append("- 월 자산증감 기여: ").append(wons(plan.get("avgMonthlyAssetGain"))).append("\n");
            Object ratio = plan.get("actualityRatio");
            if (ratio != null) {
                double r = ((Number) ratio).doubleValue();
                sb.append("- 실적/계획 비율: ").append(Math.round(r * 100)).append("% (1.0=계획대로)\n\n");
            }
        }

        // 시나리오 결과
        List<Map<String,Object>> scs = (List<Map<String,Object>>) ctx.get("scenarioResults");
        if (scs != null && !scs.isEmpty()) {
            sb.append("[예측 시나리오 결과]\n");
            for (Map<String,Object> s : scs) {
                sb.append("- ").append(s.get("weight")).append("% 시나리오: 최종 순자산 ")
                  .append(wons(s.get("finalNetAsset")))
                  .append(" (변동 ").append(wons(s.get("totalGain"))).append(")\n");
            }
            sb.append("\n");
        }

        // 주요 수입/지출 항목
        List<Map<String,Object>> inc = (List<Map<String,Object>>) ctx.get("incomeItems");
        if (inc != null && !inc.isEmpty()) {
            sb.append("[주요 수입 항목]\n");
            inc.forEach(i -> sb.append("- ").append(i.get("name")).append(": ").append(wons(i.get("totalAmount"))).append("\n"));
            sb.append("\n");
        }
        List<Map<String,Object>> exp = (List<Map<String,Object>>) ctx.get("expenseItems");
        if (exp != null && !exp.isEmpty()) {
            sb.append("[주요 지출 항목]\n");
            exp.stream().limit(8).forEach(e -> sb.append("- ").append(e.get("name")).append(": ").append(wons(e.get("totalAmount"))).append("\n"));
        }

        return sb.toString();
    }

    private String wons(Object v) {
        if (v == null) return "0원";
        long val = ((Number) v).longValue();
        long abs = Math.abs(val);
        String sign = val < 0 ? "-" : "";
        if (abs >= 100_000_000L) return sign + String.format("%.1f억원", abs / 1e8);
        if (abs >= 10_000L)      return sign + (abs / 10_000L) + "만원";
        return String.format("%,d원", val);
    }

    /** gemma4 등 thinking 모델의 <think>...</think> 블록 제거 */
    private String stripThinkTags(String text) {
        if (text == null) return "";
        // <think>...</think> 블록 제거 (dotall)
        String stripped = text.replaceAll("(?s)<think>.*?</think>", "").trim();
        return stripped.isBlank() ? text.trim() : stripped; // 제거 후 빈값이면 원본 그대로
    }

    public String generateDailyQuote(String userName) {
        String prompt = """
                오늘 하루를 차분하게 시작할 수 있는 귀감이 되는 짧은 한 줄을 한국어로 작성해줘.
                조건:
                - 35자 이내
                - 따옴표 없이 문장만
                - 설교처럼 딱딱하지 않게
                - 매번 조금 다른 표현
                """;

        try {
            String raw;
            if ("ollama".equalsIgnoreCase(provider)) {
                raw = callSimpleOllama(prompt);
            } else {
                raw = callSimpleGemini(prompt);
            }
            String quote = raw == null ? "" : raw
                    .replace("\"", "")
                    .replace("“", "")
                    .replace("”", "")
                    .trim();
            if (quote.length() > 60) quote = quote.substring(0, 60).trim();
            return quote.isBlank() ? defaultDailyQuote() : quote;
        } catch (Exception e) {
            log.warn("[ASSISTANT] daily quote generation failed: {}", e.getMessage());
            return defaultDailyQuote();
        }
    }

    private String callModel(List<Map<String, Object>> messages, String familyId, String userAuth) throws Exception {
        if ("ollama".equalsIgnoreCase(provider)) {
            return callOllama(messages, familyId, userAuth);
        }
        return callGemini(messages, familyId, userAuth);
    }

    private String callSimpleGemini(String prompt) throws Exception {
        if (geminiApiKey == null || geminiApiKey.isBlank()) {
            throw new IllegalStateException("gemini.api.key가 설정되지 않았습니다.");
        }

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("contents", List.of(Map.of(
                "role", "user",
                "parts", List.of(Map.of("text", prompt))
        )));
        body.put("generationConfig", Map.of("temperature", 0.9, "maxOutputTokens", 80));

        String url = "https://generativelanguage.googleapis.com/v1beta/models/"
                + geminiModel + ":generateContent?key=" + geminiApiKey;

        HttpResponse<String> res = postJson(url, body, Duration.ofSeconds(12));
        if (res.statusCode() != 200) {
            throw new RuntimeException("Gemini HTTP " + res.statusCode() + ": " + shortBody(res.body()));
        }

        Map<String, Object> json = om.readValue(res.body(), new TypeReference<>() {});
        List<?> candidates = (List<?>) json.get("candidates");
        if (candidates == null || candidates.isEmpty()) return "";
        @SuppressWarnings("unchecked")
        Map<String, Object> candidate = (Map<String, Object>) candidates.get(0);
        @SuppressWarnings("unchecked")
        Map<String, Object> content = (Map<String, Object>) candidate.get("content");
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> parts = (List<Map<String, Object>>) content.get("parts");
        return parts.stream().map(p -> str(p.get("text"))).reduce("", String::concat);
    }

    private String callSimpleOllama(String prompt) throws Exception {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("model", ollamaModel);
        body.put("stream", false);
        body.put("messages", List.of(
                msg("system", "너는 짧고 자연스러운 한국어 문장을 잘 쓰는 개인 AI다."),
                msg("user", prompt)
        ));
        body.put("options", Map.of("temperature", 0.9, "num_predict", 48));

        HttpResponse<String> res = postJson(trimSlash(ollamaBaseUrl) + "/api/chat", body, Duration.ofSeconds(20));
        if (res.statusCode() != 200) {
            throw new RuntimeException("Ollama HTTP " + res.statusCode() + ": " + shortBody(res.body()));
        }

        Map<String, Object> json = om.readValue(res.body(), new TypeReference<>() {});
        @SuppressWarnings("unchecked")
        Map<String, Object> message = (Map<String, Object>) json.get("message");
        return message == null ? "" : str(message.get("content"));
    }

    private String callGemini(List<Map<String, Object>> messages, String familyId, String userAuth) throws Exception {
        if (geminiApiKey == null || geminiApiKey.isBlank()) {
            throw new IllegalStateException("gemini.api.key가 설정되지 않았습니다.");
        }

        List<Map<String, Object>> contents = new ArrayList<>();
        for (Map<String, Object> message : messages) {
            String role = "assistant".equals(message.get("role")) ? "model" : "user";
            contents.add(Map.of("role", role, "parts", List.of(Map.of("text", str(message.get("content"))))));
        }

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("system_instruction", Map.of("parts", List.of(Map.of("text", systemPrompt(familyId, userAuth)))));
        body.put("contents", contents);
        body.put("generationConfig", Map.of(
                "temperature", 0.4,
                "maxOutputTokens", 2048,
                "responseMimeType", "application/json"
        ));

        String url = "https://generativelanguage.googleapis.com/v1beta/models/"
                + geminiModel + ":generateContent?key=" + geminiApiKey;

        HttpResponse<String> res = postJson(url, body);
        if (res.statusCode() != 200) {
            throw new RuntimeException("Gemini HTTP " + res.statusCode() + ": " + shortBody(res.body()));
        }

        Map<String, Object> json = om.readValue(res.body(), new TypeReference<>() {});
        List<?> candidates = (List<?>) json.get("candidates");
        if (candidates == null || candidates.isEmpty()) {
            throw new RuntimeException("Gemini 응답에 candidates가 없습니다.");
        }
        @SuppressWarnings("unchecked")
        Map<String, Object> candidate = (Map<String, Object>) candidates.get(0);
        @SuppressWarnings("unchecked")
        Map<String, Object> content = (Map<String, Object>) candidate.get("content");
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> parts = (List<Map<String, Object>>) content.get("parts");
        return parts.stream().map(p -> str(p.get("text"))).reduce("", String::concat);
    }

    private String callOllama(List<Map<String, Object>> messages, String familyId, String userAuth) throws Exception {
        List<Map<String, Object>> ollamaMessages = new ArrayList<>();
        ollamaMessages.add(msg("system", systemPrompt(familyId, userAuth)));
        for (Map<String, Object> message : messages) {
            String role = str(message.get("role"));
            if ("assistant".equals(role) || "user".equals(role) || "tool".equals(role)) {
                ollamaMessages.add(msg("tool".equals(role) ? "user" : role, str(message.get("content"))));
            }
        }

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("model", ollamaModel);
        body.put("stream", false);
        body.put("format", "json");
        body.put("messages", ollamaMessages);
        body.put("options", Map.of("temperature", 0.3));

        HttpResponse<String> res = postJson(trimSlash(ollamaBaseUrl) + "/api/chat", body);
        if (res.statusCode() != 200) {
            throw new RuntimeException("Ollama HTTP " + res.statusCode() + ": " + shortBody(res.body()));
        }

        Map<String, Object> json = om.readValue(res.body(), new TypeReference<>() {});
        @SuppressWarnings("unchecked")
        Map<String, Object> message = (Map<String, Object>) json.get("message");
        if (message == null) throw new RuntimeException("Ollama 응답에 message가 없습니다.");
        return str(message.get("content"));
    }

    private HttpResponse<String> postJson(String url, Object body) throws Exception {
        return postJson(url, body, Duration.ofSeconds(120));
    }

    private HttpResponse<String> postJson(String url, Object body, Duration timeout) throws Exception {
        HttpRequest req = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .timeout(timeout)
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(toJson(body)))
                .build();
        return httpClient.send(req, HttpResponse.BodyHandlers.ofString());
    }

    private Object executeTool(String name, Map<String, Object> args,
                               String familyId, String userId, String userAuth,
                               Consumer<Map<String, Object>> onProgress) {
        try {
            return switch (name) {
                case "global_search" -> {
                    String keyword = firstText(args.get("keyword"), args.get("q"), args.get("query"));
                    if (keyword.isBlank()) yield confirmRequired("찾을 검색어를 알려주세요.");

                    emit(onProgress, "status", "공유메모 검색 중...");
                    List<NoteVO> notes = noteService.searchNotes(familyId, keyword);

                    emit(onProgress, "status", "입금요청 검색 중...");
                    List<ScmVO> deposits = scmService.searchDepositRequests(familyId, keyword);

                    emit(onProgress, "status", "자산원장 검색 중...");
                    List<AssetVO> assets = assetMapper.searchAssets(familyId, keyword);

                    emit(onProgress, "status", "대출원장 검색 중...");
                    List<LoanVO> loans = assetMapper.searchLoans(familyId, keyword);

                    emit(onProgress, "status", "정기수입/지출 검색 중...");
                    List<CashFlowPlanVO> plans = cashFlowMapper.searchPlans(familyId, keyword);

                    yield Map.of(
                        "keyword", keyword,
                        "notes", notes.stream().map(n -> Map.of(
                                "domain", "note", "noteSeq", n.getNoteSeq(),
                                "title", nvl(n.getTitle()),
                                "contentPreview", preview(n.getContent()),
                                "regId", nvl(n.getRegId()),
                                "updatedAt", nvl(n.getUpdDtText())
                        )).toList(),
                        "depositRequests", deposits.stream().map(v -> Map.of(
                                "domain", "depositRequest", "depReqSeq", v.getDepReqSeq(),
                                "storeInfo", nvl(v.getStoreInfo()),
                                "amount", v.getAmount() == null ? 0L : v.getAmount(),
                                "reqStatus", nvl(v.getReqStatus()),
                                "reqDesc", nvl(v.getReqDesc()),
                                "regId", nvl(v.getRegId()),
                                "requestDt", nvl(v.getRequestDt())
                        )).toList(),
                        "assets", assets.stream().map(a -> Map.of(
                                "domain", "asset", "assetSeq", a.getAssetSeq(),
                                "assetNm", nvl(a.getAssetNm()),
                                "assetTypeNm", nvl(a.getAssetTypeNm()),
                                "liquidYn", nvl(a.getLiquidYn()),
                                "amount", a.getAmount() == null ? 0L : a.getAmount(),
                                "disposeYn", nvl(a.getDisposeYn()),
                                "memo", nvl(a.getMemo())
                        )).toList(),
                        "loans", loans.stream().map(l -> Map.of(
                                "domain", "loan", "loanSeq", l.getLoanSeq(),
                                "loanNm", nvl(l.getLoanNm()),
                                "loanAmount", l.getLoanAmount() == null ? 0L : l.getLoanAmount(),
                                "currentBalance", l.getCurrentBalance() == null ? 0L : l.getCurrentBalance(),
                                "interestRate", l.getInterestRate() == null ? "" : l.getInterestRate().toPlainString(),
                                "closeYn", nvl(l.getCloseYn()),
                                "memo", nvl(l.getMemo())
                        )).toList(),
                        "cashFlowPlans", plans.stream().map(p -> Map.of(
                                "domain", p.getFlowType().equals("INCOME") ? "incomePlan" : "expensePlan",
                                "planSeq", p.getPlanSeq(),
                                "planNm", nvl(p.getPlanNm()),
                                "planTypeNm", nvl(p.getPlanTypeNm()),
                                "flowType", nvl(p.getFlowType()),
                                "amount", p.getAmount() == null ? 0L : p.getAmount(),
                                "cycleDesc", nvl(p.getCycleDesc()),
                                "useYn", nvl(p.getUseYn()),
                                "memo", nvl(p.getMemo())
                        )).toList()
                    );
                }
                case "get_asset_summary" -> {
                    emit(onProgress, "status", "자산 현황 조회 중...");
                    AssetSummaryVO s = assetMapper.selectAssetSummary(familyId);
                    if (s == null) yield Map.of("message", "등록된 자산 데이터가 없습니다.");
                    Map<String, Object> sm = new LinkedHashMap<>();
                    sm.put("totalAssetAmount",        safe(s.getTotalAssetAmount()));
                    sm.put("totalLiquidAssetAmount",  safe(s.getTotalLiquidAssetAmount()));
                    sm.put("totalFixedAssetAmount",   safe(s.getTotalFixedAssetAmount()));
                    sm.put("totalInvestAmount",       safe(s.getTotalInvestAmount()));
                    sm.put("totalLoanBalance",        safe(s.getTotalLoanBalance()));
                    sm.put("netAssetAmount",          safe(s.getNetAssetAmount()));
                    sm.put("monthlyIncomeAmount",     safe(s.getMonthlyIncomeAmount()));
                    sm.put("monthlyExpenseAmount",    safe(s.getMonthlyExpenseAmount()));
                    sm.put("monthlySavingAmount",     safe(s.getMonthlySavingAmount()));
                    sm.put("monthlyInvestAmount",     safe(s.getMonthlyInvestAmount()));
                    sm.put("expectedMonthlyCashFlow", safe(s.getExpectedMonthlyCashFlow()));
                    yield sm;
                }
                case "get_asset_forecast" -> {
                    emit(onProgress, "status", "자산변동 예측 계산 중...");
                    Object monthsArg = args.getOrDefault("months", 12);
                    int months = monthsArg instanceof Number n ? Math.min(n.intValue(), 36) : 12;
                    Map<String, Object> full = forecastService.calcForecast(familyId, months, new int[]{90, 95, 100, 105, 110});

                    // AI에게 필요한 핵심 요약만 전달 (전체 배열은 토큰 낭비)
                    @SuppressWarnings("unchecked")
                    List<Map<String, Object>> scenarios = (List<Map<String, Object>>) full.get("scenarios");
                    @SuppressWarnings("unchecked")
                    List<Map<String, Object>> planSummary = (List<Map<String, Object>>) full.get("planSummary");

                    // 시나리오별 최종값 요약
                    List<Map<String, Object>> scenarioSummary = scenarios.stream().map(sc -> {
                        @SuppressWarnings("unchecked")
                        List<Number> data = (List<Number>) sc.get("data");
                        long last  = data.isEmpty() ? 0 : data.get(data.size()-1).longValue();
                        long first = data.isEmpty() ? 0 : data.get(0).longValue();
                        return Map.<String, Object>of(
                            "label",   sc.get("label"),
                            "weight",  sc.get("weight"),
                            "startNetAsset", first,
                            "endNetAsset",   last,
                            "change",        last - first
                        );
                    }).toList();

                    yield Map.of(
                        "forecastMonths",        months,
                        "currentNetAsset",       full.get("currentNetAsset"),
                        "totalAsset",            full.get("totalAsset"),
                        "totalLoan",             full.get("totalLoan"),
                        "avgMonthlyIncome",      full.get("avgMonthlyIncome"),
                        "avgMonthlyExpense",     full.get("avgMonthlyExpense"),
                        "scenarioSummary",       scenarioSummary,
                        "activePlanCount",       planSummary == null ? 0 : planSummary.size(),
                        "planSummary",           planSummary == null ? List.of() : planSummary
                    );
                }
                case "list_deposit_requests" -> {
                    ScmVO param = new ScmVO();
                    param.setFamilyId(familyId);
                    yield scmService.getDepositRequestList(param).stream().map(v -> Map.of(
                            "depReqSeq", v.getDepReqSeq(),
                            "storeInfo", nvl(v.getStoreInfo()),
                            "amount", v.getAmount() == null ? 0L : v.getAmount(),
                            "reqStatus", nvl(v.getReqStatus()),
                            "regId", nvl(v.getRegId()),
                            "requestDt", nvl(v.getRequestDt())
                    )).toList();
                }
                case "get_deposit_detail" -> {
                    Long seq = toLong(args.get("depReqSeq"));
                    ScmVO v = scmService.getDepositRequestDetail(familyId, seq);
                    if (v == null) yield Map.of("error", "입금요청을 찾을 수 없습니다.", "depReqSeq", seq);
                    yield Map.of(
                            "depReqSeq", v.getDepReqSeq(),
                            "storeInfo", nvl(v.getStoreInfo()),
                            "amount", v.getAmount() == null ? 0L : v.getAmount(),
                            "reqStatus", nvl(v.getReqStatus()),
                            "reqDesc", nvl(v.getReqDesc()),
                            "regId", nvl(v.getRegId())
                    );
                }
                case "insert_deposit_request" -> {
                    String storeInfo = requireText(args.get("storeInfo"), "storeInfo");
                    Long amount = toLong(args.get("amount"), "amount");
                    if (amount <= 0) yield Map.of("error", "amount는 0보다 커야 합니다.");
                    String reqDesc = str(args.get("reqDesc")).trim();

                    Long depReqSeq = scmService.createDepositRequest(
                            null,
                            familyId,
                            storeInfo,
                            amount,
                            reqDesc,
                            userId
                    );
                    yield Map.of(
                            "result", "등록완료",
                            "depReqSeq", depReqSeq,
                            "storeInfo", storeInfo,
                            "amount", amount,
                            "reqStatus", "STANDBY"
                    );
                }
                case "insert_note" -> {
                    String title = requireText(args.get("title"), "title");
                    String content = requireText(args.get("content"), "content");

                    NoteVO note = new NoteVO();
                    note.setFamilyId(familyId);
                    note.setTitle(title);
                    note.setContent(content);
                    note.setRegId(userId);
                    note.setUpdId(userId);
                    noteService.saveNote(note);

                    yield Map.of(
                            "result", "등록완료",
                            "noteSeq", note.getNoteSeq(),
                            "title", title
                    );
                }
                case "update_note" -> {
                    Long noteSeq = toLongOrNull(args.get("noteSeq"));
                    String targetTitle = firstText(args.get("targetTitle"), args.get("noteTitle"), args.get("lookupTitle"));
                    String title = optionalText(args.get("title"));
                    String content = optionalText(args.get("content"));

                    NoteVO current = resolveNoteTarget(familyId, noteSeq, targetTitle);
                    if (current == null) {
                        yield confirmRequired("망치마렵네요. 수정할 공유메모 번호나 제목을 알려주세요.");
                    }
                    if (title.isBlank() && content.isBlank()) {
                        yield confirmRequired("'" + current.getTitle() + "' 메모를 찾았습니다. 제목이나 내용을 어떻게 수정할까요?");
                    }

                    NoteVO note = new NoteVO();
                    note.setNoteSeq(current.getNoteSeq());
                    note.setFamilyId(familyId);
                    note.setTitle(title.isBlank() ? current.getTitle() : title);
                    note.setContent(content.isBlank() ? current.getContent() : content);
                    note.setRegId(current.getRegId());
                    note.setUpdId(userId);
                    noteService.saveNote(note);

                    yield Map.of(
                            "result", "수정완료",
                            "noteSeq", current.getNoteSeq(),
                            "title", note.getTitle()
                    );
                }
                case "approve_deposit" -> {
                    if (!"manager".equals(userAuth)) yield Map.of("error", "관리자 권한이 필요합니다.");
                    Long seq = toLongOrNull(args.get("depReqSeq"));
                    if (seq == null) {
                        yield confirmRequired("망치마렵네요. 상태를 변경할 입금요청 번호를 알려주세요.");
                    }
                    String status = str(args.get("reqStatus")).toUpperCase();
                    if (status.isBlank()) {
                        yield confirmRequired("망치마렵네요. 변경할 입금요청 상태를 알려주세요. 가능한 값은 APPROVED, REJECT, STANDBY입니다.");
                    }
                    if (!List.of("APPROVED", "REJECT", "STANDBY").contains(status)) {
                        yield Map.of("error", "지원하지 않는 상태값입니다: " + status);
                    }
                    scmService.updateDepositStatus(familyId, seq, status, userId);
                    yield Map.of("result", "처리완료", "depReqSeq", seq, "reqStatus", status);
                }
                case "delete_deposit" -> {
                    if (!"manager".equals(userAuth)) yield Map.of("error", "관리자 권한이 필요합니다.");
                    Long seq = toLong(args.get("depReqSeq"));
                    scmService.deleteDepositRequest(familyId, seq);
                    yield Map.of("result", "삭제완료", "depReqSeq", seq);
                }
                default -> Map.of("error", "알 수 없는 tool입니다: " + name);
            };
        } catch (Exception e) {
            log.warn("[ASSISTANT] tool {} failed: {}", name, e.getMessage());
            return Map.of("error", e.getMessage() == null ? e.getClass().getSimpleName() : e.getMessage());
        }
    }

    private String systemPrompt(String familyId, String userAuth) {
        boolean isManager = "manager".equals(userAuth);
        String managerTools = isManager ? """

                [관리자 전용 tool]
                approve_deposit — 입금요청 결재 처리
                  args : {"depReqSeq": <number>, "reqStatus": "APPROVED|REJECT|STANDBY"}
                  반환 : {result, depReqSeq, reqStatus}
                  규칙 : depReqSeq와 reqStatus 둘 다 명확할 때만 실행. reqStatus는 반드시 APPROVED·REJECT·STANDBY 중 하나.

                delete_deposit — 입금요청 삭제
                  args : {"depReqSeq": <number>}
                  반환 : {result, depReqSeq}
                  규칙 : 번호가 명확할 때만 실행.
                """ : "";

        return ("""
                ════════════════════════════════════════
                ^HOMES 개인 AI 어시스턴트 — 시스템 지침
                ════════════════════════════════════════

                ## 신원
                - 가정용 그룹웨어 ^HOMES의 전용 AI 어시스턴트.
                - 사용자 권한: %s
                - familyId: %s  (모든 tool은 이 familyId 범위 안에서만 동작함)

                ════════════════════════════════════════
                ## TOOL 카탈로그
                ════════════════════════════════════════
                tool이 필요할 때는 아래 정의된 tool 이름과 args 스키마를 정확히 따르세요.
                정의되지 않은 tool 이름은 절대 사용하지 마세요.

                ────────────────────────────────────────
                ### [검색]
                global_search — HOMES 전체 통합 검색
                  args : {"keyword": <string>}
                  반환 : {
                    keyword,
                    notes          : [{domain:"note", noteSeq, title, contentPreview, regId, updatedAt}],
                    depositRequests: [{domain:"depositRequest", depReqSeq, storeInfo, amount, reqStatus, reqDesc, regId, requestDt}],
                    assets         : [{domain:"asset", assetSeq, assetNm, assetTypeNm, liquidYn, amount, disposeYn, memo}],
                    loans          : [{domain:"loan", loanSeq, loanNm, loanAmount, currentBalance, interestRate, closeYn, memo}],
                    cashFlowPlans  : [{domain:"incomePlan"|"expensePlan", planSeq, planNm, planTypeNm, flowType, amount, cycleDesc, useYn, memo}]
                  }
                  언제 사용: 사용자가 "찾아줘", "검색해줘", "있어?", "어디에" 등 조회를 요청할 때.
                  주의: 결과가 비어있으면 "없습니다"라고 정직하게 답하세요. 없는 데이터를 만들지 마세요.

                ────────────────────────────────────────
                ### [자산관리]
                get_asset_summary — 자산·부채·현금흐름 현황 요약 조회
                  args : {}
                  반환 : {totalAssetAmount, totalLiquidAssetAmount, totalFixedAssetAmount,
                          totalInvestAmount, totalLoanBalance, netAssetAmount,
                          monthlyIncomeAmount, monthlyExpenseAmount, monthlySavingAmount,
                          monthlyInvestAmount, expectedMonthlyCashFlow}
                  언제 사용: "자산 얼마야?", "순자산", "대출 잔액", "월 지출" 등 현황 질문.

                get_asset_forecast — 향후 자산변동 예측 분석
                  args : {"months": <number 6~36, default 12>}
                  반환 : {forecastMonths, currentNetAsset, totalAsset, totalLoan,
                          avgMonthlyIncome, avgMonthlyExpense,
                          scenarioSummary: [{label, weight, startNetAsset, endNetAsset, change}],
                          activePlanCount, planSummary: [{planNm, flowType, amount, totalFires, totalAmount, cycleNum, cycleUnit}]}
                  언제 사용: "앞으로 자산이 어떻게 돼?", "예측", "미래 순자산", "몇 년 후 자산".
                  분석 지침:
                    - weight=50 비관적, weight=100 기준, weight=150 낙관적 시나리오임.
                    - change > 0 이면 해당 기간 자산 증가, < 0 이면 감소.
                    - avgMonthlyExpense > avgMonthlyIncome 이면 현금흐름 적자 경고 필요.
                    - 분석 결과에서 숫자는 반드시 tool 반환값에 있는 숫자만 사용. 직접 계산·추측 금지.
                    - 직접 데이터를 확인 후 심도 있는 인사이트 도출

                ────────────────────────────────────────
                ### [입금요청]
                list_deposit_requests — 입금요청 목록 조회
                  args : {}
                  반환 : [{depReqSeq, storeInfo, amount, reqStatus, regId, requestDt}]
                  상태값: STANDBY=대기중, APPROVED=결재완료, REJECT=반려

                get_deposit_detail — 입금요청 상세 조회
                  args : {"depReqSeq": <number>}
                  반환 : {depReqSeq, storeInfo, amount, reqStatus, reqDesc, regId}

                insert_deposit_request — 입금요청 등록
                  args : {"storeInfo": <string>, "amount": <number>, "reqDesc": <string|optional>}
                  반환 : {result, depReqSeq, storeInfo, amount, reqStatus}
                  규칙 : storeInfo와 amount가 명확할 때만 실행. amount는 양수.

                ────────────────────────────────────────
                ### [공유메모]
                insert_note — 공유메모 등록
                  args : {"title": <string>, "content": <string>}
                  반환 : {result, noteSeq, title}

                update_note — 공유메모 수정
                  args : {"noteSeq": <number> | "targetTitle": <string>, "title": <string|optional>, "content": <string|optional>}
                  반환 : {result, noteSeq, title}
                  규칙 :
                    - targetTitle은 현재 제목(찾을 대상), title은 새 제목. 혼동하지 마세요.
                    - noteSeq가 없으면 targetTitle로 찾습니다.
                    - 대상이 명확하지만 수정할 내용이 없으면 tool을 실행해 존재 확인 후 무엇을 수정할지 질문하세요.
                %s
                ════════════════════════════════════════
                ## 할루시네이션 방지 규칙 (반드시 준수)
                ════════════════════════════════════════
                1. tool 결과에 없는 데이터는 절대 언급하지 마세요.
                2. tool을 실행하기 전에 데이터를 가정하거나 추측하지 마세요.
                3. 금액·날짜·횟수 등 수치는 tool 반환값을 그대로 사용. 자체 계산 금지.
                4. "아마", "아마도", "약", "추정" 같은 표현을 사용할 때는 반드시 근거(tool 결과)를 명시하세요.
                5. tool 결과가 빈 배열이면 "없습니다"로 정직하게 답하세요.
                6. 존재하지 않는 tool 이름을 사용하지 마세요.
                7. 사용자가 "그거", "아까 것", "최근 것"처럼 모호하게 말하면 구체적으로 무엇인지 먼저 확인하세요.
                8. 변경·삭제 tool은 대상과 변경값이 모두 확실할 때만 실행하세요.

                ════════════════════════════════════════
                ## 응답 형식 (엄격히 준수)
                ════════════════════════════════════════
                반드시 JSON 하나만 응답하세요. markdown 코드블록(```json 형식) 절대 사용 금지.

                일반 대화:
                {"reply":"답변 내용"}

                tool 실행:
                {"tool":"tool_name","args":{...}}

                tool 결과를 받은 후 최종 답변:
                {"reply":"사용자가 이해하기 쉬운 자연어 답변"}

                ════════════════════════════════════════
                ## 대화 스타일
                ════════════════════════════════════════
                - 친근하되 간결하게. 불필요한 수식어나 과도한 공손함 지양.
                - 금액은 "2,500,000원" 또는 "250만원" 형태로 가독성 있게.
                - 자산/대출 분석 시 핵심 인사이트(주의점, 리스크, 개선점)를 함께 제시.
                - HOMES 외부의 개인정보나 금융 정보는 다루지 않음.
                """).formatted(
                isManager ? "관리자" : "일반 사용자",
                familyId,
                managerTools
        );
    }

    private Map<String, Object> parseDecision(String raw) throws Exception {
        String text = raw == null ? "" : raw.trim();
        if (text.startsWith("```")) {
            text = text.replaceFirst("^```json\\s*", "").replaceFirst("^```\\s*", "").replaceFirst("\\s*```$", "");
        }
        int start = text.indexOf('{');
        int end = text.lastIndexOf('}');
        if (start >= 0 && end > start) text = text.substring(start, end + 1);
        try {
            return om.readValue(text, new TypeReference<>() {});
        } catch (Exception e) {
            return Map.of("reply", raw);
        }
    }

    private List<Map<String, Object>> normalizeHistory(List<Map<String, Object>> history) {
        List<Map<String, Object>> result = new ArrayList<>();
        if (history == null) return result;
        for (Map<String, Object> row : history) {
            String role = str(row.get("role"));
            Object content = row.get("content");
            if (content == null && row.get("parts") instanceof List<?> parts && !parts.isEmpty()) {
                Object first = parts.get(0);
                if (first instanceof Map<?, ?> firstMap) content = firstMap.get("text");
            }
            if (role.equals("model")) role = "assistant";
            if (!role.isBlank() && content != null) result.add(msg(role, str(content)));
        }
        return result;
    }

    private Map<String, Object> msg(String role, String content) {
        return Map.of("role", role, "content", content == null ? "" : content);
    }

    private void emit(Consumer<Map<String, Object>> cb, String type, String message) {
        if (cb != null) cb.accept(Map.of("type", type, "message", message));
    }

    private void emitTool(Consumer<Map<String, Object>> cb, String type, String label, String name) {
        if (cb != null) cb.accept(Map.of("type", type, "label", label, "name", name));
    }

    private void emitToolError(Consumer<Map<String, Object>> cb, String label, String name, String error) {
        if (cb != null) cb.accept(Map.of("type", "tool_error", "label", label, "name", name, "message", error));
    }

    private void emitDone(Consumer<Map<String, Object>> cb, String reply,
                          List<Map<String, Object>> history, List<String> toolsUsed) {
        if (cb == null) return;
        Map<String, Object> event = new LinkedHashMap<>();
        event.put("type", "done_data");
        event.put("reply", reply);
        event.put("history", history);
        event.put("toolsUsed", toolsUsed);
        cb.accept(event);
    }

    private String modelLabel() {
        return "H-Ops AI";
        //return "ollama".equalsIgnoreCase(provider) ? "Ollama " + ollamaModel : "Gemini " + geminiModel;
    }

    private String toJson(Object obj) {
        try {
            return om.writeValueAsString(obj);
        } catch (Exception e) {
            return "{}";
        }
    }

    private String shortBody(String body) {
        if (body == null) return "";
        return body.length() > 500 ? body.substring(0, 500) : body;
    }

    private String trimSlash(String value) {
        return value.endsWith("/") ? value.substring(0, value.length() - 1) : value;
    }

    private String nvl(String s) {
        return s == null ? "" : s;
    }

    private String preview(String text) {
        String value = nvl(text).replaceAll("\\s+", " ").trim();
        return value.length() > 120 ? value.substring(0, 120) + "..." : value;
    }

    private String defaultDailyQuote() {
        return "작게 정리하면, 크게 편해진다.";
    }

    private String str(Object value) {
        return value == null ? "" : String.valueOf(value);
    }

    private Long toLong(Object value) {
        if (value == null) throw new IllegalArgumentException("depReqSeq가 필요합니다.");
        if (value instanceof Number n) return n.longValue();
        return Long.parseLong(String.valueOf(value));
    }

    private Long toLong(Object value, String fieldName) {
        if (value == null) throw new IllegalArgumentException(fieldName + "가 필요합니다.");
        if (value instanceof Number n) return n.longValue();
        String text = String.valueOf(value).replace(",", "").trim();
        if (text.isBlank()) throw new IllegalArgumentException(fieldName + "가 필요합니다.");
        return Long.parseLong(text);
    }

    private Long toLongOrNull(Object value) {
        if (value == null) return null;
        if (value instanceof Number n) return n.longValue();
        String text = String.valueOf(value).replace(",", "").trim();
        if (text.isBlank()) return null;
        return Long.parseLong(text);
    }

    private NoteVO resolveNoteTarget(String familyId, Long noteSeq, String targetTitle) {
        if (noteSeq != null) {
            return noteService.getNoteDetail(familyId, noteSeq);
        }
        if (targetTitle.isBlank()) {
            return null;
        }

        NoteVO cond = new NoteVO();
        cond.setFamilyId(familyId);
        cond.setTitle(targetTitle);
        List<NoteVO> candidates = noteService.getNoteList(cond);
        if (candidates == null || candidates.isEmpty()) {
            return null;
        }

        List<NoteVO> exactMatches = candidates.stream()
                .filter(note -> targetTitle.equalsIgnoreCase(nvl(note.getTitle()).trim()))
                .toList();
        if (exactMatches.size() == 1) {
            return noteService.getNoteDetail(familyId, exactMatches.get(0).getNoteSeq());
        }
        if (exactMatches.size() > 1) {
            return null;
        }
        if (candidates.size() == 1) {
            return noteService.getNoteDetail(familyId, candidates.get(0).getNoteSeq());
        }
        return null;
    }

    private String requireText(Object value, String fieldName) {
        String text = str(value).trim();
        if (text.isBlank()) throw new IllegalArgumentException(fieldName + "가 필요합니다.");
        return text;
    }

    private String optionalText(Object value) {
        return str(value).trim();
    }

    private String firstText(Object... values) {
        for (Object value : values) {
            String text = optionalText(value);
            if (!text.isBlank()) return text;
        }
        return "";
    }

    private Map<String, Object> confirmRequired(String message) {
        return Map.of("confirmRequired", true, "message", message);
    }

    private long safe(Long v) {
        return v != null ? v : 0L;
    }
}
