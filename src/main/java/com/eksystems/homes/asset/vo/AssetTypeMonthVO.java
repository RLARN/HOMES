package com.eksystems.homes.asset.vo;

import lombok.Data;

@Data
public class AssetTypeMonthVO {
    private String hstYymm;
    private String assetType;
    private String assetTypeNm;
    private long   totalAmount;
}
