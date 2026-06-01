package com.eksystems.homes.asset.service;

import com.eksystems.homes.asset.mapper.CashFlowMapper;
import com.eksystems.homes.asset.vo.CashFlowPlanVO;
import com.eksystems.homes.asset.vo.CashFlowTypeVO;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class CashFlowServiceImpl implements CashFlowService {

    private final CashFlowMapper     cashFlowMapper;
    private final CostCenterService  costCenterService;

    public CashFlowServiceImpl(CashFlowMapper cashFlowMapper,
                               CostCenterService costCenterService) {
        this.cashFlowMapper    = cashFlowMapper;
        this.costCenterService = costCenterService;
    }

    @Override
    public List<CashFlowTypeVO> getTypeList(String flowCategory) {
        return cashFlowMapper.selectTypeList(flowCategory);
    }

    @Override
    public List<CashFlowPlanVO> getPlanList(String familyId, String flowCategory, String useYn) {
        return cashFlowMapper.selectPlanList(familyId, flowCategory, useYn);
    }

    @Override
    public CashFlowPlanVO getPlanDetail(String familyId, Long planSeq) {
        return cashFlowMapper.selectPlanDetail(familyId, planSeq);
    }

    @Override
    @Transactional
    public void savePlan(CashFlowPlanVO vo, String userId) {
        boolean isNew = (vo.getPlanSeq() == null);
        if (isNew) {
            vo.setRegId(userId);
            vo.setUpdId(userId);
            cashFlowMapper.insertPlan(vo);
        } else {
            vo.setUpdId(userId);
            cashFlowMapper.updatePlan(vo);
        }
        // 정기수입만 수지계정 자동 동기화
        if ("INCOME".equals(vo.getFlowType())) {
            costCenterService.syncFromIncomePlan(vo, userId);
        }
    }

    @Override
    @Transactional
    public void deletePlan(String familyId, Long planSeq, String userId) {
        cashFlowMapper.deletePlan(familyId, planSeq, userId);
    }

    @Override
    @Transactional
    public void deleteIncomePlan(String familyId, Long planSeq, String userId) {
        // 비용센터에서 수입원으로 사용 중이면 예외
        costCenterService.checkIncomePlanDeletable(familyId, planSeq);
        cashFlowMapper.deletePlan(familyId, planSeq, userId);
    }

    @Override
    @Transactional
    public void toggleUseYn(String familyId, Long planSeq, String currentUseYn, String userId) {
        String next = "Y".equals(currentUseYn) ? "N" : "Y";
        cashFlowMapper.updateUseYn(familyId, planSeq, next, userId);
    }

    @Override
    public List<CashFlowPlanVO> getIncomePlansForCostCenter(String familyId) {
        return cashFlowMapper.selectIncomePlansForCostCenter(familyId);
    }
}
