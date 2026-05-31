<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<!doctype html>
<html lang="ko">
<head>
  <%@ include file="/WEB-INF/jsp/common/head.jsp" %>
  <title>${dispYymm} 생활비 | HOMES</title>
  <style>
    /* 카테고리 헤더 행 */
    .living-cat-row {
      background: #eef2ff !important;
    }
    .living-cat-row td { font-weight: 600; }

    /* 항목 행 */
    .living-item-row td { vertical-align: middle; }

    /* 금액 입력 */
    .amt-input {
      text-align: right;
      border: 1px solid #dee2e6;
      border-radius: 6px;
      padding: 4px 8px;
      width: 130px;
      font-size: 14px;
      background: #fff;
      transition: border-color .15s;
    }
    .amt-input:focus {
      outline: none;
      border-color: #6366f1;
      box-shadow: 0 0 0 3px rgba(99,102,241,.15);
    }
    .amt-input.saved { border-color: #10b981; background: #f0fdf4; }
    .amt-input.over  { color: #ef4444; }

    /* 카테고리 소계 강조 */
    .cat-total-cell { font-weight: 600; font-size: 13px; }

    /* 합계 행 */
    .grand-total-row { background: #f8f9fa; }
    .grand-total-row td { font-weight: 700; font-size: 15px; }

    /* 나머지 행 */
    .remain-row { background: #fff8e1; }
    .remain-row td { font-weight: 700; color: #92400e; }

    /* 진행바 */
    .mini-progress {
      height: 5px;
      border-radius: 3px;
      background: #e5e7eb;
      overflow: hidden;
      margin-top: 3px;
    }
    .mini-progress-bar { height: 100%; border-radius: 3px; transition: width .3s; }

    /* 저장 상태 뱃지 */
    .save-badge {
      font-size: 11px;
      padding: 2px 6px;
      border-radius: 10px;
    }

    @media (max-width: 767px) {
      .amt-input { width: 100px; font-size: 13px; }
      th, td { font-size: 13px; }
    }
  </style>
</head>
<body class="homes-bg">
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>

<div class="homes-shell d-lg-flex">
  <%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

  <main class="homes-main flex-grow-1 d-flex flex-column">
    <div class="homes-main-body px-3 px-md-4 py-4">

      <!-- 페이지 헤더 -->
      <div class="d-flex flex-column flex-md-row align-items-md-center justify-content-between gap-2 mb-3">
        <div>
          <div class="homes-badge mb-2">Budget</div>
          <h1 class="h4 fw-bold mb-1">${dispYymm} 생활비</h1>
          <div class="text-muted small">항목별 실제 지출금액을 입력하세요. 자동 저장됩니다.</div>
        </div>
        <div class="d-flex gap-2 flex-wrap">
          <a class="btn btn-outline-secondary homes-pill px-3"
             href="${pageContext.request.contextPath}/living/expense">← 목록</a>
          <button class="btn btn-success homes-pill px-3 d-flex align-items-center gap-1" onclick="saveAll()">
            <span class="material-symbols-rounded ms-sm">save</span>전체 저장</button>
        </div>
      </div>

      <!-- 요약 카드 -->
      <div class="row g-3 mb-4">
        <div class="col-6 col-md-3">
          <div class="card homes-card h-100">
            <div class="card-body text-center">
              <div class="text-muted small mb-1">월 예산</div>
              <div class="fw-bold fs-6 text-muted" id="summBudget">
                <fmt:formatNumber value="${totalBudget}" pattern="#,##0"/> 원
              </div>
            </div>
          </div>
        </div>
        <div class="col-6 col-md-3">
          <div class="card homes-card h-100">
            <div class="card-body text-center">
              <div class="text-muted small mb-1">실제 지출</div>
              <div class="fw-bold fs-6 text-danger" id="summActual">
                <fmt:formatNumber value="${totalActual}" pattern="#,##0"/> 원
              </div>
            </div>
          </div>
        </div>
        <div class="col-6 col-md-3">
          <div class="card homes-card h-100">
            <div class="card-body text-center">
              <div class="text-muted small mb-1">잔액</div>
              <div class="fw-bold fs-6" id="summRemain">-</div>
            </div>
          </div>
        </div>
        <div class="col-6 col-md-3">
          <div class="card homes-card h-100">
            <div class="card-body text-center">
              <div class="text-muted small mb-1">달성률</div>
              <div class="fw-bold fs-6" id="summPct">-</div>
              <div class="mini-progress mt-1">
                <div class="mini-progress-bar bg-primary" id="summBar" style="width:0%"></div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 생활비 입력 테이블 -->
      <div class="card homes-card">
        <div class="card-body p-0">
          <div class="table-responsive">
            <table class="table align-middle homes-table mb-0" id="expenseTable">
              <thead class="table-light">
                <tr>
                  <th style="width:130px;">카테고리</th>
                  <th>항목</th>
                  <th style="width:140px;" class="text-end">예산</th>
                  <th style="width:150px;" class="text-end">실제 지출</th>
                  <th style="width:130px;" class="text-end">잔액</th>
                </tr>
              </thead>
              <tbody id="expTbody">

              <%-- 카테고리별 그룹핑 렌더링 --%>
              <c:set var="prevCatSeq" value=""/>
              <c:set var="catBudgetSum" value="0"/>
              <c:set var="catActualSum" value="0"/>

              <c:forEach var="dtl" items="${dtlList}" varStatus="st">

                <%-- 카테고리가 바뀌면 이전 소계 행 출력 --%>
                <c:if test="${not empty prevCatSeq and prevCatSeq != dtl.catSeq}">
                  <tr class="living-cat-row" id="catRow_${prevCatSeq}">
                    <td colspan="2" class="text-end text-muted" style="font-size:12px;">소계</td>
                    <td class="text-end cat-total-cell text-muted" id="catBudget_${prevCatSeq}">
                      <fmt:formatNumber value="${catBudgetSum}" pattern="#,##0"/>
                    </td>
                    <td class="text-end cat-total-cell text-primary" id="catActual_${prevCatSeq}">
                      <fmt:formatNumber value="${catActualSum}" pattern="#,##0"/>
                    </td>
                    <td class="text-end cat-total-cell" id="catRemain_${prevCatSeq}">-</td>
                  </tr>
                  <c:set var="catBudgetSum" value="0"/>
                  <c:set var="catActualSum" value="0"/>
                </c:if>

                <%-- 카테고리 헤더 행 --%>
                <c:if test="${prevCatSeq != dtl.catSeq}">
                  <tr class="living-cat-row">
                    <td colspan="5">
                      <span class="material-symbols-rounded ms-sm me-1" style="color:#f59e0b;">folder</span><strong>${dtl.catNm}</strong>
                    </td>
                  </tr>
                  <c:set var="prevCatSeq" value="${dtl.catSeq}"/>
                </c:if>

                <%-- 항목 행 --%>
                <c:set var="catBudgetSum" value="${catBudgetSum + dtl.budgetAmt}"/>
                <c:set var="catActualSum" value="${catActualSum + dtl.actualAmt}"/>
                <tr class="living-item-row" data-item-seq="${dtl.itemSeq}"
                    data-cat-seq="${dtl.catSeq}"
                    data-budget="${dtl.budgetAmt}">
                  <td class="text-muted ps-4" style="font-size:12px;">└</td>
                  <td>${dtl.itemNm}</td>
                  <td class="text-end text-muted budget-cell">
                    <fmt:formatNumber value="${dtl.budgetAmt}" pattern="#,##0"/>
                  </td>
                  <td class="text-end">
                    <input type="text"
                           class="amt-input actual-input"
                           data-item-seq="${dtl.itemSeq}"
                           data-exp-seq="${mst.expSeq}"
                           data-budget="${dtl.budgetAmt}"
                           value="<fmt:formatNumber value="${dtl.actualAmt}" pattern="#,##0"/>"
                           onInput="onAmtInput(this)"
                           onBlur="autoSave(this)"
                           onFocus="this.select()"/>
                  </td>
                  <td class="text-end remain-cell" id="remain_${dtl.itemSeq}">-</td>
                </tr>

                <%-- 마지막 항목이면 소계 출력 --%>
                <c:if test="${st.last}">
                  <tr class="living-cat-row" id="catRow_${dtl.catSeq}">
                    <td colspan="2" class="text-end text-muted" style="font-size:12px;">소계</td>
                    <td class="text-end cat-total-cell text-muted" id="catBudget_${dtl.catSeq}">
                      <fmt:formatNumber value="${catBudgetSum}" pattern="#,##0"/>
                    </td>
                    <td class="text-end cat-total-cell text-primary" id="catActual_${dtl.catSeq}">
                      <fmt:formatNumber value="${catActualSum}" pattern="#,##0"/>
                    </td>
                    <td class="text-end cat-total-cell" id="catRemain_${dtl.catSeq}">-</td>
                  </tr>
                </c:if>

              </c:forEach>

              <c:if test="${empty dtlList}">
                <tr>
                  <td colspan="5" class="text-center text-muted py-5">
                    기준정보에 등록된 항목이 없습니다.<br>
                    <a href="${pageContext.request.contextPath}/living/budget" class="btn btn-sm btn-primary mt-2">기준정보설정 →</a>
                  </td>
                </tr>
              </c:if>

              </tbody>

              <!-- 합계 행 -->
              <tfoot>
                <tr class="grand-total-row">
                  <td colspan="2" class="text-end">합 계</td>
                  <td class="text-end text-muted" id="footBudget">
                    <fmt:formatNumber value="${totalBudget}" pattern="#,##0"/>
                  </td>
                  <td class="text-end text-danger" id="footActual">
                    <fmt:formatNumber value="${totalActual}" pattern="#,##0"/>
                  </td>
                  <td class="text-end" id="footRemain">-</td>
                </tr>
                <tr class="remain-row">
                  <td colspan="2" class="text-end" style="font-size:13px;">나머지 (예산 - 실제)</td>
                  <td colspan="3" class="text-end" id="footRemainLarge">-</td>
                </tr>
              </tfoot>
            </table>
          </div>
        </div>
      </div>

      <!-- 저장 상태 표시 -->
      <div class="d-flex justify-content-between align-items-center mt-3">
        <div id="saveStatus" class="text-muted small"></div>
        <button class="btn btn-success homes-pill px-4" onclick="saveAll()">💾 전체 저장</button>
      </div>

    </div><%-- homes-main-body --%>
    <%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
  </main>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
const ctx    = '${pageContext.request.contextPath}';
const expSeq = ${mst.expSeq};

/* ── 숫자 유틸 ── */
function parseN(s) {
  return parseInt((s || '').replace(/[^0-9]/g, '') || '0', 10);
}
function fmtN(n) {
  return Number(n).toLocaleString('ko-KR');
}

/* ── 입력 이벤트: 콤마 포맷 + 잔액 실시간 갱신 ── */
function onAmtInput(el) {
  const raw = el.value.replace(/[^0-9]/g, '');
  el.value  = raw ? fmtN(raw) : '';
  el.classList.remove('saved');
  updateRowRemain(el);
  updateSummary();
}

/* 행 잔액 갱신 */
function updateRowRemain(el) {
  const budget = parseInt(el.dataset.budget || '0');
  const actual = parseN(el.value);
  const remain = budget - actual;
  const itemSeq = el.dataset.itemSeq;
  const cell = document.getElementById('remain_' + itemSeq);
  if (!cell) return;
  if (budget === 0) { cell.textContent = '-'; return; }
  cell.textContent = fmtN(Math.abs(remain));
  cell.className   = 'text-end remain-cell fw-semibold ' + (remain >= 0 ? 'text-success' : 'text-danger');
}

/* 카테고리 소계 갱신 */
function updateCatTotals() {
  const catMap = {};
  document.querySelectorAll('.living-item-row').forEach(row => {
    const catSeq  = row.dataset.catSeq;
    const budget  = parseInt(row.dataset.budget || '0');
    const input   = row.querySelector('.actual-input');
    const actual  = input ? parseN(input.value) : 0;
    if (!catMap[catSeq]) catMap[catSeq] = {budget: 0, actual: 0};
    catMap[catSeq].budget += budget;
    catMap[catSeq].actual += actual;
  });
  for (const [catSeq, vals] of Object.entries(catMap)) {
    const bCell = document.getElementById('catBudget_' + catSeq);
    const aCell = document.getElementById('catActual_' + catSeq);
    const rCell = document.getElementById('catRemain_' + catSeq);
    if (bCell) bCell.textContent = fmtN(vals.budget);
    if (aCell) aCell.textContent = fmtN(vals.actual);
    if (rCell) {
      const r = vals.budget - vals.actual;
      rCell.textContent = fmtN(Math.abs(r));
      rCell.className   = 'text-end cat-total-cell fw-semibold ' + (r >= 0 ? 'text-success' : 'text-danger');
    }
  }
}

/* 전체 요약 갱신 */
function updateSummary() {
  let totalBudget = 0, totalActual = 0;
  document.querySelectorAll('.actual-input').forEach(inp => {
    totalBudget += parseInt(inp.dataset.budget || '0');
    totalActual += parseN(inp.value);
  });
  const remain = totalBudget - totalActual;
  const pct    = totalBudget > 0 ? Math.round(totalActual * 100 / totalBudget) : 0;

  document.getElementById('summBudget').textContent  = fmtN(totalBudget) + ' 원';
  document.getElementById('summActual').textContent  = fmtN(totalActual) + ' 원';

  const rEl = document.getElementById('summRemain');
  rEl.textContent = fmtN(Math.abs(remain)) + ' 원';
  rEl.className   = 'fw-bold fs-6 ' + (remain >= 0 ? 'text-success' : 'text-danger');

  document.getElementById('summPct').textContent = pct + '%';
  const bar = document.getElementById('summBar');
  bar.style.width = Math.min(pct, 100) + '%';
  bar.className   = 'mini-progress-bar ' + (pct > 100 ? 'bg-danger' : 'bg-primary');

  // 푸터
  document.getElementById('footBudget').textContent = fmtN(totalBudget);
  document.getElementById('footActual').textContent = fmtN(totalActual);
  const fRemain = document.getElementById('footRemain');
  fRemain.textContent = fmtN(Math.abs(remain));
  fRemain.className   = 'text-end fw-bold ' + (remain >= 0 ? 'text-success' : 'text-danger');

  const frLarge = document.getElementById('footRemainLarge');
  frLarge.textContent = (remain >= 0 ? '' : '-') + fmtN(Math.abs(remain)) + ' 원';
  frLarge.className   = 'text-end ' + (remain >= 0 ? 'text-success' : 'text-danger');

  updateCatTotals();
}

/* ── 자동 저장 (blur) ── */
function autoSave(el) {
  const itemSeq  = el.dataset.itemSeq;
  const actualAmt = parseN(el.value);
  const payload  = { expSeq, itemSeq: parseInt(itemSeq), actualAmt };

  fetch(ctx + '/living/expense/dtl/save', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify(payload)
  }).then(r => r.json()).then(res => {
    if (res.success) {
      el.classList.add('saved');
      showStatus('저장됨');
    } else {
      showStatus('저장 실패: ' + (res.message || ''));
    }
  }).catch(() => showStatus('저장 실패 (네트워크 오류)'));
}

/* ── 전체 저장 ── */
function saveAll() {
  const items = [];
  document.querySelectorAll('.actual-input').forEach(inp => {
    items.push({
      itemSeq:   parseInt(inp.dataset.itemSeq),
      actualAmt: parseN(inp.value)
    });
  });

  fetch(ctx + '/living/expense/dtl/saveAll', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({ expSeq, items })
  }).then(r => r.json()).then(res => {
    if (res.success) {
      document.querySelectorAll('.actual-input').forEach(inp => inp.classList.add('saved'));
      showStatus('전체 저장 완료!');
    } else {
      showStatus('저장 실패: ' + (res.message || ''));
    }
  }).catch(() => showStatus('저장 실패 (네트워크 오류)'));
}

/* 상태 메시지 */
function showStatus(msg) {
  const el = document.getElementById('saveStatus');
  el.textContent = msg;
  setTimeout(() => { el.textContent = ''; }, 3000);
}

/* ── 페이지 로드 시 초기화 ── */
window.addEventListener('DOMContentLoaded', () => {
  // 각 행 잔액 초기 계산
  document.querySelectorAll('.actual-input').forEach(el => {
    updateRowRemain(el);
  });
  updateSummary();

  // Enter키로 다음 항목 이동
  const inputs = Array.from(document.querySelectorAll('.actual-input'));
  inputs.forEach((inp, idx) => {
    inp.addEventListener('keydown', e => {
      if (e.key === 'Enter') {
        e.preventDefault();
        autoSave(inp);
        const next = inputs[idx + 1];
        if (next) { next.focus(); next.select(); }
      }
    });
  });
});
</script>
</body>
</html>
