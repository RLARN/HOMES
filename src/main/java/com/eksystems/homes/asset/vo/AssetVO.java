package com.eksystems.homes.asset.vo;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
public class AssetVO {
    private Long       assetSeq;
    private String     familyId;
    private String     assetNm;
    private String     assetType;
    private String     assetTypeNm;
    private String     liquidYn;
    private Long       amount;
    private String     memo;
    // 예상 증감률
    private BigDecimal expectedRate;    // 증감률 (%) — 양수=상승, 음수=하락
    private Integer    rateCycleNum;    // 사이클 숫자
    private String     rateCycleUnit;   // DAY / MONTH / YEAR
    private String delYn;
    private String disposeYn;
    private LocalDate   disposeYmd;
    private String disposeReason;
    private String regId;
    private LocalDateTime regDt;
    private String updId;
    private LocalDateTime updDt;
    private String updDtStr;
}
