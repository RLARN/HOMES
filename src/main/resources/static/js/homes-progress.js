/**
 * HOMES UI 유틸리티
 *  1. HOMES.go(url)           — 페이지 전환 오버레이
 *  2. HOMES.aiProgress.show/hide — H-Ops AI 인사이트 로딩 UI (공통 재사용)
 */
(function () {

  /* ═══════════════════════════════════════════════════════════
     1. 페이지 전환 오버레이
  ═══════════════════════════════════════════════════════════ */
  var pageStyle = document.createElement('style');
  pageStyle.textContent = [
    '#homesOverlay {',
    '  display: none;',
    '  position: fixed; inset: 0; z-index: 99999;',
    '  background: rgba(10, 18, 40, 0.52);',
    '  backdrop-filter: blur(3px); -webkit-backdrop-filter: blur(3px);',
    '  align-items: center; justify-content: center;',
    '}',
    '#homesOverlay.is-active { display: flex; }',
    '#homesOverlay .ho-box {',
    '  background: linear-gradient(145deg, #1e3a8a 0%, #1e40af 60%, #1d4ed8 100%);',
    '  border-radius: 24px; padding: 36px 44px;',
    '  display: flex; flex-direction: column; align-items: center; gap: 18px;',
    '  box-shadow: 0 24px 64px rgba(10,18,40,.38), 0 0 0 1px rgba(255,255,255,.10) inset;',
    '}',
    '#homesOverlay .ho-ring {',
    '  width: 48px; height: 48px;',
    '  border: 4px solid rgba(255,255,255,.22);',
    '  border-top-color: #fff; border-radius: 50%;',
    '  animation: hoSpin .72s linear infinite;',
    '}',
    '@keyframes hoSpin { to { transform: rotate(360deg); } }',
    '#homesOverlay .ho-label {',
    '  color: rgba(255,255,255,.88); font-size: 13px;',
    '  font-family: "Pretendard", system-ui, sans-serif;',
    '  font-weight: 500; letter-spacing: .06em;',
    '}',
    /* 헤더 ^HOMES 와 동일한 스타일 */
    '#homesOverlay .ho-brand {',
    '  color: rgba(255,255,255,.92);',
    '  font-family: "Pretendard", system-ui, sans-serif;',
    '  font-size: 15px; font-weight: 600; letter-spacing: .04em;',
    '}',
  ].join('\n');
  document.head.appendChild(pageStyle);

  var overlay = document.createElement('div');
  overlay.id = 'homesOverlay';
  overlay.innerHTML = [
    '<div class="ho-box">',
    '  <div class="ho-ring"></div>',
    '  <div class="ho-label">잠시만 기다려 주세요</div>',
    '  <div class="ho-brand">^HOMES</div>',
    '</div>',
  ].join('');

  document.addEventListener('DOMContentLoaded', function () { document.body.appendChild(overlay); });

  function pageShow() { overlay.classList.add('is-active'); }
  function pageHide() { overlay.classList.remove('is-active'); }

  window.addEventListener('DOMContentLoaded', pageHide);
  window.addEventListener('pageshow', pageHide);

  document.addEventListener('click', function (e) {
    if (e.defaultPrevented) return;
    var el = e.target.closest('a[href]');
    if (!el) return;
    var href = el.getAttribute('href');
    if (!href || href === '' || href === '#' || href.startsWith('#')) return;
    if (href.startsWith('javascript:')) return;
    if (el.target === '_blank') return;
    if (el.hasAttribute('download')) return;
    if (/^https?:\/\//i.test(href)) {
      try { if (new URL(href, location.href).origin !== location.origin) return; } catch (_) { return; }
    }
    pageShow();
  }, true);

  document.addEventListener('submit', function (e) {
    if (e.defaultPrevented) return;
    if (e.target.dataset.noProgress !== undefined) return;
    pageShow();
  }, true);


  /* ═══════════════════════════════════════════════════════════
     2. H-Ops AI 인사이트 로딩 UI
     사용법:
       HOMES.aiProgress.show(document.getElementById('aiLoadingWrap'));
       HOMES.aiProgress.hide(document.getElementById('aiLoadingWrap'));
  ═══════════════════════════════════════════════════════════ */
  var aiStyle = document.createElement('style');
  aiStyle.textContent = [

    /* ── 래퍼 ── */
    '.ho-ai-wrap {',
    '  position: relative; border-radius: 16px; overflow: hidden;',
    '  background: linear-gradient(135deg, #0f172a 0%, #1e3a8a 55%, #1d4ed8 100%);',
    '  padding: 28px 24px 24px;',
    '  display: flex; flex-direction: column; align-items: center; gap: 16px;',
    '}',


    /* ── 브랜드 칩 ── */
    '.ho-ai-chip {',
    '  display: inline-flex; align-items: center;',
    '}',
    '.ho-ai-chip-dot { display: none; }',
    '.ho-ai-chip-label {',
    '  font-size: 18px; font-weight: 600; letter-spacing: .04em;',
    '  color: #fff;',
    '  font-family: "Pretendard", system-ui, sans-serif;',
    '}',

    /* ── 메인 문구 ── */
    '.ho-ai-title {',
    '  font-size: 15px; font-weight: 600; color: #fff;',
    '  font-family: "Pretendard", system-ui, sans-serif;',
    '  letter-spacing: .01em; text-align: center;',
    '}',
    '.ho-ai-sub {',
    '  font-size: 12px; color: rgba(255,255,255,.55);',
    '  font-family: "Pretendard", system-ui, sans-serif;',
    '  text-align: center; margin-top: -8px;',
    '}',
    '.ho-ai-eta {',
    '  font-size: 11px; color: rgba(255,255,255,.35);',
    '  font-family: "Pretendard", system-ui, sans-serif;',
    '  text-align: center; margin-top: -4px; letter-spacing: .01em;',
    '}',

    /* ── 타이핑 도트 ── */
    '.ho-ai-dots { display: flex; gap: 6px; align-items: center; }',
    '.ho-ai-dots span {',
    '  width: 7px; height: 7px; border-radius: 50%;',
    '  background: rgba(255,255,255,.70);',
    '  animation: hoAiDot 1.2s ease-in-out infinite;',
    '}',
    '.ho-ai-dots span:nth-child(2) { animation-delay: .18s; }',
    '.ho-ai-dots span:nth-child(3) { animation-delay: .36s; }',
    '@keyframes hoAiDot {',
    '  0%,80%,100% { transform: scale(.75); opacity: .45; }',
    '  40%         { transform: scale(1.15); opacity: 1; }',
    '}',

    /* ── 하단 진행 바 ── */
    '.ho-ai-bar-wrap {',
    '  width: 100%; height: 4px; border-radius: 4px;',
    '  background: rgba(255,255,255,.12); overflow: hidden;',
    '}',
    '.ho-ai-bar {',
    '  height: 100%; border-radius: 4px;',
    '  background: linear-gradient(90deg, #3b82f6, #60a5fa, #38bdf8);',
    '  animation: hoAiBar 2.2s cubic-bezier(.4,0,.2,1) infinite;',
    '}',
    '@keyframes hoAiBar {',
    '  0%   { width: 0%;   margin-left: 0%; }',
    '  50%  { width: 70%;  margin-left: 15%; }',
    '  100% { width: 0%;   margin-left: 100%; }',
    '}',

  ].join('\n');
  document.head.appendChild(aiStyle);

  function buildAiHtml() {
    return [
      '<div class="ho-ai-wrap">',
      '  <div class="ho-ai-chip">',
      '    <span class="ho-ai-chip-dot"></span>',
      '    <span class="ho-ai-chip-label">^HOMES · H-Ops AI</span>',
      '  </div>',
      '  <div class="ho-ai-title">데이터를 분석하고 있습니다</div>',
      '  <div class="ho-ai-dots"><span></span><span></span><span></span></div>',
      '  <div class="ho-ai-sub">자산 구조와 현금흐름을 기반으로 인사이트를 생성 중이에요.</div>',
    '  <div class="ho-ai-eta">분석 요청 규모에 따라 1~3분 정도 소요될 수 있어요.</div>',
      '  <div class="ho-ai-bar-wrap"><div class="ho-ai-bar"></div></div>',
      '</div>',
    ].join('');
  }

  /* ── 공개 API ───────────────────────────────────────────── */
  window.HOMES = window.HOMES || {};

  window.HOMES.go = function (url) {
    pageShow();
    setTimeout(function () { location.href = url; }, 20);
  };

  /**
   * H-Ops AI 로딩 표시
   * @param {HTMLElement|string} target — 컨테이너 요소 또는 id 문자열
   */
  window.HOMES.aiProgress = {
    show: function (target) {
      var el = typeof target === 'string' ? document.getElementById(target) : target;
      if (!el) return;
      el.innerHTML = buildAiHtml();
      el.style.display = '';
    },
    hide: function (target) {
      var el = typeof target === 'string' ? document.getElementById(target) : target;
      if (!el) return;
      el.style.display = 'none';
      el.innerHTML = '';
    }
  };

})();
