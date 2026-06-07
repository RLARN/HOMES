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
          <h1 class="h4 fw-bold mb-1">정기지출관리</h1>
          <div class="text-muted small">공과금, 보험료, 대출이자 등 반복 지출을 관리합니다.</div>
        </div>
        <a class="btn btn-primary homes-pill px-3"
           href="${pageContext.request.contextPath}/asset/expense/form">지출 등록</a>
      </div>

      <!-- 요약 카드 -->
      <div class="row g-3 mb-4">
        <div class="col-12 col-sm-4">
          <div class="card homes-card h-100">
            <div class="card-body">
              <div class="text-muted small mb-1">활성 지출 합계</div>
              <div class="fw-bold fs-5 text-danger">
                <fmt:formatNumber value="${totalAmount}" pattern="#,##0"/> 원
              </div>
              <div class="text-muted" style="font-size:11px;">사용중(ON) 항목 기준</div>
            </div>
          </div>
        </div>
        <div class="col-12 col-sm-4">
          <div class="card homes-card h-100">
            <div class="card-body">
              <div class="text-muted small mb-1">등록 항목 수</div>
              <div class="fw-bold fs-5">${planList.size()} 건</div>
              <div class="text-muted" style="font-size:11px;">삭제 제외 전체</div>
            </div>
          </div>
        </div>
        <div class="col-12 col-sm-4">
          <div class="card homes-card h-100">
            <div class="card-body">
              <div class="text-muted small mb-1">활성 항목 수</div>
              <c:set var="activeCnt" value="0"/>
              <c:forEach var="p" items="${planList}">
                <c:if test="${p.useYn == 'Y'}"><c:set var="activeCnt" value="${activeCnt + 1}"/></c:if>
              </c:forEach>
              <div class="fw-bold fs-5 text-danger">${activeCnt} 건</div>
              <div class="text-muted" style="font-size:11px;">사용중(ON) 항목</div>
            </div>
          </div>
        </div>
      </div>

      <!-- 필터 -->
      <div class="d-flex gap-2 mb-3 flex-wrap">
        <a href="${pageContext.request.contextPath}/asset/expense"
           class="btn btn-sm homes-pill ${empty useYn ? 'btn-primary' : 'btn-outline-secondary'}">전체</a>
        <a href="${pageContext.request.contextPath}/asset/expense?useYn=Y"
           class="btn btn-sm homes-pill ${useYn == 'Y' ? 'btn-danger' : 'btn-outline-secondary'}">사용중</a>
        <a href="${pageContext.request.contextPath}/asset/expense?useYn=N"
           class="btn btn-sm homes-pill ${useYn == 'N' ? 'btn-secondary' : 'btn-outline-secondary'}">중지됨</a>
      </div>

      <!-- 목록 -->
      <div class="card homes-card">
        <div class="card-body p-0">
          <c:choose>
            <c:when test="${empty planList}">
              <div class="homes-empty">등록된 정기지출이 없습니다.</div>
            </c:when>
            <c:otherwise>
              <div class="homes-ag-wrap">
                <div id="expenseGrid" class="ag-theme-alpine"></div>
              </div>
            </c:otherwise>
          </c:choose>
        </div>
      </div>

    </div>
    <%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
  </main>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
const ctx = '${pageContext.request.contextPath}';
const isManager = '${sessionScope.LoginVO.userAuth}' === 'MANAGER';

function togglePlan(cb, planSeq, url) {
  fetch(url, {
    method: 'POST',
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: 'planSeq=' + planSeq
  }).then(r => r.json()).then(data => {
    if (!data.success) { cb.checked = !cb.checked; alert(data.message); }
    else { location.reload(); }
  }).catch(() => { cb.checked = !cb.checked; alert('오류가 발생했습니다.'); });
}

(function () {
  function d(s) { const el = document.createElement('textarea'); el.innerHTML = s; return el.value; }

  const rowData = [];
  <c:forEach var="p" items="${planList}">
  rowData.push({
    planSeq:    ${p.planSeq},
    planNm:     d('<c:out value="${p.planNm}"/>'),
    memo:       d('<c:out value="${p.memo}"/>'),
    planTypeNm: d('<c:out value="${p.planTypeNm}"/>'),
    flowType:   '${p.flowType}',
    amount:     ${p.amount},
    cycleDesc:  d('<c:out value="${p.cycleDesc}"/>'),
    startYmd:   '${p.startYmd}',
    endYmd:     '${p.endYmd}',
    updId:      d('<c:out value="${p.updId}"/>'),
    updDtStr:   '${p.updDtStr}',
    useYn:      '${p.useYn}',
  });
  </c:forEach>

  if (!rowData.length) return;

  const flowBadge = {
    SAVING: '<span class="badge bg-primary-subtle text-primary">저축</span>',
    INVEST: '<span class="badge bg-warning-subtle text-warning">투자</span>',
    EXPENSE:'<span class="badge bg-danger-subtle text-danger">지출</span>',
  };

  agGrid.createGrid(document.getElementById('expenseGrid'), {
    columnDefs: [
      { headerName: 'ON/OFF', width: 75, sortable: false,
        cellStyle: { justifyContent: 'center' },
        cellRenderer: p => {
          const cb = document.createElement('input');
          cb.type = 'checkbox';
          cb.className = 'form-check-input';
          cb.checked = p.data.useYn === 'Y';
          cb.style.cursor = 'pointer';
          cb.addEventListener('click', e => e.stopPropagation());
          cb.addEventListener('change', () => togglePlan(cb, p.data.planSeq, ctx + '/asset/expense/toggle'));
          return cb;
        }
      },
      { field: 'planNm', headerName: '지출명', flex: 1, minWidth: 160,
        cellRenderer: p => {
          const memo = p.data.memo ? '<div class="text-muted" style="font-size:11px;">' + p.data.memo + '</div>' : '';
          return '<div><div class="fw-semibold">' + p.data.planNm + '</div>' + memo + '</div>';
        }, autoHeight: true },
      { field: 'planTypeNm', headerName: '유형', width: 110,
        cellRenderer: p => '<span class="badge bg-danger-subtle text-danger">' + p.value + '</span>' },
      { field: 'flowType', headerName: '구분', width: 80,
        cellStyle: { justifyContent: 'center' },
        cellRenderer: p => flowBadge[p.value] || flowBadge.EXPENSE },
      { field: 'amount', headerName: '금액', width: 150, type: 'rightAligned',
        cellRenderer: p => '<span class="fw-semibold text-danger">' + Number(p.value).toLocaleString('ko-KR') + ' 원</span>' },
      { field: 'cycleDesc', headerName: '사이클', width: 140 },
      { field: 'startYmd',  headerName: '시작일', width: 100, cellClass: 'text-muted' },
      { field: 'endYmd',    headerName: '종료일', width: 100, cellClass: 'text-muted' },
      { field: 'updId',     headerName: '수정자', width: 90 },
      { field: 'updDtStr',  headerName: '수정일', width: 110, cellClass: 'text-muted' },
      { headerName: '', width: isManager ? 110 : 65, sortable: false,
        cellRenderer: p => {
          const el = document.createElement('div');
          el.className = 'd-flex gap-1';
          el.innerHTML = '<a href="' + ctx + '/asset/expense/form?planSeq=' + p.data.planSeq + '"' +
            ' class="btn btn-xs btn-outline-primary homes-pill px-2 py-0" style="font-size:12px;"' +
            ' onclick="event.stopPropagation()">수정</a>';
          if (isManager) {
            const form = document.createElement('form');
            form.method = 'post';
            form.action = ctx + '/asset/expense/delete';
            form.className = 'd-inline';
            form.onsubmit = () => confirm('삭제하시겠습니까?');
            form.innerHTML = '<input type="hidden" name="planSeq" value="' + p.data.planSeq + '">' +
              '<button type="submit" class="btn btn-xs btn-outline-danger homes-pill px-2 py-0"' +
              ' style="font-size:12px;" onclick="event.stopPropagation()">삭제</button>';
            el.appendChild(form);
          }
          return el;
        }
      },
    ],
    rowData,
    defaultColDef: { sortable: true, resizable: true, suppressMovable: true },
    domLayout: 'autoHeight',
    suppressCellFocus: true,
    getRowStyle: p => ({ cursor: 'pointer', opacity: p.data.useYn === 'N' ? 0.7 : 1 }),
    onRowClicked: p => HOMES.go(ctx + '/asset/expense/form?planSeq=' + p.data.planSeq),
  });
})();
</script>
</body>
</html>
