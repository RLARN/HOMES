package com.eksystems.homes.asset.vo;

import com.eksystems.homes.asset.vo.CashFlowPlanVO;
import com.eksystems.homes.living.vo.LivingIncomeMstVO;
import lombok.Data;
import java.util.List;

@Data
public class CostCenterStatusVO {
    private Long   ccSeq;
    private String ccNm;
    private String ccType;
    private Long   sourcePlanSeq;
    private Long   incomePlanSeq;
    private String incomePlanNm;
    /** 수입원 월 금액 */
    private Long   incomeMonthlyAmt;
    /** 연결된 정기지출 월 합계 */
    private Long   expenseMonthlyAmt;
    /** 정기지출 건수 */
    private int    expenseCnt;

    // ── 기간 계산 후 Java에서 세팅 ──────────────────────────
    /** 기간 내 총 수입 (incomeMonthlyAmt × months) */
    private Long totalIncomeAmt;
    /** 기간 내 총 지출 (expenseMonthlyAmt × months) */
    private Long totalExpenseAmt;
    /** 잔액 (수입 - 지출) */
    private Long balance;

    // ── 하위 항목 (화면 전용) ──────────────────────────────
    /** 이 수지계정에 연결된 지출 항목 목록 (정기지출 계획) */
    private List<CashFlowPlanVO> expensePlans;

    /** 이 수지계정의 수기 현금흐름 항목 목록 (LIVING_INCOME_MST) */
    private List<LivingIncomeMstVO> manualEntries;
}
