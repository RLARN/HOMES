package com.eksystems.homes.assistant.service;

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
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Consumer;

@Service
public class GeminiService {

    private static final Logger log = LoggerFactory.getLogger(GeminiService.class);

    private static final Map<String, String> TOOL_LABELS = Map.of(
            "list_deposit_requests", "입금요청 목록 조회",
            "get_deposit_detail", "입금요청 상세 조회",
            "global_search", "전체 검색",
            "insert_deposit_request", "입금요청 등록",
            "insert_note", "공유메모 등록",
            "update_note", "공유메모 수정",
            "approve_deposit", "입금요청 결재 처리",
            "delete_deposit", "입금요청 삭제"
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

    private final ScmService scmService;
    private final NoteService noteService;
    private final ObjectMapper om = new ObjectMapper();
    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build();

    public GeminiService(ScmService scmService, NoteService noteService) {
        this.scmService = scmService;
        this.noteService = noteService;
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
                    if (keyword.isBlank()) {
                        yield confirmRequired("찾을 검색어를 알려주세요.");
                    }

                    emit(onProgress, "status", "메모 정보를 찾고있어요.");
                    List<NoteVO> notes = noteService.searchNotes(familyId, keyword);

                    emit(onProgress, "status", "입금요청 정보를 찾고있어요.");
                    List<ScmVO> deposits = scmService.searchDepositRequests(familyId, keyword);

                    yield Map.of(
                            "keyword", keyword,
                            "notes", notes.stream().map(note -> Map.of(
                                    "type", "note",
                                    "noteSeq", note.getNoteSeq(),
                                    "title", nvl(note.getTitle()),
                                    "contentPreview", preview(note.getContent()),
                                    "regId", nvl(note.getRegId()),
                                    "updatedAt", nvl(note.getUpdDtText())
                            )).toList(),
                            "depositRequests", deposits.stream().map(v -> Map.of(
                                    "type", "depositRequest",
                                    "depReqSeq", v.getDepReqSeq(),
                                    "storeInfo", nvl(v.getStoreInfo()),
                                    "amount", v.getAmount() == null ? 0L : v.getAmount(),
                                    "reqStatus", nvl(v.getReqStatus()),
                                    "reqDesc", nvl(v.getReqDesc()),
                                    "regId", nvl(v.getRegId()),
                                    "requestDt", nvl(v.getRequestDt())
                            )).toList()
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
        return """
                당신은 가정용 그룹웨어 ^HOMES의 개인 AI 어시스턴트입니다.
                HOMES 업무가 필요할 때는 아래 tool 중 하나를 선택해서 처리할 수 있습니다.

                현재 사용자 권한: %s
                familyId: %s

                사용 가능한 tool:
                - global_search: HOMES 전체 검색. args={"keyword":"검색어"} 공유메모와 입금요청을 순서대로 검색함.
                - list_deposit_requests: 입금요청 목록 조회. args={}
                - get_deposit_detail: 입금요청 상세 조회. args={"depReqSeq":번호}
                - insert_deposit_request: 입금요청 등록. args={"storeInfo":"구매처/품목","amount":금액,"reqDesc":"요청 사유 또는 메모"}
                - insert_note: 공유메모 등록. args={"title":"제목","content":"내용"}
                - update_note: 공유메모 수정. args={"noteSeq":번호 또는 "targetTitle":"현재 제목","title":"새 제목","content":"새 내용"} 제목 또는 내용 중 바꿀 값만 포함할 수 있음.
                %s

                업데이트 tool 실행 규칙:
                - update_note는 noteSeq가 없어도 사용자가 "김치 메모"처럼 현재 제목을 말하면 targetTitle에 그 제목을 넣어 실행하세요.
                - update_note에서 대상 제목은 targetTitle, 새 제목은 title입니다. 둘을 섞지 마세요.
                - update_note에서 대상은 명확하지만 변경할 값이 없으면 tool을 실행해 대상 존재 여부를 확인한 뒤 무엇을 수정할지 물어보세요.
                - approve_deposit처럼 기존 데이터를 바꾸는 tool은 대상 번호와 변경할 값이 모두 명확할 때만 실행하세요.
                - 대상 번호, 변경할 필드, 변경할 값 중 하나라도 추측해야 한다면 tool을 실행하지 말고 {"reply":"확인 질문"} 형태로 먼저 다시 물어보세요.
                - 사용자가 "그거", "아까 것", "최근 것"처럼 애매하게 말하면 반드시 어떤 항목인지 번호나 내용을 확인하세요.

                반드시 JSON 하나만 응답하세요. markdown 코드블록은 쓰지 마세요.
                일반 대화 답변:
                {"reply":"답변 내용"}

                tool 실행이 필요한 경우:
                {"tool":"list_deposit_requests","args":{}}

                tool 결과를 받은 뒤에는 사용자가 이해하기 쉬운 자연어로 최종 답변하세요.
                사용자가 "찾아줘", "검색해줘", "어디 있어", "관련된 것 보여줘"처럼 말하면 global_search를 우선 사용하세요.
                상태 표기: STANDBY=대기, APPROVED=결재완료, REJECT=반려.
                """.formatted(
                "manager".equals(userAuth) ? "관리자" : "일반 사용자",
                familyId,
                "manager".equals(userAuth)
                        ? "- approve_deposit: 입금요청 결재 처리. args={\"depReqSeq\":번호,\"reqStatus\":\"APPROVED|REJECT|STANDBY\"}\n- delete_deposit: 입금요청 삭제. args={\"depReqSeq\":번호}"
                        : ""
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
        return "HOMES Assistant";
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
}
