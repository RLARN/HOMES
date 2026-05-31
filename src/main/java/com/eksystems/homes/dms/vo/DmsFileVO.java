package com.eksystems.homes.dms.vo;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class DmsFileVO {
    private Long   fileSeq;
    private String familyId;
    private Long   folderSeq;
    private String fileNm;       // 원본 파일명
    private String storedNm;     // 저장 파일명 (UUID)
    private long   fileSize;
    private String mimeType;
    private String regId;
    private LocalDateTime regDt;
    private String updId;
    private LocalDateTime updDt;

    // UI용
    public String getFileSizeText() {
        if (fileSize < 1024) return fileSize + " B";
        if (fileSize < 1024 * 1024) return String.format("%.1f KB", fileSize / 1024.0);
        if (fileSize < 1024 * 1024 * 1024) return String.format("%.1f MB", fileSize / (1024.0 * 1024));
        return String.format("%.2f GB", fileSize / (1024.0 * 1024 * 1024));
    }

    public String getFileIcon() {
        if (mimeType == null) return "📄";
        if (mimeType.startsWith("image/"))       return "🖼️";
        if (mimeType.equals("application/pdf")) return "📕";
        if (mimeType.startsWith("video/"))       return "🎬";
        if (mimeType.startsWith("audio/"))       return "🎵";
        if (mimeType.startsWith("text/"))        return "📝";
        if (mimeType.contains("spreadsheet") || mimeType.contains("excel")) return "📊";
        if (mimeType.contains("presentation") || mimeType.contains("powerpoint")) return "📊";
        if (mimeType.contains("word") || mimeType.contains("document")) return "📃";
        if (mimeType.contains("zip") || mimeType.contains("compressed")) return "🗜️";
        return "📄";
    }

    public boolean isViewable() {
        if (mimeType == null) return false;
        return mimeType.startsWith("image/")
                || mimeType.equals("application/pdf")
                || mimeType.startsWith("video/")
                || mimeType.startsWith("audio/")
                || mimeType.startsWith("text/");
    }
}
