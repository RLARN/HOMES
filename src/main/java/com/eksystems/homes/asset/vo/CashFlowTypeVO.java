package com.eksystems.homes.asset.vo;

import lombok.Data;

@Data
public class CashFlowTypeVO {
    private String  planType;
    private String  flowCategory; // INCOME / EXPENSE (메뉴 구분)
    private String  flowType;     // INCOME / EXPENSE / SAVING / INVEST (실제 성격)
    private String  planTypeNm;
    private Integer sortOrder;
    private String  useYn;
}
