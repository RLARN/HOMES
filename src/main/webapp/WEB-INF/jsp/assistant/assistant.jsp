<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!doctype html>
<html lang="ko">
<head>
  <%@ include file="/WEB-INF/jsp/common/head.jsp" %>
  <style>
    /* ── iOS 키보드 대응: position:fixed 기반 전체 고정 레이아웃 ── */
    html, body { height: 100%; margin: 0; overflow: hidden; }

    .homes-topbar { position: fixed !important; top: 0; left: 0; right: 0; z-index: 1030; }

    .homes-shell {
      position: fixed;
      top: 56px; left: 0; right: 0; bottom: 0;
      display: flex;
      overflow: hidden;
    }

    .homes-sidebar            { min-height: 0 !important; }
    #homesSidebar.offcanvas-lg { height: 100% !important; }

    .homes-main {
      flex: 1; min-width: 0;
      display: flex; flex-direction: column;
      overflow: hidden;
      padding: 12px 16px;
    }
    @media (min-width: 768px) { .homes-main { padding: 16px 24px; } }

    /* ── 채팅 카드 ── */
    .chat-wrap {
      flex: 1; min-height: 0;
      display: flex; flex-direction: column;
      overflow: hidden;
    }

    .chat-messages {
      flex: 1; min-height: 0;
      overflow-y: auto;
      -webkit-overflow-scrolling: touch;
      padding: 16px 20px;
      display: flex; flex-direction: column;
      gap: 14px;
    }

    /* ── 말풍선 ── */
    .chat-bubble {
      padding: 10px 14px;
      border-radius: 18px;
      line-height: 1.55;
      word-break: break-word;
      white-space: pre-wrap;
      font-size: 14px;
    }
    @media (max-width: 767px) { .chat-bubble { font-size: 13px; } }

    .chat-bubble.user {
      align-self: flex-end;
      max-width: 78%;
      background: #1e40af; color: #fff;
      border-bottom-right-radius: 4px;
    }

    /* AI 행 */
    .ai-row { display: flex; align-items: flex-start; gap: 9px; max-width: 82%; }
    .ai-avatar {
      flex-shrink: 0;
      width: 28px; height: 28px; border-radius: 50%;
      background: linear-gradient(135deg, #1e3a8a, #3b82f6);
      display: flex; align-items: center; justify-content: center;
      color: #fff; font-size: 12px; font-weight: 800;
      margin-top: 2px;
      box-shadow: 0 2px 6px rgba(30,58,138,.22);
    }
    .ai-row .chat-bubble {
      background: #fff;
      border: 1px solid rgba(17,24,39,.09);
      box-shadow: 0 2px 8px rgba(16,24,40,.05);
      border-bottom-left-radius: 4px;
    }

    /* 진행 상태 행 */
    .process-row {
      display: flex; align-items: center; gap: 9px;
      padding: 0 2px;
    }
    .process-avatar {
      width: 28px; height: 28px; border-radius: 50%;
      background: linear-gradient(135deg, #1e3a8a, #3b82f6);
      display: flex; align-items: center; justify-content: center;
      color: #fff; font-size: 12px; font-weight: 800;
      flex-shrink: 0;
    }
    .process-content {
      display: flex; flex-direction: column; gap: 4px;
    }
    .process-step {
      display: flex; align-items: center; gap: 6px;
      font-size: 12px; color: #6b7280;
      animation: fadeIn .2s ease;
    }
    .process-step.active { color: #1e40af; font-weight: 500; }
    .process-step.done   { color: #16a34a; }
    .process-step svg    { flex-shrink: 0; }
    @keyframes fadeIn { from { opacity:0; transform: translateY(4px); } to { opacity:1; transform:none; } }

    /* 생각 중 dots */
    .thinking-dots { display: flex; gap: 4px; align-items: center; padding: 3px 0; }
    .thinking-dots span {
      width: 6px; height: 6px; border-radius: 50%; background: #cbd5e1;
      animation: dot-up 1.4s ease-in-out infinite;
    }
    .thinking-dots span:nth-child(2) { animation-delay: .18s; }
    .thinking-dots span:nth-child(3) { animation-delay: .36s; }
    @keyframes dot-up {
      0%,60%,100% { transform: translateY(0);    background: #cbd5e1; }
      30%          { transform: translateY(-5px); background: #64748b; }
    }

    /* tool 배지 */
    .tool-badge {
      margin-left: 37px;
      align-self: flex-start;
      font-size: 11px; color: #6b7280;
      padding: 2px 9px; background: #f3f4f6; border-radius: 999px;
      margin-top: -6px;
    }

    /* ── 입력창 ── */
    .chat-input-bar {
      flex-shrink: 0;
      border-top: 1px solid rgba(17,24,39,.08); background: #fff;
      padding: 10px 14px;
      padding-bottom: max(10px, env(safe-area-inset-bottom));
      display: flex; gap: 8px; align-items: flex-end;
    }
    .chat-input-bar textarea {
      flex: 1; resize: none;
      border-radius: 22px; border: 1px solid rgba(17,24,39,.18);
      padding: 9px 14px; font-size: 16px; line-height: 1.5;
      max-height: 110px; overflow-y: auto; background: #f9fafb;
      transition: border-color .15s, background .15s, box-shadow .15s;
    }
    .chat-input-bar textarea:focus {
      outline: none; background: #fff;
      border-color: #1e40af; box-shadow: 0 0 0 3px rgba(30,64,175,.1);
    }
    #sendBtn {
      flex-shrink: 0; width: 40px; height: 40px; border-radius: 50%;
      padding: 0; display: flex; align-items: center; justify-content: center;
    }
    #sendBtn svg { width: 18px; height: 18px; fill: currentColor; }
  </style>
</head>
<body class="homes-bg">

  <%@ include file="/WEB-INF/jsp/common/header.jsp" %>

  <div class="homes-shell d-lg-flex">
    <%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

    <main class="homes-main flex-grow-1">
      <div class="chat-wrap card homes-card overflow-hidden">

        <div class="px-4 py-3 border-bottom d-flex align-items-center gap-2" style="flex-shrink:0;">
          <div class="homes-badge">AI</div>
          <div>
            <div class="fw-semibold">^HOMES AI Assistant</div>
            <div class="text-muted small">입금요청 조회·결재 등 HOMES 작업을 요청하세요.</div>
          </div>
        </div>

        <div class="chat-messages" id="chatMessages"></div>

        <div class="chat-input-bar">
          <textarea id="chatInput" rows="1" placeholder="무엇이든 물어보세요…"></textarea>
          <button class="btn btn-primary" id="sendBtn" onclick="sendMessage()" title="전송">
            <svg viewBox="0 0 24 24"><path d="M2.01 21L23 12 2.01 3 2 10l15 2-15 2z"/></svg>
          </button>
        </div>
      </div>
    </main>
  </div>

  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
  <script>
  window.HOMES = window.HOMES || {};
  HOMES.ctx = '${pageContext.request.contextPath}';

  let chatHistory = [];
  let isProcessing = false;

  const messagesEl = document.getElementById('chatMessages');
  const inputEl    = document.getElementById('chatInput');
  const sendBtn    = document.getElementById('sendBtn');

  // ── iOS 키보드: visual viewport 기준으로 shell 위치 재계산 ──────────────────
  (function () {
    if (!window.visualViewport) return;
    const shell = document.querySelector('.homes-shell');
    function adjust() {
      const vv    = window.visualViewport;
      const top   = Math.max(56, vv.offsetTop + 56);
      const h     = vv.height - (top - vv.offsetTop);
      shell.style.top    = top + 'px';
      shell.style.height = h + 'px';
    }
    window.visualViewport.addEventListener('resize', adjust);
    window.visualViewport.addEventListener('scroll', adjust);
  })();

  // 초기 메시지
  appendAiBubble('안녕하세요! ^HOMES 어시스턴트입니다. 무엇을 도와드릴까요?\n입금요청 목록 조회, 결재 처리 등을 도와드릴 수 있어요.');

  // Enter 전송
  inputEl.addEventListener('keydown', e => {
    if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendMessage(); }
  });
  inputEl.addEventListener('input', function () {
    this.style.height = 'auto';
    this.style.height = Math.min(this.scrollHeight, 110) + 'px';
  });

  // ── 전송 & SSE ──────────────────────────────────────────────────────────────

  async function sendMessage() {
    const text = inputEl.value.trim();
    if (!text || isProcessing) return;

    inputEl.value = ''; inputEl.style.height = 'auto';
    isProcessing = true; sendBtn.disabled = true;

    appendUserBubble(text);

    // 진행 상태 UI 생성
    const { processRowEl, addStep, removeProcess } = createProcessRow();

    try {
      const res = await fetch(HOMES.ctx + '/assistant/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ message: text, history: chatHistory })
      });

      const reader  = res.body.getReader();
      const decoder = new TextDecoder();
      let   buffer  = '';

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        buffer += decoder.decode(value, { stream: true });

        const parts = buffer.split('\n\n');
        buffer = parts.pop();

        for (const part of parts) {
          const line = part.split('\n').find(l => l.startsWith('data:'));
          if (!line) continue;
          let event;
          try { event = JSON.parse(line.slice(5).trim()); } catch { continue; }
          handleSseEvent(event, addStep, removeProcess);
        }
      }
    } catch (e) {
      removeProcess();
      appendAiBubble('네트워크 오류: ' + e.message);
    } finally {
      isProcessing = false; sendBtn.disabled = false;
      inputEl.focus();
    }
  }

  function handleSseEvent(event, addStep, removeProcess) {
    switch (event.type) {
      case 'status':
        addStep(event.message, 'active');
        break;
      case 'tool_start':
        addStep('🔧 ' + event.label + '…', 'active');
        break;
      case 'tool_end':
        addStep('✓ ' + event.label, 'done');
        break;
      case 'done_data':
        removeProcess();
        if (event.toolsUsed && event.toolsUsed.length > 0) {
          const nm = { list_deposit_requests:'목록 조회', get_deposit_detail:'상세 조회',
                       approve_deposit:'결재 처리', delete_deposit:'항목 삭제' };
          appendToolBadge('🔧 ' + event.toolsUsed.map(t => nm[t]||t).join(' · '));
        }
        appendAiBubble(event.reply, true);
        chatHistory = event.history || chatHistory;
        break;
      case 'error':
        removeProcess();
        appendAiBubble('오류: ' + event.message);
        break;
    }
  }

  // ── DOM 생성 헬퍼 ─────────────────────────────────────────────────────────

  function appendUserBubble(text) {
    const div = document.createElement('div');
    div.className = 'chat-bubble user';
    div.textContent = text;
    messagesEl.appendChild(div);
    scrollBottom();
  }

  async function appendAiBubble(text, typewrite = false) {
    const row    = document.createElement('div');  row.className = 'ai-row';
    const avatar = document.createElement('div');  avatar.className = 'ai-avatar'; avatar.textContent = '✦';
    const bubble = document.createElement('div');  bubble.className = 'chat-bubble';
    row.appendChild(avatar); row.appendChild(bubble);
    messagesEl.appendChild(row);

    if (typewrite) { await typeText(bubble, text); }
    else           { bubble.textContent = text; scrollBottom(); }
  }

  function appendToolBadge(label) {
    const div = document.createElement('div');
    div.className = 'tool-badge'; div.textContent = label;
    messagesEl.appendChild(div);
  }

  function createProcessRow() {
    const row     = document.createElement('div'); row.className = 'process-row';
    const avatar  = document.createElement('div'); avatar.className = 'process-avatar'; avatar.textContent = '✦';
    const content = document.createElement('div'); content.className = 'process-content';

    // 초기: 점 애니메이션
    const dotsDiv = document.createElement('div'); dotsDiv.className = 'thinking-dots';
    dotsDiv.innerHTML = '<span></span><span></span><span></span>';
    content.appendChild(dotsDiv);

    row.appendChild(avatar); row.appendChild(content);
    messagesEl.appendChild(row);
    scrollBottom();

    let dotRemoved = false;

    function addStep(label, state) {
      if (!dotRemoved) { dotsDiv.remove(); dotRemoved = true; }
      const step = document.createElement('div');
      step.className = 'process-step ' + (state || '');
      step.textContent = label;
      content.appendChild(step);
      scrollBottom();
    }

    function removeProcess() {
      row.remove();
    }

    return { processRowEl: row, addStep, removeProcess };
  }

  // ── 타자 효과 ─────────────────────────────────────────────────────────────

  async function typeText(el, text) {
    const chunkSize = Math.max(1, Math.ceil(text.length / 90));
    for (let i = 0; i < text.length; i += chunkSize) {
      el.textContent += text.slice(i, i + chunkSize);
      scrollBottom();
      await new Promise(r => setTimeout(r, 14));
    }
  }

  function scrollBottom() { messagesEl.scrollTop = messagesEl.scrollHeight; }
  </script>
</body>
</html>
