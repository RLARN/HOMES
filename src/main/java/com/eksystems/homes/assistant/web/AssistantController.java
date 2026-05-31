package com.eksystems.homes.assistant.web;

import com.eksystems.homes.assistant.service.GeminiService;
import com.eksystems.homes.assistant.vo.ChatRequest;
import com.eksystems.homes.login.vo.LoginVO;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpSession;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.ArrayList;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

@Controller
@RequestMapping("/assistant")
public class AssistantController {

    private final GeminiService geminiService;
    private final ObjectMapper om = new ObjectMapper();
    private final ExecutorService executor = Executors.newCachedThreadPool();

    public AssistantController(GeminiService geminiService) {
        this.geminiService = geminiService;
    }

    @GetMapping
    public String assistantPage() {
        return "assistant/assistant";
    }

    @PostMapping(value = "/chat", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    @ResponseBody
    public SseEmitter chat(@RequestBody ChatRequest req, HttpSession session) {
        SseEmitter emitter = new SseEmitter(120_000L);
        LoginVO loginUser = (LoginVO) session.getAttribute("LoginVO");

        if (loginUser == null) {
            executor.submit(() -> sendAndComplete(emitter, Map.of(
                    "type", "error",
                    "message", "세션이 만료되었습니다."
            )));
            return emitter;
        }

        if (req.getHistory() == null) req.setHistory(new ArrayList<>());

        executor.submit(() -> {
            try {
                geminiService.chat(
                        req.getMessage(),
                        req.getHistory(),
                        loginUser.getFamilyId(),
                        loginUser.getUserId(),
                        loginUser.getUserAuth(),
                        event -> send(emitter, event)
                );
                emitter.complete();
            } catch (Exception e) {
                sendAndComplete(emitter, Map.of(
                        "type", "error",
                        "message", e.getMessage() == null ? "알 수 없는 오류" : e.getMessage()
                ));
            }
        });

        return emitter;
    }

    private void send(SseEmitter emitter, Map<String, Object> event) {
        try {
            emitter.send(SseEmitter.event().data(om.writeValueAsString(event)));
        } catch (Exception e) {
            /* 개별 이벤트 전송 실패는 조용히 무시 — completeWithError 하면
               이후 모든 이벤트(done_data 포함)가 클라이언트에 도달하지 않음 */
        }
    }

    private void sendAndComplete(SseEmitter emitter, Map<String, Object> event) {
        try {
            emitter.send(SseEmitter.event().data(om.writeValueAsString(event)));
            emitter.complete();
        } catch (Exception ignored) {
        }
    }
}
