<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<!doctype html>
<html lang="ko">
<head>
  <%@ include file="/WEB-INF/jsp/common/head.jsp" %>
  <title>생활비관리 | HOMES</title>
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
          <h1 class="h4 fw-bold mb-1">생활비관리</h1>
          <div class="text-muted small">월별 실제 생활비 지출을 기록하고 예산과 비교합니다.</div>
        </div>
        <div class="d-flex gap-2 align-items-center">
          <a class="btn btn-outline-secondary homes-pill px-3"
             href="${pageContext.request.contextPath}/living/budget" class="d-inline-flex align-items-center gap-1">
            <span class="material-symbols-rounded ms-sm">settings</span>기준정보설정</a>
          <button class="btn btn-primary homes-pill px-3" onclick="openThisMonth()">이번달 입력</button>
        </div>
      </div>

      <!-- 월 선택 입력 -->
      <div class="card homes-card mb-4">
        <div class="card-body py-3">
          <div class="d-flex gap-2 align-items-center flex-wrap">
            <label class="fw-semibold mb-0">월 직접 선택</label>
            <input type="month" class="form-control" style="width:180px;" id="monthPicker"
                   value="${thisMonth.substring(0,4)}-${thisMonth.substring(4,6)}"/>
            <button class="btn btn-outline-primary homes-pill px-3" onclick="goToMonth()">해당 월 입력</button>
          </div>
        </div>
      </div>

      <!-- 월별 목록 -->
      <div class="card homes-card">
        <div class="card-body p-0">
          <c:choose>
            <c:when test="${empty expenseList}">
              <div class="text-center text-muted py-5">
                등록된 내역이 없습니다.<br>
                <button class="btn btn-sm btn-primary homes-pill mt-2" onclick="openThisMonth()">이번달 입력 시작</button>
              </div>
            </c:when>
            <c:otherwise>
              <div class="homes-ag-wrap">
                <div id="expListGrid" class="ag-theme-alpine"></div>
              </div>
            </c:otherwise>
          </c:choose>
        </div>
      </div>

    </div><%-- homes-main-body --%>
    <%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
  </main>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
const ctx       = '${pageContext.request.contextPath}';
const thisMonth = '${thisMonth}';

function openThisMonth() { location.href = ctx + '/living/expense/' + thisMonth; }
function goToMonth() {
  const val = document.getElementById('monthPicker').value;
  if (!val) return;
  location.href = ctx + '/living/expense/' + val.replace('-', '');
}

(function () {
  const rowData = [];
  <c:forEach var="exp" items="${expenseList}">
  rowData.push({
    expYymm:       '${exp.expYymm}',
    label:         '${exp.expYymm.substring(0,4)}년 ${exp.expYymm.substring(4,6)}월',
    isThis:        ${exp.expYymm == thisMonth},
    totalBudgetAmt:  ${exp.totalBudgetAmt},
    totalActualAmt:  ${exp.totalActualAmt},
    remain:          ${exp.totalBudgetAmt - exp.totalActualAmt},
    pct:             ${exp.totalBudgetAmt > 0 ? (exp.totalActualAmt * 100 / exp.totalBudgetAmt) : 0},
  });
  </c:forEach>

  if (!rowData.length) return;

  function won(v) { return Number(v).toLocaleString('ko-KR') + ' 원'; }

  agGrid.createGrid(document.getElementById('expListGrid'), {
    columnDefs: [
      { field: 'label', headerName: '년월', width: 160, minWidth: 120,
        cellRenderer: p => {
          const badge = p.data.isThis ? ' <span class="badge bg-primary ms-1" style="font-size:10px;">이번달</span>' : '';
          return '<span class="fw-semibold">' + p.data.label + '</span>' + badge;
        }
      },
      { field: 'totalBudgetAmt', headerName: '예산', type: 'rightAligned', minWidth: 120,
        valueFormatter: p => won(p.value), cellClass: 'text-muted' },
      { field: 'totalActualAmt', headerName: '실제 지출', type: 'rightAligned', minWidth: 120,
        cellRenderer: p => '<span class="fw-semibold">' + won(p.value) + '</span>' },
      { field: 'remain', headerName: '잔액', type: 'rightAligned', minWidth: 120,
        cellRenderer: p => {
          const r = p.value;
          const cls = r >= 0 ? 'text-success' : 'text-danger';
          const sign = r < 0 ? '-' : '';
          return '<span class="fw-semibold ' + cls + '">' + sign + won(Math.abs(r)) + '</span>';
        }
      },
      { field: 'pct', headerName: '달성률', width: 130, minWidth: 100,
        cellRenderer: p => {
          const pct = Math.round(p.value);
          const w   = Math.min(pct, 100);
          const cls = pct > 100 ? 'bg-danger' : 'bg-primary';
          const tc  = pct > 100 ? 'text-danger' : 'text-muted';
          return '<div class="d-flex align-items-center gap-1 w-100">' +
            '<div class="progress flex-grow-1" style="height:6px;">' +
            '<div class="progress-bar ' + cls + '" style="width:' + w + '%"></div></div>' +
            '<small class="' + tc + '">' + pct + '%</small></div>';
        }
      },
      { headerName: '관리', width: 80, sortable: false,
        cellRenderer: p => {
          const btn = document.createElement('a');
          btn.className = 'btn btn-sm btn-outline-primary homes-pill';
          btn.href = ctx + '/living/expense/' + p.data.expYymm;
          btn.textContent = '입력';
          btn.addEventListener('click', e => e.stopPropagation());
          return btn;
        }
      },
    ],
    rowData,
    defaultColDef: { sortable: true, resizable: true, suppressMovable: true },
    domLayout: 'autoHeight',
    suppressCellFocus: true,
    getRowStyle: p => ({
      cursor: 'pointer',
      background: p.data.isThis ? '#eff6ff' : '',
    }),
    onRowClicked: p => HOMES.go(ctx + '/living/expense/' + p.data.expYymm),
  });
})();
</script>
</body>
</html>
