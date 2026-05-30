package com.eksystems.homes.living.vo;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class LivingExpenseDtlVO {
    private Long   dtlSeq;
    private Long   expSeq;
    private Long   itemSeq;
    private Long   catSeq;
    private String catNm;
    private String itemNm;
    private Long   budgetAmt;
    private Long   actualAmt;
    private String memo;
    private String regId;
    private LocalDateTime regDt;
    private String updId;
    private LocalDateTime updDt;
}
