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
              &nbsp;<span class="badge bg-primary-subtle text-primary border" style="font-size:11px;">📌 전표처리 기준</span>
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
                <div class="card-header bg-transparent fw-semibold">
                  📊 수지계정별 수입 vs 지출
                </div>
                <div class="card-body chart-wrap">
                  <canvas id="barChart"></canvas>
                </div>
              </div>
            </div>
            <!-- 도넛 차트 -->
            <div class="col-12 col-lg-4">
              <div class="card homes-card h-100">
                <div class="card-header bg-transparent fw-semibold">
                  🍩 지출 비중
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
            <div class="card-header bg-transparent fw-semibold">
              📋 수지계정별 상세 내역
            </div>
            <div class="card-body p-0">
              <div class="table-responsive">
                <table class="table align-middle homes-table table-status mb-0">
                  <thead class="table-light">
                    <tr>
                      <th style="width:22%">수지계정</th>
                      <th style="width:16%">수입원</th>
                      <th class="text-end" style="width:13%">월 수입</th>
                      <th class="text-end" style="width:13%">월 지출</th>
                      <th class="text-end" style="width:13%">기간 총 수입</th>
                      <th class="text-end" style="width:13%">기간 총 지출</th>
                      <th class="text-end" style="width:10%">잔액</th>
                    </tr>
                  </thead>
                  <tbody id="ccTableBody">
                    <c:forEach var="s" items="${statusList}" varStatus="vs">
                      <c:set var="hasItems" value="${not empty s.expensePlans or not empty s.incomePlanNm}"/>

                      <%-- ── 수지계정 요약 행 ── --%>
                      <tr class="cc-summary-row"
                          onclick="toggleCC(${vs.index})"
                          data-idx="${vs.index}">
                        <td>
                          <span class="cc-toggle-icon" id="icon-${vs.index}">▶</span>
                          <span class="fw-semibold">${s.ccNm}</span>
                          <c:if test="${s.ccType == 'AUTO'}">
                            <span class="badge bg-light text-secondary border ms-1" style="font-size:10px;">자동</span>
                          </c:if>
                        </td>
                        <td class="text-muted small">
                          <c:choose>
                            <c:when test="${not empty s.incomePlanNm}">
                              <span class="badge bg-success-subtle text-success border">${s.incomePlanNm}</span>
                            </c:when>
                            <c:otherwise>-</c:otherwise>
                          </c:choose>
                        </td>
                        <td class="text-end text-success">
                          <fmt:formatNumber value="${s.incomeMonthlyAmt}" pattern="#,##0"/>
                        </td>
                        <td class="text-end text-danger">
                          <fmt:formatNumber value="${s.expenseMonthlyAmt}" pattern="#,##0"/>
                        </td>
                        <td class="text-end fw-semibold text-success">
                          <fmt:formatNumber value="${s.totalIncomeAmt}" pattern="#,##0"/>
                        </td>
                        <td class="text-end fw-semibold text-danger">
                          <fmt:formatNumber value="${s.totalExpenseAmt}" pattern="#,##0"/>
                        </td>
                        <td class="text-end fw-semibold ${s.balance >= 0 ? 'text-success' : 'text-danger'}">
                          <c:if test="${s.balance < 0}">-</c:if>
                          <fmt:formatNumber value="${s.balance < 0 ? -s.balance : s.balance}" pattern="#,##0"/>
                        </td>
                      </tr>

                      <%-- ── 하위 항목 행 (기본 숨김) ── --%>
                      <c:choose>
                        <c:when test="${not empty s.incomePlanNm}">
                          <%-- 수입원 행 --%>
                          <tr class="cc-detail-row" id="detail-${vs.index}" style="display:none;">
                            <td class="sub-label">
                              <span class="sub-type type-income">수입</span>
                              &nbsp;${s.incomePlanNm}
                            </td>
                            <td>-</td>
                            <td class="text-end text-success">
                              <fmt:formatNumber value="${s.incomeMonthlyAmt}" pattern="#,##0"/>
                            </td>
                            <td class="text-end">-</td>
                            <td class="text-end text-success">
                              <fmt:formatNumber value="${s.totalIncomeAmt}" pattern="#,##0"/>
                            </td>
                            <td class="text-end">-</td>
                            <td></td>
                          </tr>
                        </c:when>
                      </c:choose>

                      <c:forEach var="p" items="${s.expensePlans}" varStatus="ps">
                        <c:set var="flowCls" value="${p.flowType == 'EXPENSE' ? 'type-expense' : p.flowType == 'SAVING' ? 'type-saving' : 'type-invest'}"/>
                        <c:set var="flowNm"  value="${p.flowType == 'EXPENSE' ? '지출' : p.flowType == 'SAVING' ? '저축' : p.flowType == 'INVEST' ? '투자' : p.flowType}"/>
                        <tr class="cc-detail-row" id="detail-${vs.index}" style="display:none;">
                          <td class="sub-label">
                            <span class="sub-type ${flowCls}">${flowNm}</span>
                            &nbsp;${p.planNm}
                          </td>
                          <td class="text-muted" style="font-size:12px;">${p.planTypeNm}</td>
                          <td class="text-end">-</td>
                          <td class="text-end text-danger">
                            <fmt:formatNumber value="${p.amount}" pattern="#,##0"/>
                          </td>
                          <td class="text-end">-</td>
                          <td class="text-end text-danger">
                            <fmt:formatNumber value="${p.amount}" pattern="#,##0"/>
                            <span class="text-muted" style="font-size:10px;">/월</span>
                          </td>
                          <td></td>
                        </tr>
                      </c:forEach>

                      <%-- 수기 현금흐름 항목 --%>
                      <c:forEach var="m" items="${s.manualEntries}">
                        <c:set var="mFlowCls" value="${m.flowType == 'INCOME' ? 'type-income' : m.flowType == 'SAVING' ? 'type-saving' : m.flowType == 'INVEST' ? 'type-invest' : 'type-expense'}"/>
                        <c:set var="mFlowNm"  value="${m.flowType == 'INCOME' ? '수기수입' : m.flowType == 'SAVING' ? '수기저축' : m.flowType == 'INVEST' ? '수기투자' : '수기지출'}"/>
                        <tr class="cc-detail-row" id="detail-${vs.index}" style="display:none;">
                          <td class="sub-label">
                            <span class="sub-type ${mFlowCls}">${mFlowNm}</span>
                            &nbsp;<c:choose>
                              <c:when test="${not empty m.title}"><c:out value="${m.title}"/></c:when>
                              <c:otherwise>${m.incomeYymm}</c:otherwise>
                            </c:choose>
                            <c:if test="${not empty m.memo}"><span class="text-muted"> — <c:out value="${m.memo}"/></span></c:if>
                          </td>
                          <td class="text-muted" style="font-size:12px;">수기</td>
                          <c:choose>
                            <c:when test="${m.flowType == 'INCOME'}">
                              <td class="text-end text-success"><fmt:formatNumber value="${m.actualAmt}" pattern="#,##0"/></td>
                              <td class="text-end">-</td>
                              <td class="text-end text-success"><fmt:formatNumber value="${m.actualAmt}" pattern="#,##0"/></td>
                              <td class="text-end">-</td>
                            </c:when>
                            <c:otherwise>
                              <td class="text-end">-</td>
                              <td class="text-end text-danger"><fmt:formatNumber value="${m.actualAmt}" pattern="#,##0"/></td>
                              <td class="text-end">-</td>
                              <td class="text-end text-danger"><fmt:formatNumber value="${m.actualAmt}" pattern="#,##0"/></td>
                            </c:otherwise>
                          </c:choose>
                          <td></td>
                        </tr>
                      </c:forEach>

                      <%-- 항목 없는 경우 --%>
                      <c:if test="${empty s.expensePlans and empty s.incomePlanNm and empty s.manualEntries}">
                        <tr class="cc-detail-row" id="detail-${vs.index}" style="display:none;">
                          <td colspan="7" class="cc-no-detail ps-5">연결된 수입/지출 항목이 없습니다.</td>
                        </tr>
                      </c:if>

                    </c:forEach>
                  </tbody>
                  <tfoot class="table-light fw-bold">
                    <tr>
                      <td colspan="4" class="text-end">합 계</td>
                      <td class="text-end text-success">
                        <fmt:formatNumber value="${grandIncome}" pattern="#,##0"/>
                      </td>
                      <td class="text-end text-danger">
                        <fmt:formatNumber value="${grandExpense}" pattern="#,##0"/>
                      </td>
                      <td class="text-end ${grandBalance >= 0 ? 'text-success' : 'text-danger'}">
                        <c:if test="${grandBalance < 0}">-</c:if>
                        <fmt:formatNumber value="${grandBalance < 0 ? -grandBalance : grandBalance}" pattern="#,##0"/>
                      </td>
                    </tr>
                  </tfoot>
                </table>
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
/* ── 수지계정 아코디언 토글 ── */
function toggleCC(idx) {
  var rows  = document.querySelectorAll('#detail-' + idx);
  var icon  = document.getElementById('icon-' + idx);
  var isOpen = icon.classList.contains('open');

  rows.forEach(function (r) {
    r.style.display = isOpen ? 'none' : '';
  });

  if (isOpen) {
    icon.classList.remove('open');
  } else {
    icon.classList.add('open');
  }
}

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
