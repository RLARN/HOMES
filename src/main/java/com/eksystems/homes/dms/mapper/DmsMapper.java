package com.eksystems.homes.dms.mapper;

import com.eksystems.homes.dms.vo.DmsFileVO;
import com.eksystems.homes.dms.vo.DmsFolderVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface DmsMapper {

    // ── 폴더 ──────────────────────────────────────────────────────
    void insertFolder(DmsFolderVO folder);
    DmsFolderVO selectFolder(@Param("familyId") String familyId, @Param("folderSeq") Long folderSeq);
    List<DmsFolderVO> selectFoldersByParent(@Param("familyId") String familyId, @Param("parentSeq") Long parentSeq);
    List<DmsFolderVO> selectAllFolders(@Param("familyId") String familyId);
    void updateFolderName(DmsFolderVO folder);
    void deleteFolder(@Param("familyId") String familyId, @Param("folderSeq") Long folderSeq);
    /** 하위 폴더 포함 전체 folderSeq 목록 (재귀 삭제 시 파일 정리용) */
    List<Long> selectDescendantFolderSeqs(@Param("familyId") String familyId, @Param("folderSeq") Long folderSeq);

    // ── 파일 ──────────────────────────────────────────────────────
    void insertFile(DmsFileVO file);
    void updateFileName(@Param("familyId") String familyId, @Param("fileSeq") Long fileSeq,
                        @Param("fileNm") String fileNm, @Param("updId") String updId);
    DmsFileVO selectFile(@Param("familyId") String familyId, @Param("fileSeq") Long fileSeq);
    List<DmsFileVO> selectFilesByFolder(@Param("familyId") String familyId, @Param("folderSeq") Long folderSeq);
    /** 특정 폴더(들)에 속한 파일 목록 (물리 파일 삭제용) */
    List<DmsFileVO> selectFilesByFolderSeqs(@Param("familyId") String familyId, @Param("folderSeqs") List<Long> folderSeqs);
    void deleteFile(@Param("familyId") String familyId, @Param("fileSeq") Long fileSeq);
    void deleteFilesByFolderSeqs(@Param("familyId") String familyId, @Param("folderSeqs") List<Long> folderSeqs);

    // ── 쿼터 ──────────────────────────────────────────────────────
    long selectTotalUsedBytes(@Param("familyId") String familyId);

    // ── 검색 ──────────────────────────────────────────────────────
    List<DmsFileVO> searchFiles(@Param("familyId") String familyId, @Param("keyword") String keyword);
    List<DmsFolderVO> searchFolders(@Param("familyId") String familyId, @Param("keyword") String keyword);
}
