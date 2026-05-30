package com.eksystems.homes.asset.mapper;

import com.eksystems.homes.asset.vo.AssetSummaryVO;
import com.eksystems.homes.asset.vo.AssetTypeSummaryVO;
import com.eksystems.homes.asset.vo.AssetVO;
import com.eksystems.homes.asset.vo.LoanVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface AssetMapper {

    // ── 자산형태 코드 ─────────────────────────────────────
    List<AssetVO> selectAssetTypeList();

    // ── 자산원장 ──────────────────────────────────────────
    List<AssetVO> selectAssetList(@Param("familyId") String familyId,
                                  @Param("disposeYn") String disposeYn);

    AssetVO selectAssetDetail(@Param("familyId") String familyId,
                              @Param("assetSeq") Long assetSeq);

    int insertAsset(AssetVO vo);

    int updateAsset(AssetVO vo);

    int deleteAsset(@Param("familyId") String familyId,
                    @Param("assetSeq") Long assetSeq,
                    @Param("updId") String updId);

    // ── 대출원장 ──────────────────────────────────────────
    List<LoanVO> selectLoanList(@Param("familyId") String familyId,
                                @Param("closeYn") String closeYn);

    LoanVO selectLoanDetail(@Param("familyId") String familyId,
                            @Param("loanSeq") Long loanSeq);

    int insertLoan(LoanVO vo);

    int updateLoan(LoanVO vo);

    int deleteLoan(@Param("familyId") String familyId,
                   @Param("loanSeq") Long loanSeq,
                   @Param("updId") String updId);

    // ── 요약 뷰 ───────────────────────────────────────────
    AssetSummaryVO selectAssetSummary(@Param("familyId") String familyId);

    List<AssetTypeSummaryVO> selectAssetTypeSummary(@Param("familyId") String familyId);

    // ── AI 검색 ───────────────────────────────────────────
    List<AssetVO> searchAssets(@Param("familyId") String familyId,
                               @Param("keyword") String keyword);

    List<LoanVO> searchLoans(@Param("familyId") String familyId,
                             @Param("keyword") String keyword);

    /** 예측 계산용: 증감률이 설정된 활성 자산 */
    List<AssetVO> selectAssetsForForecast(@Param("familyId") String familyId);

    /** 비용센터 선택용: 유동자산(LIQUID_YN=Y, DEL_YN=N, DISPOSE_YN=N) */
    List<AssetVO> selectLiquidAssets(@Param("familyId") String familyId);

    /** 비용센터로 사용 중인지 체크 */
    int countCostCenterUsage(@Param("assetSeq") Long assetSeq);
}
