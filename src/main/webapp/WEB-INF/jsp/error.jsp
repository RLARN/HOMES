<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>^HOMES | Error</title>

  <!-- Bootstrap 5 -->
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">

  <!-- (선택) Pretendard -->
  <link rel="preconnect" href="https://cdn.jsdelivr.net">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@latest/dist/web/static/pretendard.css">

  <style>
    * { box-sizing: border-box; }
    body {
      font-family: "Pretendard", system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif;
      background: #f6f8fb;
      margin: 0;
    }

    .homes-shell {
      min-height: 100vh;
      display: grid;
      grid-template-columns: 1.05fr 0.95fr;
    }

    .homes-brand {
      background: linear-gradient(135deg, #1e3a8a, #1e40af);
      color: #fff;
      padding: 56px 56px;
      display: flex;
      flex-direction: column;
      justify-content: center;
      gap: 14px;
      position: relative;
      overflow: hidden;
    }

    .homes-brand:before {
      content: "";
      position: absolute;
      inset: -80px -120px auto auto;
      width: 260px;
      height: 260px;
      border-radius: 999px;
      background: rgba(255,255,255,.10);
      filter: blur(0px);
    }

    .homes-logo {
      display: inline-flex;
      align-items: center;
      gap: 10px;
      font-weight: 800;
      letter-spacing: -0.02em;
      font-size: 20px;
    }

    .homes-tagline {
      opacity: .88;
      line-height: 1.6;
      max-width: 36ch;
    }

    .homes-main {
      background: #fff;
      padding: 48px 48px;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .homes-card {
      width: 100%;
      max-width: 520px;
      border: 0;
      border-radius: 22px;
      box-shadow: 0 14px 34px rgba(16, 24, 40, 0.08);
    }

    .homes-badge {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      border-radius: 999px;
      padding: 8px 12px;
      font-weight: 800;
      letter-spacing: .08em;
      font-size: 12px;
      background: rgba(30, 58, 138, 0.10);
      color: #1e3a8a;
    }

    .homes-status {
      font-size: 40px;
      font-weight: 900;
      letter-spacing: -0.03em;
      color: #111827;
      margin: 8px 0 6px;
    }

    .homes-title {
      font-size: 18px;
      font-weight: 800;
      color: #111827;
      margin-bottom: 6px;
    }

    .homes-desc {
      color: #6b7280;
      line-height: 1.55;
      margin-bottom: 18px;
    }

    .homes-meta {
      background: #f8fafc;
      border: 1px solid rgba(17,24,39,.08);
      border-radius: 16px;
      padding: 14px 14px;
      font-size: 13px;
      color: #334155;
    }

    .homes-meta .k { color: #64748b; width: 92px; display: inline-block; }

    .homes-actions .btn {
      border-radius: 999px;
      padding: 10px 14px;
      font-weight: 700;
    }

    .homes-footer {
      margin-top: 14px;
      color: #94a3b8;
      font-size: 12px;
      text-align: center;
    }

    pre.homes-trace {
      white-space: pre-wrap;
      word-break: break-word;
      background: #0b1220;
      color: #cbd5e1;
      border-radius: 16px;
      padding: 14px;
      max-height: 240px;
      overflow: auto;
      font-size: 12px;
    }

    /* Responsive */
    @media (max-width: 992px) {
      .homes-shell { grid-template-columns: 1fr; }
      .homes-brand { padding: 32px; text-align: center; align-items: center; }
      .homes-main { padding: 28px; }
      .homes-tagline { max-width: 52ch; }
    }
  </style>
</head>

<body>

  <div class="homes-shell">
    <!-- Brand side -->
    <section class="homes-brand">
      <div class="homes-logo">
        <span>^HOMES</span>
      </div>
      <div class="homes-tagline">
        Home Organization &amp; Management for Enhanced Synergy<br/>
        문제가 발생했지만, 안전하게 돌아갈 수 있어요.
      </div>
      <div class="opacity-75 small">
        네트워크/권한/경로 오류일 수 있습니다. 필요하면 아래 상세정보를 확인하세요.
      </div>
    </section>

    <!-- Content side -->
    <main class="homes-main">
      <div class="card homes-card">
        <div class="card-body p-4 p-md-4">

          <div class="d-flex align-items-center justify-content-between flex-wrap gap-2">
            <div class="homes-badge">
              ERROR
              <span class="text-muted">·</span>
              <span>${error}</span>
            </div>
            <span class="text-muted small">requestId: <c:out value="${requestId}" /></span>
          </div>

          <div class="homes-status">
            <c:out value="${status}" />
          </div>

          <div class="homes-title">
            <c:choose>
              <c:when test="${status == 404}">페이지를 찾을 수 없어요</c:when>
              <c:when test="${status == 403}">접근 권한이 없어요</c:when>
              <c:when test="${status == 500}">서버에서 문제가 발생했어요</c:when>
              <c:otherwise>요청을 처리할 수 없어요</c:otherwise>
            </c:choose>
          </div>

          <div class="homes-desc">
            <c:choose>
              <c:when test="${not empty message}">
                <c:out value="${message}" />
              </c:when>
              <c:otherwise>
                잠시 후 다시 시도하거나, 홈으로 이동해 주세요.
              </c:otherwise>
            </c:choose>
          </div>

          <div class="homes-meta mb-3">
            <div><span class="k">Path</span> <c:out value="${path}" /></div>
            <div><span class="k">Time</span> <c:out value="${timestamp}" /></div>
            <c:if test="${not empty exception}">
              <div><span class="k">Exception</span> <c:out value="${exception}" /></div>
            </c:if>
          </div>

          <div class="homes-actions d-grid gap-2 d-sm-flex">
            <a class="btn btn-primary flex-fill"
               href="${pageContext.request.contextPath}/main">메인으로</a>

            <a class="btn btn-outline-primary flex-fill"
               href="${pageContext.request.contextPath}/login">로그인</a>

            <button class="btn btn-outline-secondary flex-fill" type="button"
                    onclick="history.back()">뒤로가기</button>
          </div>

          <!-- Debug (show only when trace exists or ?trace=true) -->
          <c:if test="${not empty trace}">
            <hr class="my-4">
            <details>
              <summary class="fw-semibold text-muted" style="cursor:pointer;">상세 오류 보기(개발용)</summary>
              <div class="mt-3">
                <pre class="homes-trace"><c:out value="${trace}" /></pre>
              </div>
            </details>
          </c:if>

          <div class="homes-footer">
            ^HOMES · 안정적인 복구를 위해 에러 정보를 최소한으로 표시합니다.
          </div>

        </div>
      </div>
    </main>
  </div>

  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
