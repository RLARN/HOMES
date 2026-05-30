package com.eksystems.homes.living.mapper;

import com.eksystems.homes.living.vo.*;
import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Map;

public interface LivingMapper {

    // ── 카테고리 ──────────────────────────────────────────
    List<LivingBudgetCatVO> selectCatList(@Param("familyId") String familyId);
    LivingBudgetCatVO       selectCat(@Param("familyId") String familyId,
                                      @Param("catSeq") Long catSeq);
    void insertCat(LivingBudgetCatVO vo);
    void updateCat(LivingBudgetCatVO vo);

    // ── 항목 ─────────────────────────────────────────────
    List<LivingBudgetItemVO> selectItemList(@Param("familyId") String familyId,
                                            @Param("catSeq") Long catSeq);
    List<LivingBudgetItemVO> selectAllItemList(@Param("familyId") String familyId);
    LivingBudgetItemVO       selectItem(@Param("familyId") String familyId,
                                        @Param("itemSeq") Long itemSeq);
    void insertItem(LivingBudgetItemVO vo);
    void updateItem(LivingBudgetItemVO vo);
    void deleteItem(@Param("familyId") String familyId,
                    @Param("itemSeq") Long itemSeq,
                    @Param("updId") String updId);

    // ── 월별 실적 헤더 ────────────────────────────────────
    List<LivingExpenseMstVO> selectExpenseList(@Param("familyId") String familyId);
    LivingExpenseMstVO       selectExpenseMst(@Param("familyId") String familyId,
                                              @Param("expYymm") String expYymm);
    void insertExpenseMst(LivingExpenseMstVO vo);

    // ── 월별 실적 상세 ────────────────────────────────────
    List<LivingExpenseDtlVO> selectExpenseDtlList(@Param("expSeq") Long expSeq,
                                                   @Param("familyId") String familyId);
    void upsertExpenseDtl(LivingExpenseDtlVO vo);

    // ── 월별 수입 수기 등록 ───────────────────────────────
    List<LivingIncomeMstVO> selectIncomeList(@Param("familyId") String familyId,
                                              @Param("incomeYymm") String incomeYymm);
    List<LivingIncomeMstVO> selectIncomeListByRange(@Param("familyId") String familyId,
                                                    @Param("fromYymm") String fromYymm,
                                                    @Param("toYymm") String toYymm);
    void upsertIncome(LivingIncomeMstVO vo);
    void deleteIncome(@Param("familyId") String familyId,
                      @Param("incomeSeq") Long incomeSeq);

    // ── 수기 현금흐름 (INCOME/EXPENSE 통합) ──────────────────
    List<LivingIncomeMstVO> selectManualCashflowList(@Param("familyId") String familyId,
                                                      @Param("yymm") String yymm);

    // ── 재무제표 명세용 ───────────────────────────────────
    List<LivingExpenseSummaryVO> selectExpenseSummaryByRange(@Param("familyId") String familyId,
                                                              @Param("fromYymm") String fromYymm,
                                                              @Param("toYymm") String toYymm);

    // ── 수기 현금흐름 전용 (MANUAL_CASHFLOW_MST) ──────────
    List<ManualCashflowVO> selectManualCfList(@Param("familyId") String familyId,
                                              @Param("yymm") String yymm);
    List<ManualCashflowVO> selectManualCfListByRange(@Param("familyId") String familyId,
                                                     @Param("fromYymm") String fromYymm,
                                                     @Param("toYymm") String toYymm);
    void insertManualCf(ManualCashflowVO vo);
    void updateManualCf(ManualCashflowVO vo);
    void deleteManualCf(@Param("familyId") String familyId,
                        @Param("cfSeq") Long cfSeq);
}
