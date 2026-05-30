package com.eksystems.homes.asset.vo;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class CostCenterVO {
    private Long   ccSeq;
    private String familyId;
    private String ccNm;
    /** MANUAL=수동등록, AUTO=정기지출 자동생성 */
    private String ccType;
    /** 자동생성 원본 정기지출 PLAN_SEQ */
    private Long   sourcePlanSeq;
    /** 자산원장 연동 ASSET_SEQ */
    private Long   sourceAssetSeq;
    /** 재원 수입원 PLAN_SEQ */
    private Long   incomePlanSeq;
    private String incomePlanNm;  // JOIN용
    private Long   monthlyAmt;
    private int    sortOrder;
    private String useYn;
    private String delYn;
    private String memo;
    private String regId;
    private LocalDateTime regDt;
    private String updId;
    private LocalDateTime updDt;

    /** 이 비용센터를 사용 중인 정기지출 수 (삭제 가능 여부 판단) */
    private int usedCount;
}
