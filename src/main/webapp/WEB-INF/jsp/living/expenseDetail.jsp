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

      <!-- 생활비 입력 그리드 -->
      <div class="card homes-card">
        <div class="card-body p-0">
          <c:choose>
            <c:when test="${empty dtlList}">
              <div class="text-center text-muted py-5">
                기준정보에 등록된 항목이 없습니다.<br>
                <a href="${pageContext.request.contextPath}/living/budget" class="btn btn-sm btn-primary mt-2">기준정보설정 →</a>
              </div>
            </c:when>
            <c:otherwise>
              <div class="homes-ag-wrap">
                <div id="expDtlGrid" class="ag-theme-alpine"></div>
              </div>
            </c:otherwise>
          </c:choose>
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

/* ── AG Grid 데이터 구축 ── */
(function () {
  function d(s) { const el = document.createElement('textarea'); el.innerHTML = s; return el.value; }

  /* 원본 항목 데이터 */
  const items = [];
  <c:forEach var="dtl" items="${dtlList}">
  items.push({
    itemSeq:   ${dtl.itemSeq},
    catSeq:    ${dtl.catSeq},
    catNm:     d('<c:out value="${dtl.catNm}"/>'),
    itemNm:    d('<c:out value="${dtl.itemNm}"/>'),
    budgetAmt: ${dtl.budgetAmt},
    actualAmt: ${dtl.actualAmt},
  });
  </c:forEach>

  if (!items.length) return;

  /* 카테고리별 그룹핑 → 행 데이터 구성 */
  const rowData = [];
  let prevCat = null;
  const catGroups = {};

  items.forEach(item => {
    if (item.catSeq !== prevCat) {
      if (prevCat !== null) {
        rowData.push({ rowType: 'catSubtotal', catSeq: prevCat, catNm: catGroups[prevCat].catNm });
      }
      rowData.push({ rowType: 'catHeader', catSeq: item.catSeq, catNm: item.catNm });
      catGroups[item.catSeq] = { catNm: item.catNm, budgetSum: 0, actualSum: 0 };
      prevCat = item.catSeq;
    }
    catGroups[item.catSeq].budgetSum += item.budgetAmt;
    catGroups[item.catSeq].actualSum += item.actualAmt;
    rowData.push({ rowType: 'item', ...item });
  });
  if (prevCat !== null) {
    rowData.push({ rowType: 'catSubtotal', catSeq: prevCat, catNm: catGroups[prevCat].catNm });
  }
  rowData.push({ rowType: 'grandTotal' });
  rowData.push({ rowType: 'remain' });

  function fmtN(n) { return Number(n || 0).toLocaleString('ko-KR'); }
  function parseN(s) { return parseInt((String(s) || '').replace(/[^0-9]/g, '') || '0', 10); }

  function recalc(api) {
    let totalBudget = 0, totalActual = 0;
    const catBudget = {}, catActual = {};
    api.forEachNode(n => {
      if (n.data.rowType !== 'item') return;
      totalBudget += n.data.budgetAmt;
      totalActual += n.data.actualAmt;
      catBudget[n.data.catSeq] = (catBudget[n.data.catSeq] || 0) + n.data.budgetAmt;
      catActual[n.data.catSeq] = (catActual[n.data.catSeq] || 0) + n.data.actualAmt;
    });
    const remain = totalBudget - totalActual;
    const pct = totalBudget > 0 ? Math.round(totalActual * 100 / totalBudget) : 0;

    document.getElementById('summBudget').textContent  = fmtN(totalBudget) + ' 원';
    document.getElementById('summActual').textContent  = fmtN(totalActual) + ' 원';
    const rEl = document.getElementById('summRemain');
    rEl.textContent = fmtN(Math.abs(remain)) + ' 원';
    rEl.className = 'fw-bold fs-6 ' + (remain >= 0 ? 'text-success' : 'text-danger');
    document.getElementById('summPct').textContent = pct + '%';
    const bar = document.getElementById('summBar');
    bar.style.width = Math.min(pct, 100) + '%';
    bar.className = 'mini-progress-bar ' + (pct > 100 ? 'bg-danger' : 'bg-primary');

    // 하단 요약 행 갱신
    api.forEachNode(n => {
      if (n.data.rowType === 'catSubtotal') {
        n.data._catBudget = catBudget[n.data.catSeq] || 0;
        n.data._catActual = catActual[n.data.catSeq] || 0;
      }
      if (n.data.rowType === 'grandTotal') {
        n.data._totalBudget = totalBudget;
        n.data._totalActual = totalActual;
      }
      if (n.data.rowType === 'remain') {
        n.data._remain = remain;
      }
    });
    api.refreshCells({ force: true });
  }

  function makeCellEditor(params) {
    const value = { v: params.value };
    const input = document.createElement('input');
    input.type = 'text';
    input.className = 'amt-input';
    input.style.cssText = 'width:100%;height:100%;border:1px solid #6366f1;border-radius:4px;padding:0 8px;font-size:13px;text-align:right;outline:none;';
    input.value = fmtN(params.value);
    input.addEventListener('input', () => {
      const raw = input.value.replace(/[^0-9]/g, '');
      input.value = raw ? fmtN(raw) : '';
    });
    input.addEventListener('keydown', e => {
      if (e.key === 'Tab' || e.key === 'Enter') {
        e.preventDefault();
        params.api.stopEditing();
        const col = params.api.getAllGridColumns();
        const rowIdx = params.rowIndex;
        const nextRow = params.api.getDisplayedRowAtIndex(rowIdx + 1);
        if (nextRow && nextRow.data.rowType === 'item') {
          params.api.startEditingCell({ rowIndex: rowIdx + 1, colKey: 'actualAmt' });
        }
      }
    });
    setTimeout(() => { input.focus(); input.select(); }, 0);
    return {
      getGui: () => input,
      getValue: () => parseN(input.value),
      destroy: () => {},
      afterGuiAttached: () => {},
    };
  }

  let gridApi;
  gridApi = agGrid.createGrid(document.getElementById('expDtlGrid'), {
    columnDefs: [
      { headerName: '카테고리', width: 130, minWidth: 100, field: 'catNm',
        cellRenderer: p => {
          if (p.data.rowType === 'catHeader') {
            return '<span class="material-symbols-rounded ms-sm me-1" style="color:#f59e0b;">folder</span><strong>' + p.data.catNm + '</strong>';
          }
          if (p.data.rowType === 'catSubtotal') return '<span class="text-end text-muted w-100" style="font-size:12px;">소계</span>';
          if (p.data.rowType === 'grandTotal')  return '<span class="text-end w-100">합 계</span>';
          if (p.data.rowType === 'remain')       return '<span class="text-end w-100" style="font-size:13px;">나머지</span>';
          return '<span class="text-muted ps-3" style="font-size:12px;">└</span>';
        }
      },
      { field: 'itemNm', headerName: '항목', flex: 1, minWidth: 120,
        cellRenderer: p => {
          if (p.data.rowType === 'item') return p.data.itemNm;
          if (p.data.rowType === 'remain') return '<span class="text-muted">(예산 − 실제)</span>';
          return '';
        }
      },
      { field: 'budgetAmt', headerName: '예산', width: 140, type: 'rightAligned',
        cellRenderer: p => {
          if (p.data.rowType === 'item')       return '<span class="text-muted">' + fmtN(p.value) + '</span>';
          if (p.data.rowType === 'catSubtotal') return '<span class="text-muted fw-semibold">' + fmtN(p.data._catBudget || 0) + '</span>';
          if (p.data.rowType === 'grandTotal')  return '<span class="text-muted fw-bold">' + fmtN(p.data._totalBudget || 0) + '</span>';
          if (p.data.rowType === 'remain') {
            const r = p.data._remain || 0;
            return '<span class="fw-bold ' + (r >= 0 ? 'text-success' : 'text-danger') + '">' + (r < 0 ? '-' : '') + fmtN(Math.abs(r)) + ' 원</span>';
          }
          return '';
        }
      },
      { field: 'actualAmt', headerName: '실제 지출', width: 150, type: 'rightAligned',
        editable: p => p.data.rowType === 'item',
        cellEditorFramework: null,
        cellEditor: makeCellEditor,
        cellRenderer: p => {
          if (p.data.rowType === 'item') return '<span class="fw-semibold">' + fmtN(p.value) + '</span>';
          if (p.data.rowType === 'catSubtotal') return '<span class="text-primary fw-semibold">' + fmtN(p.data._catActual || 0) + '</span>';
          if (p.data.rowType === 'grandTotal')  return '<span class="text-danger fw-bold">' + fmtN(p.data._totalActual || 0) + '</span>';
          return '';
        },
        onCellValueChanged: p => {
          if (p.data.rowType !== 'item') return;
          p.data.actualAmt = p.newValue;
          recalc(gridApi);
          autoSaveItem(p.data.itemSeq, p.newValue);
        }
      },
      { headerName: '잔액', width: 130, type: 'rightAligned',
        cellRenderer: p => {
          if (p.data.rowType !== 'item') return '';
          const r = p.data.budgetAmt - p.data.actualAmt;
          if (p.data.budgetAmt === 0) return '<span class="text-muted">-</span>';
          const cls = r >= 0 ? 'text-success' : 'text-danger';
          return '<span class="fw-semibold ' + cls + '">' + fmtN(Math.abs(r)) + '</span>';
        }
      },
    ],
    rowData,
    defaultColDef: { sortable: false, resizable: true, suppressMovable: true },
    domLayout: 'autoHeight',
    suppressCellFocus: false,
    singleClickEdit: true,
    getRowStyle: p => {
      const t = p.data.rowType;
      if (t === 'catHeader')   return { background: '#eef2ff', fontWeight: 600 };
      if (t === 'catSubtotal') return { background: '#f8fafc', fontSize: '12px' };
      if (t === 'grandTotal')  return { background: '#f8f9fa', fontWeight: 700, fontSize: '15px' };
      if (t === 'remain')      return { background: '#fff8e1', fontWeight: 700, color: '#92400e' };
      return {};
    },
  });

  recalc(gridApi);

  window._expDtlGrid = gridApi;
})();

function autoSaveItem(itemSeq, actualAmt) {
  fetch(ctx + '/living/expense/dtl/save', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ expSeq, itemSeq: parseInt(itemSeq), actualAmt: parseInt(actualAmt) })
  }).then(r => r.json()).then(res => {
    if (!res.success) console.warn('저장 실패:', res.message);
    else showStatus('저장됨');
  }).catch(() => showStatus('저장 실패 (네트워크 오류)'));
}


/* ── 전체 저장 ── */
function saveAll() {
  if (!window._expDtlGrid) return;
  const items = [];
  window._expDtlGrid.forEachNode(n => {
    if (n.data.rowType === 'item') {
      items.push({ itemSeq: n.data.itemSeq, actualAmt: n.data.actualAmt });
    }
  });
  fetch(ctx + '/living/expense/dtl/saveAll', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({ expSeq, items })
  }).then(r => r.json()).then(res => {
    showStatus(res.success ? '전체 저장 완료!' : '저장 실패: ' + (res.message || ''));
  }).catch(() => showStatus('저장 실패 (네트워크 오류)'));
}

/* 상태 메시지 */
function showStatus(msg) {
  const el = document.getElementById('saveStatus');
  el.textContent = msg;
  setTimeout(() => { el.textContent = ''; }, 3000);
}

</script>
</body>
</html>
