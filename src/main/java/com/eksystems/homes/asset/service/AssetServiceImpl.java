package com.eksystems.homes.asset.service;

import com.eksystems.homes.asset.mapper.AssetMapper;
import com.eksystems.homes.asset.vo.AssetSummaryVO;
import com.eksystems.homes.asset.vo.AssetVO;
import com.eksystems.homes.asset.vo.LoanVO;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class AssetServiceImpl implements AssetService {

    private final AssetMapper assetMapper;

    public AssetServiceImpl(AssetMapper assetMapper) {
        this.assetMapper = assetMapper;
    }

    @Override
    public List<AssetVO> getAssetTypeList() {
        return assetMapper.selectAssetTypeList();
    }

    @Override
    public List<AssetVO> getAssetList(String familyId, String disposeYn) {
        return assetMapper.selectAssetList(familyId, disposeYn);
    }

    @Override
    public AssetVO getAssetDetail(String familyId, Long assetSeq) {
        return assetMapper.selectAssetDetail(familyId, assetSeq);
    }

    @Override
    @Transactional
    public void saveAsset(AssetVO vo, String userId) {
        if (vo.getAssetSeq() == null) {
            vo.setRegId(userId);
            vo.setUpdId(userId);
            assetMapper.insertAsset(vo);
        } else {
            vo.setUpdId(userId);
            assetMapper.updateAsset(vo);
        }
    }

    @Override
    @Transactional
    public void deleteAsset(String familyId, Long assetSeq, String userId) {
        int used = assetMapper.countCostCenterUsage(assetSeq);
        if (used > 0) throw new IllegalStateException("수지계정으로 사용 중인 자산은 삭제할 수 없습니다.");
        assetMapper.deleteAsset(familyId, assetSeq, userId);
    }

    @Override
    public List<AssetVO> getLiquidAssets(String familyId) {
        return assetMapper.selectLiquidAssets(familyId);
    }

    @Override
    public List<LoanVO> getLoanList(String familyId, String closeYn) {
        return assetMapper.selectLoanList(familyId, closeYn);
    }

    @Override
    public LoanVO getLoanDetail(String familyId, Long loanSeq) {
        return assetMapper.selectLoanDetail(familyId, loanSeq);
    }

    @Override
    @Transactional
    public void saveLoan(LoanVO vo, String userId) {
        if (vo.getLoanSeq() == null) {
            vo.setRegId(userId);
            vo.setUpdId(userId);
            assetMapper.insertLoan(vo);
        } else {
            vo.setUpdId(userId);
            assetMapper.updateLoan(vo);
        }
    }

    @Override
    @Transactional
    public void deleteLoan(String familyId, Long loanSeq, String userId) {
        assetMapper.deleteLoan(familyId, loanSeq, userId);
    }

    @Override
    public AssetSummaryVO getAssetSummary(String familyId) {
        AssetSummaryVO summary = assetMapper.selectAssetSummary(familyId);
        if (summary == null) {
            summary = new AssetSummaryVO();
            summary.setFamilyId(familyId);
            summary.setTotalAssetAmount(0L);
            summary.setTotalLiquidAssetAmount(0L);
            summary.setTotalFixedAssetAmount(0L);
            summary.setTotalInvestAmount(0L);
            summary.setTotalLoanBalance(0L);
            summary.setNetAssetAmount(0L);
            summary.setMonthlyIncomeAmount(0L);
            summary.setMonthlyExpenseAmount(0L);
            summary.setMonthlySavingAmount(0L);
            summary.setMonthlyInvestAmount(0L);
            summary.setExpectedMonthlyCashFlow(0L);
        }
        return summary;
    }
}
