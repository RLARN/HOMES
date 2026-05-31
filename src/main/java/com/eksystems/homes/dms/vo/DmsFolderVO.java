package com.eksystems.homes.dms.vo;

import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Data
public class DmsFolderVO {
    private Long   folderSeq;
    private String familyId;
    private String folderNm;
    private Long   parentSeq;
    private int    sortOrder;
    private String regId;
    private LocalDateTime regDt;
    private String updId;
    private LocalDateTime updDt;

    // UI용 (JOIN/집계)
    private int    childFolderCount;
    private int    fileCount;
    private List<DmsFolderVO> children;
}
