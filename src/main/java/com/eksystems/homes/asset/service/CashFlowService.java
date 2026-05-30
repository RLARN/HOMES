package com.eksystems.homes.asset.service;

import com.eksystems.homes.asset.vo.CashFlowPlanVO;
import com.eksystems.homes.asset.vo.CashFlowTypeVO;

import java.util.List;

public interface CashFlowService {

    List<CashFlowTypeVO> getTypeList(String flowCategory);

    List<CashFlowPlanVO> getPlanList(String familyId, String flowCategory, String useYn);

    CashFlowPlanVO getPlanDetail(String familyId, Long planSeq);

    void savePlan(CashFlowPlanVO vo, String userId);

    void deletePlan(String familyId, Long planSeq, String userId);

    void toggleUseYn(String familyId, Long planSeq, String currentUseYn, String userId);

    /** 비용센터 선택용: 활성 정기수입 목록 */
    List<CashFlowPlanVO> getIncomePlansForCostCenter(String familyId);

    /**
     * 정기수입 삭제 전 비용센터 참조 여부 확인 포함 삭제
     * 비용센터에서 이 수입을 사용 중이면 IllegalStateException
     */
    void deleteIncomePlan(String familyId, Long planSeq, String userId);
}
