package com.eksystems.homes.assistant.service;

import com.eksystems.homes.assistant.vo.ChatResponse;
import com.eksystems.homes.scm.service.ScmService;
import com.eksystems.homes.scm.vo.ScmVO;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.*;
import java.util.function.Consumer;

@Service
public class GeminiService {

    private static final Logger log = LoggerFactory.getLogger(GeminiService.class);

    private static final Map<String, String> TOOL_LABELS = Map.of(
            "list_deposit_requests", "입금요청 목록 조회",
            "get_deposit_detail",    "상세 정보 조회",
            "approve_deposit",       "결재 처리",
            "delete_deposit",        "항목 삭제"
    );

    @Value("${gemini.api.key}")
    private String apiKey;

    @Value("${gemini.model}")
    private String model;

    private final ScmService   scmService;
    private final ObjectMapper om         = new ObjectMapper();
    private final HttpClient   httpClient = HttpClient.newHttpClient();

    public GeminiService(ScmService scmService) {
        this.scmService = scmService;
    }

    // ── Public (SSE 콜백 포함) ────────────────────────────────────────────────

    public ChatResponse chat(String userMessage,
                             List<Map<String, Object>> history,
                             String familyId, String userId, String userAuth,
                             Consumer<Map<String, Object>> onProgress) throws Exception {

        emit(onProgress, "status", "AI가 생각 중이에요...");

        List<Map<String, Object>> contents = new ArrayList<>(history);
        contents.add(userMsg(userMessage));
        List<String> toolsUsed = new ArrayList<>();

        for (int i = 0; i < 6; i++) {
            Map<String, Object> geminiRes;
            try {
                geminiRes = callGemini(contents, familyId, userAuth);
            } catch (Exception e) {
                String msg = e.getMessage();
                log.error("[GEMINI] API 호출 실패: {}", msg);
                emit(onProgress, "error", "Gemini API 오류: " + msg);
                throw e;
            }

            Map<String, Object> candidate = firstCandidate(geminiRes);
            String finishReason = (String) candidate.getOrDefault("finishReason", "");
            Map<String, Object> content = (Map<String, Object>) candidate.get("content");
            if (content == null) {
                String errMsg = "응답 없음 (finishReason=" + finishReason + ")";
                log.error("[GEMINI] {}", errMsg);
                throw new RuntimeException(errMsg);
            }

            List<Map<String, Object>> parts = (List<Map<String, Object>>) content.get("parts");
            Map<String, Object> fc = findFunctionCall(parts);

            if (fc == null) {
                String text = extractText(parts);
                contents.add(modelMsg(text));
                emit(onProgress, "done_data", text, contents, toolsUsed);
                return new ChatResponse(text, contents, toolsUsed);
            }

            String funcName = (String) fc.get("name");
            Map<String, Object> args = fc.containsKey("args")
                    ? (Map<String, Object>) fc.get("args") : Map.of();

            String label = TOOL_LABELS.getOrDefault(funcName, funcName);
            log.info("[GEMINI] tool={} args={}", funcName, args);
            emit(onProgress, "tool_start", label, funcName);

            contents.add(Map.of("role", "model", "parts", parts));

            Object result;
            try {
                result = executeTool(funcName, args, familyId, userId, userAuth);
            } catch (Exception e) {
                result = Map.of("error", e.getMessage());
                log.warn("[GEMINI] tool {} 실행 실패: {}", funcName, e.getMessage());
            }

            emit(onProgress, "tool_end", label, funcName);
            toolsUsed.add(funcName);

            contents.add(Map.of("role", "user", "parts", List.of(
                    Map.of("functionResponse", Map.of(
                            "name", funcName,
                            "response", Map.of("output", result)
                    ))
            )));
        }

        return new ChatResponse("처리 중 문제가 발생했습니다.", contents, toolsUsed);
    }

    // ── Gemini API 호출 (503 재시도 포함) ─────────────────────────────────────

    @SuppressWarnings("unchecked")
    private Map<String, Object> callGemini(List<Map<String, Object>> contents,
                                            String familyId, String userAuth) throws Exception {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("system_instruction", Map.of("parts", List.of(
                Map.of("text", buildSystemPrompt(familyId, userAuth))
        )));
        body.put("tools", List.of(Map.of("function_declarations", toolDefinitions(userAuth))));
        body.put("tool_config", Map.of("function_calling_config", Map.of("mode", "AUTO")));
        body.put("contents", contents);
        body.put("generationConfig", Map.of("temperature", 0.7, "maxOutputTokens", 2048));

        String url = "https://generativelanguage.googleapis.com/v1beta/models/"
                + model + ":generateContent?key=" + apiKey;
        String bodyJson = om.writeValueAsString(body);

        for (int attempt = 0; attempt <= 2; attempt++) {
            HttpRequest req = HttpRequest.newBuilder()
                    .uri(URI.create(url))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(bodyJson))
                    .build();

            HttpResponse<String> res = httpClient.send(req, HttpResponse.BodyHandlers.ofString());

            if (res.statusCode() == 503 && attempt < 2) {
                log.warn("[GEMINI] 503 수신, {}초 후 재시도 ({}/2)", attempt + 1, attempt + 1);
                Thread.sleep(1000L * (attempt + 1));
                continue;
            }
            if (res.statusCode() != 200) {
                log.error("[GEMINI] HTTP {} body={}", res.statusCode(),
                        res.body().length() > 500 ? res.body().substring(0, 500) : res.body());
                throw new RuntimeException("HTTP " + res.statusCode() + " — " +
                        parseGeminiError(res.body()));
            }
            return om.readValue(res.body(), Map.class);
        }
        throw new RuntimeException("Gemini 서비스 일시 불안정 (503 × 3). 잠시 후 다시 시도해주세요.");
    }

    private String parseGeminiError(String body) {
        try {
            Map<?, ?> map = om.readValue(body, Map.class);
            Map<?, ?> err = (Map<?, ?>) map.get("error");
            if (err != null) return (String) err.get("message");
        } catch (Exception ignored) {}
        return body.length() > 200 ? body.substring(0, 200) : body;
    }

    // ── Tool 실행 ─────────────────────────────────────────────────────────────

    private Object executeTool(String name, Map<String, Object> args,
                                String familyId, String userId, String userAuth) {
        try {
            return switch (name) {
                case "list_deposit_requests" -> {
                    ScmVO param = new ScmVO();
                    param.setFamilyId(familyId);
                    List<ScmVO> list = scmService.getDepositRequestList(param);
                    yield list.stream().map(v -> Map.of(
                            "depReqSeq", v.getDepReqSeq(),
                            "storeInfo", nvl(v.getStoreInfo()),
                            "amount",    v.getAmount() != null ? v.getAmount() : 0,
                            "reqStatus", nvl(v.getReqStatus()),
                            "regId",     nvl(v.getRegId()),
                            "requestDt", nvl(v.getRequestDt())
                    )).toList();
                }
                case "get_deposit_detail" -> {
                    Long seq = toLong(args.get("depReqSeq"));
                    ScmVO v = scmService.getDepositRequestDetail(familyId, seq);
                    if (v == null) yield Map.of("error", "항목을 찾을 수 없습니다.");
                    yield Map.of(
                            "depReqSeq", v.getDepReqSeq(),
                            "storeInfo", nvl(v.getStoreInfo()),
                            "amount",    v.getAmount() != null ? v.getAmount() : 0,
                            "reqStatus", nvl(v.getReqStatus()),
                            "reqDesc",   nvl(v.getReqDesc()),
                            "regId",     nvl(v.getRegId())
                    );
                }
                case "approve_deposit" -> {
                    if (!"manager".equals(userAuth)) yield Map.of("error", "관리자 권한 필요");
                    Long seq    = toLong(args.get("depReqSeq"));
                    String status = (String) args.get("reqStatus");
                    if (!List.of("APPROVED", "REJECT", "STANDBY").contains(status))
                        yield Map.of("error", "잘못된 상태값: " + status);
                    scmService.updateDepositStatus(familyId, seq, status, userId);
                    yield Map.of("result", "처리완료", "depReqSeq", seq, "reqStatus", status);
                }
                case "delete_deposit" -> {
                    if (!"manager".equals(userAuth)) yield Map.of("error", "관리자 권한 필요");
                    Long seq = toLong(args.get("depReqSeq"));
                    scmService.deleteDepositRequest(familyId, seq);
                    yield Map.of("result", "삭제완료", "depReqSeq", seq);
                }
                default -> Map.of("error", "알 수 없는 도구: " + name);
            };
        } catch (Exception e) {
            return Map.of("error", e.getMessage());
        }
    }

    // ── Tool 정의 ─────────────────────────────────────────────────────────────

    private List<Map<String, Object>> toolDefinitions(String userAuth) {
        List<Map<String, Object>> tools = new ArrayList<>();
        tools.add(funcDef("list_deposit_requests", "입금요청 목록을 조회합니다.", Map.of(
                "type", "object", "properties", Map.of(), "required", List.of()
        )));
        tools.add(funcDef("get_deposit_detail", "특정 입금요청 상세 정보를 조회합니다.", Map.of(
                "type", "object",
                "properties", Map.of("depReqSeq", Map.of("type", "integer", "description", "입금요청 번호")),
                "required", List.of("depReqSeq")
        )));
        if ("manager".equals(userAuth)) {
            tools.add(funcDef("approve_deposit", "입금요청을 결재 처리합니다. (관리자)", Map.of(
                    "type", "object",
                    "properties", Map.of(
                            "depReqSeq", Map.of("type", "integer", "description", "입금요청 번호"),
                            "reqStatus", Map.of("type", "string",
                                    "enum", List.of("APPROVED", "REJECT", "STANDBY"),
                                    "description", "APPROVED=결재완료, REJECT=반려, STANDBY=대기")
                    ),
                    "required", List.of("depReqSeq", "reqStatus")
            )));
            tools.add(funcDef("delete_deposit", "입금요청을 삭제합니다. (관리자)", Map.of(
                    "type", "object",
                    "properties", Map.of("depReqSeq", Map.of("type", "integer")),
                    "required", List.of("depReqSeq")
            )));
        }
        return tools;
    }

    private Map<String, Object> funcDef(String name, String desc, Map<String, Object> params) {
        return Map.of("name", name, "description", desc, "parameters", params);
    }

    private String buildSystemPrompt(String familyId, String userAuth) {
        return "당신은 ^HOMES의 개인 AI 어시스턴트입니다.\n" +
               "HOMES 시스템 기능(입금요청 조회·결재·삭제 등)을 도울 수 있고, " +
               "일상 대화, 고민 상담, 정보 검색, 글쓰기, 번역 등 어떤 주제든 자유롭게 대화할 수 있습니다.\n" +
               "현재 사용자 권한: " + ("manager".equals(userAuth) ? "관리자" : "일반 사용자") + ".\n" +
               "familyId: " + familyId + ".\n" +
               "답변 시 한국어를 기본으로 하되, 사용자가 다른 언어로 질문하면 그 언어로 답하세요. " +
               "금액은 콤마 포함 원 단위, 상태는 한글로 표시하세요. (STANDBY=대기, APPROVED=결재완료, REJECT=반려)";
    }

    // ── SSE 이벤트 emit 헬퍼 ──────────────────────────────────────────────────

    private void emit(Consumer<Map<String, Object>> cb, String type, String message) {
        if (cb != null) cb.accept(Map.of("type", type, "message", message));
    }

    private void emit(Consumer<Map<String, Object>> cb, String type, String label, Object extra) {
        if (cb == null) return;
        Map<String, Object> event = new LinkedHashMap<>();
        event.put("type", type);
        event.put("label", label);
        if (extra instanceof String) event.put("name", extra);
        cb.accept(event);
    }

    private void emit(Consumer<Map<String, Object>> cb, String type, String text,
                      List<Map<String, Object>> history, List<String> toolsUsed) {
        if (cb == null) return;
        Map<String, Object> event = new LinkedHashMap<>();
        event.put("type", type);
        event.put("reply", text);
        event.put("history", history);
        event.put("toolsUsed", toolsUsed);
        cb.accept(event);
    }

    // ── 유틸 ──────────────────────────────────────────────────────────────────

    @SuppressWarnings("unchecked")
    private Map<String, Object> firstCandidate(Map<String, Object> res) {
        List<?> candidates = (List<?>) res.get("candidates");
        if (candidates == null || candidates.isEmpty())
            throw new RuntimeException("응답에 candidates가 없습니다: " + res);
        return (Map<String, Object>) candidates.get(0);
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> findFunctionCall(List<Map<String, Object>> parts) {
        for (Map<String, Object> part : parts)
            if (part.containsKey("functionCall")) return (Map<String, Object>) part.get("functionCall");
        return null;
    }

    private String extractText(List<Map<String, Object>> parts) {
        for (Map<String, Object> part : parts)
            if (part.containsKey("text")) return (String) part.get("text");
        return "";
    }

    private Map<String, Object> userMsg(String text) {
        return Map.of("role", "user", "parts", List.of(Map.of("text", text)));
    }

    private Map<String, Object> modelMsg(String text) {
        return Map.of("role", "model", "parts", List.of(Map.of("text", text)));
    }

    private String nvl(String s) { return s == null ? "" : s; }

    private Long toLong(Object val) {
        if (val == null) throw new IllegalArgumentException("depReqSeq 누락");
        return ((Number) val).longValue();
    }
}
