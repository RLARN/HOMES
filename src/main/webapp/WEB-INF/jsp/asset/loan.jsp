<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<!doctype html>
<html lang="ko">
<head>
  <%@ include file="/WEB-INF/jsp/common/head.jsp" %>
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
          <div class="homes-badge mb-2">Asset</div>
          <h1 class="h4 fw-bold mb-1">대출원장관리</h1>
          <div class="text-muted small">현재 대출과 상환 상태를 관리합니다.</div>
        </div>
        <a class="btn btn-primary homes-pill px-3"
           href="${pageContext.request.contextPath}/asset/loan/form">대출 등록</a>
      </div>

      <!-- 요약 카드 -->
      <div class="row g-3 mb-4">
        <div class="col-12 col-sm-4">
          <div class="card homes-card h-100">
            <div class="card-body">
              <div class="text-muted small mb-1">총 대출잔액</div>
              <div class="fw-bold fs-5 text-danger">
                <fmt:formatNumber value="${summary.totalLoanBalance}" pattern="#,##0"/> 원
              </div>
              <div class="text-muted" style="font-size:11px;">상환중 대출 현재잔액 합계</div>
            </div>
          </div>
        </div>
        <div class="col-12 col-sm-4">
          <div class="card homes-card h-100">
            <div class="card-body">
              <div class="text-muted small mb-1">순자산 (자산 - 대출)</div>
              <div class="fw-bold fs-5 ${summary.netAssetAmount >= 0 ? 'text-primary' : 'text-danger'}">
                <fmt:formatNumber value="${summary.netAssetAmount}" pattern="#,##0"/> 원
              </div>
              <div class="text-muted" style="font-size:11px;">총자산 - 총대출잔액</div>
            </div>
          </div>
        </div>
        <div class="col-12 col-sm-4">
          <div class="card homes-card h-100">
            <div class="card-body">
              <div class="text-muted small mb-1">평균 금리</div>
              <div class="fw-bold fs-5">
                <c:set var="loanCount" value="0"/>
                <c:set var="rateSum" value="0"/>
                <c:forEach var="l" items="${loanList}">
                  <c:if test="${l.closeYn == 'N' and not empty l.interestRate}">
                    <c:set var="loanCount" value="${loanCount + 1}"/>
                    <c:set var="rateSum" value="${rateSum + l.interestRate}"/>
                  </c:if>
                </c:forEach>
                <c:choose>
                  <c:when test="${loanCount > 0}">
                    <fmt:formatNumber value="${rateSum / loanCount}" pattern="#,##0.##"/> %
                  </c:when>
                  <c:otherwise>- %</c:otherwise>
                </c:choose>
              </div>
              <div class="text-muted" style="font-size:11px;">상환중 대출 금리 평균</div>
            </div>
          </div>
        </div>
      </div>

      <!-- 필터 -->
      <div class="d-flex gap-2 mb-3 flex-wrap">
        <a href="${pageContext.request.contextPath}/asset/loan"
           class="btn btn-sm homes-pill ${empty closeYn ? 'btn-primary' : 'btn-outline-secondary'}">전체</a>
        <a href="${pageContext.request.contextPath}/asset/loan?closeYn=N"
           class="btn btn-sm homes-pill ${closeYn == 'N' ? 'btn-primary' : 'btn-outline-secondary'}">상환중</a>
        <a href="${pageContext.request.contextPath}/asset/loan?closeYn=Y"
           class="btn btn-sm homes-pill ${closeYn == 'Y' ? 'btn-warning' : 'btn-outline-secondary'}">완납/종료</a>
      </div>

      <!-- 대출 목록 -->
      <div class="card homes-card">
        <div class="card-body p-0">
          <c:choose>
            <c:when test="${empty loanList}">
              <div class="homes-empty">등록된 대출이 없습니다.</div>
            </c:when>
            <c:otherwise>
              <div class="homes-ag-wrap">
                <div id="loanGrid" class="ag-theme-alpine"></div>
              </div>
            </c:otherwise>
          </c:choose>
        </div>
      </div>

    </div>
    <%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
  </main>
</div>

<!-- Toast 컨테이너 -->
<div class="toast-container position-fixed top-0 end-0 p-3" style="z-index:1080;">
  <div id="appToast" class="toast align-items-center border-0" role="alert" aria-live="assertive" aria-atomic="true">
    <div class="d-flex">
      <div id="appToastBody" class="toast-body"></div>
      <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Close"></button>
    </div>
  </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
window.HOMES = window.HOMES || {};
HOMES.ctx = '${pageContext.request.contextPath}';
const isManager = '${sessionScope.LoginVO.userAuth}' === 'manager';

(function () {
  function d(s) { const el = document.createElement('textarea'); el.innerHTML = s; return el.value; }
  function won(v) { return Number(v).toLocaleString('ko-KR') + ' 원'; }

  const rowData = [];
  <c:forEach var="l" items="${loanList}">
  rowData.push({
    loanSeq:        ${l.loanSeq},
    loanNm:         d('<c:out value="${l.loanNm}"/>'),
    memo:           d('<c:out value="${l.memo}"/>'),
    loanAmount:     ${l.loanAmount},
    currentBalance: ${l.currentBalance},
    interestRate:   '${l.interestRate}',
    loanMonths:     '${l.loanMonths}',
    startYmd:       '${l.startYmd}',
    endYmd:         '${l.endYmd}',
    closeYn:        '${l.closeYn}',
    updId:          d('<c:out value="${l.updId}"/>'),
    updDtStr:       '${l.updDtStr}',
  });
  </c:forEach>

  if (!rowData.length) return;

  agGrid.createGrid(document.getElementById('loanGrid'), {
    columnDefs: [
      { field: 'loanNm', headerName: '대출명', flex: 1, minWidth: 160,
        cellRenderer: p => {
          const memo = p.data.memo ? '<div class="text-muted" style="font-size:11px;">' + p.data.memo + '</div>' : '';
          return '<div><div class="fw-semibold">' + p.data.loanNm + '</div>' + memo + '</div>';
        }, autoHeight: true },
      { field: 'loanAmount',     headerName: '최초금액',   width: 140, type: 'rightAligned',
        valueFormatter: p => won(p.value) },
      { field: 'currentBalance', headerName: '현재잔액',   width: 140, type: 'rightAligned',
        cellRenderer: p => '<span class="fw-semibold text-danger">' + won(p.value) + '</span>' },
      { field: 'interestRate', headerName: '금리', width: 75,
        cellStyle: { justifyContent: 'center' },
        valueFormatter: p => p.value ? Number(p.value).toFixed(2).replace(/\.?0+$/, '') + '%' : '-' },
      { field: 'loanMonths', headerName: '기간', width: 75,
        cellStyle: { justifyContent: 'center' },
        valueFormatter: p => p.value ? p.value + '개월' : '-' },
      { field: 'startYmd', headerName: '시작일', width: 105, cellClass: 'text-muted' },
      { field: 'endYmd',   headerName: '종료일', width: 105, cellClass: 'text-muted' },
      { field: 'closeYn',  headerName: '상태',   width: 90,
        cellStyle: { justifyContent: 'center' },
        cellRenderer: p => p.value === 'Y'
          ? '<span class="badge bg-warning-subtle text-warning">완납/종료</span>'
          : '<span class="badge bg-danger-subtle text-danger">상환중</span>' },
      { field: 'updId',    headerName: '수정자', width: 90 },
      { field: 'updDtStr', headerName: '수정일', width: 115, cellClass: 'text-muted' },
      { headerName: '', width: isManager ? 110 : 65, sortable: false,
        cellRenderer: p => {
          const el = document.createElement('div');
          el.className = 'd-flex gap-1';
          el.innerHTML = '<a href="' + HOMES.ctx + '/asset/loan/form?loanSeq=' + p.data.loanSeq + '"' +
            ' class="btn btn-xs btn-outline-primary homes-pill px-2 py-0" style="font-size:12px;"' +
            ' onclick="event.stopPropagation()">수정</a>';
          if (isManager) {
            const del = document.createElement('button');
            del.className = 'btn btn-xs btn-outline-danger homes-pill px-2 py-0';
            del.style.fontSize = '12px';
            del.textContent = '삭제';
            del.setAttribute('data-loan-seq', p.data.loanSeq);
            del.addEventListener('click', e => { e.stopPropagation(); deleteLoan(del); });
            el.appendChild(del);
          }
          return el;
        }
      },
    ],
    rowData,
    defaultColDef: { sortable: true, resizable: true, suppressMovable: true },
    domLayout: 'autoHeight',
    suppressCellFocus: true,
    getRowStyle: () => ({ cursor: 'pointer' }),
    onRowClicked: p => HOMES.go(HOMES.ctx + '/asset/loan/form?loanSeq=' + p.data.loanSeq),
  });
})();

(function () {
  const toastEl = document.getElementById('appToast');
  const toastBodyEl = document.getElementById('appToastBody');
  if (!toastEl || !toastBodyEl) return;
  const toast = bootstrap.Toast.getOrCreateInstance(toastEl, { delay: 2500, autohide: true });
  HOMES.toast = function (message, type) {
    toastBodyEl.textContent = message || '';
    toastEl.classList.remove('text-bg-success','text-bg-danger','text-bg-warning','text-bg-info','text-bg-secondary');
    toastEl.classList.add(type === 'success' ? 'text-bg-success' : type === 'danger' ? 'text-bg-danger' : 'text-bg-secondary');
    toast.show();
  };
})();

async function deleteLoan(btn) {
  if (!confirm('삭제하면 복구할 수 없습니다. 삭제하시겠습니까?')) return;
  const seq = btn.getAttribute('data-loan-seq');
  try {
    const res = await fetch(HOMES.ctx + '/asset/loan/delete', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'Accept': 'application/json' },
      body: new URLSearchParams({ loanSeq: seq })
    });
    const data = await res.json();
    if (data.success) {
      if (HOMES.toast) HOMES.toast('삭제되었습니다.', 'success');
      setTimeout(() => location.reload(), 800);
    } else {
      if (HOMES.toast) HOMES.toast(data.message || '삭제 실패', 'danger');
    }
  } catch (e) {
    if (HOMES.toast) HOMES.toast('오류: ' + e.message, 'danger');
  }
}
</script>
</body>
</html>
