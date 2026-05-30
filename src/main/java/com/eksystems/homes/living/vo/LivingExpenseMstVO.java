package com.eksystems.homes.living.vo;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class LivingExpenseMstVO {
    private Long   expSeq;
    private String familyId;
    private String expYymm;       // YYYYMM (예: 202601)
    private String expYyyymm;     // 표시용 (예: 2026년 01월)
    private String memo;
    private Long   totalBudgetAmt;
    private Long   totalActualAmt;
    private String regId;
    private LocalDateTime regDt;
    private String updId;
    private LocalDateTime updDt;
}
