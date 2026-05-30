package com.eksystems.homes.asset.vo;

import lombok.Data;

@Data
public class AssetSummaryVO {
    private String familyId;
    private Long   totalAssetAmount;
    private Long   totalLiquidAssetAmount;
    private Long   totalFixedAssetAmount;
    private Long   totalInvestAmount;
    private Long   totalLoanBalance;
    private Long   netAssetAmount;
    private Long   monthlyIncomeAmount;
    private Long   monthlyExpenseAmount;
    private Long   monthlySavingAmount;
    private Long   monthlyInvestAmount;
    private Long   expectedMonthlyCashFlow;
}
