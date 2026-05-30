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
      <a class="btn btn-sm btn-outline-light homes-pill homes-ai-btn"
         href="${pageContext.request.contextPath}/assistant"
         title="AI Assistant">H-Ops AI</a>

      <!-- 알림 구독 버튼 -->
      <button id="pushBellBtn"
              class="btn btn-sm btn-outline-light homes-pill"
              type="button"
              title="알림 설정"
              onclick="HOMES_PUSH.toggleSubscription(this)"
              style="font-size:16px; min-width:38px;display: none">
        🔔
      </button>

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
        /*overflow-y: hidden;,/* 이거땜에 모바일에서 푸터 고정안됨 */

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
	.homes-ai-btn {
	  position: relative;
	  isolation: isolate;
	  overflow: hidden;
	  color: #fff !important;
	  border-color: rgba(255,255,255,.38);
	  background:
	    linear-gradient(135deg, rgba(255,255,255,.18), rgba(255,255,255,.05)),
	    linear-gradient(135deg, #1d4ed8 0%, #1e3a8a 46%, #0e7490 100%);
	  box-shadow:
	    0 0 0 1px rgba(255,255,255,.08) inset,
	    0 8px 18px rgba(14, 116, 144, .18),
	    0 4px 10px rgba(30, 58, 138, .24);
	  transition:
	    color .2s ease,
	    border-color .2s ease,
	    background-position .35s ease,
	    box-shadow .25s ease,
	    transform .25s ease;
	}
	.homes-ai-btn::before {
	  content: "";
	  position: absolute;
	  inset: -1px;
	  z-index: -2;
	  background: linear-gradient(120deg, #38bdf8, #2563eb, #1e3a8a, #38bdf8);
	  background-size: 220% 220%;
	  opacity: .58;
	  transition: opacity .25s ease, filter .25s ease;
	}
	.homes-ai-btn::after {
	  content: "";
	  position: absolute;
	  top: -60%;
	  bottom: -60%;
	  left: -45%;
	  width: 38%;
	  z-index: -1;
	  background: linear-gradient(90deg, transparent, rgba(255,255,255,.48), transparent);
	  transform: translateX(-130%) rotate(18deg);
	  transition: transform .55s cubic-bezier(.2,.8,.2,1);
	}
	.homes-ai-btn:hover,
	.homes-ai-btn:focus-visible {
	  color: #fff !important;
	  border-color: rgba(255,255,255,.72);
	  transform: translateY(-1px);
	  box-shadow:
	    0 0 0 1px rgba(255,255,255,.18) inset,
	    0 0 22px rgba(56, 189, 248, .34),
	    0 10px 24px rgba(30, 58, 138, .38);
	}
	.homes-ai-btn:hover::before,
	.homes-ai-btn:focus-visible::before {
	  opacity: .92;
	  filter: saturate(1.25);
	  animation: homesAiAura 2.4s linear infinite;
	}
	.homes-ai-btn:hover::after,
	.homes-ai-btn:focus-visible::after {
	  transform: translateX(420%) rotate(18deg);
	}
	.homes-ai-btn:active {
	  color: #fff !important;
	  transform: translateY(0);
	  box-shadow:
	    0 0 0 1px rgba(255,255,255,.20) inset,
	    0 4px 12px rgba(30, 58, 138, .30);
	}
	@keyframes homesAiAura {
	  0% { background-position: 0% 50%; }
	  100% { background-position: 220% 50%; }
	}

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

    /* 모바일 */
    @media (max-width: 991.98px) {
        html, body {
            overflow-y: auto;
        }
        /*일단 푸터 숨김*/
        footer {
            display: none !important;
        }
    }


    /* ✅ PC에서 사이드바: 헤더(워크스페이스/검색) 위 고정 + 아래 메뉴만 스크롤 */
	@media (min-width: 992px) {
        html, body {
            overflow-y: auto;
            /*스크롤 풀기*/
        }
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

	.homes-section-label {
	  font-size: 11px;
	  font-weight: 700;
	  letter-spacing: 0.14em;
	  color: #6b7280;
	  text-transform: uppercase;
	  margin-bottom: 10px;
	}
</style>

<script>
/**
 * Web Push 구독/해제 관리
 */
window.HOMES_PUSH = (function () {

  function urlBase64ToUint8Array(base64String) {
    const padding = '='.repeat((4 - base64String.length % 4) % 4);
    const base64  = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/');
    const raw     = window.atob(base64);
    return Uint8Array.from([...raw].map(c => c.charCodeAt(0)));
  }

  async function getSubscription() {
    if (!('serviceWorker' in navigator) || !('PushManager' in window)) return null;
    const reg = await navigator.serviceWorker.ready;
    return reg.pushManager.getSubscription();
  }

  async function updateBellUI(btn) {
    if (!btn) return;
    const sub = await getSubscription();
    if (sub) {
      btn.textContent = '🔔';
      btn.title = '알림 구독 중 (클릭: 해제)';
      btn.classList.remove('btn-outline-light');
      btn.classList.add('btn-light');
    } else {
      btn.textContent = '🔕';
      btn.title = '알림 구독하기';
      btn.classList.remove('btn-light');
      btn.classList.add('btn-outline-light');
    }
  }

  async function subscribe() {
    const reg     = await navigator.serviceWorker.ready;
    const vapidKey = window.HOMES_VAPID_PUBLIC_KEY;
    if (!vapidKey) { alert('VAPID 키가 없습니다. 서버를 확인하세요.'); return; }

    const sub = await reg.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: urlBase64ToUint8Array(vapidKey)
    });

    const json = sub.toJSON();
    await fetch('/push/subscribe', {
      method:  'POST',
      headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
      body:    JSON.stringify({ endpoint: json.endpoint, keys: json.keys })
    });
  }

  async function unsubscribe() {
    const sub = await getSubscription();
    if (sub) await sub.unsubscribe();
    await fetch('/push/unsubscribe', {
      method:  'DELETE',
      headers: { 'Accept': 'application/json' }
    });
  }

  async function toggleSubscription(btn) {
    if (!('Notification' in window)) {
      alert('이 브라우저는 알림을 지원하지 않습니다.');
      return;
    }

    try {
      const existing = await getSubscription();
      if (existing) {
        await unsubscribe();
      } else {
        const permission = await Notification.requestPermission();
        if (permission !== 'granted') {
          alert('알림 권한이 거부되었습니다.\n브라우저 설정에서 허용해 주세요.');
          return;
        }
        await subscribe();
      }
      updateBellUI(btn);
    } catch (e) {
      console.error('[PUSH]', e);
      alert('알림 설정 중 오류가 발생했습니다: ' + e.message);
    }
  }

  // 페이지 로드 시 벨 아이콘 상태 초기화
  document.addEventListener('DOMContentLoaded', function () {
    updateBellUI(document.getElementById('pushBellBtn'));
  });

  return { toggleSubscription };
})();
</script>
