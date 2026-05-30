package com.eksystems.homes.asset.service;

import com.eksystems.homes.asset.vo.AssetVO;
import com.eksystems.homes.asset.vo.CashFlowPlanVO;
import com.eksystems.homes.asset.vo.CostCenterStatusVO;
import com.eksystems.homes.asset.vo.CostCenterVO;

import java.util.List;

public interface CostCenterService {

    List<CostCenterVO> getList(String familyId, String useYn);

    /**
     * 비용센터 현황: 기간(fromYymm~toYymm) 기준 수입/지출 집계
     * fromYymm, toYymm: "YYYYMM" 형식
     */
    List<CostCenterStatusVO> getStatusList(String familyId, String fromYymm, String toYymm);

    CostCenterVO getOne(String familyId, Long ccSeq);

    void save(CostCenterVO vo, String userId);

    /**
     * 비용센터 삭제 — 사용 중이면 예외 발생
     */
    void delete(String familyId, Long ccSeq, String userId);

    /**
     * 정기지출 저장 시 자동 동기화:
     *  - 신규이면 AUTO 타입 비용센터 생성
     *  - 기존이면 이름·금액 업데이트
     */
    void syncFromExpensePlan(CashFlowPlanVO plan, String userId);

    /**
     * 정기지출 삭제 시 자동 연동 삭제
     */
    void deleteBySourcePlan(String familyId, Long sourcePlanSeq, String userId);

    /**
     * 자산원장 폼: 이 자산에 연동된 비용센터 조회 (없으면 null)
     */
    CostCenterVO findBySourceAsset(String familyId, Long assetSeq);

    /**
     * 유동자산 → 비용센터 등록/수정 (체크박스 ON)
     * 이미 있으면 이름·금액 업데이트, 없으면 신규 생성
     */
    void syncFromAsset(AssetVO asset, String userId);

    /**
     * 유동자산 비용센터 등록 해제 (체크박스 OFF)
     */
    void unlinkFromAsset(String familyId, Long assetSeq, String userId);

    /**
     * 정기수입 저장 시 자동 동기화:
     *  - 신규이면 MANUAL 타입 비용센터 생성 (수입원 연결)
     *  - 기존이면 이름·금액 업데이트
     */
    void syncFromIncomePlan(CashFlowPlanVO plan, String userId);

    /**
     * 정기수입 삭제 전 사용 여부 확인:
     *  - 비용센터에서 INCOME_PLAN_SEQ로 참조 중이면 예외 발생
     */
    void checkIncomePlanDeletable(String familyId, Long incomePlanSeq);

    /**
     * 수지계정별 지출 항목 전체 조회 (Map: ccSeq → 항목 목록)
     * costCenterStatus 화면의 하위 항목 표시용
     */
    java.util.Map<Long, java.util.List<CashFlowPlanVO>> getExpensePlanMapByCC(String familyId);
}
