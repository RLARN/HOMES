package com.eksystems.homes.assistant.vo;

import java.util.List;
import java.util.Map;

public class ChatResponse {
    private String reply;
    private List<Map<String, Object>> history;
    private List<String> toolsUsed;

    public ChatResponse(String reply, List<Map<String, Object>> history, List<String> toolsUsed) {
        this.reply     = reply;
        this.history   = history;
        this.toolsUsed = toolsUsed;
    }

    public String getReply() { return reply; }
    public List<Map<String, Object>> getHistory() { return history; }
    public List<String> getToolsUsed() { return toolsUsed; }
}
