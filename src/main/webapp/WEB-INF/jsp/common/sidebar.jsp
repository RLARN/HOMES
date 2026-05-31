<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<div class="offcanvas-lg offcanvas-start homes-sidebar" tabindex="-1" id="homesSidebar">
  <div class="offcanvas-header d-lg-none">
    <h5 class="offcanvas-title">메뉴</h5>
    <button type="button" class="btn-close" aria-label="Close"
            onclick="bootstrap.Offcanvas.getOrCreateInstance(document.getElementById('homesSidebar')).hide()"></button>
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
        <button class="homes-global-search-btn" type="submit" title="검색" aria-label="검색">
          <span class="material-symbols-rounded" style="font-size:17px;">search</span>
        </button>
      </form>
    </div>

    <div class="p-3 pt-2 homes-sidebar-content">
<%--      <div class="homes-nav-title">MODULES</div>--%>
      <div class="list-group list-group-flush homes-nav">
        <%-- ✅ 구현완료 --%>

          <div class="homes-nav-title">Workspace</div>
          <a class="list-group-item list-group-item-action" href="${pageContext.request.contextPath}/main">
            <span class="ms-icon material-symbols-rounded">dashboard</span><span>대시보드</span>
          </a>
          <a class="list-group-item list-group-item-action" href="${pageContext.request.contextPath}/assistant">
            <span class="ms-icon material-symbols-rounded">grid_view</span><span>H-Ops AI</span>
          </a>
          <a class="list-group-item list-group-item-action" href="${pageContext.request.contextPath}/note/list">
            <span class="ms-icon material-symbols-rounded">sticky_note_2</span><span>공유메모</span>
          </a>
          <a class="list-group-item list-group-item-action" href="${pageContext.request.contextPath}/dms">
            <span class="ms-icon material-symbols-rounded">folder_shared</span><span>공유드라이브</span>
          </a>
          <a class="list-group-item list-group-item-action" href="${pageContext.request.contextPath}/calendar/google">
            <span class="ms-icon material-symbols-rounded">calendar_month</span><span>구글 캘린더</span>
          </a>
          <a class="list-group-item list-group-item-action" href="${pageContext.request.contextPath}/sns">
            <span class="ms-icon material-symbols-rounded">photo_library</span><span>가족 앨범</span>
          </a>

          <div class="homes-nav-title">Asset</div>
          <a class="list-group-item list-group-item-action"
             href="https://docs.google.com/spreadsheets/d/1mUF5QvNkLow8y-xjSDED4If45ZMQQ7pv15HZL2IyQfM/edit?pli=1&amp;gid=1146901647#gid=1146901647"
             target="_blank" rel="noopener noreferrer">
            <span class="ms-icon material-symbols-rounded">table_chart</span><span>자산계획관리(엑셀)</span>
          </a>
          <a class="list-group-item list-group-item-action" href="${pageContext.request.contextPath}/asset/ledger">
            <span class="ms-icon material-symbols-rounded">account_balance</span><span>자산원장관리</span>
          </a>
          <a class="list-group-item list-group-item-action" href="${pageContext.request.contextPath}/asset/loan">
            <span class="ms-icon material-symbols-rounded">credit_score</span><span>대출원장관리</span>
          </a>
          <a class="list-group-item list-group-item-action" href="${pageContext.request.contextPath}/asset/expense">
            <span class="ms-icon material-symbols-rounded">payments</span><span>정기지출관리</span>
          </a>
          <a class="list-group-item list-group-item-action" href="${pageContext.request.contextPath}/asset/income">
            <span class="ms-icon material-symbols-rounded">savings</span><span>정기수입관리</span>
          </a>
          <a class="list-group-item list-group-item-action" href="${pageContext.request.contextPath}/asset/costcenter">
            <span class="ms-icon material-symbols-rounded">manage_accounts</span><span>수지계정관리</span>
          </a>
          <a class="list-group-item list-group-item-action" href="${pageContext.request.contextPath}/asset/costcenter/status">
            <span class="ms-icon material-symbols-rounded">bar_chart</span><span>수지계정현황</span>
          </a>
          <a class="list-group-item list-group-item-action" href="${pageContext.request.contextPath}/asset/change">
            <span class="ms-icon material-symbols-rounded">trending_up</span><span>자산변동현황</span>
          </a>
          <a class="list-group-item list-group-item-action" href="${pageContext.request.contextPath}/asset/forecast">
            <span class="ms-icon material-symbols-rounded">show_chart</span><span>자산변동예상</span>
          </a>
          <a class="list-group-item list-group-item-action" href="${pageContext.request.contextPath}/financial/statement">
            <span class="ms-icon material-symbols-rounded">receipt_long</span><span>재무제표명세서</span>
          </a>
          <a class="list-group-item list-group-item-action disabled" href="#">
            <span class="ms-icon material-symbols-rounded">apartment</span>
            <span>센트레빌입주관리 <span class="badge bg-secondary ms-1" style="font-size:10px;">준비중</span></span>
          </a>

          <div class="homes-nav-title">Budget</div>
          <a class="list-group-item list-group-item-action" href="${pageContext.request.contextPath}/living/budget">
            <span class="ms-icon material-symbols-rounded">tune</span><span>생활비기준정보설정</span>
          </a>
          <a class="list-group-item list-group-item-action" href="${pageContext.request.contextPath}/living/expense">
            <span class="ms-icon material-symbols-rounded">shopping_cart</span><span>생활비관리</span>
          </a>
          <a class="list-group-item list-group-item-action" href="${pageContext.request.contextPath}/living/cashflow">
            <span class="ms-icon material-symbols-rounded">currency_exchange</span><span>수기현금흐름</span>
          </a>
          <a class="list-group-item list-group-item-action" href="${pageContext.request.contextPath}/scm/deposit/depositRequest">
            <span class="ms-icon material-symbols-rounded">request_quote</span><span>입금요청</span>
          </a>


      </div>

      <div class="homes-nav-title mt-4">QUICK</div>
      <div class="d-grid gap-2">
        <%-- 🚧 구매요청 미구현
        <button class="btn btn-light homes-quick-btn" type="button" disabled>+ 구매요청 (준비중)</button>
        --%>
        <button class="btn btn-outline-light homes-quick-btn-outline d-flex align-items-center justify-content-center gap-2" type="button"
		        onclick="HOMES.go('${pageContext.request.contextPath}/scm/deposit/depositRequest')">
          <span class="material-symbols-rounded" style="font-size:18px;">add_card</span>입금요청
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
	   사이드바 메뉴 아이콘/텍스트 정렬 (전 해상도 공통)
	========================= */
	.homes-nav .list-group-item {
	  display: flex;
	  align-items: center;
	  gap: 10px;
	  white-space: nowrap;
	  overflow: hidden;
	}

	.homes-nav .list-group-item > *:last-child {
	  min-width: 0;
	  overflow: hidden;
	  text-overflow: ellipsis;
	  white-space: nowrap;
	}

	@media (min-width: 992px) {
	  .homes-sidebar {
	    width: 280px;
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

	/* 사이드바 메뉴 아이콘 */
	.ms-icon {
	  font-size: 18px;
	  flex: 0 0 18px;
	  line-height: 1;
	  font-variation-settings: 'FILL' 1, 'wght' 400, 'GRAD' 0, 'opsz' 20;
	  opacity: .85;
	}
	.homes-nav .list-group-item.active .ms-icon { opacity: 1; }
	.homes-nav .list-group-item:hover .ms-icon { opacity: 1; }

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
    /* ── 검색 폼 ─────────────────────────────────────────── */
    const form  = document.getElementById('homesGlobalSearchForm');
    const input = document.getElementById('homesGlobalSearchInput');
    if (form && input) {
      form.addEventListener('submit', function (e) {
        e.preventDefault();
        const keyword = input.value.trim();
        if (!keyword) return;
        HOMES.go('${pageContext.request.contextPath}/assistant?search=' + encodeURIComponent(keyword));
      });
    }

    /* ── 사이드바 내부 링크 → HOMES.go() 명시 처리 ───────────
       전역 capture 리스너가 Bootstrap offcanvas 내부에서
       e.defaultPrevented 로 인해 무시되는 경우를 방어.
       DOMContentLoaded 이후 Bootstrap 로드가 완료된 시점에 실행. */
    document.addEventListener('DOMContentLoaded', function () {
      const sidebar = document.getElementById('homesSidebar');
      if (!sidebar) return;

      sidebar.querySelectorAll('a[href]').forEach(function (link) {
        const href = link.getAttribute('href');
        /* 빈 앵커, 외부 링크, _blank 는 기본 동작 유지 */
        if (!href || href === '#' || href.startsWith('#')) return;
        if (link.getAttribute('target') === '_blank')       return;
        if (/^https?:\/\//i.test(href))                     return;

        link.addEventListener('click', function (e) {
          e.preventDefault();
          e.stopPropagation();   /* 전역 capture 리스너 중복 방지 */

          /* 모바일 오프캔버스가 열려 있으면 먼저 닫기 */
          try {
            if (window.bootstrap) {
              const bsOff = bootstrap.Offcanvas.getInstance(sidebar);
              if (bsOff) bsOff.hide();
            }
          } catch (_) {}

          HOMES.go(href);
        });
      });
    });
  })();
</script>
