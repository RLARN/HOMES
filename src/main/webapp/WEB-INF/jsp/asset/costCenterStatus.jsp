<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<!doctype html>
<html lang="ko">
<head>
  <%@ include file="/WEB-INF/jsp/common/head.jsp" %>
  <title>수지계정 현황 | HOMES</title>
  <style>
    .cc-stat-card { border-radius: 14px; transition: box-shadow .2s; }
    .cc-stat-card:hover { box-shadow: 0 4px 20px rgba(0,0,0,.1); }
    .balance-positive { color: #10b981; }
    .balance-negative { color: #ef4444; }
    .chart-wrap { position: relative; min-height: 320px; }
    .period-form .form-control { max-width: 160px; }
    .table-status th { font-size: 12px; color: #6b7280; }
    .bar-inline {
      height: 6px; border-radius: 3px;
      background: #e5e7eb; overflow: hidden; margin-top: 3px;
    }
    .bar-inline-fill { height: 100%; border-radius: 3px; }

    /* ── 수지 아코디언 ── */
    .cc-summary-row { cursor: pointer; transition: background .12s; }
    .cc-summary-row:hover { background: #f8fafc !important; }
    .cc-toggle-icon { display: inline-block; width: 14px; font-size: 10px;
                      color: #94a3b8; transition: transform .18s; }
    .cc-toggle-icon.open { transform: rotate(90deg); }
    .cc-detail-row td { background: #fafbfd; font-size: 13px; padding-top: .32rem; padding-bottom: .32rem; }
    .cc-detail-row .sub-label { padding-left: 2.2rem; color: #374151; }
    .cc-detail-row .sub-type  { font-size: 11px; padding: 1px 7px; border-radius: 20px;
                                 font-weight: 500; }
    .type-income  { background: #dcfce7; color: #15803d; }
    .type-expense { background: #fee2e2; color: #b91c1c; }
    .type-saving  { background: #dbeafe; color: #1d4ed8; }
    .type-invest  { background: #fef9c3; color: #a16207; }
    .cc-no-detail { color: #9ca3af; font-style: italic; font-size: 12px; }
    .ai-result-box { font-size:14px; line-height:1.8; background:#f8fafc; border-radius:12px; padding:20px; }
    .ai-result-box strong { color:#1e293b; }
    .ai-result-collapsed { max-height:3.8em; overflow:hidden; position:relative; }
    .ai-result-collapsed::after {
      content:''; position:absolute; bottom:0; left:0; right:0; height:2em;
      background:linear-gradient(transparent, #f8fafc);
    }
    .ai-toggle-btn { font-size:12px; color:#6366f1; cursor:pointer; border:none;
                     background:none; padding:4px 0; display:block; width:100%; text-align:center; }
    .ai-toggle-btn:hover { text-decoration:underline; }
  </style>
</head>
<body class="homes-bg">
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>

<div class="homes-shell d-lg-flex">
  <%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

  <main class="homes-main flex-grow-1 d-flex flex-column">
    <div class="homes-main-body px-3 px-md-4 py-4">

      <!-- 헤더 -->
      <div class="d-flex flex-column flex-md-row align-items-md-center justify-content-between gap-2 mb-3">
        <div>
          <div class="homes-badge mb-2">Asset</div>
          <h1 class="h4 fw-bold mb-1">수지계정 현황</h1>
          <div class="text-muted small">
            수지계정별 수입·지출을 기간별로 분석합니다.
            <c:if test="${not empty dispFrom}">
              &nbsp;|&nbsp;<strong>${dispFrom} ~ ${dispTo}</strong>
            </c:if>
            <c:if test="${hasHst}">
              &nbsp;<span class="badge bg-primary-subtle text-primary border d-inline-flex align-items-center gap-1" style="font-size:11px;"><span class="material-symbols-rounded" style="font-size:12px;font-variation-settings:'FILL' 1,'wght' 400,'GRAD' 0,'opsz' 20;">push_pin</span>전표처리 기준</span>
            </c:if>
            <c:if test="${not hasHst}">
              &nbsp;<span class="badge bg-warning-subtle text-warning border" style="font-size:11px;">⚡ 실시간</span>
            </c:if>
          </div>
        </div>
        <a class="btn btn-outline-secondary homes-pill px-3"
           href="${pageContext.request.contextPath}/asset/costcenter">수지계정 관리</a>
      </div>

      <!-- 기간 선택 폼 -->
      <div class="card homes-card mb-4">
        <div class="card-body py-3">
          <form method="get" action="${pageContext.request.contextPath}/asset/costcenter/status"
                class="d-flex align-items-center gap-3 flex-wrap period-form">
            <label class="fw-semibold mb-0 text-nowrap">기간 선택</label>
            <div class="d-flex align-items-center gap-2">
              <input type="month" class="form-control" name="fromYymm" id="fromYymm"
                     value="${fromYymm.substring(0,4)}-${fromYymm.substring(4,6)}"/>
              <span class="text-muted">~</span>
              <input type="month" class="form-control" name="toYymm" id="toYymm"
                     value="${toYymm.substring(0,4)}-${toYymm.substring(4,6)}"/>
            </div>
            <div class="d-flex gap-2 flex-wrap">
              <button type="submit" class="btn btn-primary homes-pill px-3">조회</button>
              <!-- 빠른 선택 -->
              <button type="button" class="btn btn-outline-secondary btn-sm homes-pill"
                      onclick="setQuick(0,0)">이번달</button>
              <button type="button" class="btn btn-outline-secondary btn-sm homes-pill"
                      onclick="setQuick(-2,0)">3개월</button>
              <button type="button" class="btn btn-outline-secondary btn-sm homes-pill"
                      onclick="setQuick(-5,0)">6개월</button>
              <button type="button" class="btn btn-outline-secondary btn-sm homes-pill"
                      onclick="setQuick(-11,0)">12개월</button>
            </div>
          </form>
        </div>
      </div>

      <div class="card homes-card mb-4" id="aiCard">
        <div class="card-header bg-transparent border-0 pt-3 px-3 px-md-4 pb-0 d-flex align-items-center justify-content-between">
          <span class="fw-semibold">H-Ops AI 분석 리포트</span>
          <button class="btn btn-outline-secondary btn-sm homes-pill" id="aiRetryBtn" onclick="askStatusAI()" style="display:none;">다시 분석</button>
        </div>
        <div class="card-body px-3 px-md-4">
          <div id="aiLoadingWrap"></div>
          <div id="aiResultWrap" class="ai-result-box ai-result-collapsed" style="display:none;"></div>
          <button class="ai-toggle-btn" id="aiToggleBtn" style="display:none;" onclick="toggleAiResult()">전체 보기</button>
        </div>
      </div>

      <!-- 요약 카드 -->
      <div class="row g-3 mb-4">
        <div class="col-6 col-md-3">
          <div class="card homes-card cc-stat-card h-100">
            <div class="card-body text-center">
              <div class="text-muted small mb-1">총 수입</div>
              <div class="fw-bold fs-5 text-success">
                <fmt:formatNumber value="${grandIncome}" pattern="#,##0"/>
                <span class="small">원</span>
              </div>
            </div>
          </div>
        </div>
        <div class="col-6 col-md-3">
          <div class="card homes-card cc-stat-card h-100">
            <div class="card-body text-center">
              <div class="text-muted small mb-1">총 지출</div>
              <div class="fw-bold fs-5 text-danger">
                <fmt:formatNumber value="${grandExpense}" pattern="#,##0"/>
                <span class="small">원</span>
              </div>
            </div>
          </div>
        </div>
        <div class="col-6 col-md-3">
          <div class="card homes-card cc-stat-card h-100">
            <div class="card-body text-center">
              <div class="text-muted small mb-1">순수익 (수입-지출)</div>
              <div class="fw-bold fs-5 ${grandBalance >= 0 ? 'text-success' : 'text-danger'}">
                <c:if test="${grandBalance < 0}">-</c:if>
                <fmt:formatNumber value="${grandBalance < 0 ? -grandBalance : grandBalance}" pattern="#,##0"/>
                <span class="small">원</span>
              </div>
            </div>
          </div>
        </div>
        <div class="col-6 col-md-3">
          <div class="card homes-card cc-stat-card h-100">
            <div class="card-body text-center">
              <div class="text-muted small mb-1">수지계정 수</div>
              <div class="fw-bold fs-5">${statusList.size()} 개</div>
              <div class="text-muted" style="font-size:11px;">활성 기준</div>
            </div>
          </div>
        </div>
      </div>

      <c:choose>
        <c:when test="${empty statusList}">
          <div class="alert alert-info">
            등록된 수지계정가 없습니다.
            <a href="${pageContext.request.contextPath}/asset/costcenter">수지계정 관리</a>에서 추가하세요.
          </div>
        </c:when>
        <c:otherwise>

          <!-- 차트 영역 -->
          <div class="row g-3 mb-4">
            <!-- 막대 차트 -->
            <div class="col-12 col-lg-8">
              <div class="card homes-card h-100">
                <div class="card-header bg-transparent fw-semibold d-flex align-items-center gap-1">
                  <span class="material-symbols-rounded ms-sm">bar_chart</span>수지계정별 수입 vs 지출
                </div>
                <div class="card-body chart-wrap">
                  <canvas id="barChart"></canvas>
                </div>
              </div>
            </div>
            <!-- 도넛 차트 -->
            <div class="col-12 col-lg-4">
              <div class="card homes-card h-100">
                <div class="card-header bg-transparent fw-semibold d-flex align-items-center gap-1">
                  <span class="material-symbols-rounded ms-sm">donut_large</span>지출 비중
                </div>
                <div class="card-body chart-wrap d-flex flex-column align-items-center justify-content-center">
                  <canvas id="donutChart" style="max-height:260px;"></canvas>
                  <div id="donutLegend" class="mt-3 w-100" style="font-size:12px;"></div>
                </div>
              </div>
            </div>
          </div>

          <!-- 수지계정별 상세 테이블 -->
          <div class="card homes-card">
            <div class="card-header bg-transparent fw-semibold d-flex align-items-center gap-1">
              <span class="material-symbols-rounded ms-sm">list_alt</span>수지계정별 상세 내역
            </div>
            <div class="card-body p-0">
              <div class="homes-ag-wrap">
                <div id="ccStatusGrid" class="ag-theme-alpine"></div>
              </div>
              <!-- 합계 -->
              <div class="d-flex justify-content-between align-items-center px-3 py-2 fw-bold border-top" style="background:#f8fafc;font-size:13px;">
                <span>합 계</span>
                <div class="d-flex gap-4">
                  <span class="text-success">수입 <fmt:formatNumber value="${grandIncome}" pattern="#,##0"/></span>
                  <span class="text-danger">지출 <fmt:formatNumber value="${grandExpense}" pattern="#,##0"/></span>
                  <span class="${grandBalance >= 0 ? 'text-success' : 'text-danger'}">잔액
                    <c:if test="${grandBalance < 0}">-</c:if>
                    <fmt:formatNumber value="${grandBalance < 0 ? -grandBalance : grandBalance}" pattern="#,##0"/>
                  </span>
                </div>
              </div>
            </div>
          </div>

        </c:otherwise>
      </c:choose>

    </div><%-- homes-main-body --%>
    <%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
  </main>
</div>

<!-- Chart.js -->
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.3/dist/chart.umd.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
const STATUS_AI_CONTEXT = ${aiContextJson};

function renderAiText(text) {
  return String(text || '')
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
    .replace(/^### (.+)$/gm, '<div class="fw-bold mt-3 mb-1 text-primary fs-6">$1</div>')
    .replace(/^## (.+)$/gm,  '<div class="fw-bold mt-3 mb-1 fs-5">$1</div>')
    .replace(/^# (.+)$/gm,   '<div class="fw-bold mt-3 mb-1 fs-4">$1</div>')
    .replace(/^- (.+)$/gm,   '<div class="ms-3">- $1</div>')
    .replace(/\n/g, '<br>');
}

function askStatusAI() {
  const loading = document.getElementById('aiLoadingWrap');
  const result  = document.getElementById('aiResultWrap');
  const retry   = document.getElementById('aiRetryBtn');
  const toggle  = document.getElementById('aiToggleBtn');

  HOMES.aiProgress.show(loading);
  result.style.display = 'none';
  retry.style.display = 'none';
  toggle.style.display = 'none';

  const controller = new AbortController();
  const tid = setTimeout(() => controller.abort(), 175000);
  fetch('${pageContext.request.contextPath}/asset/costcenter/status/analyze', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(STATUS_AI_CONTEXT),
    signal: controller.signal
  }).finally(() => clearTimeout(tid))
    .then(r => r.json())
    .then(res => {
      HOMES.aiProgress.hide(loading);
      result.style.display = '';
      retry.style.display = '';
      if (res.success) {
        result.innerHTML = renderAiText(res.text);
        result.classList.add('ai-result-collapsed');
        toggle.style.display = '';
        toggle.textContent = '전체 보기';
      } else {
        result.innerHTML = '<span class="text-danger">' + renderAiText(res.text) + '</span>';
      }
    })
    .catch(err => {
      HOMES.aiProgress.hide(loading);
      result.style.display = '';
      retry.style.display = '';
      result.innerHTML = '<span class="text-danger">요청 실패: ' + renderAiText(err.message) + '</span>';
    });
}

function toggleAiResult() {
  const result = document.getElementById('aiResultWrap');
  const btn = document.getElementById('aiToggleBtn');
  const collapsed = result.classList.toggle('ai-result-collapsed');
  btn.textContent = collapsed ? '전체 보기' : '접기';
}

askStatusAI();

/* ── 수지계정 AG Grid ── */
(function () {
  function d(s) { const el = document.createElement('textarea'); el.innerHTML = s; return el.value; }
  function won(v) { return v != null ? Number(v).toLocaleString('ko-KR') : '-'; }

  /* 전체 행 데이터 (요약 + 상세 행 모두 포함) */
  const allRows = [];
  <c:forEach var="s" items="${statusList}" varStatus="vs">
  (function(){
    const idx = ${vs.index};
    /* 요약 행 */
    allRows.push({
      rowType: 'summary', idx,
      ccNm:            d('<c:out value="${s.ccNm}"/>'),
      ccType:          '${s.ccType}',
      incomePlanNm:    d('<c:out value="${s.incomePlanNm}"/>'),
      incomeMonthlyAmt:${s.incomeMonthlyAmt},
      expenseMonthlyAmt:${s.expenseMonthlyAmt},
      totalIncomeAmt:  ${s.totalIncomeAmt},
      totalExpenseAmt: ${s.totalExpenseAmt},
      balance:         ${s.balance},
      expanded: false,
      hasDetail: ${not empty s.expensePlans or not empty s.incomePlanNm or not empty s.manualEntries ? 'true' : 'false'},
    });
    /* 수입원 상세 */
    <c:if test="${not empty s.incomePlanNm}">
    allRows.push({ rowType:'detail', idx,
      subLabel: d('<c:out value="${s.incomePlanNm}"/>'),
      subTypeCls:'type-income', subTypeNm:'수입',
      planTypeNm: '-',
      incomeMonthlyAmt: ${s.incomeMonthlyAmt}, expenseMonthlyAmt: 0,
      totalIncomeAmt: ${s.totalIncomeAmt}, totalExpenseAmt: 0, balance: null,
    });
    </c:if>
    /* 정기지출 상세 */
    <c:forEach var="p" items="${s.expensePlans}">
    allRows.push({ rowType:'detail', idx,
      subLabel: d('<c:out value="${p.planNm}"/>'),
      subTypeCls: '${p.flowType == "EXPENSE" ? "type-expense" : p.flowType == "SAVING" ? "type-saving" : "type-invest"}',
      subTypeNm:  '${p.flowType == "EXPENSE" ? "지출" : p.flowType == "SAVING" ? "저축" : "투자"}',
      planTypeNm: d('<c:out value="${p.planTypeNm}"/>'),
      incomeMonthlyAmt: 0, expenseMonthlyAmt: ${p.amount},
      totalIncomeAmt: 0, totalExpenseAmt: ${p.amount}, balance: null,
    });
    </c:forEach>
    /* 수기 현금흐름 */
    <c:forEach var="m" items="${s.manualEntries}">
    (function(){
      const isIncome = '${m.flowType}' === 'INCOME';
      const lbl = d('<c:out value="${not empty m.title ? m.title : m.incomeYymm}"/>');
      const memo = d('<c:out value="${m.memo}"/>');
      allRows.push({ rowType:'detail', idx,
        subLabel: lbl + (memo ? ' — ' + memo : ''),
        subTypeCls: '${m.flowType == "INCOME" ? "type-income" : m.flowType == "SAVING" ? "type-saving" : m.flowType == "INVEST" ? "type-invest" : "type-expense"}',
        subTypeNm:  '${m.flowType == "INCOME" ? "수기수입" : m.flowType == "SAVING" ? "수기저축" : m.flowType == "INVEST" ? "수기투자" : "수기지출"}',
        planTypeNm: '수기',
        incomeMonthlyAmt: isIncome ? ${m.actualAmt} : 0,
        expenseMonthlyAmt: isIncome ? 0 : ${m.actualAmt},
        totalIncomeAmt: isIncome ? ${m.actualAmt} : 0,
        totalExpenseAmt: isIncome ? 0 : ${m.actualAmt}, balance: null,
      });
    })();
    </c:forEach>
    <c:if test="${empty s.expensePlans and empty s.incomePlanNm and empty s.manualEntries}">
    allRows.push({ rowType:'detail', idx, subLabel:'연결된 수입/지출 항목이 없습니다.', isEmpty: true,
      subTypeCls:'', subTypeNm:'', planTypeNm:'',
      incomeMonthlyAmt:0, expenseMonthlyAmt:0, totalIncomeAmt:0, totalExpenseAmt:0, balance:null });
    </c:if>
  })();
  </c:forEach>

  /* 초기 표시: 요약 행만 */
  let displayRows = allRows.filter(r => r.rowType === 'summary');
  let gridApi;

  const colDefs = [
    { field: 'ccNm', headerName: '수지계정', flex: 1, minWidth: 160,
      cellRenderer: p => {
        if (p.data.rowType === 'detail') {
          if (p.data.isEmpty) return '<span class="text-muted fst-italic" style="padding-left:2.2rem;">' + p.data.subLabel + '</span>';
          const typeHtml = p.data.subTypeCls
            ? '<span class="sub-type ' + p.data.subTypeCls + '">' + p.data.subTypeNm + '</span>&nbsp;' : '';
          return '<span class="sub-label" style="padding-left:2.2rem;">' + typeHtml + p.data.subLabel + '</span>';
        }
        const arrow = p.data.hasDetail ? '<span class="cc-toggle-icon" id="icon-' + p.data.idx + '">&nbsp;▶&nbsp;</span>' : '&emsp;';
        const badge = p.data.ccType === 'AUTO' ? ' <span class="badge bg-light text-secondary border ms-1" style="font-size:10px;">자동</span>' : '';
        return arrow + '<span class="fw-semibold">' + p.data.ccNm + '</span>' + badge;
      }
    },
    { field: 'incomePlanNm', headerName: '수입원', width: 150, minWidth: 100,
      cellRenderer: p => {
        if (p.data.rowType === 'detail') return '<span class="text-muted" style="font-size:12px;">' + p.data.planTypeNm + '</span>';
        return p.data.incomePlanNm
          ? '<span class="badge bg-success-subtle text-success border">' + p.data.incomePlanNm + '</span>'
          : '<span class="text-muted">-</span>';
      }
    },
    { field: 'incomeMonthlyAmt',  headerName: '월 수입',    minWidth: 100, type: 'rightAligned',
      cellRenderer: p => p.value ? '<span class="text-success">' + won(p.value) + '</span>' : '<span class="text-muted">-</span>' },
    { field: 'expenseMonthlyAmt', headerName: '월 지출',    minWidth: 100, type: 'rightAligned',
      cellRenderer: p => p.value ? '<span class="text-danger">' + won(p.value) + '</span>' : '<span class="text-muted">-</span>' },
    { field: 'totalIncomeAmt',    headerName: '기간 총 수입', minWidth: 110, type: 'rightAligned',
      cellRenderer: p => p.value ? '<span class="fw-semibold text-success">' + won(p.value) + '</span>' : '<span class="text-muted">-</span>' },
    { field: 'totalExpenseAmt',   headerName: '기간 총 지출', minWidth: 110, type: 'rightAligned',
      cellRenderer: p => p.value ? '<span class="fw-semibold text-danger">' + won(p.value) + '</span>' : '<span class="text-muted">-</span>' },
    { field: 'balance', headerName: '잔액', minWidth: 100, type: 'rightAligned',
      cellRenderer: p => {
        if (p.data.rowType === 'detail' || p.value === null) return '';
        const cls = p.value >= 0 ? 'text-success' : 'text-danger';
        const sign = p.value < 0 ? '-' : '';
        return '<span class="fw-semibold ' + cls + '">' + sign + won(Math.abs(p.value)) + '</span>';
      }
    },
  ];

  gridApi = agGrid.createGrid(document.getElementById('ccStatusGrid'), {
    columnDefs: colDefs,
    rowData: displayRows,
    defaultColDef: { sortable: false, resizable: true, suppressMovable: true },
    domLayout: 'autoHeight',
    suppressCellFocus: true,
    getRowStyle: p => ({
      background: p.data.rowType === 'detail' ? '#fafbfd' : '',
      cursor: p.data.rowType === 'summary' && p.data.hasDetail ? 'pointer' : 'default',
      fontSize: p.data.rowType === 'detail' ? '12px' : '',
    }),
    onRowClicked: p => {
      if (p.data.rowType !== 'summary' || !p.data.hasDetail) return;
      const idx = p.data.idx;
      const isExpanded = p.data.expanded;
      if (isExpanded) {
        // 상세 행 제거
        const toRemove = [];
        gridApi.forEachNode(n => { if (n.data.rowType === 'detail' && n.data.idx === idx) toRemove.push(n.data); });
        gridApi.applyTransaction({ remove: toRemove });
      } else {
        // 상세 행 삽입
        const detailRows = allRows.filter(r => r.rowType === 'detail' && r.idx === idx);
        const currentRows = [];
        gridApi.forEachNode(n => currentRows.push(n.data));
        const insertIdx = currentRows.findIndex(r => r === p.data) + 1;
        gridApi.applyTransaction({ add: detailRows, addIndex: insertIdx });
      }
      p.data.expanded = !isExpanded;
      // 아이콘 갱신
      setTimeout(() => {
        const icon = document.getElementById('icon-' + idx);
        if (icon) icon.innerHTML = p.data.expanded ? '&nbsp;▼&nbsp;' : '&nbsp;▶&nbsp;';
      }, 0);
    },
  });
})();

/* ── 기간 빠른 선택 ── */
function setQuick(fromOffset, toOffset) {
  const now  = new Date();
  const from = new Date(now.getFullYear(), now.getMonth() + fromOffset, 1);
  const to   = new Date(now.getFullYear(), now.getMonth() + toOffset,   1);

  function toInputVal(d) {
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, '0');
    return y + '-' + m;
  }

  document.getElementById('fromYymm').value = toInputVal(from);
  document.getElementById('toYymm').value   = toInputVal(to);
  document.forms[0].submit();
}

/* ── form submit 시 YYYYMM 형식으로 변환 ── */
document.querySelector('form').addEventListener('submit', function (e) {
  e.preventDefault();
  const from = document.getElementById('fromYymm').value.replace('-', '');
  const to   = document.getElementById('toYymm').value.replace('-', '');
  const url  = new URL(this.action);
  url.searchParams.set('fromYymm', from);
  url.searchParams.set('toYymm',   to);
  location.href = url.toString();
});

/* ── Chart.js 데이터 ── */
<%-- JSP에서 JSON 빌드 --%>
<c:if test="${not empty statusList}">
const labels  = [<c:forEach var="s" items="${statusList}" varStatus="st">"${s.ccNm}"<c:if test="${!st.last}">,</c:if></c:forEach>];
const incomes  = [<c:forEach var="s" items="${statusList}" varStatus="st">${s.totalIncomeAmt}<c:if test="${!st.last}">,</c:if></c:forEach>];
const expenses = [<c:forEach var="s" items="${statusList}" varStatus="st">${s.totalExpenseAmt}<c:if test="${!st.last}">,</c:if></c:forEach>];

const PALETTE_INCOME  = 'rgba(16, 185, 129, 0.75)';  // emerald
const PALETTE_EXPENSE = 'rgba(239, 68, 68, 0.75)';   // red
const DONUT_COLORS = [
  '#6366f1','#f59e0b','#10b981','#ef4444','#3b82f6',
  '#ec4899','#8b5cf6','#14b8a6','#f97316','#64748b'
];

/* ── 막대 차트 ── */
const barCtx = document.getElementById('barChart').getContext('2d');
new Chart(barCtx, {
  type: 'bar',
  data: {
    labels,
    datasets: [
      {
        label: '수입',
        data:  incomes,
        backgroundColor: PALETTE_INCOME,
        borderColor: 'rgba(16,185,129,1)',
        borderWidth: 1,
        borderRadius: 5,
      },
      {
        label: '지출',
        data:  expenses,
        backgroundColor: PALETTE_EXPENSE,
        borderColor: 'rgba(239,68,68,1)',
        borderWidth: 1,
        borderRadius: 5,
      }
    ]
  },
  options: {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { position: 'top' },
      tooltip: {
        callbacks: {
          label: ctx => ctx.dataset.label + ': ₩' + Number(ctx.parsed.y).toLocaleString('ko-KR') + '원'
        }
      }
    },
    scales: {
      y: {
        beginAtZero: true,
        ticks: {
          callback: v => '₩' + Number(v).toLocaleString('ko-KR')
        },
        grid: { color: 'rgba(0,0,0,.05)' }
      },
      x: { grid: { display: false } }
    }
  }
});

/* ── 도넛 차트 (지출 비중) ── */
const hasExpense = expenses.some(v => v > 0);
const donutCtx  = document.getElementById('donutChart').getContext('2d');

if (hasExpense) {
  new Chart(donutCtx, {
    type: 'doughnut',
    data: {
      labels,
      datasets: [{
        data:            expenses,
        backgroundColor: DONUT_COLORS.slice(0, labels.length),
        borderWidth: 2,
        hoverOffset: 8
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: true,
      cutout: '60%',
      plugins: {
        legend: { display: false },
        tooltip: {
          callbacks: {
            label: ctx => ctx.label + ': ₩' + Number(ctx.parsed).toLocaleString('ko-KR') + '원'
          }
        }
      }
    }
  });

  // 커스텀 범례
  const legend = document.getElementById('donutLegend');
  const totalExp = expenses.reduce((a, b) => a + b, 0);
  legend.innerHTML = labels.map((lbl, i) => {
    const pct = totalExp > 0 ? Math.round(expenses[i] * 100 / totalExp) : 0;
    return `<div class="d-flex align-items-center justify-content-between mb-1">
      <div class="d-flex align-items-center gap-2">
        <span style="display:inline-block;width:10px;height:10px;border-radius:50%;background:${DONUT_COLORS[i]};flex-shrink:0;"></span>
        <span>${lbl}</span>
      </div>
      <span class="fw-semibold">${pct}%</span>
    </div>`;
  }).join('');

} else {
  donutCtx.canvas.parentElement.innerHTML =
    '<div class="text-center text-muted py-5">지출 데이터가 없습니다.</div>';
}
</c:if>
</script>
</body>
</html>
