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
