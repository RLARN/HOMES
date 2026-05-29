package com.eksystems.homes.assistant.vo;

import java.util.List;
import java.util.Map;

public class ChatRequest {
    private String message;
    private List<Map<String, Object>> history;

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public List<Map<String, Object>> getHistory() {
        return history;
    }

    public void setHistory(List<Map<String, Object>> history) {
        this.history = history;
    }
}
