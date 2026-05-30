package com.eksystems.homes.asset.mapper;

import com.eksystems.homes.asset.vo.CashFlowPlanVO;
import com.eksystems.homes.asset.vo.CashFlowTypeVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface CashFlowMapper {

    // 유형 코드
    List<CashFlowTypeVO> selectTypeList(@Param("flowCategory") String flowCategory);

    // 목록 (FLOW_TYPE 그룹으로 구분: 'INCOME' or 'EXPENSE')
    List<CashFlowPlanVO> selectPlanList(@Param("familyId") String familyId,
                                        @Param("flowCategory") String flowCategory,
                                        @Param("useYn") String useYn);

    CashFlowPlanVO selectPlanDetail(@Param("familyId") String familyId,
                                    @Param("planSeq") Long planSeq);

    int insertPlan(CashFlowPlanVO vo);

    int updatePlan(CashFlowPlanVO vo);

    int deletePlan(@Param("familyId") String familyId,
                   @Param("planSeq") Long planSeq,
                   @Param("updId") String updId);

    int updateUseYn(@Param("familyId") String familyId,
                    @Param("planSeq") Long planSeq,
                    @Param("useYn") String useYn,
                    @Param("updId") String updId);

    /** 예측 계산용: 활성(USE_YN=Y) 전체 계획 (수입+지출) */
    List<CashFlowPlanVO> selectActivePlansForForecast(@Param("familyId") String familyId);

    /** AI 검색: 정기수입/지출 계획 통합 검색 */
    List<CashFlowPlanVO> searchPlans(@Param("familyId") String familyId,
                                     @Param("keyword") String keyword);

    /** 비용센터 선택용: 활성 정기수입 목록 */
    List<CashFlowPlanVO> selectIncomePlansForCostCenter(@Param("familyId") String familyId);

    /** 생활비 전체 연동 플랜 금액 일괄 업데이트 */
    void updateLivingTotalLinkedPlans(@Param("familyId") String familyId,
                                      @Param("totalAmt") long totalAmt,
                                      @Param("updId") String updId);
}
