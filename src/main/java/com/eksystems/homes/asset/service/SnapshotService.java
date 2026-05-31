package com.eksystems.homes.asset.service;

import com.eksystems.homes.asset.vo.AssetChangeSummaryVO;
import com.eksystems.homes.asset.vo.AssetTypeMonthVO;
import com.eksystems.homes.asset.vo.CostCenterStatusVO;
import com.eksystems.homes.living.vo.ManualCashflowVO;

import java.util.List;

public interface SnapshotService {

    /** 전표처리: 특정 월 스냅샷 생성 (기존 HST 삭제 후 재생성) */
    void snapshot(String familyId, String yymm, String userId);

    /** 특정 월 HST 존재 여부 */
    boolean hasSnapshot(String familyId, String yymm);

    /** 비용센터현황 조회 (HST 기반) */
    List<CostCenterStatusVO> getCostCenterHst(String familyId, String yymm);

    /** 수기 현금흐름 조회 (HST 기반, snapshot 모드용) */
    List<ManualCashflowVO> getManualCfHst(String familyId, String yymm);

    /** 자산변동현황: 월별 집계 조회 */
    List<AssetChangeSummaryVO> getAssetChangeSummary(String familyId);

    /** 자산변동현황: 자산유형별 월별 금액 조회 */
    List<AssetTypeMonthVO> getAssetTypeMonthly(String familyId);

    /** Batch용: 전체 familyId 목록 */
    List<String> getAllFamilyIds();
}
