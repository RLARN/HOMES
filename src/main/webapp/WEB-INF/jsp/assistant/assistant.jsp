<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!doctype html>
<html lang="ko">
<head>
  <%@ include file="/WEB-INF/jsp/common/head.jsp" %>
  <style>
    :root {
      --assistant-vh: 100dvh;
      --assistant-input-height: 64px;
    }
    html, body {
      width: 100%;
      height: 100%;
      overflow: hidden !important;
      overscroll-behavior: none;
    }
    body { position: fixed !important; inset: 0; touch-action: manipulation; }
    .homes-topbar { position: fixed; top: 0; left: 0; right: 0; z-index: 1030; height: 56px; }
    .homes-sidebar { min-height: 0 !important; }
    .homes-shell {
      position: fixed;
      top: 56px;
      left: 0;
      right: 0;
      height: calc(var(--assistant-vh) - 56px);
      overflow: hidden;
      display: flex;
    }
    .homes-main {
      min-width: 0;
      min-height: 0;
      flex: 1;
      display: flex;
      padding: 12px;
      overflow: hidden;
    }
    .chat-wrap {
      min-height: 0;
      flex: 1;
      display: flex;
      flex-direction: column;
      overflow: hidden;
      border-radius: 8px;
    }
    .chat-head {
      flex: 0 0 auto;
      padding: 14px 16px;
      border-bottom: 1px solid rgba(17, 24, 39, .08);
      background: #fff;
    }
    .chat-messages {
      min-height: 0;
      flex: 1;
      overflow-y: auto;
      padding: 16px;
      display: flex;
      flex-direction: column;
      gap: 12px;
      overscroll-behavior: contain;
      -webkit-overflow-scrolling: touch;
    }
    .chat-bubble {
      max-width: min(76%, 720px);
      padding: 10px 13px;
      border-radius: 16px;
      font-size: 14px;
      line-height: 1.55;
      white-space: normal;
      word-break: break-word;
    }
    .chat-bubble p { margin: 0 0 8px; }
    .chat-bubble p:last-child { margin-bottom: 0; }
    .chat-bubble ol,
    .chat-bubble ul { margin: 0 0 8px 20px; padding: 0; }
    .chat-bubble li { margin: 3px 0; }
    .chat-bubble code {
      padding: 1px 5px;
      border-radius: 5px;
      background: #f1f5f9;
      font-size: .92em;
    }
    .chat-bubble.user {
      align-self: flex-end;
      color: #fff;
      background: #1e40af;
      border-bottom-right-radius: 5px;
      white-space: pre-wrap;
    }
    .ai-row { display: flex; align-items: flex-start; gap: 9px; }
    .ai-avatar {
      flex: 0 0 28px;
      width: 28px;
      height: 28px;
      border-radius: 50%;
      object-fit: cover;
      background: #fff;
      border: 1px solid rgba(17, 24, 39, .08);
      box-shadow: 0 5px 14px rgba(30, 64, 175, .2);
    }
    .ai-row .chat-bubble {
      color: #111827;
      background: #fff;
      border: 1px solid rgba(17, 24, 39, .09);
      box-shadow: 0 2px 8px rgba(16, 24, 40, .05);
      border-bottom-left-radius: 5px;
    }
    .tool-badge {
      align-self: flex-start;
      margin-left: 37px;
      padding: 4px 10px;
      border-radius: 999px;
      color: #475569;
      background: #eef2ff;
      font-size: 12px;
    }
    .process-row {
      margin-left: 37px;
      max-width: min(76%, 720px);
      padding: 10px 12px;
      border-radius: 14px;
      color: #475569;
      background: #fff;
      border: 1px solid rgba(17, 24, 39, .08);
    }
    .process-step {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 13px;
      line-height: 1.5;
    }
    .process-step + .process-step { margin-top: 5px; }
    .process-dot {
      width: 7px;
      height: 7px;
      border-radius: 50%;
      background: #94a3b8;
    }
    .process-step.active .process-dot {
      background: #2563eb;
      animation: pulse 1s ease-in-out infinite;
    }
    .process-step.idle .process-dot { background: #94a3b8; }
    .process-step.done .process-dot { background: #16a34a; }
    .process-step.error .process-dot { background: #dc2626; }
    @keyframes pulse {
      0%, 100% { transform: scale(.9); opacity: .45; }
      50% { transform: scale(1.35); opacity: 1; }
    }
    .chat-input-bar {
      flex: 0 0 auto;
      display: flex;
      align-items: flex-end;
      gap: 8px;
      padding: 10px;
      border-top: 1px solid rgba(17, 24, 39, .08);
      background: #fff;
    }
    .chat-input-bar textarea {
      min-height: 42px;
      max-height: 120px;
      flex: 1;
      resize: none;
      overflow-y: auto;
      border-radius: 18px;
      border: 1px solid rgba(17, 24, 39, .15);
      background: #fff;
      padding: 10px 13px;
      font-size: 16px;
      line-height: 1.45;
      transition:
        border-color .2s ease,
        background-position .35s ease,
        box-shadow .25s ease;
    }
    .chat-input-bar textarea:focus {
      outline: none;
      border-color: transparent;
      background:
        linear-gradient(#fff, #fff) padding-box,
        linear-gradient(120deg, #38bdf8, #2563eb, #1e3a8a, #38bdf8) border-box;
      background-size: 100% 100%, 220% 220%;
      box-shadow:
        0 0 0 1px rgba(255,255,255,.85) inset,
        0 0 0 3px rgba(56, 189, 248, .13),
        0 0 22px rgba(37, 99, 235, .18),
        0 8px 20px rgba(30, 58, 138, .16);
      animation: homesChatInputAura 2.4s linear infinite;
    }
    @keyframes homesChatInputAura {
      0% { background-position: 0 0, 0% 50%; }
      100% { background-position: 0 0, 220% 50%; }
    }
    .send-btn {
      flex: 0 0 42px;
      width: 42px;
      height: 42px;
      border-radius: 50%;
      border: 0;
      color: #fff;
      background: #1e40af;
      font-size: 18px;
      line-height: 1;
    }
    .send-btn:disabled { opacity: .55; }
    @media (max-width: 767.98px) {
      .homes-main { padding: 0; }
      .chat-wrap { border-radius: 0; border-left: 0; border-right: 0; }
      .chat-head { padding: 11px 13px; }
      .chat-head .small { display: none; }
      .chat-messages { padding: 13px 11px; }
      .chat-input-bar {
        min-height: var(--assistant-input-height);
        padding: 10px 12px calc(26px + env(safe-area-inset-bottom, 0px));
      }
      body.keyboard-open .chat-input-bar { padding-bottom: 10px; }
      .chat-bubble { max-width: 82%; font-size: 13px; padding: 9px 12px; }
      .process-row { max-width: 82%; }
    }
  </style>
</head>
<body class="homes-bg">
  <%@ include file="/WEB-INF/jsp/common/header.jsp" %>

  <div class="homes-shell d-lg-flex" id="assistantShell">
    <%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

    <main class="homes-main">
      <div class="chat-wrap card homes-card">
        <div class="chat-head d-flex align-items-center gap-2">
          <%--<div class="homes-badge">AI</div>--%>
          <div>
            <div class="fw-semibold">H-Ops AI</div>
            <div class="text-muted small">개인 대화와 HOMES 업무 처리를 함께 도와드립니다.</div>
          </div>
        </div>

        <div class="chat-messages" id="chatMessages">
          <div class="ai-row">
            <img class="ai-avatar" src="${pageContext.request.contextPath}/img/homesAI.png" alt="^HOMES AI">
            <div class="chat-bubble"><p>무엇이든 편하게 말해주세요. 조회, 결재, 삭제 같은 HOMES 업무도 처리할 수 있어요.</p></div>
          </div>
        </div>

        <div class="chat-input-bar">
          <textarea id="chatInput" rows="1" placeholder="메시지를 입력하세요"></textarea>
          <button type="button" class="send-btn" id="sendBtn" onclick="sendMessage()">↑</button>
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
  const inputEl = document.getElementById('chatInput');
  const sendBtn = document.getElementById('sendBtn');

  let viewportRaf = 0;
  let largestViewportHeight = window.innerHeight || document.documentElement.clientHeight || 0;

  function syncViewport() {
    const vv = window.visualViewport;
    const layoutHeight = window.innerHeight || document.documentElement.clientHeight;
    const viewportHeight = vv ? vv.height : layoutHeight;
    const keyboardOffset = vv ? Math.max(0, layoutHeight - vv.height - vv.offsetTop) : 0;
    largestViewportHeight = Math.max(largestViewportHeight, viewportHeight);
    const focusedInput = document.activeElement === inputEl;
    const keyboardOpen = focusedInput && (keyboardOffset > 80 || largestViewportHeight - viewportHeight > 120);

    document.documentElement.style.setProperty('--assistant-vh', Math.max(320, viewportHeight) + 'px');
    document.body.classList.toggle('keyboard-open', keyboardOpen);
  }

  function requestViewportSync() {
    if (viewportRaf) return;
    viewportRaf = window.requestAnimationFrame(function () {
      viewportRaf = 0;
      syncViewport();
    });
  }

  if (window.visualViewport) {
    window.visualViewport.addEventListener('resize', requestViewportSync);
  }
  window.addEventListener('resize', requestViewportSync);
  syncViewport();

  window.addEventListener('orientationchange', function () {
    setTimeout(syncViewport, 250);
  });

  inputEl.addEventListener('touchstart', function (e) {
    if (document.activeElement === inputEl) return;
    e.preventDefault();
    inputEl.focus({ preventScroll: true });
    requestViewportSync();
  }, { passive: false });

  inputEl.addEventListener('focus', function () {
    resetPageScroll();
    requestViewportSync();
    setTimeout(scrollBottom, 120);
  });

  inputEl.addEventListener('blur', function () {
    setTimeout(syncViewport, 120);
  });

  inputEl.addEventListener('keydown', function (e) {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  });

  inputEl.addEventListener('input', function () {
    this.style.height = 'auto';
    this.style.height = Math.min(this.scrollHeight, 120) + 'px';
  });

  const initialSearch = new URLSearchParams(window.location.search).get('search');
  if (initialSearch && initialSearch.trim()) {
    window.setTimeout(function () {
      inputEl.value = '통합검색 : ' + initialSearch.trim();
      inputEl.dispatchEvent(new Event('input'));
      sendMessage();
    }, 250);
  }

  async function sendMessage() {
    const text = inputEl.value.trim();
    if (!text || isProcessing) return;

    inputEl.value = '';
    inputEl.style.height = 'auto';
    isProcessing = true;
    sendBtn.disabled = true;

    appendUserBubble(text);
    const process = createProcessRow();

    try {
      const res = await fetch(HOMES.ctx + '/assistant/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Accept': 'text/event-stream' },
        body: JSON.stringify({ message: text, history: chatHistory })
      });

      const reader = res.body.getReader();
      const decoder = new TextDecoder('utf-8');
      let buffer = '';

      /* SSE 라인 단위 파싱 — \n\n 기준 대신 \n 기준으로 처리해서
         연속 이벤트가 한 청크로 오거나, 스트림 종료 직전 \n\n이 없어도 안전하게 처리 */
      function flushBuffer(text) {
        text.split('\n').forEach(line => {
          if (!line.startsWith('data:')) return;
          const payload = line.slice(5).trim();
          if (!payload) return;
          try {
            handleSseEvent(JSON.parse(payload), process);
          } catch (e) {
            process.addStep('응답 해석 실패: ' + e.message, 'error');
          }
        });
      }

      while (true) {
        const { done, value } = await reader.read();
        if (done) {
          /* 스트림 종료 시 남은 버퍼 반드시 처리 (마지막 이벤트 유실 방지) */
          if (buffer.trim()) flushBuffer(buffer);
          break;
        }
        buffer += decoder.decode(value, { stream: true });
        /* 완전한 줄만 처리하고, 마지막 불완전 줄은 다음 청크를 위해 보존 */
        const nlIdx = buffer.lastIndexOf('\n');
        if (nlIdx === -1) continue;
        flushBuffer(buffer.slice(0, nlIdx));
        buffer = buffer.slice(nlIdx + 1);
      }
    } catch (e) {
      process.remove();
      appendAiBubble('네트워크 오류: ' + e.message);
    } finally {
      isProcessing = false;
      sendBtn.disabled = false;
    }
  }

  function handleSseEvent(event, process) {
    switch (event.type) {
      case 'status':
        process.addStep(event.message, 'active');
        break;
      case 'tool_start':
        process.addStep(event.label + ' 실행 중', 'active');
        break;
      case 'tool_end':
        process.finishActive(event.label + ' 완료');
        break;
      case 'tool_error':
        process.failActive(event.label + ' 오류: ' + event.message);
        break;
      case 'done_data':
        process.remove();
        if (event.toolsUsed && event.toolsUsed.length > 0) {
          const names = {
            global_search: '전체 검색',
            list_deposit_requests: '입금요청 목록 조회',
            get_deposit_detail: '입금요청 상세 조회',
            insert_deposit_request: '입금요청 등록',
            insert_note: '공유메모 등록',
            update_note: '공유메모 수정',
            approve_deposit: '입금요청 결재',
            delete_deposit: '입금요청 삭제'
          };
          appendToolBadge(event.toolsUsed.map(t => names[t] || t).join(' · '));
        }
        appendAiBubble(event.reply, true);
        chatHistory = event.history || chatHistory;
        break;
      case 'error':
        process.remove();
        appendAiBubble('오류: ' + event.message);
        break;
    }
  }

  function appendUserBubble(text) {
    const div = document.createElement('div');
    div.className = 'chat-bubble user';
    div.textContent = text;
    messagesEl.appendChild(div);
    scrollBottom();
  }

  async function appendAiBubble(text, typewrite) {
    const row = document.createElement('div');
    row.className = 'ai-row';
    const avatar = document.createElement('img');
    avatar.className = 'ai-avatar';
    avatar.src = HOMES.ctx + '/img/homesAI.png';
    avatar.alt = '^HOMES AI';
    const bubble = document.createElement('div');
    bubble.className = 'chat-bubble';
    row.appendChild(avatar);
    row.appendChild(bubble);
    messagesEl.appendChild(row);

    if (typewrite) await typeText(bubble, text || '');
    else {
      renderMarkdown(bubble, text || '');
      scrollBottom();
    }
  }

  function appendToolBadge(label) {
    const div = document.createElement('div');
    div.className = 'tool-badge';
    div.textContent = label;
    messagesEl.appendChild(div);
    scrollBottom();
  }

  function createProcessRow() {
    const box = document.createElement('div');
    box.className = 'process-row';
    messagesEl.appendChild(box);
    scrollBottom();

    return {
      addStep(label, state) {
        if (state === 'active') {
          box.querySelectorAll('.process-step.active').forEach(item => {
            item.classList.remove('active');
            item.classList.add('idle');
          });
        }
        const step = document.createElement('div');
        step.className = 'process-step ' + state;
        step.innerHTML = '<span class="process-dot"></span><span></span>';
        step.lastChild.textContent = label;
        box.appendChild(step);
        scrollBottom();
      },
      finishActive(label) {
        const activeSteps = box.querySelectorAll('.process-step.active');
        const active = activeSteps[activeSteps.length - 1];
        if (!active) {
          this.addStep(label, 'done');
          return;
        }
        this.addStep(label, 'done');
      },
      failActive(label) {
        const activeSteps = box.querySelectorAll('.process-step.active');
        const active = activeSteps[activeSteps.length - 1];
        if (!active) {
          this.addStep(label, 'error');
          return;
        }
        this.addStep(label, 'error');
      },
      remove() {
        if (box.parentNode) box.parentNode.removeChild(box);
      }
    };
  }

  async function typeText(el, text) {
    el.textContent = '';
    const chunkSize = text.length > 400 ? 3 : 1;
    for (let i = 0; i < text.length; i += chunkSize) {
      el.textContent += text.slice(i, i + chunkSize);
      scrollBottom();
      await new Promise(resolve => setTimeout(resolve, 12));
    }
    renderMarkdown(el, text);
    scrollBottom();
  }

  function renderMarkdown(el, text) {
    const lines = escapeHtml(text || '').split('\n');
    let html = '';
    let inOl = false;
    let inUl = false;

    lines.forEach(line => {
      const ordered = line.match(/^(\d+)\.\s+(.+)$/);
      const unordered = line.match(/^[-*]\s+(.+)$/);

      if (ordered) {
        if (inUl) { html += '</ul>'; inUl = false; }
        if (!inOl) { html += '<ol>'; inOl = true; }
        html += '<li>' + inlineMarkdown(ordered[2]) + '</li>';
        return;
      }

      if (unordered) {
        if (inOl) { html += '</ol>'; inOl = false; }
        if (!inUl) { html += '<ul>'; inUl = true; }
        html += '<li>' + inlineMarkdown(unordered[1]) + '</li>';
        return;
      }

      if (inOl) { html += '</ol>'; inOl = false; }
      if (inUl) { html += '</ul>'; inUl = false; }
      html += line.trim() ? '<p>' + inlineMarkdown(line) + '</p>' : '<br>';
    });

    if (inOl) html += '</ol>';
    if (inUl) html += '</ul>';
    el.innerHTML = html;
  }

  function inlineMarkdown(text) {
    return text
      .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
      .replace(/`(.+?)`/g, '<code>$1</code>');
  }

  function escapeHtml(text) {
    return text
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }

  function scrollBottom() {
    messagesEl.scrollTop = messagesEl.scrollHeight;
  }

  function resetPageScroll() {
    document.documentElement.scrollTop = 0;
    document.body.scrollTop = 0;
    if (window.scrollY !== 0) window.scrollTo(0, 0);
  }

  </script>
</body>
</html>
