package com.eksystems.homes.assistant.service;

import com.eksystems.homes.asset.mapper.AssetMapper;
import com.eksystems.homes.asset.mapper.CashFlowMapper;
import com.eksystems.homes.asset.service.CostCenterService;
import com.eksystems.homes.asset.service.ForecastService;
import com.eksystems.homes.asset.service.SnapshotService;
import com.eksystems.homes.dms.mapper.DmsMapper;
import com.eksystems.homes.dms.vo.DmsFileVO;
import com.eksystems.homes.dms.vo.DmsFolderVO;
import com.eksystems.homes.sns.mapper.SnsMapper;
import com.eksystems.homes.sns.vo.SnsPostVO;
import com.eksystems.homes.asset.vo.AssetChangeSummaryVO;
import com.eksystems.homes.asset.vo.AssetSummaryVO;
import com.eksystems.homes.asset.vo.AssetVO;
import com.eksystems.homes.asset.vo.CashFlowPlanVO;
import com.eksystems.homes.asset.vo.CostCenterStatusVO;
import com.eksystems.homes.asset.vo.LoanVO;
import com.eksystems.homes.assistant.vo.ChatResponse;
import com.eksystems.homes.living.service.LivingService;
import com.eksystems.homes.living.vo.LivingIncomeMstVO;
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
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.function.Consumer;
import java.util.stream.Collectors;

@Service
public class GeminiService {

    private static final Logger log = LoggerFactory.getLogger(GeminiService.class);

    /** 모델이 환각하는 유사 툴명 → 실제 툴명 매핑 */
    private static final Map<String, String> TOOL_ALIASES = Map.ofEntries(
            // 공유메모
            Map.entry("get_all_notes",                  "list_notes"),
            Map.entry("get_notes",                      "list_notes"),
            Map.entry("list_all_notes",                 "list_notes"),
            Map.entry("get_note_list",                  "list_notes"),
            Map.entry("create_note",                    "insert_note"),
            Map.entry("add_note",                       "insert_note"),
            Map.entry("edit_note",                      "update_note"),
            Map.entry("modify_note",                    "update_note"),
            Map.entry("remove_note",                    "delete_note"),
            // 입금요청
            Map.entry("get_pending_requests",           "list_deposit_requests"),
            Map.entry("list_pending_requests",          "list_deposit_requests"),
            Map.entry("get_requests",                   "list_deposit_requests"),
            Map.entry("get_deposit_requests",           "list_deposit_requests"),
            Map.entry("list_deposits",                  "list_deposit_requests"),
            Map.entry("get_all_deposits",               "list_deposit_requests"),
            Map.entry("create_deposit_request",         "insert_deposit_request"),
            Map.entry("add_deposit_request",            "insert_deposit_request"),
            // 대출 이자
            Map.entry("calculate_loan_interest",        "calc_loan_interest_burden"),
            Map.entry("calc_loan_interest",             "calc_loan_interest_burden"),
            Map.entry("get_loan_interest",              "calc_loan_interest_burden"),
            Map.entry("loan_interest_burden",           "calc_loan_interest_burden"),
            Map.entry("loan_interest_analysis",         "calc_loan_interest_burden"),
            // 자산 유형
            Map.entry("get_asset_composition",          "get_asset_type_summary"),
            Map.entry("get_asset_breakdown",            "get_asset_type_summary"),
            Map.entry("list_asset_types",               "get_asset_type_summary"),
            Map.entry("get_asset_type_breakdown",       "get_asset_type_summary"),
            Map.entry("asset_type_summary",             "get_asset_type_summary"),
            // 현금흐름
            Map.entry("get_cashflow_detail",            "get_manual_cashflow_detail"),
            Map.entry("list_manual_cashflow",           "get_manual_cashflow_detail"),
            Map.entry("get_manual_cashflow",            "get_manual_cashflow_detail"),
            Map.entry("manual_cashflow_detail",         "get_manual_cashflow_detail"),
            // 정기 계획
            Map.entry("list_cashflow_plans_all",        "list_cashflow_plans"),
            Map.entry("get_cashflow_plans",             "list_cashflow_plans"),
            Map.entry("get_cash_flow_plans",            "list_cashflow_plans"),
            Map.entry("list_plans",                     "list_cashflow_plans"),
            // 생활비
            Map.entry("get_living_expense_list",        "get_expense_list"),
            Map.entry("list_expense_months",            "get_expense_list"),
            Map.entry("get_living_expenses",            "get_expense_list"),
            Map.entry("list_expenses",                  "get_expense_list"),
            // 기타
            Map.entry("get_cost_center",                "get_cost_center_status"),
            Map.entry("cost_center_status",             "get_cost_center_status"),
            Map.entry("get_snapshot",                   "get_snapshot_months"),
            Map.entry("snapshot_months",                "get_snapshot_months"),
            Map.entry("get_forecast",                   "get_asset_forecast"),
            Map.entry("asset_forecast",                 "get_asset_forecast"),
            Map.entry("get_summary",                    "get_asset_summary"),
            Map.entry("asset_summary",                  "get_asset_summary"),
            Map.entry("get_asset_list",                 "list_assets"),
            Map.entry("get_loan_list",                  "list_loans"),
            Map.entry("search",                         "global_search")
    );

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
            Map.entry("list_notes",             "공유메모 목록 조회"),
            Map.entry("insert_note",            "공유메모 등록"),
            Map.entry("update_note",            "공유메모 수정"),
            Map.entry("delete_note",            "공유메모 삭제"),
            // ── 자산관리 ──────────────────────────────────────────────
            Map.entry("get_asset_summary",          "자산 요약 조회"),
            Map.entry("get_asset_forecast",         "자산변동 예측 분석"),
            Map.entry("list_assets",                "자산 목록 조회"),
            Map.entry("list_loans",                 "대출 목록 조회"),
            // ── 재정 분석 ─────────────────────────────────────────────
            Map.entry("get_snapshot_months",        "전표처리 월 목록 조회"),
            Map.entry("get_cost_center_status",     "수지계정현황 조회"),
            Map.entry("get_asset_change_history",   "자산변동현황 조회"),
            Map.entry("get_expense_summary",        "생활비 지출 요약 조회"),
            // ── 심층 분석 ─────────────────────────────────────────────
            Map.entry("list_cashflow_plans",        "정기 계획 목록 조회"),
            Map.entry("get_asset_type_summary",     "자산 유형별 구성 조회"),
            Map.entry("get_manual_cashflow_detail", "수기 현금흐름 상세 조회"),
            Map.entry("get_expense_list",           "생활비 월별 집계 조회"),
            Map.entry("calc_loan_interest_burden",  "대출 이자 부담 분석")
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

    private final ScmService        scmService;
    private final NoteService       noteService;
    private final AssetMapper       assetMapper;
    private final CashFlowMapper    cashFlowMapper;
    private final ForecastService   forecastService;
    private final SnapshotService   snapshotService;
    private final CostCenterService costCenterService;
    private final LivingService     livingService;
    private final DmsMapper         dmsMapper;
    private final SnsMapper         snsMapper;
    // 소형 LLM이 JSON 문자열 내에 unescaped 제어문자(개행 등)를 넣는 경우 허용
    private final ObjectMapper om = new ObjectMapper()
            .configure(com.fasterxml.jackson.core.JsonParser.Feature.ALLOW_UNQUOTED_CONTROL_CHARS, true);
    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build();

    public GeminiService(ScmService scmService, NoteService noteService,
                         AssetMapper assetMapper, CashFlowMapper cashFlowMapper,
                         ForecastService forecastService,
                         SnapshotService snapshotService,
                         CostCenterService costCenterService,
                         LivingService livingService,
                         DmsMapper dmsMapper,
                         SnsMapper snsMapper) {
        this.scmService        = scmService;
        this.noteService       = noteService;
        this.assetMapper       = assetMapper;
        this.cashFlowMapper    = cashFlowMapper;
        this.forecastService   = forecastService;
        this.snapshotService   = snapshotService;
        this.costCenterService = costCenterService;
        this.livingService     = livingService;
        this.dmsMapper         = dmsMapper;
        this.snsMapper         = snsMapper;
    }

    public ChatResponse chat(String userMessage,
                             List<Map<String, Object>> history,
                             String familyId, String userId, String userAuth,
                             Consumer<Map<String, Object>> onProgress) throws Exception {

        boolean isOllama = "ollama".equalsIgnoreCase(provider);

        // ── Ollama: 종합 분석 요청은 서버 오케스트레이션으로 처리 ──────────────
        if (isOllama && isComprehensiveRequest(userMessage)) {
            return handleComprehensiveOllama(userMessage, history, familyId, userId, userAuth, onProgress);
        }

        List<Map<String, Object>> messages = normalizeHistory(history);
        // Ollama: 컨텍스트 폭발 방지 — 최근 6턴만 유지
        if (isOllama && messages.size() > 12) {
            messages = messages.subList(messages.size() - 12, messages.size());
        }
        messages.add(msg("user", userMessage));
        List<String> toolsUsed = new ArrayList<>();

        emit(onProgress, "status", modelLabel() + " 가 요청을 분석 중입니다.");

        String lastTool = "";
        int sameToolStreak = 0;
        int maxTurns = isOllama ? 6 : 10;

        for (int i = 0; i < maxTurns; i++) {
            String raw = callModel(messages, familyId, userAuth);
            log.debug("[AI-RAW] turn={} len={} preview={}", i, raw.length(),
                    raw.length() > 120 ? raw.substring(0, 120) : raw);

            Map<String, Object> decision = parseDecision(raw);
            String reply = sanitizeReply(str(decision.get("reply")));
            String tool  = str(decision.get("tool"));

            // ── reply 또는 비툴 응답 ─────────────────────────────────────
            if (tool.isBlank()) {
                if (reply.isBlank() && decision.containsKey("error")) reply = str(decision.get("error"));
                if (reply.isBlank() && !raw.isBlank()) reply = sanitizeReply(raw);

                // Ollama: format:json 강제로 받은 reply는 품질이 낮을 수 있음.
                // 히스토리를 포함해 plain-text로 재생성한다.
                if (isOllama) {
                    List<Map<String, Object>> convMsgs = new ArrayList<>(messages);
                    String betterReply = generateOllamaConversation(convMsgs);
                    if (!betterReply.isBlank()) reply = betterReply;
                }

                if (reply.isBlank()) reply = "죄송합니다, 다시 한번 말씀해 주세요.";
                messages.add(msg("assistant", reply));
                List<String> usedNames = toolNamesOnly(toolsUsed);
                emitDone(onProgress, reply, messages, usedNames);
                return new ChatResponse(reply, messages, usedNames);
            }

            // ── 툴명 정규화 ───────────────────────────────────────────────
            String resolved = resolveToolName(tool);
            if (!resolved.equals(tool)) log.info("[TOOL-RESOLVE] '{}' → '{}'", tool, resolved);
            tool = resolved;

            // ── 같은 툴 반복 감지 → 강제 최종 답변 유도 ────────────────────
            if (tool.equals(lastTool)) {
                sameToolStreak++;
                if (sameToolStreak >= 2) {
                    log.warn("[LOOP-DETECT] 동일 툴 3회 연속: {}", tool);
                    messages.add(msg("user",
                            "지금까지 조회한 데이터를 바탕으로 한국어로 최종 답변해줘. " +
                            "반드시 {\"reply\":\"답변내용\"} 형식으로만 응답."));
                    sameToolStreak = 0;
                    continue;
                }
            } else {
                sameToolStreak = 0;
            }
            lastTool = tool;

            // ── 이미 사용한 인자 동일한 툴 재호출 감지 ──────────────────────
            @SuppressWarnings("unchecked")
            Map<String, Object> args = decision.get("args") instanceof Map
                    ? (Map<String, Object>) decision.get("args") : Map.of();

            String toolKey = tool + ":" + toJson(args);
            if (toolsUsed.stream().anyMatch(t -> t.equals(toolKey))) {
                log.warn("[DUP-DETECT] 동일 툴+인자 재호출 차단: {}", toolKey);
                messages.add(msg("user",
                        "이미 해당 데이터를 조회했습니다. 조회된 결과를 바탕으로 " +
                        "{\"reply\":\"한국어 답변\"} 형식으로 최종 답변해줘."));
                continue;
            }
            toolsUsed.add(toolKey); // 중복 감지용 (tool:args 형태)

            String label = TOOL_LABELS.getOrDefault(tool, tool);
            emitTool(onProgress, "tool_start", label, tool);

            Object result = executeTool(tool, args, familyId, userId, userAuth, onProgress);
            if (result instanceof Map<?, ?> resultMap && resultMap.containsKey("error")) {
                String errMsg = str(resultMap.get("error"));
                emitToolError(onProgress, label, tool, errMsg);
                if (errMsg.startsWith("알 수 없는 tool")) {
                    String fallback = "죄송합니다, 요청하신 기능을 찾을 수 없습니다. 다시 말씀해 주세요.";
                    emitDone(onProgress, fallback, messages, toolsUsed);
                    return new ChatResponse(fallback, messages, toolsUsed);
                }
            } else {
                emitTool(onProgress, "tool_end", label, tool);
            }

            // Ollama: 툴 실행 후 JSON 루프 없이 plain-text 답변 바로 생성
            if (isOllama) {
                Object trimmed = trimToolResult(tool, result);
                String directReply = generateOllamaReply(tool, trimmed);
                if (directReply.isBlank()) directReply = "데이터를 조회했습니다. 결과를 확인해 주세요.";
                List<String> usedNames = toolNamesOnly(toolsUsed);
                messages.add(msg("assistant", directReply));
                emitDone(onProgress, directReply, messages, usedNames);
                return new ChatResponse(directReply, messages, usedNames);
            }

            // Gemini: 기존 방식 유지
            messages.add(msg("assistant", toJson(Map.of("tool", tool, "args", args))));
            messages.add(msg("tool",      toJson(Map.of("tool", tool, "result", result))));
        }

        String fallback = "처리 단계가 너무 길어져 중단됐습니다. 질문을 더 구체적으로 나눠서 말씀해 주세요.";
        emitDone(onProgress, fallback, messages, toolNamesOnly(toolsUsed));
        return new ChatResponse(fallback, messages, toolNamesOnly(toolsUsed));
    }

    /** Ollama 전용: 데이터 조회 없는 일반 대화를 plain-text로 처리 (히스토리 포함) */
    private String generateOllamaConversation(List<Map<String, Object>> messages) {
        try {
            List<Map<String, Object>> ollamaMessages = new ArrayList<>();
            ollamaMessages.add(msg("system",
                    "너는 HOMES 가계부 앱의 친근한 한국어 AI 어시스턴트야. "
                    + "이전 대화 맥락을 참고해서 자연스럽게 답변해줘."));

            // tool 호출/결과 JSON 제외, 텍스트 대화 턴만 최근 6턴
            List<Map<String, Object>> textTurns = messages.stream()
                    .filter(m -> {
                        String role = str(m.get("role"));
                        if (!"user".equals(role) && !"assistant".equals(role)) return false;
                        String c = str(m.get("content"));
                        return !c.startsWith("{\"tool\"") && !c.startsWith("{\"reply\":");
                    })
                    .toList();
            int from = Math.max(0, textTurns.size() - 6);
            for (Map<String, Object> m : textTurns.subList(from, textTurns.size())) {
                ollamaMessages.add(msg(str(m.get("role")), str(m.get("content"))));
            }

            Map<String, Object> body = new LinkedHashMap<>();
            body.put("model", ollamaModel);
            body.put("stream", false);
            body.put("messages", ollamaMessages);
            body.put("options", Map.of("temperature", 0.5, "num_predict", 1024));

            HttpResponse<String> res = postJson(trimSlash(ollamaBaseUrl) + "/api/chat", body,
                    Duration.ofSeconds(90));
            if (res.statusCode() != 200)
                throw new RuntimeException("Ollama HTTP " + res.statusCode());

            Map<String, Object> json = om.readValue(res.body(), new TypeReference<>() {});
            @SuppressWarnings("unchecked")
            Map<String, Object> message = (Map<String, Object>) json.get("message");
            String content = message == null ? "" : str(message.get("content"));
            String reply = stripThinkTags(content).trim();
            return sanitizeReply(reply.isBlank() ? "죄송합니다, 답변을 생성하지 못했습니다. 다시 질문해 주세요." : reply);
        } catch (Exception e) {
            log.warn("[OLLAMA-CONV] 대화 생성 실패: {}", e.getMessage());
            return "죄송합니다, 일시적인 오류가 발생했습니다.";
        }
    }

    /** 종합/전체/전반 분석 요청 감지 */
    private boolean isComprehensiveRequest(String msg) {
        String m = msg.toLowerCase();
        return (m.contains("종합") || m.contains("전반") || m.contains("전체"))
                && (m.contains("분석") || m.contains("리포트") || m.contains("현황"));
    }

    /**
     * Ollama 전용: 툴 결과를 plain-text 한국어 답변으로 변환.
     * format:json 없이 자유 텍스트로 받아서 JSON 파싱 문제를 원천 차단한다.
     */
    private String generateOllamaReply(String toolName, Object toolResult) {
        try {
            String label      = TOOL_LABELS.getOrDefault(toolName, toolName);
            String resultJson = toJson(toolResult);

            // 시스템 + user 메시지만 — 히스토리 없이 툴 결과에만 집중
            String userPrompt = "[" + label + " 결과]\n" + resultJson
                    + "\n\n위 데이터를 한국어로 분석해줘. 핵심 수치와 인사이트 포함, 완성된 문장으로 작성해줘.";

            Map<String, Object> body = new LinkedHashMap<>();
            body.put("model", ollamaModel);
            body.put("stream", false);
            body.put("messages", List.of(
                    msg("system", "너는 가계 재정을 도와주는 친근한 한국어 AI야. 데이터를 보고 명확하고 실용적으로 분석해줘."),
                    msg("user", userPrompt)
            ));
            body.put("options", Map.of("temperature", 0.4, "num_predict", 2048));

            HttpResponse<String> res = postJson(trimSlash(ollamaBaseUrl) + "/api/chat", body,
                    Duration.ofSeconds(120));
            if (res.statusCode() != 200)
                throw new RuntimeException("Ollama HTTP " + res.statusCode());

            Map<String, Object> json = om.readValue(res.body(), new TypeReference<>() {});
            @SuppressWarnings("unchecked")
            Map<String, Object> message = (Map<String, Object>) json.get("message");
            String content = message == null ? "" : str(message.get("content"));
            return stripThinkTags(content).trim();
        } catch (Exception e) {
            log.warn("[OLLAMA-REPLY] 답변 생성 실패: {}", e.getMessage());
            return "";
        }
    }

    /**
     * Ollama 4B 전용: 종합 분석을 서버에서 직접 오케스트레이션.
     * 모델에게 멀티툴 플래닝을 맡기지 않고, 정해진 순서로 데이터를 수집한 뒤
     * 최종 요약만 모델에게 요청한다.
     */
    private ChatResponse handleComprehensiveOllama(
            String userMessage, List<Map<String, Object>> history,
            String familyId, String userId, String userAuth,
            Consumer<Map<String, Object>> onProgress) throws Exception {

        List<String> toolsUsed = new ArrayList<>();
        Map<String, Object> gathered = new LinkedHashMap<>();

        // 수집할 툴 목록 (순서 중요)
        record ToolCall(String tool, Map<String, Object> args, String label) {}
        List<ToolCall> plan = List.of(
                new ToolCall("get_asset_summary",         Map.of(), "자산 요약"),
                new ToolCall("get_cost_center_status",    Map.of(), "수지계정현황"),
                new ToolCall("get_expense_summary",       Map.of(), "생활비 요약"),
                new ToolCall("calc_loan_interest_burden", Map.of(), "대출 이자 분석")
        );

        emit(onProgress, "status", "종합 재정 분석 시작...");

        for (ToolCall tc : plan) {
            emitTool(onProgress, "tool_start", tc.label(), tc.tool());
            Object result = executeTool(tc.tool(), tc.args(), familyId, userId, userAuth, onProgress);
            if (!(result instanceof Map<?, ?> rm && rm.containsKey("error"))) {
                gathered.put(tc.tool(), trimToolResult(tc.tool(), result));
                toolsUsed.add(tc.tool());
                emitTool(onProgress, "tool_end", tc.label(), tc.tool());
            }
        }

        // 수집된 데이터를 단일 분석 프롬프트로 묶어 모델에게 요약 요청
        String summaryPrompt =
                "다음은 우리 가족 재정 데이터입니다.\n" + toJson(gathered) +
                "\n\n위 데이터를 바탕으로 한국어로 종합 재정 분석을 해줘." +
                " 핵심 지표, 잘된 점, 주의할 점, 개선 방향을 포함해서 친절하게 설명해줘.";

        emit(onProgress, "status", "데이터 수집 완료, 분석 중...");
        String analysis = analyzePrompt(summaryPrompt);

        List<Map<String, Object>> messages = normalizeHistory(history);
        messages.add(msg("user", userMessage));
        messages.add(msg("assistant", analysis));
        emitDone(onProgress, analysis, messages, toolsUsed);
        return new ChatResponse(analysis, messages, toolsUsed);
    }

    /** 모델 reply 필드 정제 — JSON 껍데기 제거, 이스케이프 변환 */
    private String sanitizeReply(String reply) {
        if (reply == null || reply.isBlank()) return "";
        String t = reply.trim();

        // ① {"reply":"..."} 등 JSON 껍데기 제거
        if (t.startsWith("{")) {
            try {
                @SuppressWarnings("unchecked")
                Map<String, Object> inner = om.readValue(t, new TypeReference<Map<String,Object>>(){});
                for (String k : new String[]{"reply","text","message","content","answer","response"}) {
                    if (inner.containsKey(k)) {
                        t = str(inner.get(k));
                        break;
                    }
                }
            } catch (Exception ignored) {
                // 파싱 실패해도 계속 — 아래에서 리터럴 이스케이프 변환 시도
            }
        }

        // ② 모델이 \n 을 리터럴 2글자로 출력한 경우 실제 개행으로 변환
        //    (JSON 파싱 성공 시에도 \\n → \n 이 남아있을 수 있음)
        if (t.contains("\\n")) {
            t = t.replace("\\n", "\n")
                 .replace("\\t", "\t")
                 .replace("\\r", "");
        }

        // ③ 여전히 {"reply":"..."} 형태면 한번 더 시도 (이스케이프 변환 후 재파싱)
        if (t.startsWith("{")) {
            try {
                @SuppressWarnings("unchecked")
                Map<String, Object> inner2 = om.readValue(t, new TypeReference<Map<String,Object>>(){});
                for (String k : new String[]{"reply","text","message","content","answer","response"}) {
                    if (inner2.containsKey(k)) return str(inner2.get(k));
                }
            } catch (Exception ignored) {}
        }

        return t;
    }

    /**
     * Ollama 전용: 툴 결과를 압축해 컨텍스트를 절약한다.
     * 리스트는 최대 5건 + 합계, 숫자 필드만 남김.
     */
    @SuppressWarnings("unchecked")
    private Object trimToolResult(String tool, Object result) {
        if (result == null) return result;
        try {
            if (result instanceof Map<?, ?> map) {
                // 리스트 필드는 5건으로 축약
                Map<String, Object> trimmed = new LinkedHashMap<>();
                for (Map.Entry<?, ?> e : map.entrySet()) {
                    String k = str(e.getKey());
                    Object v = e.getValue();
                    if (v instanceof List<?> list) {
                        int size = list.size();
                        trimmed.put(k, size > 5 ? list.subList(0, 5) : v);
                        if (size > 5) trimmed.put(k + "_total", size);
                    } else {
                        trimmed.put(k, v);
                    }
                }
                return trimmed;
            }
        } catch (Exception e) {
            log.debug("[TRIM] failed: {}", e.getMessage());
        }
        return result;
    }

    /**
     * 자산 예측 컨텍스트를 받아 단순 분석 텍스트를 반환 (tool/history 없이 단발 호출).
     */
    public String analyzeAssetForecast(Map<String, Object> aiContext) throws Exception {
        String prompt = buildForecastPrompt(aiContext);
        return analyzePrompt(prompt);
    }

    /**
     * 화면별 요약 컨텍스트를 받아 단발 분석 텍스트를 반환한다.
     */
    public String analyzeFinancialReport(Map<String, Object> aiContext) throws Exception {
        String prompt = buildFinancialReportPrompt(aiContext);
        return analyzePrompt(prompt);
    }

    private String analyzePrompt(String prompt) throws Exception {
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

    private String buildFinancialReportPrompt(Map<String, Object> ctx) {
        String reportTitle = str(ctx.get("reportTitle"));
        String reportType = str(ctx.get("reportType"));
        String generatedAt = str(ctx.get("generatedAt"));

        StringBuilder sb = new StringBuilder();
        sb.append("우리 가족 재정 화면의 요약 데이터야. 화면 성격에 맞춰 한국어로 분석 리포트를 작성해줘.\n");
        sb.append("제목: ").append(reportTitle.isBlank() ? "재정 분석 리포트" : reportTitle).append("\n");
        if (!reportType.isBlank()) sb.append("화면 유형: ").append(reportType).append("\n");
        if (!generatedAt.isBlank()) sb.append("생성일: ").append(generatedAt).append("\n");
        sb.append("\n다음 형식을 지켜줘.\n");
        sb.append("① 핵심 요약 2~3문장\n");
        sb.append("② 좋아 보이는 점\n");
        sb.append("③ 주의할 점/이상 징후\n");
        sb.append("④ 바로 할 수 있는 개선 액션 2~3개\n");
        sb.append("구체적인 금액과 비율을 언급하고, 없는 데이터는 추측하지 말아줘.\n\n");
        sb.append("[화면 요약 JSON]\n");
        sb.append(toJson(ctx));
        return sb.toString();
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
        // ── 4B 모델 툴 선택 원칙 ──────────────────────────────────────────
        // 1. 시스템 프롬프트: 전체 툴 목록 (Ollama KV 캐시 → 동일 프롬프트면 1회만 비용 발생)
        // 2. 대화: 마지막 user 메시지 1개만 (히스토리·fake 턴 주입 일절 금지)
        // 3. 결과: {"tool":"name","args":{}} 또는 {"reply":"..."}
        // ─────────────────────────────────────────────────────────────────

        // 마지막 user 메시지만 추출
        String lastUserMsg = "";
        for (int i = messages.size() - 1; i >= 0; i--) {
            if ("user".equals(str(messages.get(i).get("role")))) {
                lastUserMsg = str(messages.get(i).get("content"));
                break;
            }
        }

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("model", ollamaModel);
        body.put("stream", false);
        body.put("format", "json");
        body.put("messages", List.of(
                msg("system", systemPromptOllama(familyId, userAuth)),
                msg("user", lastUserMsg)
        ));
        // thinking 모델이 <think> 블록을 먼저 출력할 수 있으므로 num_predict 충분히
        body.put("options", Map.of("temperature", 0.05, "num_predict", 512));

        HttpResponse<String> res = postJson(trimSlash(ollamaBaseUrl) + "/api/chat", body);
        if (res.statusCode() != 200)
            throw new RuntimeException("Ollama HTTP " + res.statusCode() + ": " + shortBody(res.body()));

        Map<String, Object> json = om.readValue(res.body(), new TypeReference<>() {});
        @SuppressWarnings("unchecked")
        Map<String, Object> message = (Map<String, Object>) json.get("message");
        if (message == null) throw new RuntimeException("Ollama 응답에 message가 없습니다.");
        return stripThinkTags(str(message.get("content")));
    }

    /**
     * 4B 모델 전용 시스템 프롬프트.
     * Ollama는 동일한 시스템 프롬프트를 KV 캐시하므로 길어도 1회만 비용 발생.
     * 전체 툴 목록 + few-shot 포함. buildToolHint 없이 단독으로 충분.
     */
    private String systemPromptOllama(String familyId, String userAuth) {
        boolean isManager = "manager".equals(userAuth);
        String nowYymm  = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMM"));
        String prevYymm = LocalDate.now().minusMonths(1).format(DateTimeFormatter.ofPattern("yyyyMM"));
        String mgr = isManager
                ? "\napprove_deposit(depReqSeq,reqStatus) delete_deposit(depReqSeq)" : "";

        return "You are HOMES AI. familyId=" + familyId
             + " role=" + (isManager ? "manager" : "user")
             + " thisMonth=" + nowYymm + " lastMonth=" + prevYymm + "\n"
             + "Output ONE JSON only. No text outside JSON.\n"
             + "Tool call : {\"tool\":\"EXACT_NAME\",\"args\":{...}}\n"
             + "Text reply: {\"reply\":\"한국어 답변\"}\n\n"
             + "TOOL LIST (copy name exactly, never invent):\n"
             + "list_notes\n"
             + "insert_note           args: title, content\n"
             + "update_note           args: noteSeq or targetTitle, title, content\n"
             + "delete_note           args: noteSeq or targetTitle\n"
             + "list_deposit_requests\n"
             + "insert_deposit_request args: storeInfo, amount, reqDesc\n"
             + "get_deposit_detail    args: depReqSeq\n"
             + "get_asset_summary\n"
             + "list_assets\n"
             + "list_loans\n"
             + "get_asset_forecast    args: months\n"
             + "get_asset_type_summary\n"
             + "get_snapshot_months\n"
             + "get_cost_center_status      args: fromYymm, toYymm\n"
             + "get_asset_change_history    args: fromYymm, toYymm\n"
             + "get_expense_summary         args: fromYymm, toYymm\n"
             + "get_expense_list\n"
             + "list_cashflow_plans         args: flowCategory(INCOME/EXPENSE), useYn(Y/N)\n"
             + "get_manual_cashflow_detail  args: fromYymm, toYymm\n"
             + "calc_loan_interest_burden\n"
             + "global_search               args: keyword" + mgr + "\n\n"
             + "EXAMPLES:\n"
             + "Q:메모 목록       → {\"tool\":\"list_notes\",\"args\":{}}\n"
             + "Q:자산 현황       → {\"tool\":\"get_asset_summary\",\"args\":{}}\n"
             + "Q:이번달 생활비   → {\"tool\":\"get_expense_summary\",\"args\":{\"fromYymm\":\"" + nowYymm + "\",\"toYymm\":\"" + nowYymm + "\"}}\n"
             + "Q:저번달 생활비   → {\"tool\":\"get_expense_summary\",\"args\":{\"fromYymm\":\"" + prevYymm + "\",\"toYymm\":\"" + prevYymm + "\"}}\n"
             + "Q:대출 이자 분석  → {\"tool\":\"calc_loan_interest_burden\",\"args\":{}}\n"
             + "Q:안녕            → {\"reply\":\"안녕하세요! 무엇을 도와드릴까요?\"}\n";
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

                    emit(onProgress, "status", "공유드라이브 검색 중...");
                    List<DmsFileVO> dmsFiles = dmsMapper.searchFiles(familyId, keyword);
                    List<DmsFolderVO> dmsFolders = dmsMapper.searchFolders(familyId, keyword);

                    emit(onProgress, "status", "가족앨범 검색 중...");
                    List<SnsPostVO> snsPosts = snsMapper.searchPosts(familyId, keyword);

                    Map<String, Object> searchResult = new LinkedHashMap<>();
                    searchResult.put("keyword", keyword);
                    searchResult.put("notes", notes.stream().map(n -> {
                        Map<String, Object> m = new LinkedHashMap<>();
                        m.put("domain", "note");
                        m.put("noteSeq", n.getNoteSeq());
                        m.put("title", nvl(n.getTitle()));
                        m.put("contentPreview", preview(n.getContent()));
                        m.put("regId", nvl(n.getRegId()));
                        m.put("updatedAt", nvl(n.getUpdDtText()));
                        m.put("url", "/note/detail/" + n.getNoteSeq());
                        return m;
                    }).toList());
                    searchResult.put("depositRequests", deposits.stream().map(v -> {
                        Map<String, Object> m = new LinkedHashMap<>();
                        m.put("domain", "depositRequest");
                        m.put("depReqSeq", v.getDepReqSeq());
                        m.put("storeInfo", nvl(v.getStoreInfo()));
                        m.put("amount", v.getAmount() == null ? 0L : v.getAmount());
                        m.put("reqStatus", nvl(v.getReqStatus()));
                        m.put("reqDesc", nvl(v.getReqDesc()));
                        m.put("regId", nvl(v.getRegId()));
                        m.put("requestDt", nvl(v.getRequestDt()));
                        m.put("url", "/scm/deposit/depositRequest");
                        return m;
                    }).toList());
                    searchResult.put("assets", assets.stream().map(a -> {
                        Map<String, Object> m = new LinkedHashMap<>();
                        m.put("domain", "asset");
                        m.put("assetSeq", a.getAssetSeq());
                        m.put("assetNm", nvl(a.getAssetNm()));
                        m.put("assetTypeNm", nvl(a.getAssetTypeNm()));
                        m.put("liquidYn", nvl(a.getLiquidYn()));
                        m.put("amount", a.getAmount() == null ? 0L : a.getAmount());
                        m.put("disposeYn", nvl(a.getDisposeYn()));
                        m.put("memo", nvl(a.getMemo()));
                        m.put("url", "/asset/ledger");
                        return m;
                    }).toList());
                    searchResult.put("loans", loans.stream().map(l -> {
                        Map<String, Object> m = new LinkedHashMap<>();
                        m.put("domain", "loan");
                        m.put("loanSeq", l.getLoanSeq());
                        m.put("loanNm", nvl(l.getLoanNm()));
                        m.put("loanAmount", l.getLoanAmount() == null ? 0L : l.getLoanAmount());
                        m.put("currentBalance", l.getCurrentBalance() == null ? 0L : l.getCurrentBalance());
                        m.put("interestRate", l.getInterestRate() == null ? "" : l.getInterestRate().toPlainString());
                        m.put("closeYn", nvl(l.getCloseYn()));
                        m.put("memo", nvl(l.getMemo()));
                        m.put("url", "/asset/loan");
                        return m;
                    }).toList());
                    searchResult.put("cashFlowPlans", plans.stream().map(p -> {
                        Map<String, Object> m = new LinkedHashMap<>();
                        m.put("domain", p.getFlowType().equals("INCOME") ? "incomePlan" : "expensePlan");
                        m.put("planSeq", p.getPlanSeq());
                        m.put("planNm", nvl(p.getPlanNm()));
                        m.put("planTypeNm", nvl(p.getPlanTypeNm()));
                        m.put("flowType", nvl(p.getFlowType()));
                        m.put("amount", p.getAmount() == null ? 0L : p.getAmount());
                        m.put("cycleDesc", nvl(p.getCycleDesc()));
                        m.put("useYn", nvl(p.getUseYn()));
                        m.put("memo", nvl(p.getMemo()));
                        m.put("url", "INCOME".equals(p.getFlowType()) ? "/asset/income" : "/asset/expense");
                        return m;
                    }).toList());
                    searchResult.put("dmsFiles", dmsFiles.stream().map(f -> {
                        Map<String, Object> m = new LinkedHashMap<>();
                        m.put("domain", "dmsFile");
                        m.put("fileSeq", f.getFileSeq());
                        m.put("fileNm", nvl(f.getFileNm()));
                        m.put("mimeType", nvl(f.getMimeType()));
                        m.put("regId", nvl(f.getRegId()));
                        m.put("url", f.getFolderSeq() != null ? "/dms?folderSeq=" + f.getFolderSeq() : "/dms");
                        return m;
                    }).toList());
                    searchResult.put("dmsFolders", dmsFolders.stream().map(f -> {
                        Map<String, Object> m = new LinkedHashMap<>();
                        m.put("domain", "dmsFolder");
                        m.put("folderSeq", f.getFolderSeq());
                        m.put("folderNm", nvl(f.getFolderNm()));
                        m.put("regId", nvl(f.getRegId()));
                        m.put("url", "/dms?folderSeq=" + f.getFolderSeq());
                        return m;
                    }).toList());
                    searchResult.put("snsPosts", snsPosts.stream().map(p -> {
                        Map<String, Object> m = new LinkedHashMap<>();
                        m.put("domain", "snsPost");
                        m.put("postSeq", p.getPostSeq());
                        m.put("contentPreview", preview(p.getContent()));
                        m.put("regId", nvl(p.getRegId()));
                        m.put("url", "/sns");
                        return m;
                    }).toList());
                    yield searchResult;
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
                    int months;
                    if (monthsArg instanceof Number n) {
                        months = Math.min(Math.max(n.intValue(), 1), 120);
                    } else {
                        try { months = Math.min(Math.max(Integer.parseInt(String.valueOf(monthsArg).trim()), 1), 120); }
                        catch (NumberFormatException ignored) { months = 12; }
                    }
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

                    Map<String, Object> forecastResult = new LinkedHashMap<>();
                    forecastResult.put("forecastMonths",    months);
                    forecastResult.put("currentNetAsset",   full.get("currentNetAsset"));
                    forecastResult.put("totalAsset",        full.get("totalAsset"));
                    forecastResult.put("totalLoan",         full.get("totalLoan"));
                    forecastResult.put("avgMonthlyIncome",  full.get("planAvgIncome"));
                    forecastResult.put("avgMonthlyExpense", full.get("planAvgExpense"));
                    forecastResult.put("actualAvgMoM",      full.get("actualAvgMoM"));
                    forecastResult.put("actualityRatio",    full.get("actualityRatio"));
                    forecastResult.put("scenarioSummary",   scenarioSummary);
                    forecastResult.put("activePlanCount",   planSummary == null ? 0 : planSummary.size());
                    forecastResult.put("planSummary",       planSummary == null ? List.of() : planSummary);
                    yield forecastResult;
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
                // ── 공유메모 목록 ──────────────────────────────────────────────
                case "list_notes" -> {
                    emit(onProgress, "status", "공유메모 목록 조회 중...");
                    NoteVO param = new NoteVO();
                    param.setFamilyId(familyId);
                    List<NoteVO> notes = noteService.getNoteList(param);
                    yield notes.stream().map(n -> {
                        Map<String, Object> m = new LinkedHashMap<>();
                        m.put("noteSeq", n.getNoteSeq());
                        m.put("title", nvl(n.getTitle()));
                        m.put("contentPreview", preview(n.getContent()));
                        m.put("regId", nvl(n.getRegId()));
                        m.put("updatedAt", nvl(n.getUpdDtText()));
                        return m;
                    }).toList();
                }
                // ── 공유메모 삭제 ──────────────────────────────────────────────
                case "delete_note" -> {
                    Long noteSeq = toLongOrNull(args.get("noteSeq"));
                    String targetTitle = firstText(args.get("targetTitle"), args.get("noteTitle"));
                    NoteVO target = resolveNoteTarget(familyId, noteSeq, targetTitle);
                    if (target == null) {
                        yield confirmRequired("삭제할 공유메모 번호나 제목을 알려주세요.");
                    }
                    noteService.deleteNote(familyId, target.getNoteSeq(), userId);
                    yield Map.of("result", "삭제완료", "noteSeq", target.getNoteSeq(), "title", nvl(target.getTitle()));
                }
                // ── 자산 목록 ──────────────────────────────────────────────────
                case "list_assets" -> {
                    emit(onProgress, "status", "자산 목록 조회 중...");
                    String includeDisposed = str(args.getOrDefault("includeDisposed", "N")).equalsIgnoreCase("Y") ? null : "N";
                    List<AssetVO> assets = assetMapper.selectAssetList(familyId, includeDisposed);
                    yield assets.stream().map(a -> {
                        Map<String, Object> m = new LinkedHashMap<>();
                        m.put("assetSeq", a.getAssetSeq());
                        m.put("assetNm", nvl(a.getAssetNm()));
                        m.put("assetTypeNm", nvl(a.getAssetTypeNm()));
                        m.put("liquidYn", nvl(a.getLiquidYn()));
                        m.put("amount", a.getAmount() == null ? 0L : a.getAmount());
                        m.put("disposeYn", nvl(a.getDisposeYn()));
                        m.put("memo", nvl(a.getMemo()));
                        return m;
                    }).toList();
                }
                // ── 대출 목록 ──────────────────────────────────────────────────
                case "list_loans" -> {
                    emit(onProgress, "status", "대출 목록 조회 중...");
                    String includeClosed = str(args.getOrDefault("includeClosed", "N")).equalsIgnoreCase("Y") ? null : "N";
                    List<LoanVO> loans = assetMapper.selectLoanList(familyId, includeClosed);
                    yield loans.stream().map(l -> {
                        Map<String, Object> m = new LinkedHashMap<>();
                        m.put("loanSeq", l.getLoanSeq());
                        m.put("loanNm", nvl(l.getLoanNm()));
                        m.put("loanAmount", l.getLoanAmount() == null ? 0L : l.getLoanAmount());
                        m.put("currentBalance", l.getCurrentBalance() == null ? 0L : l.getCurrentBalance());
                        m.put("interestRate", l.getInterestRate() == null ? "" : l.getInterestRate().toPlainString());
                        m.put("closeYn", nvl(l.getCloseYn()));
                        m.put("memo", nvl(l.getMemo()));
                        return m;
                    }).toList();
                }
                // ── 생활비 지출 요약 ───────────────────────────────────────────
                case "get_expense_summary" -> {
                    String fromArg = str(args.getOrDefault("fromYymm", "")).trim();
                    String toArg   = str(args.getOrDefault("toYymm", "")).trim();
                    String thisMonth = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMM"));
                    if (fromArg.isBlank()) fromArg = thisMonth;
                    if (toArg.isBlank())   toArg   = thisMonth;
                    emit(onProgress, "status", "생활비 지출 요약 조회 중 (" + fromArg + "~" + toArg + ")...");
                    List<com.eksystems.homes.living.vo.LivingExpenseSummaryVO> summaryList =
                            livingService.getExpenseSummaryByRange(familyId, fromArg, toArg);
                    long totalBudget = summaryList.stream()
                            .mapToLong(s -> s.getTotalBudgetAmt() == null ? 0L : s.getTotalBudgetAmt()).sum();
                    long totalActual = summaryList.stream()
                            .mapToLong(s -> s.getTotalActualAmt() == null ? 0L : s.getTotalActualAmt()).sum();
                    Map<String, Object> result = new LinkedHashMap<>();
                    result.put("period", Map.of("fromYymm", fromArg, "toYymm", toArg));
                    result.put("totalBudgetAmt", totalBudget);
                    result.put("totalActualAmt", totalActual);
                    result.put("balance", totalBudget - totalActual);
                    result.put("categories", summaryList.stream().map(s -> {
                        Map<String, Object> m = new LinkedHashMap<>();
                        m.put("catNm", nvl(s.getCatNm()));
                        m.put("budgetAmt", s.getTotalBudgetAmt() == null ? 0L : s.getTotalBudgetAmt());
                        m.put("actualAmt", s.getTotalActualAmt() == null ? 0L : s.getTotalActualAmt());
                        m.put("balance", (s.getTotalBudgetAmt() == null ? 0L : s.getTotalBudgetAmt())
                                       - (s.getTotalActualAmt() == null ? 0L : s.getTotalActualAmt()));
                        return m;
                    }).toList());
                    yield result;
                }
                // ── 전표처리 월 목록 ──────────────────────────────────────────
                case "get_snapshot_months" -> {
                    emit(onProgress, "status", "전표처리 월 목록 조회 중...");
                    String fromArg = str(args.getOrDefault("fromYymm", "")).trim();
                    String toArg   = str(args.getOrDefault("toYymm", "")).trim();

                    List<AssetChangeSummaryVO> all = snapshotService.getAssetChangeSummary(familyId);
                    List<String> snapshotMonths = all.stream()
                            .map(AssetChangeSummaryVO::getHstYymm)
                            .filter(ym -> (fromArg.isBlank() || ym.compareTo(fromArg) >= 0)
                                    && (toArg.isBlank() || ym.compareTo(toArg) <= 0))
                            .sorted()
                            .toList();

                    String latestSnapshot = snapshotMonths.isEmpty() ? null
                            : snapshotMonths.get(snapshotMonths.size() - 1);
                    String earliestSnapshot = snapshotMonths.isEmpty() ? null
                            : snapshotMonths.get(0);

                    yield Map.of(
                        "snapshotMonths",    snapshotMonths,
                        "count",             snapshotMonths.size(),
                        "earliest",          earliestSnapshot != null ? earliestSnapshot : "",
                        "latest",            latestSnapshot   != null ? latestSnapshot   : "",
                        "currentMonth",      LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMM")),
                        "note",              "snapshotMonths 목록에 있는 달만 전표처리(확정) 데이터입니다. 없는 달은 실시간(미확정) 계획 데이터로 조회됩니다."
                    );
                }

                // ── 수지계정현황 ──────────────────────────────────────────────
                case "get_cost_center_status" -> {
                    String fromYymm = str(args.getOrDefault("fromYymm", "")).trim();
                    String toYymm   = str(args.getOrDefault("toYymm", "")).trim();
                    String thisMonth = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMM"));
                    if (fromYymm.isBlank()) fromYymm = thisMonth;
                    if (toYymm.isBlank())   toYymm   = thisMonth;

                    emit(onProgress, "status", "수지계정현황 조회 중 (" + fromYymm + "~" + toYymm + ")...");

                    List<String> months = aiListMonths(fromYymm, toYymm);
                    List<String> snapshotMonths = months.stream()
                            .filter(ym -> snapshotService.hasSnapshot(familyId, ym))
                            .toList();
                    List<String> liveMonths = months.stream()
                            .filter(ym -> !snapshotService.hasSnapshot(familyId, ym))
                            .toList();

                    List<CostCenterStatusVO> statusList;
                    if (months.size() == 1) {
                        if (!snapshotMonths.isEmpty()) {
                            statusList = snapshotService.getCostCenterHst(familyId, fromYymm);
                            for (CostCenterStatusVO s : statusList) {
                                long inc = s.getIncomeMonthlyAmt()  != null ? s.getIncomeMonthlyAmt()  : 0L;
                                long exp = s.getExpenseMonthlyAmt() != null ? s.getExpenseMonthlyAmt() : 0L;
                                s.setTotalIncomeAmt(inc);
                                s.setTotalExpenseAmt(exp);
                                s.setBalance(inc - exp);
                            }
                        } else {
                            statusList = costCenterService.getStatusList(familyId, fromYymm, toYymm);
                        }
                    } else {
                        statusList = aiBuildMultiMonthStatus(familyId, months);
                    }

                    // 수기 현금흐름 합산
                    List<LivingIncomeMstVO> allManual = livingService.getIncomeListByRange(familyId, fromYymm, toYymm);
                    Map<Long, Long> manualIncByCC = allManual.stream()
                            .filter(m -> "INCOME".equals(m.getFlowType()) && m.getCcSeq() != null)
                            .collect(Collectors.groupingBy(LivingIncomeMstVO::getCcSeq,
                                    Collectors.summingLong(m -> m.getActualAmt() != null ? m.getActualAmt() : 0L)));
                    Map<Long, Long> manualExpByCC = allManual.stream()
                            .filter(m -> !"INCOME".equals(m.getFlowType()) && m.getCcSeq() != null)
                            .collect(Collectors.groupingBy(LivingIncomeMstVO::getCcSeq,
                                    Collectors.summingLong(m -> m.getActualAmt() != null ? m.getActualAmt() : 0L)));

                    for (CostCenterStatusVO s : statusList) {
                        long inc = (s.getTotalIncomeAmt()  != null ? s.getTotalIncomeAmt()  : 0L)
                                 + manualIncByCC.getOrDefault(s.getCcSeq(), 0L);
                        long exp = (s.getTotalExpenseAmt() != null ? s.getTotalExpenseAmt() : 0L)
                                 + manualExpByCC.getOrDefault(s.getCcSeq(), 0L);
                        s.setTotalIncomeAmt(inc);
                        s.setTotalExpenseAmt(exp);
                        s.setBalance(inc - exp);
                    }

                    long grandIncome  = statusList.stream().mapToLong(s -> s.getTotalIncomeAmt()  != null ? s.getTotalIncomeAmt()  : 0L).sum();
                    long grandExpense = statusList.stream().mapToLong(s -> s.getTotalExpenseAmt() != null ? s.getTotalExpenseAmt() : 0L).sum();

                    List<Map<String, Object>> centers = statusList.stream().map(s -> {
                        long inc = s.getTotalIncomeAmt()  != null ? s.getTotalIncomeAmt()  : 0L;
                        long exp = s.getTotalExpenseAmt() != null ? s.getTotalExpenseAmt() : 0L;
                        Map<String, Object> row = new LinkedHashMap<>();
                        row.put("ccSeq",    s.getCcSeq());
                        row.put("name",     nvl(s.getCcNm()));
                        row.put("type",     nvl(s.getCcType()));
                        row.put("income",   inc);
                        row.put("expense",  exp);
                        row.put("balance",  inc - exp);
                        row.put("expenseSharePct", grandExpense > 0
                                ? Math.round(exp * 1000.0 / grandExpense) / 10.0 : 0.0);
                        return row;
                    }).toList();

                    yield Map.of(
                        "period", Map.of("fromYymm", fromYymm, "toYymm", toYymm),
                        "dataSource", Map.of(
                            "snapshotMonths", snapshotMonths,
                            "liveMonths",     liveMonths,
                            "note",           snapshotMonths.isEmpty()
                                ? "전체 기간이 실시간(전표처리 전) 데이터입니다."
                                : liveMonths.isEmpty()
                                    ? "전체 기간이 전표처리(확정) 데이터입니다."
                                    : "일부 달만 전표처리됨. 혼재된 데이터입니다."
                        ),
                        "summary", Map.of(
                            "totalIncome",      grandIncome,
                            "totalExpense",     grandExpense,
                            "balance",          grandIncome - grandExpense,
                            "expenseRatePct",   grandIncome > 0
                                    ? Math.round(grandExpense * 1000.0 / grandIncome) / 10.0 : 0.0,
                            "costCenterCount",  statusList.size()
                        ),
                        "costCenters", centers,
                        "topExpenseCenters", centers.stream()
                            .sorted((a, b) -> Long.compare(
                                    ((Number) b.get("expense")).longValue(),
                                    ((Number) a.get("expense")).longValue()))
                            .limit(5).toList(),
                        "negativeBalanceCenters", centers.stream()
                            .filter(v -> ((Number) v.get("balance")).longValue() < 0)
                            .toList()
                    );
                }

                // ── 자산변동현황 ──────────────────────────────────────────────
                case "get_asset_change_history" -> {
                    String fromYymm = str(args.getOrDefault("fromYymm", "")).trim();
                    String toYymm   = str(args.getOrDefault("toYymm", "")).trim();

                    emit(onProgress, "status", "자산변동현황 조회 중...");

                    List<AssetChangeSummaryVO> summaryList = snapshotService.getAssetChangeSummary(familyId);
                    if (!fromYymm.isBlank()) {
                        String ff = fromYymm;
                        summaryList = summaryList.stream()
                                .filter(s -> s.getHstYymm().compareTo(ff) >= 0).toList();
                    }
                    if (!toYymm.isBlank()) {
                        String tt = toYymm;
                        summaryList = summaryList.stream()
                                .filter(s -> s.getHstYymm().compareTo(tt) <= 0).toList();
                    }

                    List<Map<String, Object>> monthly = new ArrayList<>();
                    for (int i = 0; i < summaryList.size(); i++) {
                        AssetChangeSummaryVO s = summaryList.get(i);
                        long momChange = i == 0 ? 0L
                                : s.getNetAssetAmt() - summaryList.get(i - 1).getNetAssetAmt();
                        Map<String, Object> row = new LinkedHashMap<>();
                        row.put("hstYymm",       s.getHstYymm());
                        row.put("dataSource",    "snapshot");  // 전표처리된 데이터
                        row.put("totalAsset",    s.getTotalAssetAmt());
                        row.put("totalLoan",     s.getTotalLoanBalance());
                        row.put("netAsset",      s.getNetAssetAmt());
                        row.put("liquidAsset",   s.getLiquidAssetAmt());
                        row.put("fixedAsset",    s.getFixedAssetAmt());
                        row.put("monthlyIncome", s.getMonthlyIncome());
                        row.put("monthlyExpense",s.getMonthlyExpense());
                        row.put("momNetAsset",   momChange);
                        monthly.add(row);
                    }

                    AssetChangeSummaryVO latest = summaryList.isEmpty() ? null
                            : summaryList.get(summaryList.size() - 1);
                    long avgMom = summaryList.size() > 1
                            ? Math.round(monthly.stream().skip(1)
                                    .mapToLong(m -> ((Number) m.get("momNetAsset")).longValue())
                                    .average().orElse(0.0))
                            : 0L;
                    long posMonths = monthly.stream()
                            .filter(m -> ((Number) m.get("momNetAsset")).longValue() > 0).count();
                    long negMonths = monthly.stream()
                            .filter(m -> ((Number) m.get("momNetAsset")).longValue() < 0).count();

                    Map<String, Object> result = new LinkedHashMap<>();
                    result.put("note", "자산변동현황은 전표처리(스냅샷)된 달의 확정 데이터입니다. 전표처리되지 않은 달은 포함되지 않습니다.");
                    result.put("dataSource", "snapshot");
                    result.put("totalMonths", summaryList.size());
                    result.put("fromYymm", fromYymm.isBlank() ? (monthly.isEmpty() ? "" : str(monthly.get(0).get("hstYymm"))) : fromYymm);
                    result.put("toYymm",   toYymm.isBlank()   ? (monthly.isEmpty() ? "" : str(monthly.get(monthly.size() - 1).get("hstYymm"))) : toYymm);
                    if (latest != null) {
                        result.put("latestMonth", Map.of(
                            "hstYymm",      latest.getHstYymm(),
                            "totalAsset",   latest.getTotalAssetAmt(),
                            "totalLoan",    latest.getTotalLoanBalance(),
                            "netAsset",     latest.getNetAssetAmt(),
                            "liquidAsset",  latest.getLiquidAssetAmt(),
                            "fixedAsset",   latest.getFixedAssetAmt()
                        ));
                    }
                    result.put("movementSummary", Map.of(
                        "averageMomChange", avgMom,
                        "positiveMonths",   posMonths,
                        "negativeMonths",   negMonths
                    ));
                    result.put("monthlyTrend", monthly);
                    yield result;
                }

                // ── 정기 계획 목록 ────────────────────────────────────────────
                case "list_cashflow_plans" -> {
                    String flowCat = str(args.getOrDefault("flowCategory", "")).trim().toUpperCase();
                    String useYnArg = str(args.getOrDefault("useYn", "")).trim().toUpperCase();
                    String flowCatParam = flowCat.isBlank() ? null : flowCat;
                    String useYnParam   = useYnArg.isBlank() ? null : useYnArg;
                    emit(onProgress, "status", "정기 수입/지출 계획 목록 조회 중...");
                    List<CashFlowPlanVO> plans = cashFlowMapper.selectPlanList(familyId, flowCatParam, useYnParam);

                    long totalIncome  = plans.stream()
                            .filter(p -> "INCOME".equals(p.getFlowType()) && "Y".equals(p.getUseYn()))
                            .mapToLong(p -> p.getAmount() == null ? 0L : p.getAmount()).sum();
                    long totalExpense = plans.stream()
                            .filter(p -> "EXPENSE".equals(p.getFlowType()) && "Y".equals(p.getUseYn()))
                            .mapToLong(p -> p.getAmount() == null ? 0L : p.getAmount()).sum();
                    long totalSaving  = plans.stream()
                            .filter(p -> "SAVING".equals(p.getFlowType()) && "Y".equals(p.getUseYn()))
                            .mapToLong(p -> p.getAmount() == null ? 0L : p.getAmount()).sum();
                    long totalInvest  = plans.stream()
                            .filter(p -> "INVEST".equals(p.getFlowType()) && "Y".equals(p.getUseYn()))
                            .mapToLong(p -> p.getAmount() == null ? 0L : p.getAmount()).sum();

                    Map<String, Object> result = new LinkedHashMap<>();
                    result.put("filter", Map.of("flowCategory", flowCat.isBlank() ? "ALL" : flowCat,
                                                "useYn", useYnArg.isBlank() ? "ALL" : useYnArg));
                    result.put("activeMonthlyIncome",  totalIncome);
                    result.put("activeMonthlyExpense", totalExpense);
                    result.put("activeMonthlyNetCashFlow", totalIncome - totalExpense - totalSaving - totalInvest);
                    result.put("plans", plans.stream().map(p -> {
                        Map<String, Object> m = new LinkedHashMap<>();
                        m.put("planSeq",    p.getPlanSeq());
                        m.put("planNm",     nvl(p.getPlanNm()));
                        m.put("planTypeNm", nvl(p.getPlanTypeNm()));
                        m.put("flowType",   nvl(p.getFlowType()));
                        m.put("amount",     p.getAmount() == null ? 0L : p.getAmount());
                        m.put("cycleDesc",  nvl(p.getCycleDesc()));
                        m.put("useYn",      nvl(p.getUseYn()));
                        m.put("startYmd",   p.getStartYmd() != null ? p.getStartYmd().toString() : "");
                        m.put("endYmd",     p.getEndYmd()   != null ? p.getEndYmd().toString()   : "");
                        m.put("memo",       nvl(p.getMemo()));
                        return m;
                    }).toList());
                    yield result;
                }

                // ── 자산 유형별 구성 요약 ─────────────────────────────────────
                case "get_asset_type_summary" -> {
                    emit(onProgress, "status", "자산 유형별 구성 분석 중...");
                    List<com.eksystems.homes.asset.vo.AssetTypeSummaryVO> typeSummary =
                            assetMapper.selectAssetTypeSummary(familyId);
                    long grandTotal = typeSummary.stream()
                            .mapToLong(t -> t.getTotalAmount() == null ? 0L : t.getTotalAmount()).sum();
                    List<Map<String, Object>> types = typeSummary.stream().map(t -> {
                        long amt = t.getTotalAmount() == null ? 0L : t.getTotalAmount();
                        Map<String, Object> m = new LinkedHashMap<>();
                        m.put("assetType",   nvl(t.getAssetType()));
                        m.put("assetTypeNm", nvl(t.getAssetTypeNm()));
                        m.put("totalAmount", amt);
                        m.put("assetCount",  t.getAssetCount() == null ? 0L : t.getAssetCount());
                        m.put("sharePct",    grandTotal > 0
                                ? Math.round(amt * 1000.0 / grandTotal) / 10.0 : 0.0);
                        return m;
                    }).sorted((a, b) -> Long.compare(
                            ((Number) b.get("totalAmount")).longValue(),
                            ((Number) a.get("totalAmount")).longValue()
                    )).toList();
                    yield Map.of(
                        "grandTotalAmount", grandTotal,
                        "typeCount",        types.size(),
                        "types",            types,
                        "diversification",  types.size() >= 4 ? "분산투자(4종류 이상)"
                                          : types.size() >= 2 ? "부분분산(2~3종류)" : "집중(1종류)"
                    );
                }

                // ── 수기 현금흐름 실적 상세 ──────────────────────────────────
                case "get_manual_cashflow_detail" -> {
                    String fromArg = str(args.getOrDefault("fromYymm", "")).trim();
                    String toArg   = str(args.getOrDefault("toYymm",   "")).trim();
                    String thisMonth = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMM"));
                    if (fromArg.isBlank()) fromArg = thisMonth;
                    if (toArg.isBlank())   toArg   = thisMonth;
                    emit(onProgress, "status", "수기 현금흐름 실적 조회 중 (" + fromArg + "~" + toArg + ")...");

                    List<com.eksystems.homes.living.vo.ManualCashflowVO> cfList =
                            livingService.getManualCfListByRange(familyId, fromArg, toArg);

                    long totalInc = cfList.stream()
                            .filter(c -> "INCOME".equals(c.getFlowType()))
                            .mapToLong(c -> c.getActualAmt() == null ? 0L : c.getActualAmt()).sum();
                    long totalExp = cfList.stream()
                            .filter(c -> !"INCOME".equals(c.getFlowType()))
                            .mapToLong(c -> c.getActualAmt() == null ? 0L : c.getActualAmt()).sum();

                    yield Map.of(
                        "period",       Map.of("fromYymm", fromArg, "toYymm", toArg),
                        "totalIncome",  totalInc,
                        "totalExpense", totalExp,
                        "netCashFlow",  totalInc - totalExp,
                        "itemCount",    cfList.size(),
                        "items",        cfList.stream().map(c -> {
                            Map<String, Object> m = new LinkedHashMap<>();
                            m.put("cfSeq",     c.getCfSeq());
                            m.put("ccNm",      nvl(c.getCcNm()));
                            m.put("flowType",  nvl(c.getFlowType()));
                            m.put("flowYymm",  nvl(c.getFlowYymm()));
                            m.put("title",     nvl(c.getTitle()));
                            m.put("actualAmt", c.getActualAmt() == null ? 0L : c.getActualAmt());
                            m.put("memo",      nvl(c.getMemo()));
                            m.put("regId",     nvl(c.getRegId()));
                            m.put("regDtStr",  nvl(c.getRegDtStr()));
                            return m;
                        }).toList()
                    );
                }

                // ── 생활비 집계 월별 목록 ─────────────────────────────────────
                case "get_expense_list" -> {
                    emit(onProgress, "status", "생활비 집계 월별 목록 조회 중...");
                    List<com.eksystems.homes.living.vo.LivingExpenseMstVO> expList =
                            livingService.getExpenseList(familyId);
                    long totalBudget = expList.stream()
                            .mapToLong(e -> e.getTotalBudgetAmt() == null ? 0L : e.getTotalBudgetAmt()).sum();
                    long totalActual = expList.stream()
                            .mapToLong(e -> e.getTotalActualAmt() == null ? 0L : e.getTotalActualAmt()).sum();
                    yield Map.of(
                        "monthCount",   expList.size(),
                        "totalBudget",  totalBudget,
                        "totalActual",  totalActual,
                        "avgMonthlyBudget", expList.isEmpty() ? 0L : totalBudget / expList.size(),
                        "avgMonthlyActual", expList.isEmpty() ? 0L : totalActual / expList.size(),
                        "months", expList.stream().map(e -> {
                            long bgt = e.getTotalBudgetAmt() == null ? 0L : e.getTotalBudgetAmt();
                            long act = e.getTotalActualAmt() == null ? 0L : e.getTotalActualAmt();
                            Map<String, Object> m = new LinkedHashMap<>();
                            m.put("expSeq",        e.getExpSeq());
                            m.put("expYymm",       nvl(e.getExpYymm()));
                            m.put("expYyyymm",     nvl(e.getExpYyyymm()));
                            m.put("totalBudgetAmt", bgt);
                            m.put("totalActualAmt", act);
                            m.put("balance",        bgt - act);
                            m.put("overBudget",     act > bgt);
                            return m;
                        }).toList()
                    );
                }

                // ── 대출 이자 부담 분석 ───────────────────────────────────────
                case "calc_loan_interest_burden" -> {
                    emit(onProgress, "status", "대출 이자 부담 계산 중...");
                    List<LoanVO> loans = assetMapper.selectLoanList(familyId, "N");
                    AssetSummaryVO assetSummary = assetMapper.selectAssetSummary(familyId);

                    long monthlyIncome = assetSummary != null && assetSummary.getMonthlyIncomeAmount() != null
                            ? assetSummary.getMonthlyIncomeAmount() : 0L;

                    List<Map<String, Object>> loanDetails = loans.stream().map(l -> {
                        long balance = l.getCurrentBalance() == null ? 0L : l.getCurrentBalance();
                        double rate = l.getInterestRate() == null ? 0.0
                                : l.getInterestRate().doubleValue();
                        long monthlyInterest = Math.round(balance * (rate / 100.0) / 12.0);
                        Map<String, Object> m = new LinkedHashMap<>();
                        m.put("loanSeq",          l.getLoanSeq());
                        m.put("loanNm",           nvl(l.getLoanNm()));
                        m.put("currentBalance",   balance);
                        m.put("interestRatePct",  rate);
                        m.put("estMonthlyInterest", monthlyInterest);
                        m.put("annualInterest",   monthlyInterest * 12L);
                        return m;
                    }).toList();

                    long totalBalance  = loans.stream()
                            .mapToLong(l -> l.getCurrentBalance() == null ? 0L : l.getCurrentBalance()).sum();
                    long totalMonthlyInterest = loanDetails.stream()
                            .mapToLong(d -> ((Number) d.get("estMonthlyInterest")).longValue()).sum();
                    double dtiRatio = monthlyIncome > 0
                            ? Math.round(totalMonthlyInterest * 1000.0 / monthlyIncome) / 10.0 : 0.0;

                    yield Map.of(
                        "note",                "interestRate가 0이거나 누락된 대출은 월이자 0원으로 계산됩니다.",
                        "activeLoanCount",     loans.size(),
                        "totalLoanBalance",    totalBalance,
                        "estTotalMonthlyInterest", totalMonthlyInterest,
                        "estAnnualInterest",   totalMonthlyInterest * 12L,
                        "monthlyIncome",       monthlyIncome,
                        "interestBurdenRatioPct", dtiRatio,
                        "riskLevel",           dtiRatio > 30 ? "고위험(30% 초과)" : dtiRatio > 15 ? "주의(15~30%)" : "양호(15% 미만)",
                        "loans",               loanDetails
                    );
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
                    notes          : [{domain:"note", noteSeq, title, contentPreview, regId, updatedAt, url}],
                    depositRequests: [{domain:"depositRequest", depReqSeq, storeInfo, amount, reqStatus, reqDesc, regId, requestDt, url}],
                    assets         : [{domain:"asset", assetSeq, assetNm, assetTypeNm, liquidYn, amount, disposeYn, memo, url}],
                    loans          : [{domain:"loan", loanSeq, loanNm, loanAmount, currentBalance, interestRate, closeYn, memo, url}],
                    cashFlowPlans  : [{domain:"incomePlan"|"expensePlan", planSeq, planNm, planTypeNm, flowType, amount, cycleDesc, useYn, memo, url}],
                    dmsFiles       : [{domain:"dmsFile", fileSeq, fileNm, mimeType, regId, url}],
                    dmsFolders     : [{domain:"dmsFolder", folderSeq, folderNm, regId, url}],
                    snsPosts       : [{domain:"snsPost", postSeq, contentPreview, regId, url}]
                  }
                  언제 사용: 사용자가 "찾아줘", "검색해줘", "있어?", "어디에" 등 조회를 요청할 때.
                  주의: 결과가 비어있으면 "없습니다"라고 정직하게 답하세요. 없는 데이터를 만들지 마세요.
                  링크 안내: 각 결과의 url 필드를 사용해 "[이름](url)" 마크다운 링크 형태로 사용자가 바로 이동할 수 있게 안내하세요.

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
                  args : {"months": <number 1~120, default 12>}
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
                ### [재정 분석 — 기간별 조회]

                ★ 기간 설정 전략 (반드시 준수):
                  - 기간을 지정하지 않으면 get_snapshot_months를 먼저 호출해 전표처리된 달을 확인하세요.
                  - 전표처리된 달은 확정 데이터(신뢰도 높음), 그렇지 않은 달은 실시간 계획 데이터(미확정)입니다.
                  - 사용자가 "최근 3개월", "올해" 등으로 물으면 snapshot_months 결과를 기준으로 기간을 설정하세요.
                  - fromYymm/toYymm 형식: "YYYYMM" (예: "202501")

                get_snapshot_months — 전표처리(확정)된 월 목록 조회
                  args : {"fromYymm": <optional>, "toYymm": <optional>}
                  반환 : {
                    snapshotMonths: [YYYYMM, ...],  // 전표처리 완료된 달
                    count, earliest, latest, currentMonth,
                    note
                  }
                  언제 사용:
                    - 기간 설정이 필요한 분석 질문을 받았을 때 먼저 호출
                    - "전표처리된 달이 있어?", "확정 데이터 알려줘"

                get_cost_center_status — 수지계정현황 조회 (기간별 수입/지출 분석)
                  args : {"fromYymm": <YYYYMM, optional, default 이번달>, "toYymm": <YYYYMM, optional, default 이번달>}
                  반환 : {
                    period: {fromYymm, toYymm},
                    dataSource: {
                      snapshotMonths: [...],   // 이 달들은 전표처리 확정 데이터
                      liveMonths:     [...],   // 이 달들은 실시간(미확정) 데이터
                      note: 데이터 혼재 여부 설명
                    },
                    summary: {totalIncome, totalExpense, balance, expenseRatePct, costCenterCount},
                    costCenters: [{ccSeq, name, type, income, expense, balance, expenseSharePct}],
                    topExpenseCenters: [...상위5개...],
                    negativeBalanceCenters: [...적자 센터...]
                  }
                  언제 사용: "수지계정", "수입/지출 현황", "어디서 돈 많이 써?", "생활비 분석", "센터별 수지"
                  분석 지침:
                    - balance < 0 인 센터는 적자 → 지출 조정 필요성 언급
                    - snapshotMonths/liveMonths 를 구분해서 사용자에게 데이터 신뢰도를 설명할 것
                    - 기간이 명확하지 않으면 get_snapshot_months 먼저 호출해 최신 확정 월 파악

                get_asset_change_history — 자산변동현황 조회 (월별 자산 추이)
                  args : {"fromYymm": <YYYYMM, optional>, "toYymm": <YYYYMM, optional>}
                  반환 : {
                    note: 데이터 특성 설명,
                    dataSource: "snapshot",   // 항상 전표처리 확정 데이터
                    totalMonths,
                    latestMonth: {hstYymm, totalAsset, totalLoan, netAsset, liquidAsset, fixedAsset},
                    movementSummary: {averageMomChange, positiveMonths, negativeMonths},
                    monthlyTrend: [{
                      hstYymm, dataSource:"snapshot",
                      totalAsset, totalLoan, netAsset, liquidAsset, fixedAsset,
                      monthlyIncome, monthlyExpense, momNetAsset (전월 대비 순자산 증감)
                    }]
                  }
                  언제 사용: "자산 변동", "월별 자산 추이", "순자산 증감", "자산 얼마나 늘었어?"
                  분석 지침:
                    - 이 tool은 전표처리된 달만 반환함. 전표처리 안 된 달은 결과에 없음.
                    - momNetAsset > 0 이면 그달 순자산 증가, < 0 이면 감소
                    - 특정 기간 분석 시 fromYymm/toYymm 으로 범위 좁혀 재호출 가능

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
                list_notes — 공유메모 전체 목록 조회
                  args : {}
                  반환 : [{noteSeq, title, contentPreview, regId, updatedAt}]
                  언제 사용: "메모 목록", "메모 뭐 있어?", "공유메모 보여줘"

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

                delete_note — 공유메모 삭제
                  args : {"noteSeq": <number> | "targetTitle": <string>}
                  반환 : {result, noteSeq, title}
                  규칙 : 삭제 대상이 명확할 때만 실행. 복구 불가임을 사용자에게 한번 확인할 것.

                ────────────────────────────────────────
                ### [자산·대출 목록]
                list_assets — 자산 원장 목록 조회
                  args : {"includeDisposed": "Y"|"N" (optional, default "N")}
                  반환 : [{assetSeq, assetNm, assetTypeNm, liquidYn, amount, disposeYn, memo}]
                  언제 사용: "자산 목록", "어떤 자산 있어?", "자산 원장 보여줘"
                  참고: liquidYn=Y 유동자산, liquidYn=N 고정자산

                list_loans — 대출 원장 목록 조회
                  args : {"includeClosed": "Y"|"N" (optional, default "N")}
                  반환 : [{loanSeq, loanNm, loanAmount, currentBalance, interestRate, closeYn, memo}]
                  언제 사용: "대출 목록", "대출 뭐 있어?", "대출 원장 보여줘"

                ────────────────────────────────────────
                ### [생활비 분석]
                get_expense_summary — 카테고리별 생활비 예산·실적 요약
                  args : {"fromYymm": <YYYYMM, optional, default 이번달>, "toYymm": <YYYYMM, optional, default 이번달>}
                  반환 : {
                    period: {fromYymm, toYymm},
                    totalBudgetAmt, totalActualAmt, balance,
                    categories: [{catNm, budgetAmt, actualAmt, balance}]
                  }
                  언제 사용: "생활비 얼마나 썼어?", "이번 달 생활비", "예산 대비 지출", "카테고리별 지출"
                  분석 지침:
                    - balance < 0 이면 예산 초과 → 지출 주의 필요
                    - 초과 카테고리를 강조해서 알려줄 것

                get_expense_list — 생활비 집계 월별 목록 (전체 기간 조회)
                  args : {}
                  반환 : {
                    monthCount, totalBudget, totalActual,
                    avgMonthlyBudget, avgMonthlyActual,
                    months: [{expSeq, expYymm, expYyyymm, totalBudgetAmt, totalActualAmt, balance, overBudget}]
                  }
                  언제 사용: "생활비 집계 목록", "몇 월치 생활비 있어?", "생활비 전체 기간 보여줘", 장기 추이 분석
                  분석 지침:
                    - overBudget=true 달이 많으면 예산 기준 재검토 필요
                    - avgMonthlyActual 과 avgMonthlyBudget 을 비교해 습관적 초과 여부 판단

                ────────────────────────────────────────
                ### [심층 분석]

                list_cashflow_plans — 정기 수입/지출/저축/투자 계획 전체 목록
                  args : {"flowCategory": "INCOME"|"EXPENSE"|"SAVING"|"INVEST" (optional, default 전체), "useYn": "Y"|"N" (optional, default 전체)}
                  반환 : {
                    filter: {flowCategory, useYn},
                    activeMonthlyIncome, activeMonthlyExpense, activeMonthlyNetCashFlow,
                    plans: [{planSeq, planNm, planTypeNm, flowType, amount, cycleDesc, useYn, startYmd, endYmd, memo}]
                  }
                  언제 사용: "정기 계획 목록", "매달 나가는 고정비", "수입 계획 뭐 있어?", "활성 계획만 보여줘"
                  분석 지침:
                    - useYn=N 인 항목은 비활성(예측에서 제외됨)
                    - activeMonthlyNetCashFlow 가 음수면 현금흐름 적자 경고
                    - cycleDesc 로 주기 확인 (매월, 3개월마다 등)

                get_asset_type_summary — 자산 유형별 구성·분산 분석
                  args : {}
                  반환 : {
                    grandTotalAmount,
                    typeCount,
                    diversification: "분산투자(4종류 이상)"|"부분분산(2~3종류)"|"집중(1종류)",
                    types: [{assetType, assetTypeNm, totalAmount, assetCount, sharePct}]  // sharePct: 전체 대비 %%
                  }
                  언제 사용: "자산 구성", "어디에 자산이 몰려 있어?", "분산 잘 됐어?", "자산 유형별 비율"
                  분석 지침:
                    - sharePct 가 70%% 넘는 단일 유형이 있으면 집중 위험 언급
                    - 현금·예금 비중과 투자자산 비중 균형을 확인할 것

                get_manual_cashflow_detail — 기간별 수기 현금흐름 실적 항목 상세
                  args : {"fromYymm": <YYYYMM, optional, default 이번달>, "toYymm": <YYYYMM, optional, default 이번달>}
                  반환 : {
                    period: {fromYymm, toYymm},
                    totalIncome, totalExpense, netCashFlow, itemCount,
                    items: [{cfSeq, ccNm, flowType, flowYymm, title, actualAmt, memo, regId, regDtStr}]
                  }
                  언제 사용: "현금흐름 상세", "수기로 입력한 수입/지출", "비용센터별 실적 항목"
                  분석 지침:
                    - INCOME 항목은 수입, 나머지는 지출
                    - ccNm 으로 어느 비용센터에서 발생했는지 확인 가능
                    - 수지계정현황(get_cost_center_status)과 함께 쓰면 항목 수준 드릴다운 가능

                calc_loan_interest_burden — 대출별 추정 이자 부담 계산
                  args : {}
                  반환 : {
                    note,
                    activeLoanCount, totalLoanBalance,
                    estTotalMonthlyInterest, estAnnualInterest,
                    monthlyIncome,
                    interestBurdenRatioPct,  // 월이자/월수입 × 100
                    riskLevel: "양호(15%% 미만)"|"주의(15~30%%)"|"고위험(30%% 초과)",
                    loans: [{loanSeq, loanNm, currentBalance, interestRatePct, estMonthlyInterest, annualInterest}]
                  }
                  언제 사용: "이자 부담 얼마야?", "이자 부담률", "대출 이자 총합", "빚 얼마나 무거워?"
                  분석 지침:
                    - interestRatePct=0 인 대출은 이자 없는 가족간 차용 등으로 이해
                    - riskLevel="고위험" 이면 조기상환·차환 검토 제안
                    - 수입 대비 이자비율(DTI 일부)로 재정 건전성 평가에 활용
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
                반드시 아래 세 가지 JSON 형식 중 하나만 응답하세요.
                tool_calls / functionCall / function_call 등 다른 형식 절대 사용 금지.
                markdown 코드블록(```json 형식) 절대 사용 금지.

                일반 대화:
                {"reply":"답변 내용"}

                tool 실행 (tool 키 필수, tool_calls 키 사용 금지):
                {"tool":"tool_name","args":{...}}

                tool 결과를 받은 후 최종 답변:
                {"reply":"사용자가 이해하기 쉬운 자연어 답변"}

                ★ tool 이름은 반드시 TOOL 카탈로그에 정의된 이름 그대로 사용하세요.
                   정의되지 않은 이름(예: get_asset_composition 등)은 절대 사용하지 마세요.

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

    @SuppressWarnings("unchecked")
    private Map<String, Object> parseDecision(String raw) {
        if (raw == null || raw.isBlank()) {
            return Map.of("reply", "");
        }

        String text = raw.trim();

        // ① 마크다운 코드블록 제거
        if (text.startsWith("```")) {
            text = text.replaceFirst("(?s)^```[a-zA-Z]*\\s*", "")
                       .replaceFirst("(?s)\\s*```$", "").trim();
        }

        // ② <think>...</think> 제거 (reasoning 모델 대응)
        text = text.replaceAll("(?s)<think>.*?</think>", "").trim();

        // ③ 리터럴 \n → 실제 개행 사전 변환 (소형 모델이 \\n 로 출력하는 경우)
        //    단, JSON 파싱 전에 변환하면 JSON 구조가 깨질 수 있으므로
        //    파싱 실패 시에만 적용 (아래 catch 블록에서 처리)

        // ④ JSON 블록 추출 (앞뒤 텍스트 제거)
        int start = text.indexOf('{');
        int end   = text.lastIndexOf('}');
        if (start >= 0 && end > start) {
            text = text.substring(start, end + 1);
        } else {
            // JSON이 없으면 전체 텍스트를 reply로 처리
            String cleaned = raw.replaceAll("(?s)<think>.*?</think>", "").trim();
            return Map.of("reply", sanitizeReply(cleaned.isBlank() ? "" : cleaned));
        }

        // ④ 불완전한 JSON 보완 (소형 모델 트런케이션 대응)
        text = repairJson(text);

        Map<String, Object> parsed;
        try {
            parsed = om.readValue(text, new TypeReference<>() {});
        } catch (Exception e) {
            // 파싱 실패 → raw를 reply로
            String fallback = raw.replaceAll("(?s)<think>.*?</think>", "").trim();
            return Map.of("reply", sanitizeReply(fallback));
        }

        // ⑤ 다양한 tool-call 포맷 정규화
        if (!parsed.containsKey("tool")) {
            // tool_calls 포맷
            if (parsed.containsKey("tool_calls")) {
                List<?> calls = (List<?>) parsed.get("tool_calls");
                if (calls != null && !calls.isEmpty()) {
                    Map<?, ?> first = (Map<?, ?>) calls.get(0);
                    String toolName = firstText(first.get("function"), first.get("name"));
                    Object argsRaw  = first.get("args") != null ? first.get("args") : first.get("arguments");
                    Map<String, Object> norm = new LinkedHashMap<>();
                    norm.put("tool", toolName);
                    norm.put("args", argsRaw instanceof Map ? argsRaw : Map.of());
                    return norm;
                }
            }
            // functionCall 포맷
            if (parsed.containsKey("functionCall")) {
                Map<?, ?> fc = (Map<?, ?>) parsed.get("functionCall");
                if (fc != null) {
                    String toolName = firstText(fc.get("name"), fc.get("function"));
                    Object argsRaw  = fc.get("args") != null ? fc.get("args") : fc.get("arguments");
                    Map<String, Object> norm = new LinkedHashMap<>();
                    norm.put("tool", toolName);
                    norm.put("args", argsRaw instanceof Map ? argsRaw : Map.of());
                    return norm;
                }
            }
            // action 포맷 (일부 모델)
            if (parsed.containsKey("action") && parsed.containsKey("action_input")) {
                Map<String, Object> norm = new LinkedHashMap<>();
                norm.put("tool", str(parsed.get("action")));
                Object ai = parsed.get("action_input");
                norm.put("args", ai instanceof Map ? ai : Map.of());
                return norm;
            }
        }

        return parsed;
    }

    /** 트런케이션된 JSON 보완: 닫히지 않은 중괄호·따옴표 추가 */
    private String repairJson(String text) {
        if (text == null || text.isBlank()) return "{}";
        try {
            om.readValue(text, new TypeReference<Map<String, Object>>() {});
            return text; // 이미 유효
        } catch (Exception ignored) {}

        StringBuilder sb = new StringBuilder(text.trim());
        // 열린 따옴표 닫기 (단순 휴리스틱)
        long quotes = sb.chars().filter(c -> c == '"').count();
        if (quotes % 2 != 0) sb.append('"');
        // 열린 중괄호/대괄호 닫기
        int braceDepth = 0, bracketDepth = 0;
        boolean inStr = false;
        for (int i = 0; i < sb.length(); i++) {
            char c = sb.charAt(i);
            char prev = i > 0 ? sb.charAt(i - 1) : 0;
            if (c == '"' && prev != '\\') inStr = !inStr;
            if (!inStr) {
                if (c == '{') braceDepth++;
                else if (c == '}') braceDepth--;
                else if (c == '[') bracketDepth++;
                else if (c == ']') bracketDepth--;
            }
        }
        // 마지막 쉼표 제거
        String s = sb.toString().replaceAll(",\\s*$", "");
        sb = new StringBuilder(s);
        for (int i = 0; i < bracketDepth; i++) sb.append(']');
        for (int i = 0; i < braceDepth;   i++) sb.append('}');
        return sb.toString();
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

    /** YYYYMM 범위 내 월 목록 생성 */
    private List<String> aiListMonths(String fromYymm, String toYymm) {
        List<String> months = new ArrayList<>();
        try {
            LocalDate from = LocalDate.of(
                    Integer.parseInt(fromYymm.substring(0, 4)),
                    Integer.parseInt(fromYymm.substring(4, 6)), 1);
            LocalDate to = LocalDate.of(
                    Integer.parseInt(toYymm.substring(0, 4)),
                    Integer.parseInt(toYymm.substring(4, 6)), 1);
            DateTimeFormatter fmt = DateTimeFormatter.ofPattern("yyyyMM");
            while (!from.isAfter(to)) {
                months.add(from.format(fmt));
                from = from.plusMonths(1);
            }
        } catch (Exception e) {
            months.add(fromYymm);
        }
        return months;
    }

    /** 멀티월 수지계정 집계: 월별로 스냅샷 우선 */
    private List<CostCenterStatusVO> aiBuildMultiMonthStatus(String familyId, List<String> months) {
        Map<Long, CostCenterStatusVO> accumulated = new LinkedHashMap<>();
        for (String ym : months) {
            List<CostCenterStatusVO> monthData;
            if (snapshotService.hasSnapshot(familyId, ym)) {
                monthData = snapshotService.getCostCenterHst(familyId, ym);
                for (CostCenterStatusVO s : monthData) {
                    long inc = s.getIncomeMonthlyAmt()  != null ? s.getIncomeMonthlyAmt()  : 0L;
                    long exp = s.getExpenseMonthlyAmt() != null ? s.getExpenseMonthlyAmt() : 0L;
                    s.setTotalIncomeAmt(inc);
                    s.setTotalExpenseAmt(exp);
                }
            } else {
                monthData = costCenterService.getStatusList(familyId, ym, ym);
            }
            for (CostCenterStatusVO s : monthData) {
                if (s.getCcSeq() == null) continue;
                CostCenterStatusVO acc = accumulated.computeIfAbsent(s.getCcSeq(), k -> {
                    CostCenterStatusVO v = new CostCenterStatusVO();
                    v.setCcSeq(s.getCcSeq());
                    v.setCcNm(s.getCcNm());
                    v.setCcType(s.getCcType());
                    v.setIncomePlanNm(s.getIncomePlanNm());
                    v.setTotalIncomeAmt(0L);
                    v.setTotalExpenseAmt(0L);
                    return v;
                });
                acc.setTotalIncomeAmt(acc.getTotalIncomeAmt()
                        + (s.getTotalIncomeAmt()  != null ? s.getTotalIncomeAmt()  : 0L));
                acc.setTotalExpenseAmt(acc.getTotalExpenseAmt()
                        + (s.getTotalExpenseAmt() != null ? s.getTotalExpenseAmt() : 0L));
            }
        }
        List<CostCenterStatusVO> result = new ArrayList<>(accumulated.values());
        result.forEach(s -> s.setBalance(s.getTotalIncomeAmt() - s.getTotalExpenseAmt()));
        return result;
    }

    /**
     * 모델이 환각한 툴명을 실제 툴명으로 해석한다.
     * 우선순위: ① 정확 일치 → ② 알리아스 맵 → ③ 부분 문자열 매핑 → ④ 키워드 폴백
     */
    private String resolveToolName(String tool) {
        if (tool == null || tool.isBlank()) return tool;

        // ① 정확 일치
        if (TOOL_LABELS.containsKey(tool)) return tool;

        // ② 알리아스 맵
        String aliased = TOOL_ALIASES.get(tool);
        if (aliased != null) return aliased;

        // ③ 부분 문자열: 알려진 툴명이 요청명 안에 있거나, 요청명이 알려진 툴명 안에 있는 경우
        String lower = tool.toLowerCase().replace("-", "_");
        for (String known : TOOL_LABELS.keySet()) {
            String knownL = known.toLowerCase();
            if (lower.contains(knownL) || knownL.contains(lower)) return known;
        }

        // ④ 키워드 기반 폴백
        if (lower.contains("pending") || lower.contains("deposit"))  return "list_deposit_requests";
        if (lower.contains("note"))                                   return "list_notes";
        if (lower.contains("interest") || lower.contains("burden"))  return "calc_loan_interest_burden";
        if (lower.contains("loan") && lower.contains("list"))        return "list_loans";
        if (lower.contains("loan"))                                   return "list_loans";
        if (lower.contains("asset") && lower.contains("type"))       return "get_asset_type_summary";
        if (lower.contains("asset") && lower.contains("forecast"))   return "get_asset_forecast";
        if (lower.contains("asset") && lower.contains("change"))     return "get_asset_change_history";
        if (lower.contains("asset") && lower.contains("summ"))       return "get_asset_summary";
        if (lower.contains("asset"))                                  return "get_asset_summary";
        if (lower.contains("cost") || lower.contains("center"))      return "get_cost_center_status";
        if (lower.contains("snapshot"))                               return "get_snapshot_months";
        if (lower.contains("expense") && lower.contains("summ"))     return "get_expense_summary";
        if (lower.contains("expense") || lower.contains("living"))   return "get_expense_list";
        if (lower.contains("cashflow") || lower.contains("cash_flow")) return "list_cashflow_plans";
        if (lower.contains("plan"))                                   return "list_cashflow_plans";
        if (lower.contains("manual"))                                 return "get_manual_cashflow_detail";
        if (lower.contains("search") || lower.contains("find"))      return "global_search";
        if (lower.contains("forecast") || lower.contains("predict")) return "get_asset_forecast";

        log.warn("[TOOL-RESOLVE] 알 수 없는 툴명 (폴백 실패): '{}'", tool);
        return tool; // 그래도 모르면 그대로 → executeTool default → error 반환
    }

    /** toolsUsed 리스트에서 "tool:args" 형태를 "tool" 이름만 추출 */
    private List<String> toolNamesOnly(List<String> toolsUsed) {
        return toolsUsed.stream()
                .map(t -> t.contains(":") ? t.substring(0, t.indexOf(':')) : t)
                .distinct()
                .toList();
    }

    private Map<String, Object> confirmRequired(String message) {
        return Map.of("confirmRequired", true, "message", message);
    }

    private long safe(Long v) {
        return v != null ? v : 0L;
    }
}
