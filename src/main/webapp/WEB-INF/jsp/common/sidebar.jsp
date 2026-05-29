<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<div class="offcanvas-lg offcanvas-start homes-sidebar" tabindex="-1" id="homesSidebar">
  <div class="offcanvas-header d-lg-none">
    <h5 class="offcanvas-title">메뉴</h5>
    <button type="button" class="btn-close" data-bs-dismiss="offcanvas" aria-label="Close"></button>
  </div>

  <div class="offcanvas-body p-0">
    <div class="homes-sidebar-header">
      <div class="d-flex align-items-center gap-2">
        <!--<img src="${pageContext.request.contextPath}/assets/logo/logo-homes-icon.png" alt="^" class="homes-logo-icon">-->
        <div>
          <div class="text-white fw-semibold">♡ 애콩이네 하우뜨 ♡</div>
          <div class="text-white-50 small">Home Organization &amp; Synergy</div>
        </div>
      </div>

      <div class="mt-3">
        <input class="form-control form-control-sm homes-search" type="search" placeholder="통합검색 (준비중)">
      </div>
    </div>

    <div class="p-3 pt-2 homes-sidebar-content">
      <div class="homes-nav-title">MODULES</div>
      <div class="list-group list-group-flush homes-nav">
        <%-- ✅ 구현완료 --%>
        <a class="list-group-item list-group-item-action" href="${pageContext.request.contextPath}/main">대시보드</a>
        <a class="list-group-item list-group-item-action" href="${pageContext.request.contextPath}/scm/deposit/depositRequest">입금요청</a>
        <a class="list-group-item list-group-item-action" href="${pageContext.request.contextPath}/assistant">AI Assistant</a>
        <%-- 🚧 미구현 (준비중)        --%>
        <a class="list-group-item list-group-item-action disabled" href="#">자산관리 <span class="badge bg-secondary ms-1" style="font-size:10px;">준비중</span></a>
        <a class="list-group-item list-group-item-action disabled" href="#">DMS (증명서) <span class="badge bg-secondary ms-1" style="font-size:10px;">준비중</span></a>
        <a class="list-group-item list-group-item-action disabled" href="#">구글 캘린더 <span class="badge bg-secondary ms-1" style="font-size:10px;">준비중</span></a>
        <a class="list-group-item list-group-item-action disabled" href="#">공유메모 <span class="badge bg-secondary ms-1" style="font-size:10px;">준비중</span></a>
        <a class="list-group-item list-group-item-action disabled" href="#">가족 앨범(SNS) <span class="badge bg-secondary ms-1" style="font-size:10px;">준비중</span></a>
        <a class="list-group-item list-group-item-action disabled" href="#">통합검색 <span class="badge bg-secondary ms-1" style="font-size:10px;">준비중</span></a>

      </div>

      <div class="homes-nav-title mt-4">QUICK</div>
      <div class="d-grid gap-2">
        <%-- 🚧 구매요청 미구현
        <button class="btn btn-light homes-quick-btn" type="button" disabled>+ 구매요청 (준비중)</button>
        --%>
        <button class="btn btn-outline-light homes-quick-btn-outline" type="button"
		        onclick="location.href='${pageContext.request.contextPath}/scm/deposit/depositRequest'">
		  + 입금요청
		</button>
      </div>
      <div class="small text-white-50 mt-4">Power by eksystems</div>
      <%--<div class="small text-white-50 mt-4">© 2026 eksystems. All rights reserved.</div>--%>
    </div>
  </div>
</div>
<style>
	/* =========================
	   Responsive
	========================= */
	@media (max-width: 991.98px) {
	  .homes-sidebar {
	    min-height: auto;
	  }
	}

	/* =========================
	   ⭐ PC 사이드바 메뉴 줄바꿈 문제 해결 ⭐
	========================= */
	@media (min-width: 992px) {

	  /* 사이드바 폭 확보 (원하면 값 조절 가능) */
	  .homes-sidebar {
	    width: 280px;
	  }

	  /* 메뉴 한 줄 유지 + 말줄임 */
	  .homes-nav .list-group-item {
	    display: flex;
	    align-items: center;
	    gap: 10px;
	    white-space: nowrap;
	    overflow: hidden;
	  }

	  /* 아이콘 + 텍스트 구조 대비 */
	  .homes-nav .list-group-item > *:last-child {
	    min-width: 0;
	    overflow: hidden;
	    text-overflow: ellipsis;
	    white-space: nowrap;
	  }
	}
	
	.homes-footer {
	  border-top: 1px solid rgba(17, 24, 39, .08);
	  background: rgba(255,255,255,.72);
	  backdrop-filter: blur(8px);
	}

	/* ✅ 메인영역 하단 고정 */
	.homes-footer-fixed{
	  position: sticky;     /* fixed 말고 sticky! */
	  bottom: 0;
	  z-index: 10;
	}

</style>