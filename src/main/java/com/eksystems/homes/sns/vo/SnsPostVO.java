package com.eksystems.homes.sns.vo;

import lombok.Data;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Data
public class SnsPostVO {
    private Long   postSeq;
    private String familyId;
    private String content;
    private String regId;
    private LocalDateTime regDt;
    private LocalDateTime updDt;

    // JOIN / 집계
    private List<SnsPostImgVO> images;
    private int  likeCount;
    private boolean liked;
    private int  commentCount;

    public String getRegDtText() {
        if (regDt == null) return "";
        return regDt.format(DateTimeFormatter.ofPattern("yyyy.MM.dd HH:mm"));
    }

    /** 사용자별 아바타 색상 (고정) */
    public String getAvatarColor() {
        if (regId == null) return "#6b7280";
        int h = Math.abs(regId.hashCode()) % 6;
        return switch (h) {
            case 0 -> "#3b82f6";
            case 1 -> "#10b981";
            case 2 -> "#f59e0b";
            case 3 -> "#ec4899";
            case 4 -> "#8b5cf6";
            default -> "#ef4444";
        };
    }

    public String getAvatarInitial() {
        if (regId == null || regId.isBlank()) return "?";
        return regId.substring(0, 1).toUpperCase();
    }
}
