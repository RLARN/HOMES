<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover, interactive-widget=resizes-content">
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<title>^HOMES</title>

<!-- Bootstrap -->
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">

<!-- Pretendard -->
<link rel="stylesheet"
      href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@latest/dist/web/static/pretendard.css">

<!-- Material Symbols Rounded -->
<link rel="stylesheet"
      href="https://fonts.googleapis.com/css2?family=Material+Symbols+Rounded:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200&display=block">

<!-- HOMES 공통 CSS -->
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/homes.css">

<!-- AG Grid Community -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/ag-grid-community@31.3.4/styles/ag-grid.css">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/ag-grid-community@31.3.4/styles/ag-theme-alpine.css">
<script src="https://cdn.jsdelivr.net/npm/ag-grid-community@31.3.4/dist/ag-grid-community.min.js"></script>
<style>
/* ── AG Grid HOMES 테마 오버라이드 ── */
.ag-theme-alpine {
  --ag-font-family: 'Pretendard', system-ui, sans-serif;
  --ag-font-size: 13px;
  --ag-row-height: 44px;
  --ag-header-height: 38px;
  --ag-borders: none;
  --ag-border-color: #e5e7eb;
  --ag-header-background-color: #f8fafc;
  --ag-header-foreground-color: #6b7280;
  --ag-background-color: #fff;
  --ag-odd-row-background-color: #fff;
  --ag-row-hover-color: #f8fafc;
  --ag-row-border-color: #f1f5f9;
  --ag-selected-row-background-color: #eef2ff;
  --ag-cell-horizontal-padding: 14px;
  --ag-header-column-separator-display: none;
  --ag-header-column-resize-handle-display: none;
}
.ag-theme-alpine .ag-header { border-bottom: 1px solid #e5e7eb; }
.ag-theme-alpine .ag-root-wrapper { border: none; border-radius: 0; }
.ag-theme-alpine .ag-row { border-bottom: 1px solid #f1f5f9; cursor: default; }
.ag-theme-alpine .ag-row:last-child { border-bottom: none; }
.ag-theme-alpine .ag-cell { display: flex; align-items: center; }
.ag-theme-alpine .ag-header-cell-label { font-weight: 600; }
/* 우측 정렬 컬럼용 */
.ag-theme-alpine .ag-right-aligned-cell { justify-content: flex-end; }
.ag-theme-alpine .ag-right-aligned-header .ag-header-cell-label { justify-content: flex-end; }
/* 중앙 정렬 */
.ag-theme-alpine .ag-center-cols-container .ag-cell[col-id="center"],
.ag-cell-center { justify-content: center !important; text-align: center; }
/* 포커스 하이라이트 제거 */
.ag-theme-alpine .ag-cell:focus { outline: none; box-shadow: none; }
.ag-theme-alpine .ag-cell-focus { box-shadow: none !important; border: none !important; }
/* 그리드 래퍼 */
.homes-ag-wrap { width: 100%; }
</style>

<!-- HOMES 화면 전환 오버레이 -->
<script src="${pageContext.request.contextPath}/js/homes-progress.js"></script>

<!-- PWA -->
<link rel="manifest" href="${pageContext.request.contextPath}/manifest.json">

<!-- VAPID 공개키 (Web Push 구독 시 사용) -->
<script>
  window.HOMES_VAPID_PUBLIC_KEY = '${vapidPublicKey}';
</script>

<!-- Service Worker 등록 -->
<script>
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('/sw.js').catch(function (e) {
      console.warn('[SW] 등록 실패:', e);
    });
  }
</script>
