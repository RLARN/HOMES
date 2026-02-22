<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<meta charset="UTF-8">
<nav class="navbar navbar-expand-lg navbar-dark homes-topbar sticky-top">
  <div class="container-fluid px-3">

    <button class="btn btn-outline-light d-lg-none me-2" type="button"
            data-bs-toggle="offcanvas" data-bs-target="#homesSidebar">
      ☰
    </button>

    <a class="navbar-brand d-flex align-items-center gap-2"
       href="${pageContext.request.contextPath}/main">
<!--      <img src="${pageContext.request.contextPath}/assets/logo/logo-homes-icon.png"alt="^HOMES" class="homes-logo-icon">-->
      <span class="fw-semibold">^HOMES</span>
    </a>

    <div class="ms-auto d-flex align-items-center gap-2">
      <div class="dropdown">
		<button class="btn btn-sm btn-light homes-pill dropdown-toggle"
		        type="button"
		        data-bs-toggle="dropdown">
		  ${sessionScope.LoginVO.userNm} 님
		</button>
        <ul class="dropdown-menu dropdown-menu-end">
          <li><a class="dropdown-item" href="#">프로필</a></li>
          <li><a class="dropdown-item" href="#">설정</a></li>
          <li><hr class="dropdown-divider"></li>
          <li><a class="dropdown-item text-danger" href="${pageContext.request.contextPath}/logout">로그아웃</a></li>
        </ul>
      </div>
    </div>

  </div>
</nav>
<style>
	/* =========================
	   Global
	========================= */
	* { box-sizing: border-box; }
	html, body {
		overflow-y: hidden;,/* 이거땜에 모바일에서 푸터 고정안됨 */
		 height: 100%;
	 
	  }
	body { font-family: "Pretendard", system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif; }
	.homes-bg { background: #f6f8fb; }

	/* ✅ 레이아웃 고정(PC에서 흰 여백 제거 핵심) */
	/*.homes-shell { min-height: 100vh; }*/
/*	.homes-main { min-width: 0; }  flex overflow 깨짐 방지 */

	/* =========================
	   Topbar
	========================= */
	.homes-topbar {
	  background: linear-gradient(135deg, #1e3a8a, #1e40af);
	  border-bottom: 1px solid rgba(255,255,255,.12);
	}
	.homes-pill { border-radius: 999px; }
	.homes-logo-icon { width: 28px; height: 28px; object-fit: contain; }

	/* =========================
	   Sidebar
	========================= */
	.homes-sidebar {
	  background: linear-gradient(135deg, #1e3a8a, #1e40af);
	  color: #fff;
	  min-height: calc(100vh - 56px);
	  border-right: 1px solid rgba(255,255,255,.12);
	}
	.homes-sidebar-header {
	  padding: 18px 16px 16px 16px;
	  border-bottom: 1px solid rgba(255,255,255,.14);
	}
	.homes-search {
	  border-radius: 999px;
	  border: 1px solid rgba(255,255,255,.25);
	  background: rgba(255,255,255,.12);
	  color: #fff;
	}
	.homes-search::placeholder { color: rgba(255,255,255,.70); }
	.homes-search:focus {
	  box-shadow: 0 0 0 2px rgba(255,255,255,.18);
	  border-color: rgba(255,255,255,.45);
	}
	.homes-nav-title {
	  font-size: 11px;
	  letter-spacing: .12em;
	  color: rgba(255,255,255,.65);
	  margin: 10px 2px 8px;
	}
	.homes-nav .list-group-item {
	  border: 0;
	  border-radius: 12px;
	  margin-bottom: 6px;
	  background: rgba(255,255,255,.10);
	  color: rgba(255,255,255,.92);
	}
	.homes-nav .list-group-item:hover { background: rgba(255,255,255,.16); color: #fff; }
	.homes-nav .list-group-item.active { background: rgba(255,255,255,.92); color: #1e3a8a; font-weight: 700; }

	.homes-quick-btn { border-radius: 16px; font-weight: 700; }
	.homes-quick-btn-outline { border-radius: 16px; border-color: rgba(255,255,255,.55); color: #fff; }
	.homes-quick-btn-outline:hover { background: rgba(255,255,255,.14); border-color: rgba(255,255,255,.70); color: #fff; }

	/* ✅ PC에서 사이드바: 헤더(워크스페이스/검색) 위 고정 + 아래 메뉴만 스크롤 */
	@media (min-width: 992px) {
	  #homesSidebar.offcanvas-lg{
	    position: sticky;
	    top: 56px; /* header.jsp topbar 높이(기본 56px). 다르면 숫자만 바꿔 */
	    height: calc(100vh - 56px);

	    flex: 0 0 280px;
	    width: 280px;

	    transform: none !important;
	    visibility: visible !important;
	  }

	  #homesSidebar .offcanvas-body{
	    height: 100%;
	    display: flex;
	    flex-direction: column;
	  }

	  /* sidebar.jsp에서 메뉴 영역 div에 homes-sidebar-content 넣어둔 전제 */
	  #homesSidebar .homes-sidebar-header { flex: 0 0 auto; }
	  #homesSidebar .homes-sidebar-content { flex: 1 1 auto; overflow-y: auto; }

	  /* 메뉴 텍스트 줄바꿈 방지 + 말줄임 */
	  #homesSidebar .homes-nav .list-group-item{
	    white-space: nowrap;
	    overflow: hidden;
	    text-overflow: ellipsis;
	  }
	}

	/* =========================
	   Main cards
	========================= */
	.homes-card { border: 0; border-radius: 18px; box-shadow: 0 10px 26px rgba(16, 24, 40, 0.06); }
	.homes-badge {
	  font-size: 11px;
	  letter-spacing: .12em;
	  padding: 6px 10px;
	  border-radius: 999px;
	  background: rgba(30, 58, 138, 0.10);
	  color: #1e3a8a;
	  font-weight: 800;
	}

	/* =========================
	   Hero
	========================= */
	.homes-hero {
	  border-radius: 22px;
	  background: linear-gradient(135deg, #1e3a8a, #1e40af);
	  overflow: hidden;
	  box-shadow: 0 16px 34px rgba(30, 64, 175, .18);
	}
	.homes-kicker {
	  display: inline-block;
	  font-size: 11px;
	  letter-spacing: .14em;
	  color: rgba(255,255,255,.70);
	  margin-bottom: 10px;
	}
	.homes-empty {
	  border: 1px dashed rgba(17, 24, 39, .18);
	  border-radius: 16px;
	  padding: 16px;
	  color: #111827;
	  background: rgba(255,255,255,.70);
	}
	.homes-quote { font-size: 16px; font-weight: 800; color: #111827; }
</style>