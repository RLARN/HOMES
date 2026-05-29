<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
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
              <a class="btn btn-outline-light homes-pill px-3" href="${pageContext.request.contextPath}/note/form">새 글 작성</a>
            </div>
          </div>
        </div>
      </div>

      <div class="card homes-card mb-4">
        <div class="card-header bg-transparent border-0 pt-3 px-3 px-md-4">
          <div class="fw-semibold">오늘의 한 줄</div>
        </div>
        <div class="card-body pt-2 px-3 px-md-4">
          <div class="homes-quote">
            “<c:out value="${dailyQuote}" />”
          </div>
          <div class="small text-muted mt-2">
            AI가 오늘을 위한 문장을 추천했어요.
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
                  <div class="small text-muted">전월 대비 <span class="text-success fw-semibold">12% 증가</span></div>
                </div>
                <div class="homes-badge">Budget</div>
              </div>
            </div>
          </div>
        </div>

        <div class="col-12 col-md-6 col-xl-3">
          <div class="card homes-card">
            <div class="card-body">
              <div class="d-flex align-items-start justify-content-between">
                <div>
                  <div class="text-muted small">결재 대기</div>
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
                  <div class="text-muted small">총 자산</div>
                  <div class="h4 mb-1 fw-bold">8,223,000,000 KRW</div>
                  <div class="small text-muted">전월 대비 <span class="text-success fw-semibold">21% 증가</span></div>
                </div>
                <div class="homes-badge">Asset</div>
              </div>
            </div>
          </div>
        </div>
        <div class="col-12 col-md-6 col-xl-3">
          <div class="card homes-card">
            <div class="card-body">
              <div class="d-flex align-items-start justify-content-between">
                <div>
                  <div class="text-muted small">연간 자산 증가율</div>
                  <div class="h4 mb-1 fw-bold">21.38%</div>
                  <div class="small text-muted">전년 대비 <span class="text-success fw-semibold">424,000,000 KRW 증가</span></div>
                </div>
                <div class="homes-badge">Asset</div>
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
                  <div class="h4 mb-1 fw-bold">3</div>
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
                  <div class="text-muted small">새 메모</div>
                  <div class="h4 mb-1 fw-bold">1</div>
                  <div class="small text-muted">오늘 작성</div>
                </div>
                <div class="homes-badge">note</div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <!-- Photo Gallery -->
      <div class="card homes-card mt-3 mb-4">
        <div class="card-header bg-transparent border-0 pt-3 px-3 px-md-4">
          <div class="d-flex align-items-center justify-content-between">
            <div class="fw-semibold">가족 앨범</div>
            <a class="small text-decoration-none" href="#">전체보기</a>
          </div>
        </div>

        <div class="card-body pt-2 px-3 px-md-4">
          <div class="row g-3 homes-gallery">
            <div class="col-6 col-md-3">
              <a href="/main/1.jpg" class="homes-gallery-item" target="_blank">
                <img src="/main/1.jpg" alt="gallery-1">
              </a>
            </div>

            <div class="col-6 col-md-3">
              <a href="/main/2.jpg" class="homes-gallery-item" target="_blank">
                <img src="/main/2.jpg" alt="gallery-2">
              </a>
            </div>

            <div class="col-6 col-md-3">
              <a href="/main/3.jpg" class="homes-gallery-item" target="_blank">
                <img src="/main/3.jpg" alt="gallery-3">
              </a>
            </div>

            <div class="col-6 col-md-3">
              <a href="/main/4.jpg" class="homes-gallery-item" target="_blank">
                <img src="/main/4.jpg" alt="gallery-4">
              </a>
            </div>
          </div>
          <div class="small text-muted mt-3">
            최근 사진 4장을 미리보기로 보여줘요. (추후 업로드/앨범 기능으로 확장 가능)
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
                <a class="small text-decoration-none" href="${pageContext.request.contextPath}/note/list">전체보기</a>
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
                <button class="btn btn-outline-secondary homes-pill"
                        type="button"
                        onclick="location.href='${pageContext.request.contextPath}/note/form'">
                  메모 남기기
                </button>
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

  <style>
    <%--갤러리 css--%>
    .homes-gallery-item{
      display:block;
      border-radius: 16px;
      overflow:hidden;
      background: rgba(255,255,255,.06);
      border: 1px solid rgba(255,255,255,.08);
      box-shadow: 0 6px 18px rgba(0,0,0,.08);
      transition: transform .18s ease, box-shadow .18s ease, border-color .18s ease;
    }
    .homes-gallery-item img{
      width:100%;
      height:140px;
      object-fit: cover;
      display:block;
      filter: saturate(1.02);
    }
    @media (min-width: 768px){
      .homes-gallery-item img{ height: 150px; }
    }
    @media (min-width: 1200px){
      .homes-gallery-item img{ height: 250px; }
    }
    .homes-gallery-item:hover{
      transform: translateY(-2px);
      border-color: rgba(255,255,255,.18);
      box-shadow: 0 10px 24px rgba(0,0,0,.14);
    }
  </style>
</body>
</html>
