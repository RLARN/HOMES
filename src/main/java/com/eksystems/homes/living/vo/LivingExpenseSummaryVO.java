package com.eksystems.homes.living.vo;

import lombok.Data;

@Data
public class LivingExpenseSummaryVO {
    private Long   catSeq;
    private String catNm;
    private Long   totalBudgetAmt;
    private Long   totalActualAmt;
}
