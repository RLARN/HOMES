package com.eksystems.homes.asset.vo;

import lombok.Data;

@Data
public class AssetTypeSummaryVO {
    private String familyId;
    private String assetType;
    private String assetTypeNm;
    private Long   totalAmount;
    private Long   assetCount;
}
