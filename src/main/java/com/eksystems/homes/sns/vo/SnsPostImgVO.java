package com.eksystems.homes.sns.vo;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class SnsPostImgVO {
    private Long   imgSeq;
    private Long   postSeq;
    private String familyId;
    private String fileNm;
    private String storedNm;
    private int    sortOrder;
    private String regId;
    private LocalDateTime regDt;
}
