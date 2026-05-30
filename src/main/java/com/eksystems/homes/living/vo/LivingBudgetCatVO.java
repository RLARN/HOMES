package com.eksystems.homes.living.vo;

import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Data
public class LivingBudgetCatVO {
    private Long   catSeq;
    private String familyId;
    private String catNm;
    private int    sortOrder;
    private String useYn;
    private String regId;
    private LocalDateTime regDt;
    private String updId;
    private LocalDateTime updDt;

    /** 카테고리 하위 항목 목록 (서비스 레이어에서 조합) */
    private List<LivingBudgetItemVO> items;
    /** 카테고리 예산 합계 */
    private Long totalBudgetAmt;
}
