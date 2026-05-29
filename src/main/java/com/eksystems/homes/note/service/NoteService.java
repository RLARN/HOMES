package com.eksystems.homes.note.service;

import com.eksystems.homes.note.vo.NoteVO;

import java.util.List;

public interface NoteService {
    List<NoteVO> getNoteList(NoteVO noteVO);

    List<NoteVO> searchNotes(String familyId, String keyword);

    NoteVO getNoteDetail(String familyId, Long noteSeq);

    void saveNote(NoteVO noteVO);

    void deleteNote(String familyId, Long noteSeq, String updId);
}
