<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
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

        <div class="d-flex flex-column flex-md-row align-items-md-center justify-content-between gap-2 mb-3">
          <div>
            <div class="homes-badge mb-2">NOTE</div>
            <h1 class="h4 fw-bold mb-1">공유메모</h1>
            <div class="text-muted small">가족이 함께 보는 간단한 메모 게시판입니다.</div>
          </div>
          <a class="btn btn-primary homes-pill px-3" href="${pageContext.request.contextPath}/note/form">메모 등록</a>
        </div>

        <c:if test="${not empty message}">
          <div class="alert alert-info py-2">${message}</div>
        </c:if>

        <div class="card homes-card">
          <div class="card-header bg-transparent border-0 pt-3 px-3 px-md-4">
            <form method="get" action="${pageContext.request.contextPath}/note/list">
              <div class="row g-2 align-items-center">
                <div class="col-12 col-md-10">
                  <input type="search"
                         class="form-control homes-search-light"
                         name="q"
                         value="${q}"
                         placeholder="제목으로 검색">
                </div>
                <div class="col-12 col-md-2 d-grid">
                  <button class="btn btn-outline-primary homes-pill" type="submit">검색</button>
                </div>
              </div>
            </form>
          </div>

          <div class="card-body p-0 px-0">
            <div class="homes-ag-wrap">
              <div id="noteGrid" class="ag-theme-alpine"></div>
            </div>
            <c:if test="${empty noteList}">
              <div class="homes-empty">등록된 공유메모가 없습니다.</div>
            </c:if>
          </div>
        </div>
      </div>

      <%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
    </main>
  </div>

  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
(function () {
  const ctx = '${pageContext.request.contextPath}';
  function d(s) { const el = document.createElement('textarea'); el.innerHTML = s; return el.value; }

  const rowData = [];
  <c:forEach var="note" items="${noteList}">
  rowData.push({
    noteSeq: ${note.noteSeq},
    title:   d('<c:out value="${note.title}"/>'),
    regId:   d('<c:out value="${note.regId}"/>'),
    updId:   d('<c:out value="${note.updId}"/>'),
    updDtText: d('<c:out value="${note.updDtText}"/>'),
  });
  </c:forEach>

  if (!rowData.length) return;

  agGrid.createGrid(document.getElementById('noteGrid'), {
    columnDefs: [
      { field: 'title', headerName: '제목', flex: 1, minWidth: 200,
        cellRenderer: p => '<div><div class="fw-semibold text-truncate">' + p.data.title +
          '</div><div class="text-muted" style="font-size:11px;">최초 작성자 ' + p.data.regId + '</div></div>',
        autoHeight: true,
      },
      { field: 'updId',     headerName: '마지막 수정자', width: 140, minWidth: 100 },
      { field: 'updDtText', headerName: '수정일',       width: 160, minWidth: 120,
        cellClass: 'text-muted' },
    ],
    rowData,
    defaultColDef: { sortable: true, resizable: true, suppressMovable: true },
    domLayout: 'autoHeight',
    suppressCellFocus: true,
    rowClass: 'homes-row-click',
    onRowClicked: p => HOMES.go(ctx + '/note/detail?noteSeq=' + p.data.noteSeq),
    getRowStyle: () => ({ cursor: 'pointer' }),
  });
})();
</script>
</body>
</html>
