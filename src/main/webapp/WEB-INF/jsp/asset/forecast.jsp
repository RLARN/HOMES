<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!doctype html>
<html lang="ko">
<head>
  <%@ include file="/WEB-INF/jsp/common/head.jsp" %>
  <title>자산변동예상 | HOMES</title>
  <style>
    /* ── KPI ── */
    .kpi-card { border-radius:14px; transition:transform .15s,box-shadow .15s; }
    .kpi-card:hover { transform:translateY(-2px); box-shadow:0 8px 24px rgba(0,0,0,.1); }
    .kpi-val { font-size:1.15rem; font-weight:700; line-height:1.2; }
    .kpi-sub { font-size:11px; color:#9ca3af; margin-top:2px; }
    /* ── 시나리오 입력 (가로) ── */
    .scenario-chip { display:inline-flex; align-items:center; gap:5px;
                     background:#f1f5f9; border-radius:20px; padding:4px 10px; }
    .scenario-dot  { width:10px; height:10px; border-radius:50%; flex-shrink:0; }
    .scenario-pct  { width:52px; text-align:center; font-size:12px;
                     border:none; background:transparent; outline:none; font-weight:600; }
    /* ── 차트 ── */
    .chart-wrap { position:relative; min-height:280px; }
    .chart-wrap-sm { position:relative; min-height:220px; }
    /* ── 인사이트 박스 ── */
    .insight-item { font-size:13px; padding:8px 12px; border-radius:8px;
                    background:#f8fafc; border-left:3px solid #6366f1; margin-bottom:6px; }
    /* ── 탭 ── */
    .nav-tabs .nav-link { font-size:13px; }
    /* ── 실적 보정 배지 ── */
    .ratio-badge { font-size:11px; border-radius:20px; padding:2px 8px; }
    /* ── AI 박스 ── */
    .ai-result-box { font-size:14px; line-height:1.8;
                     background:#f8fafc; border-radius:12px; padding:20px; }
    .ai-result-box strong { color:#1e293b; }
    /* 접힌 상태: 2줄만 표시 */
    .ai-result-collapsed { max-height:3.8em; overflow:hidden; position:relative; }
    .ai-result-collapsed::after {
      content:''; position:absolute; bottom:0; left:0; right:0; height:2em;
      background:linear-gradient(transparent, #f8fafc);
    }
    /* 토글 버튼 */
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

      <!-- ── 페이지 헤더 ── -->
      <div class="d-flex flex-column flex-md-row align-items-md-center justify-content-between gap-2 mb-3">
        <div>
          <div class="homes-badge mb-2">Asset</div>
          <h1 class="h4 fw-bold mb-1">자산변동예상</h1>
          <div class="text-muted small" id="hstBadgeWrap">
            전표처리 실적 기반으로 보정된 예측 · 자산 증감률 반영
          </div>
        </div>
      </div>

      <!-- ── 컨트롤 패널 (한 줄) ── -->
      <div class="card homes-card mb-3">
        <div class="card-body py-2 px-3 px-md-4">
          <div class="d-flex flex-wrap align-items-center gap-3">

            <!-- 예측 종료 시점 -->
            <div class="d-flex align-items-center gap-2">
              <span class="fw-semibold small text-nowrap">종료 시점</span>
              <input type="month" class="form-control form-control-sm" id="untilYymm" style="width:150px;" />
              <span class="text-muted small text-nowrap" id="monthsDisplay"></span>
            </div>

            <div class="vr d-none d-md-block"></div>

            <!-- 시나리오 설정 (가로) -->
            <div class="d-flex align-items-center gap-1 flex-wrap">
              <span class="fw-semibold small text-nowrap me-1">시나리오</span>
              <div id="scenarioInputs" class="d-flex gap-2 flex-wrap"></div>
            </div>

            <div class="ms-auto">
              <button class="btn btn-primary btn-sm homes-pill px-3" onclick="loadData()">조회</button>
            </div>

          </div>
        </div>
      </div>

      <!-- ── AI 분석 (최상단) ── -->
      <div class="card homes-card mb-4" id="aiCard">
        <div class="card-header bg-transparent border-0 pt-3 px-3 px-md-4 pb-0 d-flex align-items-center justify-content-between">
          <span class="fw-semibold">H-Ops AI 분석 리포트</span>
          <div class="d-flex gap-2">
            <button class="btn btn-outline-secondary btn-sm homes-pill d-flex align-items-center gap-1" id="aiRetryBtn" onclick="askAI()" style="display:none;">
              <span class="material-symbols-rounded ms-sm">refresh</span>재분석</button>
          </div>
        </div>
        <div class="card-body px-3 px-md-4">
          <div id="aiLoadingWrap"></div>
          <div id="aiResultWrap" class="ai-result-box ai-result-collapsed" style="display:none;"></div>
          <button class="ai-toggle-btn" id="aiToggleBtn" style="display:none;" onclick="toggleAiResult()">▼ 전체 보기</button>
        </div>
      </div>

      <!-- ── KPI 카드 ── -->
      <div class="row g-3 mb-4">
        <div class="col-6 col-md-3">
          <div class="card homes-card kpi-card h-100">
            <div class="card-body">
              <div class="text-muted small mb-1">현재 순자산</div>
              <div class="kpi-val" id="cardNetAsset">-</div>
              <div class="kpi-sub">총자산 − 총대출</div>
            </div>
          </div>
        </div>
        <div class="col-6 col-md-3">
          <div class="card homes-card kpi-card h-100">
            <div class="card-body">
              <div class="text-muted small mb-1">실적 월평균 순변동</div>
              <div class="kpi-val text-success" id="cardActualMoM">-</div>
              <div class="kpi-sub">전표처리 이력 기준</div>
            </div>
          </div>
        </div>
        <div class="col-6 col-md-3">
          <div class="card homes-card kpi-card h-100">
            <div class="card-body">
              <div class="text-muted small mb-1">계획 대비 실적 보정</div>
              <div class="kpi-val" id="cardRatio">-</div>
              <div class="kpi-sub" id="cardRatioSub">전표처리 이력 없음</div>
            </div>
          </div>
        </div>
        <div class="col-6 col-md-3">
          <div class="card homes-card kpi-card h-100">
            <div class="card-body">
              <div class="text-muted small mb-1">기간 말 순자산 (100%)</div>
              <div class="kpi-val" id="cardEndAsset">-</div>
              <div class="kpi-sub">기준 시나리오 기준</div>
            </div>
          </div>
        </div>
      </div>

      <!-- ── 인사이트 ── -->
      <div id="insightBox" class="mb-3" style="display:none;"></div>

      <!-- ── 메인 차트: 순자산 예측 ── -->
      <div class="card homes-card mb-3">
        <div class="card-header bg-transparent border-0 pt-3 px-3 px-md-4 pb-0 d-flex align-items-center justify-content-between">
          <div class="fw-semibold d-flex align-items-center gap-1">
            <span class="material-symbols-rounded ms-btn">trending_up</span>순자산 변동 예측</div>
          <span class="badge bg-primary-subtle text-primary border" style="font-size:11px;" id="forecastBadge"></span>
        </div>
        <div class="card-body px-3 px-md-4">
          <div id="chartLoading" class="text-center py-5 text-muted">
            <div class="spinner-border spinner-border-sm me-2"></div>데이터를 불러오는 중...
          </div>
          <canvas id="forecastChart" style="display:none; max-height:400px;"></canvas>
        </div>
      </div>

      <!-- ── 인사이트 차트 행 ── -->
      <div class="row g-3 mb-3">
        <!-- 실적 MoM 이력 + 예측 연결 -->
        <div class="col-12 col-lg-6">
          <div class="card homes-card h-100">
            <div class="card-header bg-transparent fw-semibold d-flex align-items-center gap-1">
              <span class="material-symbols-rounded ms-sm">bar_chart</span>실적 월변동 이력 &amp; 예측 기준선
            </div>
            <div class="card-body chart-wrap-sm">
              <div id="momChartEmpty" class="text-center text-muted py-4 d-none">전표처리 이력 없음</div>
              <canvas id="momChart"></canvas>
            </div>
          </div>
        </div>
        <!-- 저축률 추이 -->
        <div class="col-12 col-lg-6">
          <div class="card homes-card h-100">
            <div class="card-header bg-transparent fw-semibold d-flex align-items-center gap-1">
              <span class="material-symbols-rounded ms-sm">show_chart</span>저축률 추이 (전표처리 실적)
            </div>
            <div class="card-body chart-wrap-sm">
              <div id="srChartEmpty" class="text-center text-muted py-4 d-none">전표처리 이력 없음</div>
              <canvas id="savingRateChart"></canvas>
            </div>
          </div>
        </div>
      </div>

      <div class="row g-3 mb-4">
        <!-- 수입 vs 지출 계획 분포 -->
        <div class="col-12 col-lg-5">
          <div class="card homes-card h-100">
            <div class="card-header bg-transparent fw-semibold d-flex align-items-center gap-1">
              <span class="material-symbols-rounded ms-sm">donut_large</span>수입 / 지출 구성 (계획 기준)
            </div>
            <div class="card-body d-flex flex-column align-items-center chart-wrap-sm">
              <canvas id="flowPieChart" style="max-height:200px;"></canvas>
              <div id="flowPieLegend" class="mt-2 w-100" style="font-size:11px;"></div>
            </div>
          </div>
        </div>
        <!-- 자산 증감률 자산별 기여 -->
        <div class="col-12 col-lg-7">
          <div class="card homes-card h-100">
            <div class="card-header bg-transparent fw-semibold d-flex align-items-center gap-1">
              <span class="material-symbols-rounded ms-sm">stacked_bar_chart</span>자산별 예상 기여 (증감률 기반, 기간 합계)
            </div>
            <div class="card-body chart-wrap-sm">
              <div id="rateBarEmpty" class="text-center text-muted py-4 d-none">증감률 설정된 자산 없음</div>
              <canvas id="rateBarChart"></canvas>
            </div>
          </div>
        </div>
      </div>

      <!-- ── 탭 영역 ── -->
      <div class="card homes-card">
        <div class="card-header bg-transparent border-0 pt-3 px-3 px-md-4 pb-0">
          <ul class="nav nav-tabs" id="detailTab">
            <li class="nav-item">
              <button class="nav-link active" data-bs-toggle="tab" data-bs-target="#tabBreakdown">예측 월별 상세</button>
            </li>
            <li class="nav-item">
              <button class="nav-link" data-bs-toggle="tab" data-bs-target="#tabHistory">전표 실적</button>
            </li>
            <li class="nav-item">
              <button class="nav-link" data-bs-toggle="tab" data-bs-target="#tabPlans">현금흐름 항목</button>
            </li>
            <li class="nav-item">
              <button class="nav-link" data-bs-toggle="tab" data-bs-target="#tabAssetRate">자산 증감률</button>
            </li>
          </ul>
        </div>
        <div class="card-body px-3 px-md-4 pt-2">
          <div class="tab-content">

            <!-- 예측 월별 상세 -->
            <div class="tab-pane fade show active" id="tabBreakdown">
              <div class="table-responsive">
                <table class="table align-middle homes-table" id="breakdownTable">
                  <thead>
                    <tr class="text-muted small">
                      <th>월</th>
                      <th class="text-end">보정 수입</th>
                      <th class="text-end">자산증감</th>
                      <th class="text-end">보정 지출</th>
                      <th class="text-end">순변동 (100%)</th>
                      <th class="text-end">누적 순자산 (100%)</th>
                    </tr>
                  </thead>
                  <tbody id="breakdownBody">
                    <tr><td colspan="6" class="text-center text-muted py-4">조회 중...</td></tr>
                  </tbody>
                </table>
              </div>
            </div>

            <!-- 전표 실적 -->
            <div class="tab-pane fade" id="tabHistory">
              <div class="table-responsive">
                <table class="table align-middle homes-table">
                  <thead>
                    <tr class="text-muted small">
                      <th>전표 기준월</th>
                      <th class="text-end">총자산</th>
                      <th class="text-end">총대출</th>
                      <th class="text-end">순자산</th>
                      <th class="text-end">월 수입계획</th>
                      <th class="text-end">월 지출계획</th>
                      <th class="text-end">MoM 순자산 변동</th>
                    </tr>
                  </thead>
                  <tbody id="historyBody">
                    <tr><td colspan="7" class="text-center text-muted py-4">조회 중...</td></tr>
                  </tbody>
                </table>
              </div>
            </div>

            <!-- 현금흐름 항목 -->
            <div class="tab-pane fade" id="tabPlans">
              <div class="table-responsive">
                <table class="table align-middle homes-table">
                  <thead>
                    <tr class="text-muted small">
                      <th>항목명</th>
                      <th>유형</th>
                      <th class="text-center">구분</th>
                      <th class="text-center">사이클</th>
                      <th class="text-end">1회 금액</th>
                      <th class="text-end">발동횟수</th>
                      <th class="text-end">기간 합계</th>
                    </tr>
                  </thead>
                  <tbody id="planSummaryBody">
                    <tr><td colspan="7" class="text-center text-muted py-4">조회 중...</td></tr>
                  </tbody>
                </table>
              </div>
            </div>

            <!-- 자산 증감률 -->
            <div class="tab-pane fade" id="tabAssetRate">
              <div class="table-responsive">
                <table class="table align-middle homes-table">
                  <thead>
                    <tr class="text-muted small">
                      <th>자산명</th>
                      <th class="text-end">현재금액</th>
                      <th class="text-center">증감률</th>
                      <th class="text-center">사이클</th>
                      <th class="text-end">월 기여분</th>
                      <th class="text-end">기간 총 기여</th>
                    </tr>
                  </thead>
                  <tbody id="assetRateBody">
                    <tr><td colspan="6" class="text-center text-muted py-4">조회 중...</td></tr>
                  </tbody>
                </table>
              </div>
              <div class="text-muted small mt-2 px-1">
                ※ 증감률은 자산원장 수정 화면에서 설정합니다. (주식·펀드·부동산 등 기대 수익률)
              </div>
            </div>


          </div>
        </div>
      </div>

    </div>
    <%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
  </main>
</div>

<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.3/dist/chart.umd.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
(function () {
  'use strict';

  const ctx = '${pageContext.request.contextPath}';

  // ── 시나리오 색상·기본값 ─────────────────────────────────
  const SC_DEFS = [
    { pct: 90,  color: '#ef4444', label: '비관' },
    { pct: 95,  color: '#f97316', label: '보수' },
    { pct: 100, color: '#3b82f6', label: '기준' },
    { pct: 105, color: '#10b981', label: '긍정' },
    { pct: 110, color: '#8b5cf6', label: '낙관' },
  ];
  const MAX_SC = 5;

  let charts = {};   // chart instances keyed by id
  let rawData = null;

  // ── 시나리오 입력 UI 초기화 ──────────────────────────────
  function initScenarioInputs() {
    const wrap = document.getElementById('scenarioInputs');
    wrap.innerHTML = SC_DEFS.map((sc, i) =>
      '<label class="scenario-chip" style="cursor:pointer;" title="' + sc.label + '">' +
      '<input type="checkbox" class="form-check-input sc-check me-1" id="scCheck' + i + '" data-idx="' + i + '" checked style="margin:0;">' +
      '<span class="scenario-dot" style="background:' + sc.color + ';"></span>' +
      '<input type="number" class="scenario-pct" id="scPct' + i + '" value="' + sc.pct + '" min="1" max="500" onclick="event.stopPropagation();">' +
      '<span style="font-size:11px;color:#6b7280;">%</span>' +
      '</label>'
    ).join('');
  }

  // ── 기본 날짜 세팅 (현재 + 12개월) ──────────────────────
  function initDatePicker() {
    const d = new Date();
    d.setMonth(d.getMonth() + 12);
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, '0');
    document.getElementById('untilYymm').value = y + '-' + m;
    updateMonthsDisplay();
    document.getElementById('untilYymm').addEventListener('change', updateMonthsDisplay);
  }

  function updateMonthsDisplay() {
    const val = document.getElementById('untilYymm').value;
    if (!val) return;
    const now   = new Date(); now.setDate(1);
    const until = new Date(val + '-01');
    const diff  = Math.round((until - now) / (1000 * 60 * 60 * 24 * 30.44));
    document.getElementById('monthsDisplay').textContent = '(' + Math.max(1, diff) + '개월)';
  }

  // ── 데이터 로드 ──────────────────────────────────────────
  function loadData() {
    const until   = document.getElementById('untilYymm').value;
    const weights = Array.from({length: SC_DEFS.length}, (_, i) => {
      const el = document.getElementById('scPct' + i);
      return el ? (parseInt(el.value) || 100) : SC_DEFS[i].pct;
    }).join(',');

    document.getElementById('chartLoading').style.display = '';
    document.getElementById('forecastChart').style.display = 'none';

    fetch(ctx + '/asset/forecast/data?untilYymm=' + until + '&weights=' + weights)
      .then(r => r.json())
      .then(data => {
        rawData = data;
        renderAll(data);
        askAI();
      })
      .catch(err => {
        document.getElementById('chartLoading').textContent = '로드 실패: ' + err.message;
      });
  }

  // ── 전체 렌더 ────────────────────────────────────────────
  function renderAll(data) {
    renderKpi(data);
    renderInsights(data.insights);
    renderForecastChart(data);
    renderMomChart(data);
    renderSavingRateChart(data);
    renderFlowPieChart(data);
    renderRateBarChart(data.assetRateSummary);
    renderBreakdown(data.breakdown);
    renderHistory(data);
    renderPlanSummary(data.planSummary);
    renderAssetRate(data.assetRateSummary);
    renderAiJson(data.aiContext);
    // 배지
    const months = data.breakdown ? data.breakdown.length : 0;
    document.getElementById('forecastBadge').textContent =
      months + '개월 예측 · ' + (data.hstCount || 0) + '개월 실적 기반';
  }

  // ── KPI ─────────────────────────────────────────────────
  function renderKpi(data) {
    document.getElementById('cardNetAsset').textContent = fmtShort(data.currentNetAsset) + '원';

    const mom = data.actualAvgMoM || 0;
    const momEl = document.getElementById('cardActualMoM');
    momEl.textContent = (mom >= 0 ? '+' : '') + fmtShort(mom) + '원/월';
    momEl.className = 'kpi-val ' + (mom >= 0 ? 'text-success' : 'text-danger');

    const ratio = data.actualityRatio;
    const ratioEl = document.getElementById('cardRatio');
    if (data.hstCount >= 2) {
      const pct = Math.round((ratio - 1) * 1000) / 10;
      ratioEl.textContent = (pct >= 0 ? '+' : '') + pct + '%';
      ratioEl.className = 'kpi-val ' + (pct >= 0 ? 'text-success' : 'text-danger');
      document.getElementById('cardRatioSub').textContent = '계획 대비 실적 달성률 보정';
    } else {
      ratioEl.textContent = '-';
      document.getElementById('cardRatioSub').textContent = '전표처리 이력 부족 (계획 기준 적용)';
    }

    const base = data.scenarios ? data.scenarios.find(s => s.weight === 100) : null;
    const endEl = document.getElementById('cardEndAsset');
    if (base && base.data && base.data.length) {
      const finalNet = base.data[base.data.length - 1];
      const gain = finalNet - data.currentNetAsset;
      endEl.textContent = fmtShort(finalNet) + '원';
      endEl.className = 'kpi-val ' + (finalNet >= data.currentNetAsset ? 'text-success' : 'text-danger');
    }
  }

  // ── 인사이트 ─────────────────────────────────────────────
  function renderInsights(insights) {
    const box = document.getElementById('insightBox');
    if (!insights || !insights.length) { box.style.display = 'none'; return; }
    box.style.display = '';
    box.innerHTML = '<div class="fw-semibold small text-muted mb-2 d-flex align-items-center gap-1"><span class="material-symbols-rounded ms-sm">lightbulb</span>예측 인사이트</div>' +
      insights.map(txt => '<div class="insight-item">' + esc(txt) + '</div>').join('');
  }

  // ── 메인 예측 차트 ───────────────────────────────────────
  function renderForecastChart(data) {
    document.getElementById('chartLoading').style.display = 'none';
    const canvas = document.getElementById('forecastChart');
    canvas.style.display = '';

    const checks = Array.from(document.querySelectorAll('.sc-check'));
    const activeIdxs = new Set(checks.filter(c => c.checked).map(c => parseInt(c.dataset.idx)));

    const datasets = (data.scenarios || []).map((sc, i) => {
      if (!activeIdxs.has(i)) return null;
      return {
        label:           sc.label,
        data:            sc.data,
        borderColor:     sc.borderColor,
        backgroundColor: sc.backgroundColor,
        tension:         sc.tension || 0.3,
        fill:            sc.weight === 100,
        borderWidth:     sc.borderWidth || 2,
        borderDash:      sc.borderDash || [],
        pointRadius:     data.labels.length > 24 ? 0 : 3,
        pointHoverRadius: 5
      };
    }).filter(Boolean);

    destroyChart('forecastChart');
    charts['forecastChart'] = new Chart(canvas, {
      type: 'line',
      data: { labels: data.labels, datasets },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: { mode: 'index', intersect: false },
        plugins: {
          legend: { position: 'top', labels: { boxWidth: 12, font: { size: 12 } } },
          tooltip: { callbacks: { label: c => ' ' + c.dataset.label + ': ' + fmt(c.raw) + '원' } }
        },
        scales: {
          x: { grid: { display: false } },
          y: {
            ticks: { callback: v => fmtShort(v) + '원' },
            grid:  { color: 'rgba(0,0,0,.05)' }
          }
        }
      }
    });
  }

  // ── MoM 이력 차트 ────────────────────────────────────────
  function renderMomChart(data) {
    const canvas = document.getElementById('momChart');
    const empty  = document.getElementById('momChartEmpty');
    if (!data.hstMoM || data.hstMoM.length < 2) {
      canvas.style.display = 'none';
      empty.classList.remove('d-none');
      return;
    }
    empty.classList.add('d-none');
    canvas.style.display = '';

    const momColors = data.hstMoM.map(v => v >= 0 ? 'rgba(16,185,129,.7)' : 'rgba(239,68,68,.7)');
    // 예측 기준선 (actualAvgMoM) 수평선
    const avgLine = data.hstLabels.map(() => data.actualAvgMoM);

    destroyChart('momChart');
    charts['momChart'] = new Chart(canvas, {
      type: 'bar',
      data: {
        labels: data.hstLabels,
        datasets: [
          {
            type: 'bar',
            label: '실적 MoM',
            data:  data.hstMoM,
            backgroundColor: momColors,
            borderWidth: 0,
            borderRadius: 4,
            yAxisID: 'y',
          },
          {
            type: 'line',
            label: '평균 (예측 기준)',
            data:  avgLine,
            borderColor: '#6366f1',
            borderWidth: 2,
            borderDash: [5, 3],
            pointRadius: 0,
            fill: false,
            yAxisID: 'y',
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { position: 'top', labels: { boxWidth: 10, font: { size: 11 } } },
          tooltip: { callbacks: { label: c => ' ' + c.dataset.label + ': ' + fmt(c.raw) + '원' } }
        },
        scales: {
          x: { grid: { display: false } },
          y: { ticks: { callback: v => fmtShort(v) }, grid: { color: 'rgba(0,0,0,.05)' } }
        }
      }
    });
  }

  // ── 저축률 추이 차트 ─────────────────────────────────────
  function renderSavingRateChart(data) {
    const canvas = document.getElementById('savingRateChart');
    const empty  = document.getElementById('srChartEmpty');
    if (!data.hstSavingRates || data.hstSavingRates.length < 2) {
      canvas.style.display = 'none';
      empty.classList.remove('d-none');
      return;
    }
    empty.classList.add('d-none');
    canvas.style.display = '';

    destroyChart('savingRateChart');
    charts['savingRateChart'] = new Chart(canvas, {
      type: 'line',
      data: {
        labels: data.hstLabels,
        datasets: [{
          label: '저축률(%)',
          data:  data.hstSavingRates,
          borderColor: '#10b981',
          backgroundColor: 'rgba(16,185,129,.1)',
          fill: true,
          tension: 0.35,
          pointRadius: 4,
          borderWidth: 2,
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: { callbacks: { label: c => ' 저축률: ' + c.parsed.y + '%' } }
        },
        scales: {
          x: { grid: { display: false } },
          y: {
            max: 100,
            ticks: { callback: v => v + '%' },
            grid: { color: 'rgba(0,0,0,.05)' }
          }
        }
      }
    });
  }

  // ── 수입/지출 파이 ───────────────────────────────────────
  function renderFlowPieChart(data) {
    const plans = data.planSummary || [];
    const incTotal = plans.filter(p => p.flowType === 'INCOME').reduce((s, p) => s + (p.totalAmount || 0), 0);
    const expTotal = plans.filter(p => p.flowType !== 'INCOME').reduce((s, p) => s + (p.totalAmount || 0), 0);

    const canvas = document.getElementById('flowPieChart');
    const legend = document.getElementById('flowPieLegend');
    if (incTotal + expTotal === 0) {
      canvas.style.display = 'none';
      legend.textContent = '데이터 없음';
      return;
    }

    const pieLabels = ['수입', '지출'];
    const pieData   = [incTotal, expTotal];
    const pieColors = ['rgba(16,185,129,.8)', 'rgba(239,68,68,.8)'];

    destroyChart('flowPieChart');
    charts['flowPieChart'] = new Chart(canvas, {
      type: 'doughnut',
      data: { labels: pieLabels, datasets: [{ data: pieData, backgroundColor: pieColors, borderWidth: 2, hoverOffset: 6 }] },
      options: {
        responsive: true,
        maintainAspectRatio: true,
        cutout: '55%',
        plugins: {
          legend: { display: false },
          tooltip: { callbacks: { label: c => ' ' + c.label + ': ' + fmt(c.parsed) + '원' } }
        }
      }
    });

    const total = incTotal + expTotal;
    legend.innerHTML = pieLabels.map((lbl, i) =>
      '<div class="d-flex justify-content-between align-items-center mb-1">' +
      '<div class="d-flex align-items-center gap-1">' +
      '<span style="width:10px;height:10px;border-radius:50%;background:' + pieColors[i] + ';display:inline-block;"></span>' +
      '<span>' + lbl + '</span></div>' +
      '<span class="fw-semibold">' + Math.round(pieData[i] * 100 / total) + '%</span></div>'
    ).join('');
  }

  // ── 자산별 기여 가로 바 ──────────────────────────────────
  function renderRateBarChart(assetRates) {
    const canvas = document.getElementById('rateBarChart');
    const empty  = document.getElementById('rateBarEmpty');
    if (!assetRates || !assetRates.length) {
      canvas.style.display = 'none';
      empty.classList.remove('d-none');
      return;
    }
    empty.classList.add('d-none');
    canvas.style.display = '';

    const names  = assetRates.map(a => a.assetNm);
    const totals = assetRates.map(a => a.totalGain || 0);
    const colors = totals.map(v => v >= 0 ? 'rgba(16,185,129,.75)' : 'rgba(239,68,68,.75)');

    destroyChart('rateBarChart');
    charts['rateBarChart'] = new Chart(canvas, {
      type: 'bar',
      data: {
        labels: names,
        datasets: [{
          label: '기간 총 기여',
          data: totals,
          backgroundColor: colors,
          borderWidth: 0,
          borderRadius: 4,
        }]
      },
      options: {
        indexAxis: 'y',
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: { callbacks: { label: c => ' ' + (c.raw >= 0 ? '+' : '') + fmt(c.raw) + '원' } }
        },
        scales: {
          x: { ticks: { callback: v => fmtShort(v) }, grid: { color: 'rgba(0,0,0,.05)' } },
          y: { grid: { display: false } }
        }
      }
    });
  }

  // ── 탭: 예측 월별 상세 ───────────────────────────────────
  function renderBreakdown(breakdown) {
    const tbody = document.getElementById('breakdownBody');
    if (!breakdown || !breakdown.length) {
      tbody.innerHTML = '<tr><td colspan="6" class="homes-empty">데이터 없음</td></tr>';
      return;
    }
    tbody.innerHTML = breakdown.map(r => {
      const gain   = r.assetGain || 0;
      const netCls = r.net >= 0 ? 'text-success' : 'text-danger';
      const cumCls = r.cumulative >= 0 ? 'text-primary' : 'text-danger';
      return '<tr>' +
        '<td class="fw-semibold text-nowrap">' + r.month + '</td>' +
        '<td class="text-end text-success text-nowrap">'  + fmt(r.income) + '원</td>' +
        '<td class="text-end text-nowrap ' + (gain >= 0 ? 'text-success' : 'text-danger') + '">' + (gain >= 0 ? '+' : '') + fmt(gain) + '원</td>' +
        '<td class="text-end text-danger text-nowrap">'   + fmt(r.expense) + '원</td>' +
        '<td class="text-end text-nowrap fw-semibold ' + netCls + '">' + (r.net >= 0 ? '+' : '') + fmt(r.net) + '원</td>' +
        '<td class="text-end text-nowrap fw-semibold ' + cumCls + '">' + fmt(r.cumulative) + '원</td>' +
        '</tr>';
    }).join('');
  }

  // ── 탭: 전표 실적 ────────────────────────────────────────
  function renderHistory(data) {
    const tbody = document.getElementById('historyBody');
    const hst   = data.hstNetAssets || [];
    const lbls  = data.hstLabels    || [];
    const mom   = data.hstMoM       || [];
    const inc   = [];  // not available per-month from API directly, skip
    if (!hst.length) {
      tbody.innerHTML = '<tr><td colspan="7" class="text-center text-muted py-4">전표처리 이력이 없습니다.<br><small>수지계정현황에서 전표처리 후 다시 확인하세요.</small></td></tr>';
      return;
    }
    // We only have aggregated hst data; reconstruct from breakdown approximation
    tbody.innerHTML = hst.map((net, i) => {
      const m = mom[i] || 0;
      const mCls = m > 0 ? 'text-success' : m < 0 ? 'text-danger' : 'text-muted';
      return '<tr>' +
        '<td class="fw-semibold">' + (lbls[i] || '-') + '</td>' +
        '<td class="text-end">-</td>' +
        '<td class="text-end">-</td>' +
        '<td class="text-end text-primary fw-semibold">' + fmt(net) + '원</td>' +
        '<td class="text-end text-success">-</td>' +
        '<td class="text-end text-danger">-</td>' +
        '<td class="text-end ' + mCls + '">' + (i === 0 ? '-' : (m >= 0 ? '+' : '') + fmt(m) + '원') + '</td>' +
        '</tr>';
    }).join('');
  }

  // ── 탭: 현금흐름 항목 ────────────────────────────────────
  function renderPlanSummary(plans) {
    const tbody = document.getElementById('planSummaryBody');
    if (!plans || !plans.length) {
      tbody.innerHTML = '<tr><td colspan="7" class="homes-empty">항목 없음</td></tr>';
      return;
    }
    const flowMap  = { INCOME:'수입', EXPENSE:'지출', SAVING:'저축', INVEST:'투자' };
    const unitMap  = { DAY:'일', MONTH:'개월', YEAR:'년' };
    const income   = plans.filter(p => p.flowType === 'INCOME');
    const expense  = plans.filter(p => p.flowType !== 'INCOME');
    let html = '';
    if (income.length) {
      html += '<tr class="table-success"><td colspan="7" class="fw-semibold small py-1 px-2">▶ 수입 항목</td></tr>';
      html += income.map(p => planRow(p, 'text-success', flowMap, unitMap)).join('');
    }
    if (expense.length) {
      html += '<tr class="table-danger"><td colspan="7" class="fw-semibold small py-1 px-2">▶ 지출/저축/투자 항목</td></tr>';
      html += expense.map(p => planRow(p, 'text-danger', flowMap, unitMap)).join('');
    }
    tbody.innerHTML = html;
  }

  function planRow(p, cls, flowMap, unitMap) {
    return '<tr>' +
      '<td class="fw-semibold">' + esc(p.planNm) + '</td>' +
      '<td><span class="badge bg-secondary-subtle text-secondary">' + esc(p.planTypeNm || '-') + '</span></td>' +
      '<td class="text-center"><span class="badge ' + (p.flowType === 'INCOME' ? 'bg-success-subtle text-success' : 'bg-danger-subtle text-danger') + '">' + (flowMap[p.flowType] || p.flowType) + '</span></td>' +
      '<td class="text-center small text-muted">매 ' + (p.cycleNum || 1) + (unitMap[p.cycleUnit] || '') + '</td>' +
      '<td class="text-end text-nowrap ' + cls + '">'              + fmt(p.amount)      + '원</td>' +
      '<td class="text-end text-nowrap">'                          + p.totalFires       + '회</td>' +
      '<td class="text-end text-nowrap fw-semibold ' + cls + '">'  + fmt(p.totalAmount) + '원</td>' +
      '</tr>';
  }

  // ── 탭: 자산 증감률 ──────────────────────────────────────
  function renderAssetRate(assets) {
    const tbody = document.getElementById('assetRateBody');
    if (!assets || !assets.length) {
      tbody.innerHTML = '<tr><td colspan="6" class="homes-empty">증감률 설정 자산 없음</td></tr>';
      return;
    }
    const unitMap = { DAY:'일', MONTH:'개월', YEAR:'년' };
    tbody.innerHTML = assets.map(a => {
      const rate  = parseFloat(a.expectedRate) || 0;
      const mo    = a.monthlyGain || 0;
      const tot   = a.totalGain   || 0;
      return '<tr>' +
        '<td class="fw-semibold">' + esc(a.assetNm) + '</td>' +
        '<td class="text-end">' + fmt(a.amount) + '원</td>' +
        '<td class="text-center ' + (rate >= 0 ? 'text-success' : 'text-danger') + '">' + (rate >= 0 ? '+' : '') + rate + '%</td>' +
        '<td class="text-center text-muted small">매 ' + (a.rateCycleNum || 1) + (unitMap[a.rateCycleUnit] || '') + '</td>' +
        '<td class="text-end ' + (mo >= 0 ? 'text-success' : 'text-danger') + '">' + (mo >= 0 ? '+' : '') + fmt(mo) + '원/월</td>' +
        '<td class="text-end fw-semibold ' + (tot >= 0 ? 'text-success' : 'text-danger') + '">' + (tot >= 0 ? '+' : '') + fmt(tot) + '원</td>' +
        '</tr>';
    }).join('');
  }

  // ── 탭: AI 분석 ──────────────────────────────────────────
  function renderAiJson(aiCtx) {
    // aiContext는 rawData에 저장만 해두고 화면엔 표시 안 함
  }

  function askAI() {
    if (!rawData || !rawData.aiContext) return;

    const loading = document.getElementById('aiLoadingWrap');
    const result  = document.getElementById('aiResultWrap');
    const retry   = document.getElementById('aiRetryBtn');

    HOMES.aiProgress.show(loading);
    result.style.display  = 'none';
    retry.style.display   = 'none';

    const controller = new AbortController();
    const tid = setTimeout(() => controller.abort(), 175000); // 175초

    fetch(ctx + '/asset/forecast/analyze', {
      method:  'POST',
      headers: { 'Content-Type': 'application/json' },
      body:    JSON.stringify(rawData.aiContext),
      signal:  controller.signal
    }).finally(() => clearTimeout(tid))
    .then(r => r.json())
    .then(res => {
      HOMES.aiProgress.hide(loading);
      result.style.display  = '';
      retry.style.display   = '';

      const toggle = document.getElementById('aiToggleBtn');
      if (res.success) {
        result.innerHTML = res.text
          .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
          .replace(/^### (.+)$/gm, '<div class="fw-bold mt-3 mb-1 text-primary fs-6">$1</div>')
          .replace(/^## (.+)$/gm,  '<div class="fw-bold mt-3 mb-1 fs-5">$1</div>')
          .replace(/^# (.+)$/gm,   '<div class="fw-bold mt-3 mb-1 fs-4">$1</div>')
          .replace(/^- (.+)$/gm,   '<div class="ms-3">• $1</div>')
          .replace(/\n/g, '<br>');
        // 기본 접힌 상태로 시작
        result.classList.add('ai-result-collapsed');
        toggle.style.display = '';
        toggle.textContent   = '▼ 전체 보기';
      } else {
        result.innerHTML = '<span class="text-danger">' + esc(res.text) + '</span>';
        toggle.style.display = 'none';
      }
    })
    .catch(err => {
      HOMES.aiProgress.hide(loading);
      result.style.display  = '';
      retry.style.display   = '';
      result.innerHTML = '<span class="text-danger">요청 실패: ' + esc(err.message) + '</span>';
    });
  }

  // ── 유틸 ─────────────────────────────────────────────────
  function fmt(v) { if (v == null) return '0'; return Math.round(v).toLocaleString('ko-KR'); }
  function fmtShort(v) {
    const abs = Math.abs(v || 0);
    const sign = v < 0 ? '-' : '';
    if (abs >= 1e8) return sign + (abs / 1e8).toFixed(1) + '억';
    if (abs >= 1e4) return sign + Math.round(abs / 1e4).toLocaleString() + '만';
    return (Math.round(v || 0)).toLocaleString('ko-KR');
  }
  function esc(s) { return s ? String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;') : ''; }
  function destroyChart(id) { if (charts[id]) { charts[id].destroy(); delete charts[id]; } }

  // ── 초기화 ────────────────────────────────────────────────
  initScenarioInputs();
  initDatePicker();
  loadData();

  // 시나리오 체크 변경 시 차트만 재렌더
  document.getElementById('scenarioInputs').addEventListener('change', function(e) {
    if (e.target.classList.contains('sc-check') && rawData) renderForecastChart(rawData);
  });

  function toggleAiResult() {
    const result = document.getElementById('aiResultWrap');
    const btn    = document.getElementById('aiToggleBtn');
    const collapsed = result.classList.toggle('ai-result-collapsed');
    btn.textContent = collapsed ? '▼ 전체 보기' : '▲ 접기';
  }

  window.loadData       = loadData;
  window.askAI          = askAI;
  window.toggleAiResult = toggleAiResult;
})();
</script>
</body>
</html>
