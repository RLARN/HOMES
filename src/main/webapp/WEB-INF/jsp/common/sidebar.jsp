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

      <form class="mt-3 homes-global-search" id="homesGlobalSearchForm">
        <input class="form-control form-control-sm homes-search"
               id="homesGlobalSearchInput"
               type="search"
               placeholder="통합검색">
        <button class="homes-global-search-btn" type="submit" title="검색" aria-label="검색">↑</button>
      </form>
    </div>

    <div class="p-3 pt-2 homes-sidebar-content">
<%--      <div class="homes-nav-title">MODULES</div>--%>
      <div class="list-group list-group-flush homes-nav">
        <%-- ✅ 구현완료 --%>

          <div class="homes-nav-title">Workspace</div>
          <a class="list-group-item list-group-item-action" href="${pageContext.request.contextPath}/main">대시보드</a>
        <a class="list-group-item list-group-item-action" href="${pageContext.request.contextPath}/assistant">AI Assistant</a>
        <a class="list-group-item list-group-item-action" href="${pageContext.request.contextPath}/note/list">공유메모</a>
        <a class="list-group-item list-group-item-action disabled" href="#">DMS (증명서) <span class="badge bg-secondary ms-1" style="font-size:10px;">준비중</span></a>
        <a class="list-group-item list-group-item-action disabled" href="#">구글 캘린더 <span class="badge bg-secondary ms-1" style="font-size:10px;">준비중</span></a>
        <a class="list-group-item list-group-item-action disabled" href="#">가족 앨범(SNS) <span class="badge bg-secondary ms-1" style="font-size:10px;">준비중</span></a>


          <div class="homes-nav-title">Asset</div>
          <a class="list-group-item list-group-item-action"
             href="https://docs.google.com/spreadsheets/d/1mUF5QvNkLow8y-xjSDED4If45ZMQQ7pv15HZL2IyQfM/edit?pli=1&amp;gid=1146901647#gid=1146901647"
             target="_blank"
             rel="noopener noreferrer">자산계획관리(엑셀)</a>
        <a class="list-group-item list-group-item-action disabled" href="#">자산원장관리 <span class="badge bg-secondary ms-1" style="font-size:10px;">준비중</span></a><%--자산 등록--%>
        <a class="list-group-item list-group-item-action disabled" href="#">대출원장관리 <span class="badge bg-secondary ms-1" style="font-size:10px;">준비중</span></a><%--대출자산 등록--%>
        <a class="list-group-item list-group-item-action disabled" href="#">정기지출관리 <span class="badge bg-secondary ms-1" style="font-size:10px;">준비중</span></a><%--정기지출 등록--%>
        <a class="list-group-item list-group-item-action disabled" href="#">정기수입관리 <span class="badge bg-secondary ms-1" style="font-size:10px;">준비중</span></a><%--정기수입 등록--%>
        <a class="list-group-item list-group-item-action disabled" href="#">유동자산현황 <span class="badge bg-secondary ms-1" style="font-size:10px;">준비중</span></a><%--유동자산 현황 뷰 --%>
        <a class="list-group-item list-group-item-action disabled" href="#">부동자산현황 <span class="badge bg-secondary ms-1" style="font-size:10px;">준비중</span></a><%--부동자산 현황 뷰 --%>
        <a class="list-group-item list-group-item-action disabled" href="#">자산변동현황 <span class="badge bg-secondary ms-1" style="font-size:10px;">준비중</span></a><%--자산변동 그래프 뷰 --%>
        <a class="list-group-item list-group-item-action disabled" href="#">자산변동예상 <span class="badge bg-secondary ms-1" style="font-size:10px;">준비중</span></a><%--자산변동 예상그래프 뷰--%>
        <a class="list-group-item list-group-item-action disabled" href="#">센트레빌입주관리 <span class="badge bg-secondary ms-1" style="font-size:10px;">준비중</span></a><%--센트레빌 입주시 목표 현금--%>
        <div class="homes-nav-title">Budget</div>
        <a class="list-group-item list-group-item-action disabled" href="#">생활비기준정보설정 <span class="badge bg-secondary ms-1" style="font-size:10px;">준비중</span></a><%--생활비 관련은 안필요할수도--%>
        <a class="list-group-item list-group-item-action disabled" href="#">생활비관리 <span class="badge bg-secondary ms-1" style="font-size:10px;">준비중</span></a><%-- 생활비지출을 입력하거나 입금요청에서 선택 --%>
        <a class="list-group-item list-group-item-action disabled" href="#">자산지출관리 <span class="badge bg-secondary ms-1" style="font-size:10px;">준비중</span></a><%-- 자산지출을 입력하거나 입금요청에서 선택 --%>
        <a class="list-group-item list-group-item-action" href="${pageContext.request.contextPath}/scm/deposit/depositRequest">입금요청</a>


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

	.homes-global-search {
	  display: flex;
	  gap: 6px;
	  align-items: center;
	}

	.homes-global-search .homes-search {
	  min-width: 0;
	  flex: 1;
	  font-size: 16px;
	}

	.homes-global-search-btn {
	  flex: 0 0 31px;
	  width: 31px;
	  height: 31px;
	  padding: 0;
	  border: 0;
	  border-radius: 50%;
	  background: #fff;
	  color: #fff;
	  color: #1e40af;
	  box-shadow: 0 6px 16px rgba(15, 23, 42, .18);
	  font-size: 15px;
	  font-weight: 600;
	  line-height: 1;
	  display: inline-flex;
	  align-items: center;
	  justify-content: center;
	}

	.homes-global-search-btn:hover,
	.homes-global-search-btn:focus {
	  background: #eef2ff;
	  outline: none;
	}

</style>
<script>
  (function () {
    const form = document.getElementById('homesGlobalSearchForm');
    const input = document.getElementById('homesGlobalSearchInput');
    if (!form || !input) return;

    form.addEventListener('submit', function (e) {
      e.preventDefault();
      const keyword = input.value.trim();
      if (!keyword) return;
      location.href = '${pageContext.request.contextPath}/assistant?search=' + encodeURIComponent(keyword);
    });
  })();
</script>
