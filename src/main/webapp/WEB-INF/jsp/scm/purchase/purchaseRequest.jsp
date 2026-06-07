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

        <!-- Page Header -->
        <div class="d-flex flex-column flex-md-row align-items-md-center justify-content-between gap-2 mb-3">
          <div>
            <div class="homes-badge mb-2">SCM</div>
            <h1 class="h4 fw-bold mb-1">입금요청 작성</h1>
            <div class="text-muted small">금액과 사유를 입력하고 상신하세요. 오른쪽에서 기존 요청을 검색할 수 있어요.</div>
          </div>
        </div>

        <div class="row g-3">
          <!-- =======================
               Left: 입력(상신)
          ======================= -->
          <div class="col-12 col-xl-4">
            <div class="card homes-card homes-form-card">
              <div class="card-header bg-transparent border-0 pt-3 px-3 px-md-4">
                <div class="fw-semibold">입금요청 입력</div>
                <div class="text-muted small mt-1">필수값만 먼저 만들고, 나중에 첨부/결재선 추가해도 됨</div>
              </div>

              <div class="card-body pt-2 px-3 px-md-4">
                <form method="post" action="${pageContext.request.contextPath}/scm/purchase/request/save" id="depositForm">
                  <!-- 사용처 -->
                  <div class="mb-3">
                    <label class="form-label fw-semibold">사용처 <span class="text-danger">*</span></label>
					  <input type="text"
					         class="form-control"
					         name="store"
					         id="store"
					         placeholder="예) 현대백화점"
					         value="${param.store}">
					</div>
                  <!-- 금액 -->
                  <div class="mb-3">
                    <label class="form-label fw-semibold">금액 <span class="text-danger">*</span></label>
                    <div class="input-group">
                      <span class="input-group-text">₩</span>
                      <input type="text"
                             class="form-control"
                             name="amount"
                             id="amount"
                             inputmode="numeric"
                             placeholder="예) 32000"
                             value="${param.amount}">
                    </div>
                    <div class="form-text">숫자만 입력. 자동 콤마는 프론트에서 처리(아래 스크립트).</div>
                  </div>

                  <!-- 사유 -->
                  <div class="mb-3">
                    <label class="form-label fw-semibold">사유</label>
                    <textarea class="form-control"
                              name="reason"
                              id="reason"
                              rows="5"
                              placeholder="예) 주말 장보기 / 기저귀 구매 / 공과금 등">${param.reason}</textarea>
                  </div>

                  <!-- 버튼 -->
                  <div class="d-grid gap-2">
                    <button type="submit" class="btn btn-primary homes-pill" id="btnSubmit">
                      상신
                    </button>
                    <button type="button" class="btn btn-outline-secondary homes-pill" id="btnReset">
                      초기화
                    </button>
                  </div>

                  <!-- 안내/에러 메시지 영역(백엔드에서 msg 내려주면 표시) -->
                  <c:if test="${not empty msg}">
                    <div class="alert alert-info mt-3 mb-0" role="alert">
                      ${msg}
                    </div>
                  </c:if>
                </form>
              </div>
            </div>
          </div>

          <!-- =======================
               Right: 리스트(검색)
          ======================= -->
          <div class="col-12 col-xl-8">
            <div class="card homes-card">
              <div class="card-header bg-transparent border-0 pt-3 px-3 px-md-4">
                <div class="d-flex flex-column flex-md-row align-items-md-center justify-content-between gap-2">
                  <div>
                    <div class="fw-semibold">기존 입금요청 리스트</div>
                    <div class="text-muted small">백엔드에서 SCM_DEPOSIT_REQUEST_LIST 조회</div>
                  </div>
                </div>

                <!-- 검색 -->
                <form method="get" action="${pageContext.request.contextPath}/scm/purchase/request" class="mt-3">
                  <div class="row g-2 align-items-center">
                    <div class="col-12 col-md-8">
                      <input type="search"
                             class="form-control homes-search-light"
                             name="q"
                             placeholder="검색(사유/상태/금액 등) — 예: 장보기, 32000"
                             value="${param.q}">
                    </div>
                    <div class="col-6 col-md-2">
                      <select class="form-select" name="status">
                        <option value="">전체상태</option>
                        <option value="REQUEST" ${param.status == 'REQUEST' ? 'selected' : ''}>요청</option>
                        <option value="APPROVED" ${param.status == 'APPROVED' ? 'selected' : ''}>승인</option>
                        <option value="REJECTED" ${param.status == 'REJECTED' ? 'selected' : ''}>반려</option>
                      </select>
                    </div>
                    <div class="col-6 col-md-2 d-grid">
                      <button class="btn btn-outline-primary homes-pill" type="submit">검색</button>
                    </div>
                  </div>
                </form>
              </div>

              <div class="card-body pt-2 px-3 px-md-4">
                <c:choose>
                  <c:when test="${empty requestList}">
                    <div class="homes-empty">
                      아직 등록된 입금요청이 없어요.
                      <span class="text-muted">(좌측에서 작성 후 상신)</span>
                    </div>
                  </c:when>
                  <c:otherwise>
                    <div class="homes-ag-wrap">
                      <div id="reqGrid" class="ag-theme-alpine"></div>
                    </div>
                  </c:otherwise>
                </c:choose>

                <!-- 페이징 자리(나중에) -->
                <c:if test="${not empty page}">
                  <div class="d-flex justify-content-center mt-3">
                    ${page}
                  </div>
                </c:if>
              </div>
            </div>
          </div>
        </div>

      </div>

      <%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
    </main>
  </div>

  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
  <script>
  (function () {
    function d(s) { const el = document.createElement('textarea'); el.innerHTML = s; return el.value; }
    const rowData = [];
    <c:forEach var="row" items="${requestList}">
    rowData.push({
      requestId:   '${row.requestId}',
      requestDt:   d('<c:out value="${row.requestDt}"/>'),
      reason:      d('<c:out value="${row.reason}"/>'),
      requesterNm: d('<c:out value="${row.requesterNm}"/>'),
      amount:      d('<c:out value="${row.amount}"/>'),
      status:      d('<c:out value="${row.status}"/>'),
    });
    </c:forEach>

    if (!rowData.length) return;
    const ctx = '${pageContext.request.contextPath}';
    const statusBadge = s => {
      if (s === 'APPROVED') return '<span class="badge rounded-pill text-bg-success">APPROVED</span>';
      if (s === 'REJECTED') return '<span class="badge rounded-pill text-bg-danger">REJECTED</span>';
      return '<span class="badge rounded-pill text-bg-secondary">' + s + '</span>';
    };

    agGrid.createGrid(document.getElementById('reqGrid'), {
      columnDefs: [
        { field: 'requestDt', headerName: '요청일', width: 120, cellClass: 'text-muted' },
        { field: 'reason', headerName: '사유', flex: 1, minWidth: 200,
          cellRenderer: p => `<div>
            <div class="fw-semibold text-truncate">${p.data.reason}</div>
            <div class="text-muted" style="font-size:11px;">${p.data.requesterNm}</div>
          </div>`, autoHeight: true },
        { field: 'amount',  headerName: '금액',  width: 140, type: 'rightAligned',
          cellRenderer: p => '<span class="fw-bold">' + p.value + '</span>' },
        { field: 'status',  headerName: '상태',  width: 110,
          cellStyle: { justifyContent: 'center' },
          cellRenderer: p => statusBadge(p.value) },
        { headerName: '상세', width: 90, sortable: false,
          cellStyle: { justifyContent: 'center' },
          cellRenderer: p => {
            const a = document.createElement('a');
            a.className = 'btn btn-sm btn-outline-secondary homes-pill';
            a.href = ctx + '/scm/purchase/request/detail?id=' + p.data.requestId;
            a.textContent = '보기';
            return a;
          }
        },
      ],
      rowData,
      defaultColDef: { sortable: true, resizable: true, suppressMovable: true },
      domLayout: 'autoHeight',
      suppressCellFocus: true,
    });
  })();
  </script>

  <style>
    /* 페이지 전용: 메인 톤 유지하면서 입력 카드 강조 */
    .homes-form-card{
      background: linear-gradient(180deg, rgba(255,255,255,.95), rgba(255,255,255,.90));
    }
    .homes-search-light{
      border-radius: 999px;
    }
    .homes-table thead th{
      border-top: 0;
      border-bottom: 1px solid rgba(17,24,39,.08);
    }
    .homes-table tbody tr{
      border-color: rgba(17,24,39,.06);
    }
  </style>

  <script>
    // 금액: 숫자만 + 콤마 표시(화면용)
    (function () {
      const amountEl = document.getElementById('amount');
      const resetBtn = document.getElementById('btnReset');
      const formEl = document.getElementById('depositForm');

      function formatNumber(v) {
        if (!v) return '';
        const n = v.replace(/[^\d]/g, '');
        if (!n) return '';
        return n.replace(/\B(?=(\d{3})+(?!\d))/g, ',');
      }

      if (amountEl) {
        amountEl.addEventListener('input', function () {
          const caret = this.selectionStart;
          this.value = formatNumber(this.value);
          // caret 위치 완벽 보정은 생략(간단버전)
          this.setSelectionRange(caret, caret);
        });

        // submit 전에 콤마 제거해서 서버로 보냄
        formEl.addEventListener('submit', function () {
          amountEl.value = amountEl.value.replace(/[^\d]/g, '');
        });
      }

      if (resetBtn) {
        resetBtn.addEventListener('click', function () {
          formEl.reset();
        });
      }
    })();
  </script>
</body>
</html>
