package com.eksystems.homes.living.service;

import com.eksystems.homes.living.vo.*;

import java.util.List;

public interface LivingService {

    // ── 기준정보 설정 ─────────────────────────────────────
    List<LivingBudgetCatVO> getCatListWithItems(String familyId);
    void saveCat(LivingBudgetCatVO vo, String userId);

    List<LivingBudgetItemVO> getItemList(String familyId, Long catSeq);
    void saveItem(LivingBudgetItemVO vo, String userId);
    void deleteItem(String familyId, Long itemSeq, String userId);

    // ── 생활비 관리 ───────────────────────────────────────
    List<LivingExpenseMstVO> getExpenseList(String familyId);

    /**
     * 해당 년월의 실적 헤더를 조회하거나 없으면 생성 후 반환.
     * 상세(DTL)는 기준정보 항목 기준으로 구성하여 반환.
     */
    LivingExpenseMstVO getOrCreateExpense(String familyId, String yymm, String userId);
    List<LivingExpenseDtlVO> getExpenseDtlList(String familyId, Long expSeq);

    /** 항목 하나 저장 (AJAX용) */
    void saveExpenseDtl(LivingExpenseDtlVO vo, String userId);

    /** 전체 항목 일괄 저장 */
    void saveAllExpenseDtl(Long expSeq, List<LivingExpenseDtlVO> dtlList, String userId);

    // ── 월별 수입 수기 등록 ───────────────────────────────
    List<LivingIncomeMstVO> getIncomeList(String familyId, String incomeYymm);
    List<LivingIncomeMstVO> getIncomeListByRange(String familyId, String fromYymm, String toYymm);
    void saveIncome(LivingIncomeMstVO vo, String userId);
    void deleteIncome(String familyId, Long incomeSeq);

    // ── 수기 현금흐름 (INCOME/EXPENSE) ───────────────────
    /** @deprecated LIVING_INCOME_MST 기반, FinancialController 이전 완료 시 제거 예정 */
    List<LivingIncomeMstVO> getManualCashflowList(String familyId, String yymm);

    // ── 수기 현금흐름 전용 (MANUAL_CASHFLOW_MST) ──────────
    List<ManualCashflowVO> getManualCfList(String familyId, String yymm);
    List<ManualCashflowVO> getManualCfListByRange(String familyId, String fromYymm, String toYymm);
    void saveManualCf(ManualCashflowVO vo, String userId);
    void deleteManualCf(String familyId, Long cfSeq);

    // ── 재무제표 명세용 ───────────────────────────────────
    List<LivingBudgetItemVO> getAllItemList(String familyId);
    List<LivingExpenseSummaryVO> getExpenseSummaryByRange(String familyId, String fromYymm, String toYymm);
}
