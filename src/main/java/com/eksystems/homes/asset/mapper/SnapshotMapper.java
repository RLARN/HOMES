package com.eksystems.homes.asset.mapper;

import com.eksystems.homes.asset.vo.AssetChangeSummaryVO;
import com.eksystems.homes.asset.vo.AssetTypeMonthVO;
import com.eksystems.homes.asset.vo.CostCenterStatusVO;
import com.eksystems.homes.living.vo.ManualCashflowVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface SnapshotMapper {

    // ── 전표처리: 기존 HST 삭제 (재처리 허용) ─────────────────
    void deleteCostCenterHst  (@Param("familyId") String familyId, @Param("yymm") String yymm);
    void deleteAssetHst       (@Param("familyId") String familyId, @Param("yymm") String yymm);
    void deleteLoanHst        (@Param("familyId") String familyId, @Param("yymm") String yymm);
    void deleteCashflowHst    (@Param("familyId") String familyId, @Param("yymm") String yymm);
    void deleteManualCfHst    (@Param("familyId") String familyId, @Param("yymm") String yymm);

    // ── 전표처리: 현재 상태 스냅샷 INSERT ──────────────────────
    void insertCostCenterHst  (@Param("familyId") String familyId, @Param("yymm") String yymm);
    void insertAssetHst       (@Param("familyId") String familyId, @Param("yymm") String yymm);
    void insertLoanHst        (@Param("familyId") String familyId, @Param("yymm") String yymm);
    void insertCashflowHst    (@Param("familyId") String familyId, @Param("yymm") String yymm);
    void insertManualCfHst    (@Param("familyId") String familyId, @Param("yymm") String yymm);

    // ── 조회: 특정 월 HST 존재 여부 ───────────────────────────
    int countHst(@Param("familyId") String familyId, @Param("yymm") String yymm);

    // ── 조회: 비용센터현황 (HST 기반) ─────────────────────────
    List<CostCenterStatusVO> selectCostCenterHst(
            @Param("familyId") String familyId,
            @Param("yymm") String yymm);

    // ── 조회: 자산변동현황 월별 집계 ──────────────────────────
    List<AssetChangeSummaryVO> selectAssetChangeSummary(@Param("familyId") String familyId);

    // ── 조회: 자산유형별 월별 금액 ────────────────────────────
    List<AssetTypeMonthVO> selectAssetTypeMonthly(@Param("familyId") String familyId);

    // ── 조회: 수기 현금흐름 HST (snapshot 모드용) ─────────────
    List<ManualCashflowVO> selectManualCfHst(
            @Param("familyId") String familyId,
            @Param("yymm") String yymm);

    // ── Batch용: 전표처리 대상 familyId 전체 조회 ─────────────
    List<String> selectAllFamilyIds();
}
