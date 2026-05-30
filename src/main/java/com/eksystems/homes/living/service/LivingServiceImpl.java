package com.eksystems.homes.living.service;

import com.eksystems.homes.asset.mapper.CashFlowMapper;
import com.eksystems.homes.living.mapper.LivingMapper;
import com.eksystems.homes.living.vo.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class LivingServiceImpl implements LivingService {

    private final LivingMapper   livingMapper;
    private final CashFlowMapper cashFlowMapper;

    public LivingServiceImpl(LivingMapper livingMapper, CashFlowMapper cashFlowMapper) {
        this.livingMapper   = livingMapper;
        this.cashFlowMapper = cashFlowMapper;
    }

    // ── 기준정보 설정 ─────────────────────────────────────

    @Override
    public List<LivingBudgetCatVO> getCatListWithItems(String familyId) {
        List<LivingBudgetCatVO>  cats  = livingMapper.selectCatList(familyId);
        List<LivingBudgetItemVO> items = livingMapper.selectAllItemList(familyId);

        // catSeq 기준으로 items 그룹핑
        Map<Long, List<LivingBudgetItemVO>> itemMap = items.stream()
                .collect(Collectors.groupingBy(LivingBudgetItemVO::getCatSeq));

        for (LivingBudgetCatVO cat : cats) {
            List<LivingBudgetItemVO> catItems = itemMap.getOrDefault(cat.getCatSeq(), Collections.emptyList());
            cat.setItems(catItems);
            long total = catItems.stream()
                    .mapToLong(i -> i.getBudgetAmt() != null ? i.getBudgetAmt() : 0L)
                    .sum();
            cat.setTotalBudgetAmt(total);
        }
        return cats;
    }

    @Override
    @Transactional
    public void saveCat(LivingBudgetCatVO vo, String userId) {
        if (vo.getCatSeq() == null) {
            vo.setRegId(userId);
            livingMapper.insertCat(vo);
        } else {
            vo.setUpdId(userId);
            livingMapper.updateCat(vo);
        }
    }

    @Override
    public List<LivingBudgetItemVO> getItemList(String familyId, Long catSeq) {
        return livingMapper.selectItemList(familyId, catSeq);
    }

    @Override
    @Transactional
    public void saveItem(LivingBudgetItemVO vo, String userId) {
        if (vo.getItemSeq() == null) {
            vo.setRegId(userId);
            livingMapper.insertItem(vo);
        } else {
            vo.setUpdId(userId);
            livingMapper.updateItem(vo);
        }
        syncLivingTotalPlans(vo.getFamilyId(), userId);
    }

    @Override
    @Transactional
    public void deleteItem(String familyId, Long itemSeq, String userId) {
        livingMapper.deleteItem(familyId, itemSeq, userId);
        syncLivingTotalPlans(familyId, userId);
    }

    /** 생활비 전체 연동 플랜의 금액을 현재 기준정보 합계로 갱신 */
    private void syncLivingTotalPlans(String familyId, String userId) {
        long total = livingMapper.selectAllItemList(familyId).stream()
                .mapToLong(i -> i.getBudgetAmt() != null ? i.getBudgetAmt() : 0L)
                .sum();
        cashFlowMapper.updateLivingTotalLinkedPlans(familyId, total, userId);
    }

    // ── 생활비 관리 ───────────────────────────────────────

    @Override
    public List<LivingExpenseMstVO> getExpenseList(String familyId) {
        return livingMapper.selectExpenseList(familyId);
    }

    @Override
    @Transactional
    public LivingExpenseMstVO getOrCreateExpense(String familyId, String yymm, String userId) {
        LivingExpenseMstVO mst = livingMapper.selectExpenseMst(familyId, yymm);
        if (mst == null) {
            mst = new LivingExpenseMstVO();
            mst.setFamilyId(familyId);
            mst.setExpYymm(yymm);
            mst.setRegId(userId);
            livingMapper.insertExpenseMst(mst);
            mst = livingMapper.selectExpenseMst(familyId, yymm);
        }
        return mst;
    }

    @Override
    public List<LivingExpenseDtlVO> getExpenseDtlList(String familyId, Long expSeq) {
        // 기준정보 전체 항목을 기반으로 DTL 구성 (실적이 없는 항목도 포함)
        List<LivingBudgetItemVO> allItems = livingMapper.selectAllItemList(familyId);
        List<LivingExpenseDtlVO> savedDtls = livingMapper.selectExpenseDtlList(expSeq, familyId);

        // 저장된 실적을 itemSeq 기준으로 Map화
        Map<Long, LivingExpenseDtlVO> dtlMap = savedDtls.stream()
                .collect(Collectors.toMap(LivingExpenseDtlVO::getItemSeq, d -> d));

        List<LivingExpenseDtlVO> result = new ArrayList<>();
        for (LivingBudgetItemVO item : allItems) {
            LivingExpenseDtlVO dtl = dtlMap.getOrDefault(item.getItemSeq(), new LivingExpenseDtlVO());
            dtl.setExpSeq(expSeq);
            dtl.setItemSeq(item.getItemSeq());
            dtl.setCatSeq(item.getCatSeq());
            dtl.setCatNm(item.getCatNm());
            dtl.setItemNm(item.getItemNm());
            dtl.setBudgetAmt(item.getBudgetAmt());
            if (dtl.getActualAmt() == null) dtl.setActualAmt(0L);
            result.add(dtl);
        }
        return result;
    }

    @Override
    @Transactional
    public void saveExpenseDtl(LivingExpenseDtlVO vo, String userId) {
        vo.setRegId(userId);
        vo.setUpdId(userId);
        livingMapper.upsertExpenseDtl(vo);
    }

    @Override
    @Transactional
    public void saveAllExpenseDtl(Long expSeq, List<LivingExpenseDtlVO> dtlList, String userId) {
        for (LivingExpenseDtlVO dtl : dtlList) {
            dtl.setExpSeq(expSeq);
            dtl.setRegId(userId);
            dtl.setUpdId(userId);
            livingMapper.upsertExpenseDtl(dtl);
        }
    }

    // ── 월별 수입 수기 등록 ───────────────────────────────

    @Override
    public List<LivingIncomeMstVO> getIncomeList(String familyId, String incomeYymm) {
        return livingMapper.selectIncomeList(familyId, incomeYymm);
    }

    @Override
    @Transactional
    public void saveIncome(LivingIncomeMstVO vo, String userId) {
        vo.setRegId(userId);
        vo.setUpdId(userId);
        livingMapper.upsertIncome(vo);
    }

    @Override
    public List<LivingIncomeMstVO> getIncomeListByRange(String familyId, String fromYymm, String toYymm) {
        return livingMapper.selectIncomeListByRange(familyId, fromYymm, toYymm);
    }

    @Override
    @Transactional
    public void deleteIncome(String familyId, Long incomeSeq) {
        livingMapper.deleteIncome(familyId, incomeSeq);
    }

    @Override
    public List<LivingIncomeMstVO> getManualCashflowList(String familyId, String yymm) {
        return livingMapper.selectManualCashflowList(familyId, yymm);
    }

    // ── 수기 현금흐름 전용 (MANUAL_CASHFLOW_MST) ──────────

    @Override
    public List<ManualCashflowVO> getManualCfList(String familyId, String yymm) {
        return livingMapper.selectManualCfList(familyId, yymm);
    }

    @Override
    public List<ManualCashflowVO> getManualCfListByRange(String familyId, String fromYymm, String toYymm) {
        return livingMapper.selectManualCfListByRange(familyId, fromYymm, toYymm);
    }

    @Override
    @Transactional
    public void saveManualCf(ManualCashflowVO vo, String userId) {
        vo.setRegId(userId);
        vo.setUpdId(userId);
        if (vo.getCfSeq() == null) {
            livingMapper.insertManualCf(vo);
        } else {
            livingMapper.updateManualCf(vo);
        }
    }

    @Override
    @Transactional
    public void deleteManualCf(String familyId, Long cfSeq) {
        livingMapper.deleteManualCf(familyId, cfSeq);
    }

    @Override
    public List<LivingBudgetItemVO> getAllItemList(String familyId) {
        return livingMapper.selectAllItemList(familyId);
    }

    @Override
    public List<LivingExpenseSummaryVO> getExpenseSummaryByRange(String familyId, String fromYymm, String toYymm) {
        return livingMapper.selectExpenseSummaryByRange(familyId, fromYymm, toYymm);
    }
}
