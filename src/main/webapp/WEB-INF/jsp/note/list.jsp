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

          <div class="card-body pt-2 px-3 px-md-4">
            <div class="table-responsive">
              <table class="table align-middle homes-table">
                <thead>
                  <tr class="text-muted small">
                    <th>제목</th>
                    <th style="width: 140px;" class="text-nowrap">마지막 수정자</th>
                    <th style="width: 160px;" class="text-nowrap">수정일</th>
                  </tr>
                </thead>
                <tbody>
                  <c:choose>
                    <c:when test="${empty noteList}">
                      <tr>
                        <td colspan="3">
                          <div class="homes-empty">등록된 공유메모가 없습니다.</div>
                        </td>
                      </tr>
                    </c:when>
                    <c:otherwise>
                      <c:forEach var="note" items="${noteList}">
                        <tr onclick="HOMES.go('${pageContext.request.contextPath}/note/detail?noteSeq=${note.noteSeq}')"
                            style="cursor:pointer;">
                          <td>
                            <div class="fw-semibold text-truncate" style="max-width: 720px;">
                              <c:out value="${note.title}" />
                            </div>
                            <div class="text-muted small">
                              최초 작성자 <c:out value="${note.regId}" />
                            </div>
                          </td>
                          <td class="text-nowrap"><c:out value="${note.updId}" /></td>
                          <td class="text-muted text-nowrap"><c:out value="${note.updDtText}" /></td>
                        </tr>
                      </c:forEach>
                    </c:otherwise>
                  </c:choose>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>

      <%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
    </main>
  </div>

  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
