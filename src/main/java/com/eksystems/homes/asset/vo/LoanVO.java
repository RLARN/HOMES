package com.eksystems.homes.asset.vo;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
public class LoanVO {
    private Long       loanSeq;
    private String     familyId;
    private String     loanNm;
    private Long       loanAmount;
    private Long       currentBalance;
    private BigDecimal interestRate;
    private Integer    loanMonths;
    private LocalDate  startYmd;
    private LocalDate  endYmd;
    private String     memo;
    private String     delYn;
    private String     closeYn;
    private LocalDate  closeYmd;
    private String     closeReason;
    private String     regId;
    private LocalDateTime regDt;
    private String     updId;
    private LocalDateTime updDt;
    private String     updDtStr;
}
