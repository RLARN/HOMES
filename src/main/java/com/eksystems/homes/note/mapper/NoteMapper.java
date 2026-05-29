package com.eksystems.homes.note.mapper;

import com.eksystems.homes.note.vo.NoteVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface NoteMapper {
    List<NoteVO> selectNoteList(NoteVO noteVO);

    List<NoteVO> searchNotes(@Param("familyId") String familyId,
                             @Param("keyword") String keyword);

    NoteVO selectNoteDetail(@Param("familyId") String familyId,
                            @Param("noteSeq") Long noteSeq);

    int insertNoteMst(NoteVO noteVO);

    int insertNoteDtl(NoteVO noteVO);

    int updateNoteMst(NoteVO noteVO);

    int updateNoteDtl(NoteVO noteVO);

    int deleteNote(@Param("familyId") String familyId,
                   @Param("noteSeq") Long noteSeq,
                   @Param("updId") String updId);
}
