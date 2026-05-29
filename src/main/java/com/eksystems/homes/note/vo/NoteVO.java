package com.eksystems.homes.note.vo;

import java.time.LocalDateTime;

public class NoteVO {
    private Long noteSeq;
    private String familyId;
    private String title;
    private String content;
    private String delYn;
    private String regId;
    private LocalDateTime regDt;
    private String updId;
    private LocalDateTime updDt;
    private String regDtText;
    private String updDtText;

    public Long getNoteSeq() {
        return noteSeq;
    }

    public void setNoteSeq(Long noteSeq) {
        this.noteSeq = noteSeq;
    }

    public String getFamilyId() {
        return familyId;
    }

    public void setFamilyId(String familyId) {
        this.familyId = familyId;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public String getDelYn() {
        return delYn;
    }

    public void setDelYn(String delYn) {
        this.delYn = delYn;
    }

    public String getRegId() {
        return regId;
    }

    public void setRegId(String regId) {
        this.regId = regId;
    }

    public LocalDateTime getRegDt() {
        return regDt;
    }

    public void setRegDt(LocalDateTime regDt) {
        this.regDt = regDt;
    }

    public String getUpdId() {
        return updId;
    }

    public void setUpdId(String updId) {
        this.updId = updId;
    }

    public LocalDateTime getUpdDt() {
        return updDt;
    }

    public void setUpdDt(LocalDateTime updDt) {
        this.updDt = updDt;
    }

    public String getRegDtText() {
        return regDtText;
    }

    public void setRegDtText(String regDtText) {
        this.regDtText = regDtText;
    }

    public String getUpdDtText() {
        return updDtText;
    }

    public void setUpdDtText(String updDtText) {
        this.updDtText = updDtText;
    }
}
