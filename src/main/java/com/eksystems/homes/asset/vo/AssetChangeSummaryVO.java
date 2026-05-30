package com.eksystems.homes.asset.vo;

import lombok.Data;

@Data
public class AssetChangeSummaryVO {
    private String hstYymm;
    private long   totalAssetAmt;
    private long   liquidAssetAmt;
    private long   fixedAssetAmt;
    private long   totalLoanBalance;
    private long   netAssetAmt;
    private long   monthlyIncome;
    private long   monthlyExpense;
}
