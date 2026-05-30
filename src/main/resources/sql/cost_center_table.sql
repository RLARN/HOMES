-- =====================================================
-- HOMES 비용센터 관리 SQL
-- charset: utf8mb4
-- =====================================================

-- 1. 비용센터 마스터
CREATE TABLE IF NOT EXISTS COST_CENTER_MST (
    CC_SEQ          BIGINT       AUTO_INCREMENT PRIMARY KEY,
    FAMILY_ID       VARCHAR(30)  NOT NULL,
    CC_NM           VARCHAR(200) NOT NULL             COMMENT '비용센터명',
    CC_TYPE         VARCHAR(20)  NOT NULL DEFAULT 'MANUAL'
                                                      COMMENT 'MANUAL=수동등록, AUTO=정기지출 자동생성',
    SOURCE_PLAN_SEQ BIGINT                            COMMENT '자동생성 원본 정기지출 PLAN_SEQ',
    INCOME_PLAN_SEQ BIGINT                            COMMENT '재원 수입원 PLAN_SEQ (정기수입관리)',
    MONTHLY_AMT     BIGINT       NOT NULL DEFAULT 0   COMMENT '월 금액',
    SORT_ORDER      INT          NOT NULL DEFAULT 0,
    USE_YN          CHAR(1)      NOT NULL DEFAULT 'Y',
    DEL_YN          CHAR(1)      NOT NULL DEFAULT 'N',
    MEMO            VARCHAR(500),
    REG_ID          VARCHAR(30),
    REG_DT          DATETIME     NOT NULL DEFAULT NOW(),
    UPD_ID          VARCHAR(30),
    UPD_DT          DATETIME,
    UNIQUE KEY UK_CC_SOURCE_PLAN (SOURCE_PLAN_SEQ)  -- 정기지출 1:1 매핑
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX IF NOT EXISTS IDX_CC_FAMILY ON COST_CENTER_MST (FAMILY_ID, DEL_YN, USE_YN);

-- 2. CASH_FLOW_PLAN_MST.COST_CENTER_TYPE 에 'CC' 구분 추가
--    (기존 ASSET/INCOME 값은 레거시로 유지, 신규는 'CC' 사용)
--    별도 컬럼 변경 없음 — 기존 컬럼 그대로 활용

-- 3. 기존 정기지출 항목을 비용센터로 마이그레이션 (선택적 실행)
-- INSERT IGNORE INTO COST_CENTER_MST
--     (FAMILY_ID, CC_NM, CC_TYPE, SOURCE_PLAN_SEQ, MONTHLY_AMT, USE_YN, DEL_YN, REG_ID, REG_DT)
-- SELECT FAMILY_ID, PLAN_NM, 'AUTO', PLAN_SEQ, AMOUNT, USE_YN, DEL_YN, REG_ID, REG_DT
-- FROM CASH_FLOW_PLAN_MST
-- WHERE FLOW_TYPE IN ('EXPENSE','SAVING','INVEST')
--   AND DEL_YN = 'N';
