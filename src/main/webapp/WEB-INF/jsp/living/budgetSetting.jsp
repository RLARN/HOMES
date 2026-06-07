<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<!doctype html>
<html lang="ko">
<head>
  <%@ include file="/WEB-INF/jsp/common/head.jsp" %>
  <title>생활비 기준정보설정 | HOMES</title>
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
          <h1 class="h4 fw-bold mb-1">생활비 기준정보설정</h1>
          <div class="text-muted small">카테고리·항목별 월 예산을 설정하고 수입원을 연결합니다.</div>
        </div>
        <div class="d-flex gap-2">
          <button class="btn btn-outline-primary homes-pill px-3" onclick="openCatModal(null)">+ 카테고리 추가</button>
          <a class="btn btn-primary homes-pill px-3" href="${pageContext.request.contextPath}/living/expense">생활비관리 →</a>
        </div>
      </div>

      <!-- 요약 카드 -->
      <div class="row g-3 mb-4">
        <div class="col-6 col-md-3">
          <div class="card homes-card h-100">
            <div class="card-body">
              <div class="text-muted small mb-1">월 예산 합계</div>
              <div class="fw-bold fs-5 text-primary">
                <fmt:formatNumber value="${grandTotal}" pattern="#,##0"/> 원
              </div>
            </div>
          </div>
        </div>
        <div class="col-6 col-md-3">
          <div class="card homes-card h-100">
            <div class="card-body">
              <div class="text-muted small mb-1">수입원 합계</div>
              <div class="fw-bold fs-5 text-success">
                <fmt:formatNumber value="${incomeTotal}" pattern="#,##0"/> 원
              </div>
              <div class="text-muted" style="font-size:11px;">수지계정 월 금액 기준</div>
            </div>
          </div>
        </div>
        <div class="col-6 col-md-3">
          <div class="card homes-card h-100">
            <div class="card-body">
              <div class="text-muted small mb-1">잔액 (수입 − 예산)</div>
              <div class="fw-bold fs-5 ${balance >= 0 ? 'text-success' : 'text-danger'}">
                <fmt:formatNumber value="${balance}" pattern="#,##0"/> 원
              </div>
            </div>
          </div>
        </div>
        <div class="col-6 col-md-3">
          <div class="card homes-card h-100">
            <div class="card-body">
              <div class="text-muted small mb-1">이달 수입 등록</div>
              <div class="fw-bold fs-5 text-info">
                <fmt:formatNumber value="${incomeEntryTotal}" pattern="#,##0"/> 원
              </div>
              <div class="text-muted" style="font-size:11px;">${incomeEntries.size()} 건 등록</div>
            </div>
          </div>
        </div>
      </div>

      <!-- 카테고리별 항목 그리드 -->
      <div class="card homes-card">
        <div class="card-body p-0">
          <c:choose>
            <c:when test="${empty catList}">
              <div class="text-center text-muted py-5">
                카테고리가 없습니다. 위의 [+ 카테고리 추가]를 눌러 시작하세요.
              </div>
            </c:when>
            <c:otherwise>
              <div class="homes-ag-wrap">
                <div id="budgetGrid" class="ag-theme-alpine"></div>
              </div>
            </c:otherwise>
          </c:choose>
        </div>
      </div>

      <!-- 이달 수입 수기 등록 섹션 -->
      <div class="card homes-card mt-4">
        <div class="card-header bg-transparent d-flex align-items-center justify-content-between">
          <span class="fw-semibold d-flex align-items-center gap-1">
            <span class="material-symbols-rounded ms-sm" style="color:#16a34a;">add_circle</span>이달 수입 등록 (${thisMonth.substring(0,4)}년 ${thisMonth.substring(4,6)}월)</span>
          <button class="btn btn-sm btn-outline-success homes-pill px-3" onclick="openIncomeModal(null)">+ 수입 추가</button>
        </div>
        <div class="card-body p-0">
          <c:choose>
            <c:when test="${empty incomeEntries}">
              <div class="text-center text-muted py-4 fst-italic px-3">
                이달 등록된 수입이 없습니다. [+ 수입 추가]를 눌러 등록하세요.
              </div>
            </c:when>
            <c:otherwise>
              <div class="homes-ag-wrap">
                <div id="incomeGrid" class="ag-theme-alpine"></div>
              </div>
            </c:otherwise>
          </c:choose>
        </div>
      </div>

    </div><%-- homes-main-body --%>
    <%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
  </main>
</div>

<!-- ── 카테고리 모달 ── -->
<div class="modal fade" id="catModal" tabindex="-1">
  <div class="modal-dialog modal-sm modal-dialog-centered">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="catModalTitle">카테고리 추가</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <input type="hidden" id="catSeq"/>
        <div class="mb-3">
          <label class="form-label fw-semibold">카테고리명 <span class="text-danger">*</span></label>
          <input type="text" class="form-control" id="catNm" placeholder="예) 공과금" maxlength="100"/>
        </div>
        <div class="mb-2">
          <label class="form-label fw-semibold">정렬순서</label>
          <input type="number" class="form-control" id="catSortOrder" placeholder="10" min="0"/>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">취소</button>
        <button type="button" class="btn btn-primary" onclick="saveCat()">저장</button>
      </div>
    </div>
  </div>
</div>

<!-- ── 항목 모달 ── -->
<div class="modal fade" id="itemModal" tabindex="-1">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="itemModalTitle">항목 추가</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <input type="hidden" id="itemSeq"/>
        <input type="hidden" id="itemCatSeq"/>
        <div class="mb-3">
          <label class="form-label fw-semibold">카테고리</label>
          <input type="text" class="form-control" id="itemCatNm" readonly/>
        </div>
        <div class="mb-3">
          <label class="form-label fw-semibold">항목명 <span class="text-danger">*</span></label>
          <input type="text" class="form-control" id="itemNm" placeholder="예) 전기요금" maxlength="100"/>
        </div>
        <div class="mb-3">
          <label class="form-label fw-semibold">월 예산금액 <span class="text-danger">*</span></label>
          <div class="input-group">
            <span class="input-group-text">₩</span>
            <input type="text" class="form-control text-end" id="itemBudgetAmt" placeholder="0"
                   oninput="fmtAmt(this)"/>
            <span class="input-group-text">원</span>
          </div>
        </div>
        <div class="mb-3">
          <label class="form-label fw-semibold">수입원 (수지계정) <span class="text-muted small">(선택)</span></label>
          <select class="form-select" id="itemCcSeq">
            <option value="">-- 선택 안함 --</option>
            <c:forEach var="cc" items="${costCenterList}">
              <option value="${cc.ccSeq}">${cc.ccNm}</option>
            </c:forEach>
          </select>
          <div class="form-text">이 항목의 재원이 되는 수지계정를 선택하세요.</div>
        </div>
        <div class="mb-2">
          <label class="form-label fw-semibold">메모</label>
          <input type="text" class="form-control" id="itemMemo" placeholder="메모 (선택)" maxlength="500"/>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">취소</button>
        <button type="button" class="btn btn-primary" onclick="saveItem()">저장</button>
      </div>
    </div>
  </div>
</div>

<!-- ── 수입 등록 모달 ── -->
<div class="modal fade" id="incomeModal" tabindex="-1">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="incomeModalTitle">수입 추가</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <input type="hidden" id="incomeSeq"/>
        <div class="mb-3">
          <label class="form-label fw-semibold">수지계정 <span class="text-danger">*</span></label>
          <select class="form-select" id="incomeCcSeq" onchange="onCcChange(this)">
            <option value="">-- 선택 --</option>
            <c:forEach var="cc" items="${costCenterList}">
              <option value="${cc.ccSeq}" data-monthly="${cc.monthlyAmt}">${cc.ccNm}</option>
            </c:forEach>
          </select>
        </div>
        <div class="mb-3">
          <label class="form-label fw-semibold">수입금액 <span class="text-muted small">(선택 — 수지계정 정기금액 자동입력)</span></label>
          <div class="input-group">
            <span class="input-group-text">₩</span>
            <input type="text" class="form-control text-end" id="incomeActualAmt" placeholder="0"
                   oninput="fmtAmt(this)"/>
            <span class="input-group-text">원</span>
          </div>
        </div>
        <div class="mb-2">
          <label class="form-label fw-semibold">메모</label>
          <input type="text" class="form-control" id="incomeMemo" placeholder="메모 (선택)" maxlength="500"/>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">취소</button>
        <button type="button" class="btn btn-success" onclick="saveIncome()">저장</button>
      </div>
    </div>
  </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
const ctx = '${pageContext.request.contextPath}';

/* ── 예산 그리드 데이터 구성 ── */
(function () {
  function d(s) { const el = document.createElement('textarea'); el.innerHTML = s; return el.value; }
  function won(v) { return Number(v || 0).toLocaleString('ko-KR') + ' 원'; }

  const budgetRows = [];
  <c:forEach var="cat" items="${catList}">
  (function () {
    budgetRows.push({
      rowType: 'catHeader',
      catSeq:        ${cat.catSeq},
      catNm:         d('<c:out value="${cat.catNm}"/>'),
      sortOrder:     ${cat.sortOrder},
      totalBudgetAmt:${cat.totalBudgetAmt},
    });
    <c:choose>
      <c:when test="${empty cat.items}">
    budgetRows.push({ rowType: 'emptyItem', catSeq: ${cat.catSeq} });
      </c:when>
      <c:otherwise>
        <c:forEach var="item" items="${cat.items}">
    budgetRows.push({
      rowType:   'item',
      catSeq:    ${item.catSeq},
      catNm:     d('<c:out value="${item.catNm}"/>'),
      itemSeq:   ${item.itemSeq},
      itemNm:    d('<c:out value="${item.itemNm}"/>'),
      budgetAmt: ${item.budgetAmt},
      ccSeq:     ${empty item.ccSeq ? 'null' : item.ccSeq},
      ccNm:      d('<c:out value="${item.ccNm}"/>'),
    });
        </c:forEach>
      </c:otherwise>
    </c:choose>
  })();
  </c:forEach>
  budgetRows.push({ rowType: 'grandTotal', totalBudgetAmt: ${grandTotal} });

  if (document.getElementById('budgetGrid')) {
    agGrid.createGrid(document.getElementById('budgetGrid'), {
      columnDefs: [
        { field: 'catNm', headerName: '카테고리', width: 170, minWidth: 120,
          cellRenderer: p => {
            if (p.data.rowType === 'catHeader') {
              return '<span class="material-symbols-rounded ms-sm me-1" style="color:#f59e0b;vertical-align:-3px;">folder</span>' +
                     '<strong>' + p.data.catNm + '</strong>';
            }
            if (p.data.rowType === 'emptyItem')  return '<span class="text-muted fst-italic ps-3" style="font-size:12px;">항목 없음</span>';
            if (p.data.rowType === 'grandTotal')  return '';
            return '<span class="text-muted ps-3" style="font-size:12px;">└</span>';
          }
        },
        { field: 'itemNm', headerName: '항목명', flex: 1, minWidth: 120,
          cellRenderer: p => {
            if (p.data.rowType === 'item')       return p.data.itemNm;
            if (p.data.rowType === 'grandTotal')  return '<span class="fw-bold">월 예산 합계</span>';
            return '';
          }
        },
        { field: 'budgetAmt', headerName: '예산금액', width: 140, type: 'rightAligned',
          cellRenderer: p => {
            if (p.data.rowType === 'catHeader')  return '<span class="fw-semibold text-primary">' + won(p.data.totalBudgetAmt) + '</span>';
            if (p.data.rowType === 'item')       return won(p.value);
            if (p.data.rowType === 'grandTotal') return '<span class="fw-bold text-primary fs-6">' + won(p.data.totalBudgetAmt) + '</span>';
            return '';
          }
        },
        { field: 'ccNm', headerName: '수입원', width: 160, minWidth: 120,
          cellRenderer: p => {
            if (p.data.rowType !== 'item') return '';
            return p.data.ccNm
              ? '<span class="badge bg-light text-dark border">' + p.data.ccNm + '</span>'
              : '<span class="text-muted">-</span>';
          }
        },
        { headerName: '관리', width: 120, sortable: false,
          cellStyle: { justifyContent: 'center' },
          cellRenderer: p => {
            if (p.data.rowType === 'catHeader') {
              const wrap = document.createElement('div');
              wrap.className = 'd-flex align-items-center gap-1';

              const editBtn = document.createElement('button');
              editBtn.className = 'btn btn-sm btn-link py-0 px-1 text-muted';
              editBtn.title = '카테고리 수정';
              editBtn.innerHTML = '<span class="material-symbols-rounded ms-sm">edit</span>';
              editBtn.onclick = () => openCatModal(p.data.catSeq, p.data.catNm, p.data.sortOrder);
              wrap.appendChild(editBtn);

              const delBtn = document.createElement('button');
              delBtn.className = 'btn btn-sm btn-link py-0 px-1 text-danger';
              delBtn.title = '카테고리 삭제';
              delBtn.innerHTML = '<span class="material-symbols-rounded ms-sm">delete</span>';
              delBtn.onclick = () => deleteCat(p.data.catSeq);
              wrap.appendChild(delBtn);

              const addBtn = document.createElement('button');
              addBtn.className = 'btn btn-sm btn-outline-primary homes-pill px-2 py-0';
              addBtn.style.fontSize = '12px';
              addBtn.textContent = '+ 항목';
              addBtn.onclick = () => openItemModal(null, p.data.catSeq, p.data.catNm);
              wrap.appendChild(addBtn);

              return wrap;
            }
            if (p.data.rowType === 'item') {
              const wrap = document.createElement('div');
              wrap.className = 'd-flex align-items-center justify-content-center gap-1';

              const editBtn = document.createElement('button');
              editBtn.className = 'btn btn-sm btn-link p-0 text-muted';
              editBtn.title = '수정';
              editBtn.innerHTML = '<span class="material-symbols-rounded ms-sm">edit</span>';
              editBtn.onclick = () => openItemModal(p.data.itemSeq, p.data.catSeq, p.data.catNm, p.data.itemNm, p.data.budgetAmt, p.data.ccSeq);
              wrap.appendChild(editBtn);

              const delBtn = document.createElement('button');
              delBtn.className = 'btn btn-sm btn-link p-0 text-danger';
              delBtn.title = '삭제';
              delBtn.innerHTML = '<span class="material-symbols-rounded ms-sm">delete</span>';
              delBtn.onclick = () => deleteItem(p.data.itemSeq);
              wrap.appendChild(delBtn);

              return wrap;
            }
            return '';
          }
        },
      ],
      rowData: budgetRows,
      defaultColDef: { sortable: false, resizable: true, suppressMovable: true },
      domLayout: 'autoHeight',
      suppressCellFocus: true,
      getRowStyle: p => {
        if (p.data.rowType === 'catHeader')  return { background: '#f3f4f6', fontWeight: 600 };
        if (p.data.rowType === 'grandTotal') return { background: '#f8f9fa', fontWeight: 700 };
        return {};
      },
    });
  }

  /* ── 이달 수입 그리드 ── */
  const incomeRows = [];
  <c:forEach var="inc" items="${incomeEntries}">
  incomeRows.push({
    incomeSeq: ${inc.incomeSeq},
    ccSeq:     ${inc.ccSeq},
    ccNm:      d('<c:out value="${inc.ccNm}"/>'),
    actualAmt: ${inc.actualAmt},
    memo:      d('<c:out value="${inc.memo}"/>'),
  });
  </c:forEach>

  if (incomeRows.length && document.getElementById('incomeGrid')) {
    agGrid.createGrid(document.getElementById('incomeGrid'), {
      columnDefs: [
        { field: 'ccNm',      headerName: '수지계정',  flex: 1, minWidth: 120 },
        { field: 'actualAmt', headerName: '수입금액',  width: 140, type: 'rightAligned',
          cellRenderer: p => '<span class="text-success fw-semibold">' + Number(p.value).toLocaleString('ko-KR') + ' 원</span>' },
        { field: 'memo',      headerName: '메모',       flex: 1, minWidth: 100, cellClass: 'text-muted' },
        { headerName: '관리', width: 80, sortable: false,
          cellStyle: { justifyContent: 'center' },
          cellRenderer: p => {
            const wrap = document.createElement('div');
            wrap.className = 'd-flex align-items-center justify-content-center gap-1';

            const editBtn = document.createElement('button');
            editBtn.className = 'btn btn-sm btn-link p-0 text-muted';
            editBtn.title = '수정';
            editBtn.innerHTML = '<span class="material-symbols-rounded ms-sm">edit</span>';
            editBtn.onclick = () => openIncomeModal(p.data.incomeSeq, p.data.ccSeq, p.data.ccNm, p.data.actualAmt, p.data.memo);
            wrap.appendChild(editBtn);

            const delBtn = document.createElement('button');
            delBtn.className = 'btn btn-sm btn-link p-0 text-danger';
            delBtn.title = '삭제';
            delBtn.innerHTML = '<span class="material-symbols-rounded ms-sm">delete</span>';
            delBtn.onclick = () => deleteIncome(p.data.incomeSeq);
            wrap.appendChild(delBtn);

            return wrap;
          }
        },
      ],
      rowData: incomeRows,
      defaultColDef: { sortable: false, resizable: true, suppressMovable: true },
      domLayout: 'autoHeight',
      suppressCellFocus: true,
      pinnedBottomRowData: [{ ccNm: '합계', actualAmt: ${incomeEntryTotal}, _isTotal: true }],
      getRowStyle: p => p.node.rowPinned ? { background: '#f8f9fa', fontWeight: 700 } : {},
    });
  }
})();
const catModal    = new bootstrap.Modal(document.getElementById('catModal'));
const itemModal   = new bootstrap.Modal(document.getElementById('itemModal'));
const incomeModal = new bootstrap.Modal(document.getElementById('incomeModal'));

/* ── 숫자 포맷 ── */
function fmtAmt(el) {
  const raw = el.value.replace(/[^0-9]/g, '');
  el.value = raw ? Number(raw).toLocaleString('ko-KR') : '';
}
function parseAmt(s) {
  return parseInt((s||'').replace(/[^0-9]/g, '') || '0', 10);
}

/* ── 카테고리 모달 ── */
function openCatModal(catSeq, catNm, sortOrder) {
  document.getElementById('catSeq').value      = catSeq || '';
  document.getElementById('catNm').value       = catNm || '';
  document.getElementById('catSortOrder').value = sortOrder || '';
  document.getElementById('catModalTitle').textContent = catSeq ? '카테고리 수정' : '카테고리 추가';
  catModal.show();
  setTimeout(() => document.getElementById('catNm').focus(), 300);
}

function saveCat() {
  const catNm = document.getElementById('catNm').value.trim();
  if (!catNm) { alert('카테고리명을 입력하세요.'); return; }
  const payload = {
    catSeq:    document.getElementById('catSeq').value || null,
    catNm:     catNm,
    sortOrder: parseInt(document.getElementById('catSortOrder').value || '0')
  };
  fetch(ctx + '/living/budget/cat/save', {
    method: 'POST', headers: {'Content-Type': 'application/json'},
    body: JSON.stringify(payload)
  }).then(r => r.json()).then(res => {
    if (res.success) { catModal.hide(); location.reload(); }
    else alert('저장 실패: ' + (res.message || ''));
  });
}

function deleteCat(catSeq) {
  if (!confirm('카테고리를 비활성화하시겠습니까?\n(하위 항목은 유지됩니다)')) return;
  fetch(ctx + '/living/budget/cat/delete', {
    method: 'POST', headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({catSeq})
  }).then(r => r.json()).then(res => {
    if (res.success) location.reload();
    else alert('실패: ' + (res.message || ''));
  });
}

/* ── 항목 모달 ── */
function openItemModal(itemSeq, catSeq, catNm, itemNm, budgetAmt, ccSeq) {
  document.getElementById('itemSeq').value       = itemSeq || '';
  document.getElementById('itemCatSeq').value    = catSeq;
  document.getElementById('itemCatNm').value     = catNm;
  document.getElementById('itemNm').value        = itemNm || '';
  document.getElementById('itemBudgetAmt').value = budgetAmt ? Number(budgetAmt).toLocaleString('ko-KR') : '';
  document.getElementById('itemCcSeq').value     = ccSeq || '';
  document.getElementById('itemMemo').value      = '';
  document.getElementById('itemModalTitle').textContent = itemSeq ? '항목 수정' : '항목 추가';
  itemModal.show();
  setTimeout(() => document.getElementById('itemNm').focus(), 300);
}

function saveItem() {
  const itemNm    = document.getElementById('itemNm').value.trim();
  const budgetAmt = parseAmt(document.getElementById('itemBudgetAmt').value);
  if (!itemNm) { alert('항목명을 입력하세요.'); return; }
  const ccSeq = document.getElementById('itemCcSeq').value;
  const payload = {
    itemSeq:   document.getElementById('itemSeq').value || null,
    catSeq:    document.getElementById('itemCatSeq').value,
    itemNm:    itemNm,
    budgetAmt: budgetAmt,
    ccSeq:     ccSeq || null,
    memo:      document.getElementById('itemMemo').value.trim()
  };
  fetch(ctx + '/living/budget/item/save', {
    method: 'POST', headers: {'Content-Type': 'application/json'},
    body: JSON.stringify(payload)
  }).then(r => r.json()).then(res => {
    if (res.success) { itemModal.hide(); location.reload(); }
    else alert('저장 실패: ' + (res.message || ''));
  });
}

/* ── 수입 모달 ── */
function openIncomeModal(incomeSeq, ccSeq, ccNm, actualAmt, memo) {
  document.getElementById('incomeSeq').value        = incomeSeq || '';
  document.getElementById('incomeCcSeq').value      = ccSeq || '';
  document.getElementById('incomeActualAmt').value  = actualAmt ? Number(actualAmt).toLocaleString('ko-KR') : '';
  document.getElementById('incomeMemo').value       = memo || '';
  document.getElementById('incomeModalTitle').textContent = incomeSeq ? '수입 수정' : '수입 추가';
  incomeModal.show();
  setTimeout(() => document.getElementById('incomeCcSeq').focus(), 300);
}

function onCcChange(sel) {
  const monthly = sel.options[sel.selectedIndex]?.dataset?.monthly;
  if (monthly && Number(monthly) > 0) {
    document.getElementById('incomeActualAmt').value = Number(monthly).toLocaleString('ko-KR');
  }
}

function saveIncome() {
  const ccSeq     = document.getElementById('incomeCcSeq').value;
  const actualAmt = parseAmt(document.getElementById('incomeActualAmt').value);
  if (!ccSeq) { alert('수지계정를 선택하세요.'); return; }
  const payload = {
    incomeSeq:   document.getElementById('incomeSeq').value || null,
    ccSeq:       ccSeq,
    incomeYymm:  '${thisMonth}',
    actualAmt:   actualAmt,
    memo:        document.getElementById('incomeMemo').value.trim()
  };
  fetch(ctx + '/living/income/save', {
    method: 'POST', headers: {'Content-Type': 'application/json'},
    body: JSON.stringify(payload)
  }).then(r => r.json()).then(res => {
    if (res.success) { incomeModal.hide(); location.reload(); }
    else alert('저장 실패: ' + (res.message || ''));
  });
}

function deleteIncome(incomeSeq) {
  if (!confirm('수입 내역을 삭제하시겠습니까?')) return;
  fetch(ctx + '/living/income/delete', {
    method: 'POST', headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({incomeSeq})
  }).then(r => r.json()).then(res => {
    if (res.success) location.reload();
    else alert('실패: ' + (res.message || ''));
  });
}

function deleteItem(itemSeq) {
  if (!confirm('항목을 삭제하시겠습니까?')) return;
  fetch(ctx + '/living/budget/item/delete', {
    method: 'POST', headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({itemSeq})
  }).then(r => r.json()).then(res => {
    if (res.success) location.reload();
    else alert('실패: ' + (res.message || ''));
  });
}
</script>
</body>
</html>
