package com.eksystems.homes.note.service;

import com.eksystems.homes.note.mapper.NoteMapper;
import com.eksystems.homes.note.vo.NoteVO;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class NoteServiceImpl implements NoteService {

    private final NoteMapper noteMapper;

    public NoteServiceImpl(NoteMapper noteMapper) {
        this.noteMapper = noteMapper;
    }

    @Override
    public List<NoteVO> getNoteList(NoteVO noteVO) {
        return noteMapper.selectNoteList(noteVO);
    }

    @Override
    public List<NoteVO> searchNotes(String familyId, String keyword) {
        return noteMapper.searchNotes(familyId, keyword);
    }

    @Override
    public NoteVO getNoteDetail(String familyId, Long noteSeq) {
        return noteMapper.selectNoteDetail(familyId, noteSeq);
    }

    @Override
    @Transactional
    public void saveNote(NoteVO noteVO) {
        if (noteVO.getNoteSeq() == null) {
            noteMapper.insertNoteMst(noteVO);
            noteMapper.insertNoteDtl(noteVO);
            return;
        }

        noteMapper.updateNoteMst(noteVO);
        noteMapper.updateNoteDtl(noteVO);
    }

    @Override
    @Transactional
    public void deleteNote(String familyId, Long noteSeq, String updId) {
        noteMapper.deleteNote(familyId, noteSeq, updId);
    }
}
