package com.eksystems.homes.assistant.web;

import com.eksystems.homes.assistant.service.GeminiService;
import com.eksystems.homes.assistant.vo.ChatRequest;
import com.eksystems.homes.login.vo.LoginVO;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpSession;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.ArrayList;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

@Controller
@RequestMapping("/assistant")
public class AssistantController {

    private final GeminiService   geminiService;
    private final ObjectMapper    om       = new ObjectMapper();
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
            executor.submit(() -> {
                try {
                    emitter.send(SseEmitter.event().data("{\"type\":\"error\",\"message\":\"세션 만료\"}"));
                    emitter.complete();
                } catch (Exception ignored) {}
            });
            return emitter;
        }

        if (req.getHistory() == null) req.setHistory(new ArrayList<>());

        String familyId = loginUser.getFamilyId();
        String userId   = loginUser.getUserId();
        String userAuth = loginUser.getUserAuth();

        executor.submit(() -> {
            try {
                geminiService.chat(
                        req.getMessage(),
                        req.getHistory(),
                        familyId, userId, userAuth,
                        event -> {
                            try {
                                emitter.send(SseEmitter.event().data(om.writeValueAsString(event)));
                            } catch (Exception e) {
                                emitter.completeWithError(e);
                            }
                        }
                );
                emitter.complete();
            } catch (Exception e) {
                try {
                    emitter.send(SseEmitter.event().data(
                            "{\"type\":\"error\",\"message\":\"" +
                            e.getMessage().replace("\"", "'") + "\"}"
                    ));
                    emitter.complete();
                } catch (Exception ignored) {}
            }
        });

        return emitter;
    }
}
