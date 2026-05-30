package com.eksystems.homes.living.vo;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class LivingBudgetItemVO {
    private Long   itemSeq;
    private String familyId;
    private Long   catSeq;
    private String catNm;
    private String itemNm;
    private Long   budgetAmt;
    private Long   incomePlanSeq;   // FK → CASH_FLOW_PLAN_MST (레거시)
    private String incomePlanNm;    // JOIN
    private Long   ccSeq;           // FK → COST_CENTER_MST (수입원 비용센터)
    private String ccNm;            // JOIN
    private int    sortOrder;
    private String useYn;
    private String delYn;
    private String memo;
    private String regId;
    private LocalDateTime regDt;
    private String updId;
    private LocalDateTime updDt;
}
