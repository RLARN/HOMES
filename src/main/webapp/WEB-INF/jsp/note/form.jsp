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
            <h1 class="h4 fw-bold mb-1">
              <c:choose>
                <c:when test="${empty note.noteSeq}">공유메모 등록</c:when>
                <c:otherwise>공유메모 수정</c:otherwise>
              </c:choose>
            </h1>
            <div class="text-muted small">가족과 공유할 내용을 작성하세요.</div>
          </div>
          <a class="btn btn-outline-secondary homes-pill px-3" href="${pageContext.request.contextPath}/note/list">목록</a>
        </div>

        <div class="card homes-card">
          <div class="card-body px-3 px-md-4 py-4">
            <form method="post" action="${pageContext.request.contextPath}/note/save">
              <input type="hidden" name="noteSeq" value="${note.noteSeq}">

              <div class="mb-3">
                <label class="form-label fw-semibold">제목 <span class="text-danger">*</span></label>
                <input type="text"
                       class="form-control"
                       name="title"
                       value="${note.title}"
                       maxlength="200"
                       required>
              </div>

              <div class="mb-3">
                <label class="form-label fw-semibold">내용 <span class="text-danger">*</span></label>
                <textarea class="form-control note-editor"
                          name="content"
                          rows="14"
                          required><c:out value="${note.content}" /></textarea>
              </div>

              <div class="d-flex justify-content-end gap-2">
                <button class="btn btn-outline-secondary homes-pill px-3" type="button"
                        onclick="history.back();">취소</button>
                <button class="btn btn-primary homes-pill px-3" type="submit">저장</button>
              </div>
            </form>
          </div>
        </div>
      </div>

      <%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
    </main>
  </div>

  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
  <style>
    .note-editor {
      min-height: 320px;
      line-height: 1.7;
      resize: vertical;
    }
  </style>
</body>
</html>
