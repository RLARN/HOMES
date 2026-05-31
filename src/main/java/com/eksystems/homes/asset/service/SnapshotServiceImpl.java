package com.eksystems.homes.asset.service;

import com.eksystems.homes.asset.mapper.SnapshotMapper;
import com.eksystems.homes.asset.vo.AssetChangeSummaryVO;
import com.eksystems.homes.asset.vo.AssetTypeMonthVO;
import com.eksystems.homes.asset.vo.CostCenterStatusVO;
import com.eksystems.homes.living.vo.ManualCashflowVO;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class SnapshotServiceImpl implements SnapshotService {

    private final SnapshotMapper snapshotMapper;

    public SnapshotServiceImpl(SnapshotMapper snapshotMapper) {
        this.snapshotMapper = snapshotMapper;
    }

    @Override
    @Transactional
    public void snapshot(String familyId, String yymm, String userId) {
        // 기존 HST 삭제 (재처리 허용)
        snapshotMapper.deleteCostCenterHst(familyId, yymm);
        snapshotMapper.deleteAssetHst(familyId, yymm);
        snapshotMapper.deleteLoanHst(familyId, yymm);
        snapshotMapper.deleteCashflowHst(familyId, yymm);
        snapshotMapper.deleteManualCfHst(familyId, yymm);

        // 현재 상태 스냅샷
        snapshotMapper.insertCostCenterHst(familyId, yymm);
        snapshotMapper.insertAssetHst(familyId, yymm);
        snapshotMapper.insertLoanHst(familyId, yymm);
        snapshotMapper.insertCashflowHst(familyId, yymm);
        snapshotMapper.insertManualCfHst(familyId, yymm);
    }

    @Override
    public boolean hasSnapshot(String familyId, String yymm) {
        return snapshotMapper.countHst(familyId, yymm) > 0;
    }

    @Override
    public List<CostCenterStatusVO> getCostCenterHst(String familyId, String yymm) {
        return snapshotMapper.selectCostCenterHst(familyId, yymm);
    }

    @Override
    public List<ManualCashflowVO> getManualCfHst(String familyId, String yymm) {
        return snapshotMapper.selectManualCfHst(familyId, yymm);
    }

    @Override
    public List<AssetChangeSummaryVO> getAssetChangeSummary(String familyId) {
        return snapshotMapper.selectAssetChangeSummary(familyId);
    }

    @Override
    public List<AssetTypeMonthVO> getAssetTypeMonthly(String familyId) {
        return snapshotMapper.selectAssetTypeMonthly(familyId);
    }

    @Override
    public List<String> getAllFamilyIds() {
        return snapshotMapper.selectAllFamilyIds();
    }
}
