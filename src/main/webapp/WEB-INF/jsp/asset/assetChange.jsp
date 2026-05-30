<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<!doctype html>
<html lang="ko">
<head>
  <%@ include file="/WEB-INF/jsp/common/head.jsp" %>
  <title>자산변동현황 | HOMES</title>
  <style>
    /* ── KPI 카드 ── */
    .kpi-card { border-radius: 16px; border: none; transition: transform .15s, box-shadow .15s; }
    .kpi-card:hover { transform: translateY(-2px); box-shadow: 0 8px 24px rgba(0,0,0,.1); }
    .kpi-icon { width: 44px; height: 44px; border-radius: 12px;
                display: flex; align-items: center; justify-content: center; font-size: 20px; }
    .kpi-val  { font-size: 1.35rem; font-weight: 700; line-height: 1.2; }
    .kpi-sub  { font-size: 11px; color: #9ca3af; margin-top: 2px; }
    /* ── 차트 공통 ── */
    .chart-card { border-radius: 14px; }
    .chart-wrap { position: relative; min-height: 280px; }
    .chart-wrap-sm { position: relative; min-height: 230px; }
    /* ── 인사이트 뱃지 ── */
    .insight-badge { font-size: 11px; padding: 3px 8px; border-radius: 20px; }
    /* ── 테이블 ── */
    .tbl-snapshot th { font-size: 12px; color: #6b7280; }
    .mom-positive { color: #10b981; font-weight: 600; }
    .mom-negative { color: #ef4444; font-weight: 600; }
    .mom-zero     { color: #9ca3af; }
    /* ── 섹션 타이틀 ── */
    .section-title { font-size: 13px; font-weight: 600; color: #6b7280; letter-spacing: .05em;
                     text-transform: uppercase; margin-bottom: 12px; }
    /* ── 기간 뱃지 ── */
    .period-chip { cursor: pointer; border-radius: 20px; font-size: 12px; padding: 4px 12px; }
  </style>
</head>
<body class="homes-bg">
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>

<div class="homes-shell d-lg-flex">
  <%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

  <main class="homes-main flex-grow-1 d-flex flex-column">
    <div class="homes-main-body px-3 px-md-4 py-4">

      <!-- ── 페이지 헤더 ── -->
      <div class="d-flex flex-column flex-md-row align-items-md-center justify-content-between gap-2 mb-4">
        <div>
          <div class="homes-badge mb-2">Asset</div>
          <h1 class="h4 fw-bold mb-1">자산변동현황</h1>
          <div class="text-muted small">
            전표처리(월 마감) 기준으로 자산·부채·순자산의 변화를 분석합니다.
            <span class="badge bg-primary-subtle text-primary border ms-1" style="font-size:11px;">📌 전표처리 기준</span>
          </div>
        </div>
        <a class="btn btn-outline-secondary homes-pill px-3"
           href="${pageContext.request.contextPath}/asset/costcenter/status">수지계정현황</a>
      </div>

      <c:choose>
        <c:when test="${not hasData}">
          <!-- ── 데이터 없음 ── -->
          <div class="card homes-card text-center py-5">
            <div class="card-body">
              <div style="font-size: 48px;">📊</div>
              <h5 class="mt-3 fw-semibold">전표처리 데이터가 없습니다</h5>
              <p class="text-muted small mb-3">
                수지계정현황 화면에서 월별 전표처리를 실행하면<br>
                이 화면에서 자산변동 인사이트를 확인할 수 있습니다.
              </p>
              <a class="btn btn-primary homes-pill px-4"
                 href="${pageContext.request.contextPath}/asset/costcenter/status">전표처리 하러 가기</a>
            </div>
          </div>
        </c:when>
        <c:otherwise>

          <!-- ── KPI 카드 4개 ── -->
          <div class="row g-3 mb-4">
            <!-- 총 자산 -->
            <div class="col-6 col-md-3">
              <div class="card homes-card kpi-card h-100">
                <div class="card-body">
                  <div class="d-flex align-items-center gap-2 mb-2">
                    <div class="kpi-icon bg-blue-subtle" style="background:#eff6ff;">💰</div>
                    <span class="text-muted small">총 자산</span>
                  </div>
                  <div class="kpi-val text-primary">
                    <c:choose>
                      <c:when test="${latest.totalAssetAmt >= 100000000}">
                        <fmt:formatNumber value="${latest.totalAssetAmt / 100000000}" pattern="#,##0.0"/>억
                      </c:when>
                      <c:otherwise>
                        <fmt:formatNumber value="${latest.totalAssetAmt / 10000}" pattern="#,##0"/>만
                      </c:otherwise>
                    </c:choose>
                    <span class="small">원</span>
                  </div>
                  <div class="kpi-sub">최신 전표처리 기준</div>
                </div>
              </div>
            </div>
            <!-- 순 자산 -->
            <div class="col-6 col-md-3">
              <div class="card homes-card kpi-card h-100">
                <div class="card-body">
                  <div class="d-flex align-items-center gap-2 mb-2">
                    <div class="kpi-icon" style="background:#f0fdf4;">🏆</div>
                    <span class="text-muted small">순 자산</span>
                  </div>
                  <div class="kpi-val ${latest.netAssetAmt >= 0 ? 'text-success' : 'text-danger'}">
                    <c:if test="${latest.netAssetAmt < 0}">-</c:if>
                    <c:choose>
                      <c:when test="${(latest.netAssetAmt < 0 ? -latest.netAssetAmt : latest.netAssetAmt) >= 100000000}">
                        <fmt:formatNumber value="${(latest.netAssetAmt < 0 ? -latest.netAssetAmt : latest.netAssetAmt) / 100000000}" pattern="#,##0.0"/>억
                      </c:when>
                      <c:otherwise>
                        <fmt:formatNumber value="${(latest.netAssetAmt < 0 ? -latest.netAssetAmt : latest.netAssetAmt) / 10000}" pattern="#,##0"/>만
                      </c:otherwise>
                    </c:choose>
                    <span class="small">원</span>
                  </div>
                  <div class="kpi-sub">총자산 - 총대출</div>
                </div>
              </div>
            </div>
            <!-- 총 대출 -->
            <div class="col-6 col-md-3">
              <div class="card homes-card kpi-card h-100">
                <div class="card-body">
                  <div class="d-flex align-items-center gap-2 mb-2">
                    <div class="kpi-icon" style="background:#fef2f2;">🏦</div>
                    <span class="text-muted small">총 대출 잔액</span>
                  </div>
                  <div class="kpi-val text-danger">
                    <c:choose>
                      <c:when test="${latest.totalLoanBalance >= 100000000}">
                        <fmt:formatNumber value="${latest.totalLoanBalance / 100000000}" pattern="#,##0.0"/>억
                      </c:when>
                      <c:otherwise>
                        <fmt:formatNumber value="${latest.totalLoanBalance / 10000}" pattern="#,##0"/>만
                      </c:otherwise>
                    </c:choose>
                    <span class="small">원</span>
                  </div>
                  <div class="kpi-sub">현재 상환 중인 대출</div>
                </div>
              </div>
            </div>
            <!-- 전월 대비 순자산 -->
            <div class="col-6 col-md-3">
              <div class="card homes-card kpi-card h-100">
                <div class="card-body">
                  <div class="d-flex align-items-center gap-2 mb-2">
                    <div class="kpi-icon" style="background:#faf5ff;">📈</div>
                    <span class="text-muted small">전월대비 순자산</span>
                  </div>
                  <div class="kpi-val ${momChange > 0 ? 'text-success' : momChange < 0 ? 'text-danger' : 'text-muted'}">
                    <c:if test="${momChange > 0}">+</c:if>
                    <c:if test="${momChange < 0}">-</c:if>
                    <c:choose>
                      <c:when test="${(momChange < 0 ? -momChange : momChange) >= 100000000}">
                        <fmt:formatNumber value="${(momChange < 0 ? -momChange : momChange) / 100000000}" pattern="#,##0.0"/>억
                      </c:when>
                      <c:otherwise>
                        <fmt:formatNumber value="${(momChange < 0 ? -momChange : momChange) / 10000}" pattern="#,##0"/>만
                      </c:otherwise>
                    </c:choose>
                    <span class="small">원</span>
                  </div>
                  <div class="kpi-sub">
                    <c:if test="${prev != null}">
                      ${prev.hstYymm.substring(0,4)}.${prev.hstYymm.substring(4,6)} →
                      ${latest.hstYymm.substring(0,4)}.${latest.hstYymm.substring(4,6)}
                    </c:if>
                    <c:if test="${prev == null}">첫 전표처리</c:if>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- ── Row 1: 순자산 트렌드 (Area) + MoM 증감 (Bar) ── -->
          <div class="row g-3 mb-3">
            <div class="col-12 col-lg-8">
              <div class="card homes-card chart-card h-100">
                <div class="card-header bg-transparent d-flex align-items-center justify-content-between">
                  <span class="fw-semibold">📈 순자산 트렌드</span>
                  <span class="insight-badge bg-primary-subtle text-primary border">총자산 · 대출 · 순자산</span>
                </div>
                <div class="card-body chart-wrap">
                  <canvas id="trendChart"></canvas>
                </div>
              </div>
            </div>
            <div class="col-12 col-lg-4">
              <div class="card homes-card chart-card h-100">
                <div class="card-header bg-transparent d-flex align-items-center justify-content-between">
                  <span class="fw-semibold">📊 월별 순자산 증감</span>
                  <span class="insight-badge bg-success-subtle text-success border">MoM Δ</span>
                </div>
                <div class="card-body chart-wrap">
                  <canvas id="momChart"></canvas>
                </div>
              </div>
            </div>
          </div>

          <!-- ── Row 2: 자산유형 적층 + 도넛 ── -->
          <div class="row g-3 mb-3">
            <div class="col-12 col-lg-7">
              <div class="card homes-card chart-card h-100">
                <div class="card-header bg-transparent d-flex align-items-center justify-content-between">
                  <span class="fw-semibold">🗂️ 자산유형별 구성 변화</span>
                  <span class="insight-badge bg-warning-subtle text-warning border">Stacked Bar</span>
                </div>
                <div class="card-body chart-wrap">
                  <canvas id="stackedChart"></canvas>
                </div>
              </div>
            </div>
            <div class="col-12 col-lg-5">
              <div class="card homes-card chart-card h-100">
                <div class="card-header bg-transparent d-flex align-items-center justify-content-between">
                  <span class="fw-semibold">🍩 최신월 자산 비중</span>
                  <span class="insight-badge bg-info-subtle text-info border">${latest.hstYymm.substring(0,4)}.${latest.hstYymm.substring(4,6)} 기준</span>
                </div>
                <div class="card-body d-flex flex-column align-items-center justify-content-center chart-wrap-sm">
                  <canvas id="donutChart" style="max-height:210px;"></canvas>
                  <div id="donutLegend" class="mt-3 w-100" style="font-size:12px;"></div>
                </div>
              </div>
            </div>
          </div>

          <!-- ── Row 3: 유동/비유동 비율 + 현금흐름 ── -->
          <div class="row g-3 mb-4">
            <div class="col-12 col-lg-6">
              <div class="card homes-card chart-card h-100">
                <div class="card-header bg-transparent d-flex align-items-center justify-content-between">
                  <span class="fw-semibold">💧 유동 vs 비유동 자산</span>
                  <span class="insight-badge bg-secondary-subtle text-secondary border">Area</span>
                </div>
                <div class="card-body chart-wrap-sm">
                  <canvas id="liquidChart"></canvas>
                </div>
              </div>
            </div>
            <div class="col-12 col-lg-6">
              <div class="card homes-card chart-card h-100">
                <div class="card-header bg-transparent d-flex align-items-center justify-content-between">
                  <span class="fw-semibold">💸 월별 현금흐름 계획</span>
                  <span class="insight-badge bg-danger-subtle text-danger border">수입 vs 지출</span>
                </div>
                <div class="card-body chart-wrap-sm">
                  <canvas id="cashflowChart"></canvas>
                </div>
              </div>
            </div>
          </div>

          <!-- ── 월별 스냅샷 상세 테이블 ── -->
          <div class="card homes-card">
            <div class="card-header bg-transparent fw-semibold d-flex align-items-center justify-content-between"
                 style="cursor:pointer;" data-bs-toggle="collapse" data-bs-target="#snapshotTable">
              <span>📋 월별 전표처리 상세 내역</span>
              <span class="text-muted small">클릭하여 펼치기/접기 ▾</span>
            </div>
            <div class="collapse show" id="snapshotTable">
              <div class="card-body p-0">
                <div class="table-responsive">
                  <table class="table align-middle homes-table tbl-snapshot mb-0">
                    <thead class="table-light">
                      <tr>
                        <th>전표 기준월</th>
                        <th class="text-end">총 자산</th>
                        <th class="text-end">총 대출</th>
                        <th class="text-end">순 자산</th>
                        <th class="text-end">유동 자산</th>
                        <th class="text-end">비유동 자산</th>
                        <th class="text-end">월 수입계획</th>
                        <th class="text-end">월 지출계획</th>
                        <th class="text-end">순자산 증감 (MoM)</th>
                      </tr>
                    </thead>
                    <tbody>
                      <c:forEach var="s" items="${summaryList}" varStatus="st">
                        <tr>
                          <td class="fw-semibold">${s.hstYymm.substring(0,4)}년 ${s.hstYymm.substring(4,6)}월</td>
                          <td class="text-end text-primary">
                            <fmt:formatNumber value="${s.totalAssetAmt}" pattern="#,##0"/>
                          </td>
                          <td class="text-end text-danger">
                            <fmt:formatNumber value="${s.totalLoanBalance}" pattern="#,##0"/>
                          </td>
                          <td class="text-end fw-bold ${s.netAssetAmt >= 0 ? 'text-success' : 'text-danger'}">
                            <c:if test="${s.netAssetAmt < 0}">-</c:if>
                            <fmt:formatNumber value="${s.netAssetAmt < 0 ? -s.netAssetAmt : s.netAssetAmt}" pattern="#,##0"/>
                          </td>
                          <td class="text-end">
                            <fmt:formatNumber value="${s.liquidAssetAmt}" pattern="#,##0"/>
                          </td>
                          <td class="text-end">
                            <fmt:formatNumber value="${s.fixedAssetAmt}" pattern="#,##0"/>
                          </td>
                          <td class="text-end text-success">
                            <fmt:formatNumber value="${s.monthlyIncome}" pattern="#,##0"/>
                          </td>
                          <td class="text-end text-danger">
                            <fmt:formatNumber value="${s.monthlyExpense}" pattern="#,##0"/>
                          </td>
                          <td class="text-end" id="mom-${st.index}">
                            <span class="text-muted small">-</span>
                          </td>
                        </tr>
                      </c:forEach>
                    </tbody>
                  </table>
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

<c:if test="${hasData}">
<script>
/* ━━━━━━━━━━━━━━━━ 데이터 ━━━━━━━━━━━━━━━━ */
const LABELS       = ${labelsJson};
const TOTAL_ASSETS = ${totalAssetsJson};
const TOTAL_LOANS  = ${totalLoansJson};
const NET_ASSETS   = ${netAssetsJson};
const LIQUID       = ${liquidJson};
const FIXED        = ${fixedJson};
const INCOMES      = ${incomesJson};
const EXPENSES     = ${expensesJson};
const MOM          = ${momJson};
const TYPE_DATA    = ${typeDataJson};   // { 유형명: [amount, ...] }
const LATEST_PIE   = ${latestPieJson};  // { 유형명: amount }

/* ━━━━━━━━━━━━━━━━ 팔레트 ━━━━━━━━━━━━━━━━ */
const COLORS = [
  '#6366f1','#f59e0b','#10b981','#3b82f6',
  '#ec4899','#8b5cf6','#14b8a6','#f97316','#64748b','#ef4444'
];

function won(v) { return '₩' + Number(v).toLocaleString('ko-KR') + '원'; }
function eok(v) {
  const abs = Math.abs(v);
  if (abs >= 1e8) return (v < 0 ? '-' : '') + (abs / 1e8).toFixed(1) + '억';
  if (abs >= 1e4) return (v < 0 ? '-' : '') + Math.round(abs / 1e4).toLocaleString() + '만';
  return v.toLocaleString();
}

const commonScales = {
  x: { grid: { display: false } },
  y: {
    beginAtZero: false,
    ticks: { callback: v => eok(v) },
    grid: { color: 'rgba(0,0,0,.05)' }
  }
};

/* ━━━━━━━━━━━━━━━━ 1. 순자산 트렌드 (Line + Fill) ━━━━━━━━━━━━━━━━ */
new Chart(document.getElementById('trendChart'), {
  type: 'line',
  data: {
    labels: LABELS,
    datasets: [
      {
        label: '총자산',
        data: TOTAL_ASSETS,
        borderColor: '#6366f1',
        backgroundColor: 'rgba(99,102,241,.08)',
        fill: true,
        tension: .35,
        pointRadius: 4,
        pointHoverRadius: 7,
        borderWidth: 2,
      },
      {
        label: '총대출',
        data: TOTAL_LOANS,
        borderColor: '#ef4444',
        backgroundColor: 'rgba(239,68,68,.06)',
        fill: true,
        tension: .35,
        pointRadius: 4,
        pointHoverRadius: 7,
        borderWidth: 2,
        borderDash: [5,3],
      },
      {
        label: '순자산',
        data: NET_ASSETS,
        borderColor: '#10b981',
        backgroundColor: 'rgba(16,185,129,.12)',
        fill: true,
        tension: .35,
        pointRadius: 5,
        pointHoverRadius: 8,
        borderWidth: 3,
      }
    ]
  },
  options: {
    responsive: true,
    maintainAspectRatio: false,
    interaction: { mode: 'index', intersect: false },
    plugins: {
      legend: { position: 'top' },
      tooltip: { callbacks: { label: ctx => ' ' + ctx.dataset.label + ': ' + won(ctx.parsed.y) } }
    },
    scales: commonScales
  }
});

/* ━━━━━━━━━━━━━━━━ 2. MoM 순자산 증감 (Bar, 색상 조건부) ━━━━━━━━━━━━━━━━ */
new Chart(document.getElementById('momChart'), {
  type: 'bar',
  data: {
    labels: LABELS,
    datasets: [{
      label: '순자산 증감',
      data: MOM,
      backgroundColor: MOM.map(v => v > 0 ? 'rgba(16,185,129,.75)' : v < 0 ? 'rgba(239,68,68,.75)' : 'rgba(156,163,175,.4)'),
      borderColor:     MOM.map(v => v > 0 ? 'rgba(16,185,129,1)'   : v < 0 ? 'rgba(239,68,68,1)'   : 'rgba(156,163,175,.6)'),
      borderWidth: 1,
      borderRadius: 5,
    }]
  },
  options: {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { display: false },
      tooltip: {
        callbacks: {
          label: ctx => (ctx.parsed.y > 0 ? '+' : '') + won(ctx.parsed.y)
        }
      }
    },
    scales: {
      x: { grid: { display: false } },
      y: {
        ticks: { callback: v => eok(v) },
        grid:  { color: 'rgba(0,0,0,.05)' }
      }
    }
  }
});

/* ━━━━━━━━━━━━━━━━ 3. 자산유형별 적층 바 ━━━━━━━━━━━━━━━━ */
const typeKeys     = Object.keys(TYPE_DATA);
const typeDatasets = typeKeys.map((key, i) => ({
  label: key,
  data:  TYPE_DATA[key],
  backgroundColor: COLORS[i % COLORS.length],
  borderWidth: 0,
  borderRadius: 3,
}));

new Chart(document.getElementById('stackedChart'), {
  type: 'bar',
  data: { labels: LABELS, datasets: typeDatasets },
  options: {
    responsive: true,
    maintainAspectRatio: false,
    interaction: { mode: 'index', intersect: false },
    plugins: {
      legend: { position: 'top', labels: { boxWidth: 12, font: { size: 11 } } },
      tooltip: { callbacks: { label: ctx => ' ' + ctx.dataset.label + ': ' + won(ctx.parsed.y) } }
    },
    scales: {
      x: { stacked: true, grid: { display: false } },
      y: {
        stacked: true,
        ticks: { callback: v => eok(v) },
        grid: { color: 'rgba(0,0,0,.05)' }
      }
    }
  }
});

/* ━━━━━━━━━━━━━━━━ 4. 최신월 도넛 ━━━━━━━━━━━━━━━━ */
const pieLabels = Object.keys(LATEST_PIE);
const pieValues = Object.values(LATEST_PIE);
const pieTotal  = pieValues.reduce((a, b) => a + b, 0);

if (pieLabels.length > 0 && pieTotal > 0) {
  new Chart(document.getElementById('donutChart'), {
    type: 'doughnut',
    data: {
      labels: pieLabels,
      datasets: [{
        data:            pieValues,
        backgroundColor: COLORS.slice(0, pieLabels.length),
        borderWidth: 2,
        hoverOffset: 8
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: true,
      cutout: '62%',
      plugins: {
        legend: { display: false },
        tooltip: {
          callbacks: {
            label: ctx => ' ' + ctx.label + ': ' + won(ctx.parsed) +
                         ' (' + Math.round(ctx.parsed * 100 / pieTotal) + '%)'
          }
        }
      }
    }
  });

  document.getElementById('donutLegend').innerHTML = pieLabels.map(function(lbl, i) {
    const pct = pieTotal > 0 ? Math.round(pieValues[i] * 100 / pieTotal) : 0;
    return '<div class="d-flex align-items-center justify-content-between mb-1">'
      + '<div class="d-flex align-items-center gap-2">'
      + '<span style="display:inline-block;width:10px;height:10px;border-radius:50%;background:' + COLORS[i] + ';flex-shrink:0;"></span>'
      + '<span>' + lbl + '</span>'
      + '</div>'
      + '<span class="fw-semibold">' + pct + '%</span>'
      + '</div>';
  }).join('');
} else {
  document.getElementById('donutChart').parentElement.innerHTML =
    '<div class="text-center text-muted py-4">데이터 없음</div>';
}

/* ━━━━━━━━━━━━━━━━ 5. 유동/비유동 Area ━━━━━━━━━━━━━━━━ */
new Chart(document.getElementById('liquidChart'), {
  type: 'line',
  data: {
    labels: LABELS,
    datasets: [
      {
        label: '유동자산',
        data: LIQUID,
        borderColor: '#3b82f6',
        backgroundColor: 'rgba(59,130,246,.15)',
        fill: true,
        tension: .35,
        pointRadius: 3,
        borderWidth: 2,
      },
      {
        label: '비유동자산',
        data: FIXED,
        borderColor: '#f59e0b',
        backgroundColor: 'rgba(245,158,11,.12)',
        fill: true,
        tension: .35,
        pointRadius: 3,
        borderWidth: 2,
      }
    ]
  },
  options: {
    responsive: true,
    maintainAspectRatio: false,
    interaction: { mode: 'index', intersect: false },
    plugins: {
      legend: { position: 'top' },
      tooltip: { callbacks: { label: ctx => ' ' + ctx.dataset.label + ': ' + won(ctx.parsed.y) } }
    },
    scales: commonScales
  }
});

/* ━━━━━━━━━━━━━━━━ 6. 현금흐름 계획 (Mixed: Bar + Line) ━━━━━━━━━━━━━━━━ */
const savingRate = INCOMES.map((inc, i) => inc > 0
  ? Math.round((inc - EXPENSES[i]) * 100 / inc)
  : null);

new Chart(document.getElementById('cashflowChart'), {
  type: 'bar',
  data: {
    labels: LABELS,
    datasets: [
      {
        type: 'bar',
        label: '월 수입계획',
        data: INCOMES,
        backgroundColor: 'rgba(16,185,129,.7)',
        borderRadius: 4,
        borderWidth: 0,
        yAxisID: 'yAmt',
      },
      {
        type: 'bar',
        label: '월 지출계획',
        data: EXPENSES,
        backgroundColor: 'rgba(239,68,68,.65)',
        borderRadius: 4,
        borderWidth: 0,
        yAxisID: 'yAmt',
      },
      {
        type: 'line',
        label: '저축률(%)',
        data: savingRate,
        borderColor: '#8b5cf6',
        backgroundColor: 'rgba(139,92,246,.1)',
        fill: false,
        tension: .35,
        pointRadius: 4,
        borderWidth: 2,
        yAxisID: 'yPct',
      }
    ]
  },
  options: {
    responsive: true,
    maintainAspectRatio: false,
    interaction: { mode: 'index', intersect: false },
    plugins: {
      legend: { position: 'top', labels: { boxWidth: 12, font: { size: 11 } } },
      tooltip: {
        callbacks: {
          label: ctx => {
            if (ctx.dataset.yAxisID === 'yPct') return ' 저축률: ' + (ctx.parsed.y ?? '-') + '%';
            return ' ' + ctx.dataset.label + ': ' + won(ctx.parsed.y);
          }
        }
      }
    },
    scales: {
      x: { grid: { display: false } },
      yAmt: {
        position: 'left',
        beginAtZero: true,
        ticks: { callback: v => eok(v) },
        grid: { color: 'rgba(0,0,0,.05)' }
      },
      yPct: {
        position: 'right',
        beginAtZero: true,
        max: 100,
        ticks: { callback: v => v + '%' },
        grid: { display: false }
      }
    }
  }
});

/* ━━━━━━━━━━━━━━━━ 테이블 MoM 컬럼 채우기 ━━━━━━━━━━━━━━━━ */
MOM.forEach((v, i) => {
  const el = document.getElementById('mom-' + i);
  if (!el) return;
  if (i === 0) { el.innerHTML = '<span class="text-muted small">-</span>'; return; }
  const cls = v > 0 ? 'mom-positive' : v < 0 ? 'mom-negative' : 'mom-zero';
  const prefix = v > 0 ? '+' : v < 0 ? '' : '';
  el.innerHTML = '<span class="' + cls + '">' + prefix + Number(v).toLocaleString('ko-KR') + '원</span>';
});
</script>
</c:if>
</body>
</html>
