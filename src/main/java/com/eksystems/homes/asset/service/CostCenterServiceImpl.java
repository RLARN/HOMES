package com.eksystems.homes.asset.service;

import com.eksystems.homes.asset.mapper.CostCenterMapper;
import com.eksystems.homes.asset.vo.AssetVO;
import com.eksystems.homes.asset.vo.CashFlowPlanVO;
import com.eksystems.homes.asset.vo.CostCenterStatusVO;
import com.eksystems.homes.asset.vo.CostCenterVO;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.Period;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class CostCenterServiceImpl implements CostCenterService {

    private final CostCenterMapper costCenterMapper;

    public CostCenterServiceImpl(CostCenterMapper costCenterMapper) {
        this.costCenterMapper = costCenterMapper;
    }

    @Override
    public List<CostCenterVO> getList(String familyId, String useYn) {
        return costCenterMapper.selectList(familyId, useYn);
    }

    @Override
    public CostCenterVO getOne(String familyId, Long ccSeq) {
        return costCenterMapper.selectOne(familyId, ccSeq);
    }

    @Override
    @Transactional
    public void save(CostCenterVO vo, String userId) {
        if (vo.getCcSeq() == null) {
            vo.setRegId(userId);
            vo.setUpdId(userId);
            if (vo.getCcType() == null) vo.setCcType("MANUAL");
            costCenterMapper.insert(vo);
        } else {
            vo.setUpdId(userId);
            costCenterMapper.update(vo);
        }
    }

    @Override
    @Transactional
    public void delete(String familyId, Long ccSeq, String userId) {
        int used = costCenterMapper.countUsedByCcSeq(familyId, ccSeq);
        if (used > 0) {
            throw new IllegalStateException(
                "이 수지계정은 정기지출 " + used + "건에서 사용 중입니다. 먼저 정기지출의 수지계정 연결을 해제하세요."
            );
        }
        costCenterMapper.softDelete(familyId, ccSeq, userId);
    }

    @Override
    @Transactional
    public void syncFromExpensePlan(CashFlowPlanVO plan, String userId) {
        if (plan.getPlanSeq() == null) return;

        CostCenterVO existing = costCenterMapper.selectBySourcePlan(plan.getFamilyId(), plan.getPlanSeq());

        if (existing == null) {
            // 신규 생성
            CostCenterVO cc = new CostCenterVO();
            cc.setFamilyId(plan.getFamilyId());
            cc.setCcNm(plan.getPlanNm());
            cc.setCcType("AUTO");
            cc.setSourcePlanSeq(plan.getPlanSeq());
            cc.setMonthlyAmt(plan.getAmount());
            cc.setUseYn(plan.getUseYn() != null ? plan.getUseYn() : "Y");
            cc.setRegId(userId);
            cc.setUpdId(userId);
            costCenterMapper.insert(cc);
        } else {
            // 이름·금액·사용여부 동기화
            existing.setCcNm(plan.getPlanNm());
            existing.setMonthlyAmt(plan.getAmount());
            existing.setUseYn(plan.getUseYn() != null ? plan.getUseYn() : existing.getUseYn());
            existing.setUpdId(userId);
            costCenterMapper.update(existing);
        }
    }

    @Override
    @Transactional
    public void deleteBySourcePlan(String familyId, Long sourcePlanSeq, String userId) {
        costCenterMapper.softDeleteBySourcePlan(familyId, sourcePlanSeq, userId);
    }

    @Override
    public List<CostCenterStatusVO> getStatusList(String familyId, String fromYymm, String toYymm) {
        List<CostCenterStatusVO> list = costCenterMapper.selectStatusList(familyId);

        // 기간 내 개월 수 계산
        int months = calcMonths(fromYymm, toYymm);

        long totalIncome  = 0L;
        long totalExpense = 0L;

        for (CostCenterStatusVO s : list) {
            long income  = s.getIncomeMonthlyAmt()  != null ? s.getIncomeMonthlyAmt()  : 0L;
            long expense = s.getExpenseMonthlyAmt() != null ? s.getExpenseMonthlyAmt() : 0L;

            s.setTotalIncomeAmt(income  * months);
            s.setTotalExpenseAmt(expense * months);
            s.setBalance(income * months - expense * months);

            totalIncome  += income  * months;
            totalExpense += expense * months;
        }
        return list;
    }

    /** "YYYYMM" 두 값 사이의 개월 수 (포함) */
    private int calcMonths(String from, String to) {
        if (from == null || to == null || from.length() < 6 || to.length() < 6) return 1;
        try {
            LocalDate fromDate = LocalDate.of(
                    Integer.parseInt(from.substring(0, 4)),
                    Integer.parseInt(from.substring(4, 6)), 1);
            LocalDate toDate   = LocalDate.of(
                    Integer.parseInt(to.substring(0, 4)),
                    Integer.parseInt(to.substring(4, 6)), 1);
            if (toDate.isBefore(fromDate)) return 1;
            Period p = Period.between(fromDate, toDate.plusMonths(1));
            return Math.max(1, p.getYears() * 12 + p.getMonths());
        } catch (Exception e) {
            return 1;
        }
    }

    @Override
    public CostCenterVO findBySourceAsset(String familyId, Long assetSeq) {
        return costCenterMapper.selectBySourceAsset(familyId, assetSeq);
    }

    @Override
    @Transactional
    public void syncFromAsset(AssetVO asset, String userId) {
        CostCenterVO existing = costCenterMapper.selectBySourceAsset(asset.getFamilyId(), asset.getAssetSeq());
        if (existing == null) {
            CostCenterVO cc = new CostCenterVO();
            cc.setFamilyId(asset.getFamilyId());
            cc.setCcNm(asset.getAssetNm());
            cc.setCcType("MANUAL");
            cc.setSourceAssetSeq(asset.getAssetSeq());
            cc.setMonthlyAmt(asset.getAmount());
            cc.setUseYn("Y");
            cc.setRegId(userId);
            cc.setUpdId(userId);
            costCenterMapper.insert(cc);
        } else {
            existing.setCcNm(asset.getAssetNm());
            existing.setMonthlyAmt(asset.getAmount());
            existing.setUpdId(userId);
            costCenterMapper.update(existing);
        }
    }

    @Override
    @Transactional
    public void unlinkFromAsset(String familyId, Long assetSeq, String userId) {
        costCenterMapper.softDeleteBySourceAsset(familyId, assetSeq, userId);
    }

    @Override
    @Transactional
    public void syncFromIncomePlan(CashFlowPlanVO plan, String userId) {
        if (plan.getPlanSeq() == null) return;

        CostCenterVO existing = costCenterMapper.selectByIncomePlanSeq(plan.getFamilyId(), plan.getPlanSeq());

        if (existing == null) {
            CostCenterVO cc = new CostCenterVO();
            cc.setFamilyId(plan.getFamilyId());
            cc.setCcNm(plan.getPlanNm());
            cc.setCcType("MANUAL");
            cc.setIncomePlanSeq(plan.getPlanSeq());
            cc.setMonthlyAmt(plan.getAmount());
            cc.setUseYn(plan.getUseYn() != null ? plan.getUseYn() : "Y");
            cc.setRegId(userId);
            cc.setUpdId(userId);
            costCenterMapper.insert(cc);
        } else {
            existing.setCcNm(plan.getPlanNm());
            existing.setMonthlyAmt(plan.getAmount());
            existing.setUseYn(plan.getUseYn() != null ? plan.getUseYn() : existing.getUseYn());
            existing.setUpdId(userId);
            costCenterMapper.update(existing);
        }
    }

    @Override
    public Map<Long, List<CashFlowPlanVO>> getExpensePlanMapByCC(String familyId) {
        List<CashFlowPlanVO> all = costCenterMapper.selectExpensePlansWithCC(familyId);
        // costCenterSeq 에 c.CC_SEQ 가 담겨 있음 (SQL 쿼리 참고)
        return all.stream()
                .filter(p -> p.getCostCenterSeq() != null)
                .collect(Collectors.groupingBy(
                        CashFlowPlanVO::getCostCenterSeq,
                        LinkedHashMap::new,
                        Collectors.toList()));
    }

    @Override
    public void checkIncomePlanDeletable(String familyId, Long incomePlanSeq) {
        int cnt = costCenterMapper.countByIncomePlanSeq(familyId, incomePlanSeq);
        if (cnt > 0) {
            throw new IllegalStateException(
                "이 수입원은 수지계정 " + cnt + "건에서 사용 중입니다. 먼저 수지계정의 수입원 연결을 해제하세요."
            );
        }
    }
}
