package com.eksystems.homes.asset.mapper;

import com.eksystems.homes.asset.vo.CostCenterStatusVO;
import com.eksystems.homes.asset.vo.CostCenterVO;
import org.apache.ibatis.annotations.Param;

import java.util.List;


public interface CostCenterMapper {

    List<CostCenterVO> selectList(@Param("familyId") String familyId,
                                  @Param("useYn") String useYn);

    CostCenterVO selectOne(@Param("familyId") String familyId,
                           @Param("ccSeq") Long ccSeq);

    CostCenterVO selectBySourcePlan(@Param("familyId") String familyId,
                                    @Param("sourcePlanSeq") Long sourcePlanSeq);

    CostCenterVO selectBySourceAsset(@Param("familyId") String familyId,
                                     @Param("sourceAssetSeq") Long sourceAssetSeq);

    void insert(CostCenterVO vo);

    void update(CostCenterVO vo);

    void softDelete(@Param("familyId") String familyId,
                    @Param("ccSeq") Long ccSeq,
                    @Param("updId") String updId);

    /** 정기지출 삭제 시 연동 삭제 (SOURCE_PLAN_SEQ 기준) */
    void softDeleteBySourcePlan(@Param("familyId") String familyId,
                                @Param("sourcePlanSeq") Long sourcePlanSeq,
                                @Param("updId") String updId);

    /** 자산원장 연동 비용센터 삭제 (SOURCE_ASSET_SEQ 기준) */
    void softDeleteBySourceAsset(@Param("familyId") String familyId,
                                 @Param("sourceAssetSeq") Long sourceAssetSeq,
                                 @Param("updId") String updId);

    /** 이 비용센터를 사용 중인 정기지출 수 */
    int countUsedByCcSeq(@Param("familyId") String familyId,
                         @Param("ccSeq") Long ccSeq);

    /** 이 정기수입을 INCOME_PLAN_SEQ로 사용 중인 비용센터 수 */
    int countByIncomePlanSeq(@Param("familyId") String familyId,
                             @Param("incomePlanSeq") Long incomePlanSeq);

    /** 정기수입으로 자동 생성된 비용센터 조회 (INCOME_PLAN_SEQ 기준) */
    CostCenterVO selectByIncomePlanSeq(@Param("familyId") String familyId,
                                       @Param("incomePlanSeq") Long incomePlanSeq);

    /** 비용센터 현황: 비용센터별 수입/지출 집계 */
    List<CostCenterStatusVO> selectStatusList(@Param("familyId") String familyId);
}
