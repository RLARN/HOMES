package com.eksystems.homes.asset.vo;

import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
public class CashFlowPlanVO {
    private Long      planSeq;
    private String    familyId;
    private String    planNm;
    private String    planType;       // FK → CASH_FLOW_TYPE_CD
    private String    planTypeNm;     // 유형명 (JOIN)
    private String    flowType;       // INCOME/EXPENSE/SAVING/INVEST
    private Long      amount;
    // 사이클
    private Integer   cycleNum;       // 숫자 (예: 1, 3, 6)
    private String    cycleUnit;      // DAY/MONTH/YEAR
    private Integer   cycleBaseDay;   // 기준일 (예: 25)
    private Integer   cycleBaseMonth; // 기준월 (예: 3, YEAR 단위일 때)
    private String    cycleDesc;      // View에서 생성되는 사이클 설명 문자열
    private LocalDate startYmd;
    private LocalDate endYmd;
    private String    costCenterType;  // 'ASSET' or 'INCOME'
    private Long      costCenterSeq;   // 비용센터 SEQ
    private Long      loanSeq;         // 대출 SEQ (대출 유형일 때 필수)
    private String    loanNm;          // 대출명 (JOIN)
    private String    livingTotalLinkYn; // 생활비 전체 연동 여부 (Y이면 기준정보 합계 자동 동기화)
    private String    useYn;
    private String    delYn;
    private String    memo;
    private String    regId;
    private LocalDateTime regDt;
    private String    updId;
    private LocalDateTime updDt;
    private String    updDtStr;       // DATE_FORMAT 결과
}
