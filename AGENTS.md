# HOMES 프로젝트

가족 단위 가계부/구매 관리 웹 애플리케이션.

## 기술 스택

- **Spring Boot 3.5** / Java 17
- **MyBatis** (쿼리: `src/main/resources/mapper/**/*.xml`)
- **MariaDB** — `localhost:3306/homes` (user: homes / pw: homespw)
- **JSP + JSTL** (`src/main/webapp/WEB-INF/jsp/`)
- 서버 포트: **80**

## 패키지 구조

```
com.eksystems.homes
├── login/       로그인·로그아웃·세션 관리
├── main/        메인 화면
├── scm/         구매·입금 요청 관리
└── common/
    └── interceptor/  LoginInterceptor (미로그인 접근 차단)
                  WebMvcConfig (인터셉터 등록)
```

## 핵심 도메인 규칙

- **familyId** 로 데이터 격리 — 모든 조회/저장 시 familyId 조건 필수
- 세션 키: `"LoginVO"` → `LoginVO` 객체 (familyId, userId, userNm, userAuth 포함)
- 입금요청 상태값: `STANDBY` (상신됨), 추후 승인/반려 상태 추가 예정

## 주요 기능 현황

| 기능 | 상태 |
|------|------|
| 로그인/로그아웃 | 완료 |
| 입금요청 작성 (AJAX) | 완료 |
| 입금요청 목록/상세 | 완료 |
| 구매요청 | 화면만 있음, 미구현 |

## DB 테이블

- `SCM_DEPOSIT_REQUEST_MST` — 입금요청 (DEP_REQ_SEQ, FAMILY_ID, PUR_ITEM_SEQ, STORE_INFO, AMOUNT, REQ_STATUS, REQ_DESC, REG_ID, REG_DT, UPD_ID, UPD_DT)

## 레이어 패턴

Controller → Service (interface + Impl) → Mapper (interface) → XML

VO는 Lombok `@Data` 사용하나 getter/setter 수동 작성 혼재 중.
