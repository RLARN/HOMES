package com.eksystems.homes.asset.service;

import com.eksystems.homes.asset.vo.AssetSummaryVO;
import com.eksystems.homes.asset.vo.AssetVO;
import com.eksystems.homes.asset.vo.LoanVO;

import java.util.List;

public interface AssetService {

    // ── 자산형태 코드 ─────────────────────────────────────
    List<AssetVO> getAssetTypeList();

    // ── 자산원장 ──────────────────────────────────────────
    List<AssetVO> getAssetList(String familyId, String disposeYn);

    AssetVO getAssetDetail(String familyId, Long assetSeq);

    void saveAsset(AssetVO vo, String userId);

    void deleteAsset(String familyId, Long assetSeq, String userId);

    /** 비용센터 선택용: 유동자산 목록 */
    List<AssetVO> getLiquidAssets(String familyId);

    // ── 대출원장 ──────────────────────────────────────────
    List<LoanVO> getLoanList(String familyId, String closeYn);

    LoanVO getLoanDetail(String familyId, Long loanSeq);

    void saveLoan(LoanVO vo, String userId);

    void deleteLoan(String familyId, Long loanSeq, String userId);

    // ── 요약 ─────────────────────────────────────────────
    AssetSummaryVO getAssetSummary(String familyId);
}
