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
          <h1 class="h4 fw-bold mb-1">자산원장관리</h1>
          <div class="text-muted small">현재 보유 자산을 등록하고 상태를 관리합니다.</div>
        </div>
        <a class="btn btn-primary homes-pill px-3"
           href="${pageContext.request.contextPath}/asset/ledger/form">자산 등록</a>
      </div>

      <!-- 요약 카드 -->
      <div class="row g-3 mb-4">
        <div class="col-12 col-sm-4">
          <div class="card homes-card h-100">
            <div class="card-body">
              <div class="text-muted small mb-1">총 자산</div>
              <div class="fw-bold fs-5">
                <fmt:formatNumber value="${summary.totalAssetAmount}" pattern="#,##0"/> 원
              </div>
              <div class="text-muted" style="font-size:11px;">보유중 자산 합계 (말소 제외)</div>
            </div>
          </div>
        </div>
        <div class="col-12 col-sm-4">
          <div class="card homes-card h-100">
            <div class="card-body">
              <div class="text-muted small mb-1">유동 자산</div>
              <div class="fw-bold fs-5 text-success">
                <fmt:formatNumber value="${summary.totalLiquidAssetAmount}" pattern="#,##0"/> 원
              </div>
              <div class="text-muted" style="font-size:11px;">현금화 용이 자산</div>
            </div>
          </div>
        </div>
        <div class="col-12 col-sm-4">
          <div class="card homes-card h-100">
            <div class="card-body">
              <div class="text-muted small mb-1">투자 자산</div>
              <div class="fw-bold fs-5 text-primary">
                <fmt:formatNumber value="${summary.totalInvestAmount}" pattern="#,##0"/> 원
              </div>
              <div class="text-muted" style="font-size:11px;">주식·펀드·코인·연금</div>
            </div>
          </div>
        </div>
      </div>

      <!-- 필터 -->
      <div class="d-flex gap-2 mb-3 flex-wrap">
        <a href="${pageContext.request.contextPath}/asset/ledger"
           class="btn btn-sm homes-pill ${empty disposeYn ? 'btn-primary' : 'btn-outline-secondary'}">전체</a>
        <a href="${pageContext.request.contextPath}/asset/ledger?disposeYn=N"
           class="btn btn-sm homes-pill ${disposeYn == 'N' ? 'btn-primary' : 'btn-outline-secondary'}">보유중</a>
        <a href="${pageContext.request.contextPath}/asset/ledger?disposeYn=Y"
           class="btn btn-sm homes-pill ${disposeYn == 'Y' ? 'btn-warning' : 'btn-outline-secondary'}">말소됨</a>
      </div>

      <!-- 자산 목록 -->
      <div class="card homes-card">
        <div class="card-body p-0">
          <c:choose>
            <c:when test="${empty assetList}">
              <div class="homes-empty">등록된 자산이 없습니다.</div>
            </c:when>
            <c:otherwise>
              <div class="homes-ag-wrap">
                <div id="assetGrid" class="ag-theme-alpine"></div>
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

  const rowData = [];
  <c:forEach var="a" items="${assetList}">
  rowData.push({
    assetSeq:    ${a.assetSeq},
    assetNm:     d('<c:out value="${a.assetNm}"/>'),
    memo:        d('<c:out value="${a.memo}"/>'),
    assetTypeNm: d('<c:out value="${a.assetTypeNm}"/>'),
    liquidYn:    '${a.liquidYn}',
    amount:      ${a.amount},
    disposeYn:   '${a.disposeYn}',
    disposeYmd:  '${a.disposeYmd}',
    updId:       d('<c:out value="${a.updId}"/>'),
    updDtStr:    '${a.updDtStr}',
  });
  </c:forEach>

  if (!rowData.length) return;

  agGrid.createGrid(document.getElementById('assetGrid'), {
    columnDefs: [
      { field: 'assetNm', headerName: '자산명', flex: 1, minWidth: 160,
        cellRenderer: p => {
          const memo = p.data.memo ? '<div class="text-muted" style="font-size:11px;">' + p.data.memo + '</div>' : '';
          return '<div><div class="fw-semibold">' + p.data.assetNm + '</div>' + memo + '</div>';
        }, autoHeight: true },
      { field: 'assetTypeNm', headerName: '자산형태', width: 120 },
      { field: 'liquidYn', headerName: '유동성', width: 85,
        cellStyle: { justifyContent: 'center' },
        cellRenderer: p => p.value === 'Y'
          ? '<span class="badge bg-success-subtle text-success">유동</span>'
          : '<span class="badge bg-secondary-subtle text-secondary">비유동</span>' },
      { field: 'amount', headerName: '금액', width: 150, type: 'rightAligned',
        cellRenderer: p => '<span class="fw-semibold">' + Number(p.value).toLocaleString('ko-KR') + ' 원</span>' },
      { field: 'disposeYn', headerName: '상태', width: 85,
        cellStyle: { justifyContent: 'center' },
        cellRenderer: p => p.value === 'Y'
          ? '<span class="badge bg-warning-subtle text-warning">말소됨</span>'
          : '<span class="badge bg-primary-subtle text-primary">보유중</span>' },
      { field: 'disposeYmd', headerName: '말소일',  width: 100, cellClass: 'text-muted' },
      { field: 'updId',      headerName: '수정자',  width: 90 },
      { field: 'updDtStr',   headerName: '수정일',  width: 115, cellClass: 'text-muted' },
      { headerName: '', width: isManager ? 110 : 65, sortable: false,
        cellRenderer: p => {
          const el = document.createElement('div');
          el.className = 'd-flex gap-1';
          el.innerHTML = '<a href="' + HOMES.ctx + '/asset/ledger/form?assetSeq=' + p.data.assetSeq + '"' +
            ' class="btn btn-xs btn-outline-primary homes-pill px-2 py-0" style="font-size:12px;"' +
            ' onclick="event.stopPropagation()">수정</a>';
          if (isManager) {
            const del = document.createElement('button');
            del.className = 'btn btn-xs btn-outline-danger homes-pill px-2 py-0';
            del.style.fontSize = '12px';
            del.textContent = '삭제';
            del.setAttribute('data-asset-seq', p.data.assetSeq);
            del.addEventListener('click', e => { e.stopPropagation(); deleteAsset(del); });
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
    onRowClicked: p => HOMES.go(HOMES.ctx + '/asset/ledger/form?assetSeq=' + p.data.assetSeq),
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

async function deleteAsset(btn) {
  if (!confirm('삭제하면 복구할 수 없습니다. 삭제하시겠습니까?')) return;
  const seq = btn.getAttribute('data-asset-seq');
  try {
    const res = await fetch(HOMES.ctx + '/asset/ledger/delete', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'Accept': 'application/json' },
      body: new URLSearchParams({ assetSeq: seq })
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
