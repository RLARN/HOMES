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
            <div class="text-muted small">메모 내용을 확인합니다.</div>
          </div>
          <div class="d-flex gap-2">
            <a class="btn btn-outline-secondary homes-pill px-3" href="${pageContext.request.contextPath}/note/list">목록</a>
            <a class="btn btn-primary homes-pill px-3" href="${pageContext.request.contextPath}/note/form?noteSeq=${note.noteSeq}">수정</a>
          </div>
        </div>

        <c:if test="${not empty message}">
          <div class="alert alert-info py-2">${message}</div>
        </c:if>

        <div class="card homes-card">
          <div class="card-header bg-transparent border-0 pt-3 px-3 px-md-4">
            <div class="d-flex flex-column flex-md-row justify-content-between gap-2">
              <div>
                <div class="fw-semibold h5 mb-1"><c:out value="${note.title}" /></div>
                <div class="text-muted small">
                  작성 <c:out value="${note.regId}" /> · <c:out value="${note.regDtText}" />
                  <span class="mx-1">|</span>
                  수정 <c:out value="${note.updId}" /> · <c:out value="${note.updDtText}" />
                </div>
              </div>
            </div>
          </div>

          <div class="card-body pt-2 px-3 px-md-4">
            <div class="note-content">
              <c:out value="${note.content}" />
            </div>

            <div class="d-flex justify-content-end gap-2 mt-4">
              <form method="post"
                    action="${pageContext.request.contextPath}/note/delete"
                    onsubmit="return confirm('이 메모를 삭제할까요?');">
                <input type="hidden" name="noteSeq" value="${note.noteSeq}">
                <button class="btn btn-outline-danger homes-pill px-3" type="submit">삭제</button>
              </form>
            </div>
          </div>
        </div>
      </div>

      <%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
    </main>
  </div>

  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
  <style>
    .note-content {
      min-height: 220px;
      white-space: pre-wrap;
      line-height: 1.7;
      color: #111827;
    }
  </style>
</body>
</html>
