<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!doctype html>
<html lang="ko">
<head>
  <%@ include file="/WEB-INF/jsp/common/head.jsp" %>
  <style>
    .calendar-main {
      min-width: 0;
      min-height: calc(100vh - 56px);
      padding: 18px;
    }

    .calendar-panel {
      min-height: calc(100vh - 92px);
      display: flex;
      flex-direction: column;
      overflow: hidden;
      border-radius: 8px;
      background: #fff;
      box-shadow: 0 10px 26px rgba(16, 24, 40, 0.06);
    }

    .calendar-toolbar {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      padding: 16px 18px;
      border-bottom: 1px solid rgba(17, 24, 39, .08);
    }

    .calendar-title {
      font-size: 18px;
      font-weight: 800;
      color: #111827;
    }

    .calendar-actions {
      display: flex;
      gap: 8px;
      flex-wrap: wrap;
      justify-content: flex-end;
    }

    .calendar-content {
      flex: 1;
      min-height: 0;
      padding: 18px;
      overflow: auto;
      background:
        radial-gradient(circle at 12% 16%, rgba(56, 189, 248, .08), transparent 26%),
        linear-gradient(180deg, #fff, #f8fafc);
    }

    .calendar-state {
      padding: 14px 16px;
      border-radius: 8px;
      border: 1px solid rgba(30, 58, 138, .12);
      background: rgba(255,255,255,.76);
      color: #475569;
    }

    .calendar-list {
      display: grid;
      gap: 10px;
      margin-top: 14px;
    }

    .calendar-event {
      display: grid;
      grid-template-columns: minmax(104px, 140px) 1fr;
      gap: 14px;
      padding: 14px;
      border: 1px solid rgba(17, 24, 39, .08);
      border-radius: 8px;
      background: rgba(255,255,255,.86);
      box-shadow: 0 6px 16px rgba(16, 24, 40, .04);
    }

    .calendar-event-time {
      color: #1e3a8a;
      font-size: 13px;
      font-weight: 800;
      line-height: 1.45;
    }

    .calendar-event-title {
      color: #111827;
      font-weight: 800;
      word-break: break-word;
    }

    .calendar-event-meta {
      margin-top: 4px;
      color: #64748b;
      font-size: 13px;
      word-break: break-word;
    }

    .calendar-config-code {
      margin-top: 10px;
      padding: 12px;
      border-radius: 8px;
      background: #0f172a;
      color: #dbeafe;
      font-size: 13px;
      white-space: pre-wrap;
    }

    @media (max-width: 767.98px) {
      .calendar-main { padding: 0; }
      .calendar-panel {
        min-height: calc(100vh - 56px);
        border-radius: 0;
      }
      .calendar-toolbar {
        align-items: flex-start;
        flex-direction: column;
      }
      .calendar-actions {
        width: 100%;
        justify-content: flex-start;
      }
      .calendar-event {
        grid-template-columns: 1fr;
      }
    }
  </style>
</head>
<body class="homes-bg">
  <%@ include file="/WEB-INF/jsp/common/header.jsp" %>

  <div class="homes-shell d-lg-flex">
    <%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

    <main class="calendar-main flex-grow-1">
      <section class="calendar-panel">
        <div class="calendar-toolbar">
          <div>
            <div class="calendar-title">구글 캘린더</div>
            <div class="text-muted small">Google Calendar API로 불러온 내 일정</div>
          </div>
          <div class="calendar-actions">
            <button class="btn btn-primary homes-pill px-3" type="button" id="googleAuthorizeBtn" disabled>구글 연결</button>
            <button class="btn btn-outline-primary homes-pill px-3 d-none" type="button" id="googleRefreshBtn">새로고침</button>
            <button class="btn btn-outline-secondary homes-pill px-3 d-none" type="button" id="googleSignoutBtn">연결 해제</button>
          </div>
        </div>

        <div class="calendar-content">
          <div class="calendar-state" id="calendarStatus">구글 캘린더 연동을 준비하고 있습니다.</div>
          <div class="calendar-list" id="calendarList"></div>
        </div>
      </section>
    </main>
  </div>

  <script>
    const GOOGLE_CALENDAR_CLIENT_ID = '${googleCalendarClientId}';
    const GOOGLE_CALENDAR_API_KEY = '${googleCalendarApiKey}';
    const GOOGLE_CALENDAR_DISCOVERY_DOC = 'https://www.googleapis.com/discovery/v1/apis/calendar/v3/rest';
    const GOOGLE_CALENDAR_SCOPES = 'https://www.googleapis.com/auth/calendar.readonly';

    let googleTokenClient;
    let googleGapiReady = false;
    let googleGisReady = false;

    const authorizeBtn = document.getElementById('googleAuthorizeBtn');
    const refreshBtn = document.getElementById('googleRefreshBtn');
    const signoutBtn = document.getElementById('googleSignoutBtn');
    const statusEl = document.getElementById('calendarStatus');
    const listEl = document.getElementById('calendarList');

    function setStatus(message, tone) {
      statusEl.textContent = message;
      statusEl.classList.toggle('border-danger', tone === 'error');
      statusEl.classList.toggle('text-danger', tone === 'error');
    }

    function hasGoogleConfig() {
      return GOOGLE_CALENDAR_CLIENT_ID && GOOGLE_CALENDAR_API_KEY;
    }

    function showConfigMissing() {
      authorizeBtn.disabled = true;
      statusEl.innerHTML =
        'Google Calendar API 설정값이 필요합니다.' +
        '<div class="calendar-config-code">google.calendar.client-id=YOUR_CLIENT_ID\\n' +
        'google.calendar.api-key=YOUR_API_KEY</div>' +
        '<div class="small mt-2">Google Cloud Console에서 Calendar API를 사용 설정하고, Authorized JavaScript origins에 현재 주소를 등록해주세요.</div>';
    }

    function maybeEnableGoogleCalendar() {
      if (!hasGoogleConfig()) {
        showConfigMissing();
        return;
      }
      if (googleGapiReady && googleGisReady) {
        authorizeBtn.disabled = false;
        setStatus('구글 계정을 연결하면 다가오는 일정을 불러옵니다.');
      }
    }

    window.gapiLoaded = function () {
      gapi.load('client', async function () {
        try {
          await gapi.client.init({
            apiKey: GOOGLE_CALENDAR_API_KEY,
            discoveryDocs: [GOOGLE_CALENDAR_DISCOVERY_DOC]
          });
          googleGapiReady = true;
          maybeEnableGoogleCalendar();
        } catch (error) {
          setStatus('Google API 초기화 실패: ' + (error.message || error.details || error), 'error');
        }
      });
    };

    window.gisLoaded = function () {
      if (!hasGoogleConfig()) {
        googleGisReady = true;
        maybeEnableGoogleCalendar();
        return;
      }
      googleTokenClient = google.accounts.oauth2.initTokenClient({
        client_id: GOOGLE_CALENDAR_CLIENT_ID,
        scope: GOOGLE_CALENDAR_SCOPES,
        callback: ''
      });
      googleGisReady = true;
      maybeEnableGoogleCalendar();
    };

    async function loadUpcomingEvents() {
      setStatus('일정을 불러오는 중입니다...');
      listEl.innerHTML = '';

      try {
        const response = await gapi.client.calendar.events.list({
          calendarId: 'primary',
          timeMin: new Date().toISOString(),
          showDeleted: false,
          singleEvents: true,
          maxResults: 20,
          orderBy: 'startTime'
        });
        renderEvents(response.result.items || []);
      } catch (error) {
        setStatus('일정을 불러오지 못했습니다: ' + (error.message || error.result?.error?.message || error), 'error');
      }
    }

    function renderEvents(events) {
      if (!events.length) {
        setStatus('다가오는 일정이 없습니다.');
        return;
      }

      setStatus(events.length + '개의 다가오는 일정을 불러왔습니다.');
      listEl.innerHTML = events.map(function (event) {
        const start = event.start && (event.start.dateTime || event.start.date);
        const end = event.end && (event.end.dateTime || event.end.date);
        return [
          '<article class="calendar-event">',
          '  <div class="calendar-event-time">' + escapeHtml(formatEventDate(start, end)) + '</div>',
          '  <div>',
          '    <div class="calendar-event-title">' + escapeHtml(event.summary || '(제목 없음)') + '</div>',
          event.location ? '    <div class="calendar-event-meta">' + escapeHtml(event.location) + '</div>' : '',
          event.description ? '    <div class="calendar-event-meta">' + escapeHtml(stripHtml(event.description)) + '</div>' : '',
          '  </div>',
          '</article>'
        ].join('');
      }).join('');
    }

    function formatEventDate(start, end) {
      if (!start) return '시간 미정';
      const options = { month: 'short', day: 'numeric', weekday: 'short', hour: '2-digit', minute: '2-digit' };
      const startDate = new Date(start);
      if (Number.isNaN(startDate.getTime())) return start;
      const startText = startDate.toLocaleString('ko-KR', options);
      if (!end) return startText;
      const endDate = new Date(end);
      if (Number.isNaN(endDate.getTime())) return startText;
      return startText + ' - ' + endDate.toLocaleTimeString('ko-KR', { hour: '2-digit', minute: '2-digit' });
    }

    function stripHtml(value) {
      const div = document.createElement('div');
      div.innerHTML = value;
      return div.textContent || div.innerText || '';
    }

    function escapeHtml(value) {
      return String(value).replace(/[&<>"']/g, function (char) {
        return ({
          '&': '&amp;',
          '<': '&lt;',
          '>': '&gt;',
          '"': '&quot;',
          "'": '&#39;'
        })[char];
      });
    }

    authorizeBtn.addEventListener('click', function () {
      if (!googleTokenClient) return;
      googleTokenClient.callback = async function (response) {
        if (response.error) {
          setStatus('구글 연결 실패: ' + response.error, 'error');
          return;
        }
        authorizeBtn.textContent = '다시 연결';
        refreshBtn.classList.remove('d-none');
        signoutBtn.classList.remove('d-none');
        await loadUpcomingEvents();
      };
      googleTokenClient.requestAccessToken({ prompt: gapi.client.getToken() ? '' : 'consent' });
    });

    refreshBtn.addEventListener('click', loadUpcomingEvents);

    signoutBtn.addEventListener('click', function () {
      const token = gapi.client.getToken();
      if (token) {
        google.accounts.oauth2.revoke(token.access_token);
        gapi.client.setToken('');
      }
      listEl.innerHTML = '';
      authorizeBtn.textContent = '구글 연결';
      refreshBtn.classList.add('d-none');
      signoutBtn.classList.add('d-none');
      setStatus('구글 연결을 해제했습니다.');
    });
  </script>
  <script async defer src="https://apis.google.com/js/api.js" onload="gapiLoaded()"></script>
  <script async defer src="https://accounts.google.com/gsi/client" onload="gisLoaded()"></script>
</body>
</html>
