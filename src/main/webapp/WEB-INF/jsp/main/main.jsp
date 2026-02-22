<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!doctype html>
<html lang="ko">
<head>
  <%@ include file="/WEB-INF/jsp/common/head.jsp" %>
</head>

<body class="homes-bg">

  <%@ include file="/WEB-INF/jsp/common/header.jsp" %>

  <!-- ✅ PC에서 "사이드바 + 메인"을 확실히 2컬럼으로 고정 (흰 여백/깨짐 방지) -->
  <div class="homes-shell d-lg-flex">

    <!-- Sidebar -->
    <%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

    <!-- Main content -->
    <main class="homes-main flex-grow-1 px-3 px-md-4 py-4">

      <!-- Hero -->
      <div class="homes-hero card border-0 mb-4">
        <div class="card-body p-4 p-md-5">
          <div class="d-flex flex-column flex-md-row align-items-md-center justify-content-between gap-3">
            <div>
              <div class="homes-kicker">WELCOME BACK</div>
              <h1 class="h3 mb-2 fw-bold text-white">오늘도 가족의 하루를 정리해볼까요?</h1>
              <div class="text-white-50">
                입금요청, 일정, 메모, 추억까지 한 곳에서.
              </div>
            </div>
            <div class="d-flex gap-2">
              <a class="btn btn-light homes-pill px-3" href="#">오늘 일정 보기</a>
              <a class="btn btn-outline-light homes-pill px-3" href="#">새 글 작성</a>
            </div>
          </div>
        </div>
      </div>

      <!-- KPI cards -->
      <div class="row g-3 mb-4">
        <div class="col-12 col-md-6 col-xl-3">
          <div class="card homes-card">
            <div class="card-body">
              <div class="d-flex align-items-start justify-content-between">
                <div>
                  <div class="text-muted small">이번달 입금 요청 금액</div>
				  <div class="h4 mb-1 fw-bold">
				    <fmt:formatNumber value="${requestedTotal}" pattern="#,##0" />원
				  </div>
                  <div class="small text-muted">전월 대비 <span class="text-success fw-semibold">0%</span></div>
                </div>
                <div class="homes-badge">ASSET</div>
              </div>
            </div>
          </div>
        </div>

        <div class="col-12 col-md-6 col-xl-3">
          <div class="card homes-card">
            <div class="card-body">
              <div class="d-flex align-items-start justify-content-between">
                <div>
                  <div class="text-muted small">입금요청 대기</div>
                  <div class="h4 mb-1 fw-bold">${requestedStandbyCount}</div>
                  <div class="small text-muted">처리 필요</div>
                </div>
                <div class="homes-badge">APPROVAL</div>
              </div>
            </div>
          </div>
        </div>

        <div class="col-12 col-md-6 col-xl-3">
          <div class="card homes-card">
            <div class="card-body">
              <div class="d-flex align-items-start justify-content-between">
                <div>
                  <div class="text-muted small">이번주 일정</div>
                  <div class="h4 mb-1 fw-bold">0</div>
                  <div class="small text-muted">Google 연동 예정</div>
                </div>
                <div class="homes-badge">CAL</div>
              </div>
            </div>
          </div>
        </div>

        <div class="col-12 col-md-6 col-xl-3">
          <div class="card homes-card">
            <div class="card-body">
              <div class="d-flex align-items-start justify-content-between">
                <div>
                  <div class="text-muted small">새 메모/게시글</div>
                  <div class="h4 mb-1 fw-bold">0</div>
                  <div class="small text-muted">오늘 작성</div>
                </div>
                <div class="homes-badge">BOARD</div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Content rows -->
      <div class="row g-3">
        <!-- Left: Recent activities -->
        <div class="col-12 col-xl-8">
          <div class="card homes-card">
            <div class="card-header bg-transparent border-0 pt-3 px-3 px-md-4">
              <div class="d-flex align-items-center justify-content-between">
                <div class="fw-semibold">최근 활동</div>
                <a class="small text-decoration-none" href="#">전체보기</a>
              </div>
            </div>

            <div class="card-body pt-2 px-3 px-md-4">
              <div class="homes-empty">
                아직 기록된 활동이 없어요. <span class="text-muted">(+ 구매요청 / 새 글 작성)</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Right: Quick panel -->
        <div class="col-12 col-xl-4">
          <div class="card homes-card mb-3">
            <div class="card-header bg-transparent border-0 pt-3 px-3 px-md-4">
              <div class="fw-semibold">빠른 입력</div>
            </div>

            <div class="card-body pt-2 px-3 px-md-4">
              <div class="d-grid gap-2">
                <button class="btn btn-primary homes-pill" type="button">구매요청 작성</button>
				<button class="btn btn-outline-primary homes-pill"
				        type="button"
				        onclick="location.href='${pageContext.request.contextPath}/scm/deposit/depositRequest'">
				  입금요청 작성
				</button>
                <button class="btn btn-outline-secondary homes-pill" type="button">메모 남기기</button>
              </div>
            </div>
          </div>

          <div class="card homes-card">
            <div class="card-header bg-transparent border-0 pt-3 px-3 px-md-4">
              <div class="fw-semibold">오늘의 한 줄</div>
            </div>

            <div class="card-body pt-2 px-3 px-md-4">
              <div class="homes-quote">
                “작게 정리하면, 크게 편해진다.”
              </div>
              <div class="small text-muted mt-2">
                (나중에 AI가 추천 문구/가계부 요약도 가능)
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="py-4 small text-muted">
        <!--^HOMES · Home Organization &amp; Management for Enhanced Synergy-->
      </div>
	  <%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
    </main>
  </div>

  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

  <!-- ✅ style은 main.jsp에 그대로 둔다 -->
  <style>
	
  </style>
</body>
</html>
