package com.eksystems.homes.living.vo;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class LivingIncomeMstVO {
    private Long   incomeSeq;
    private String familyId;
    private Long   ccSeq;
    private String ccNm;        // JOIN
    private String title;
    private String flowType;    // INCOME / EXPENSE
    private String incomeYymm;
    private Long   actualAmt;
    private String memo;
    private String regId;
    private LocalDateTime regDt;
    private String regDtStr;    // DATE_FORMAT 결과
    private String updId;
    private LocalDateTime updDt;
}
