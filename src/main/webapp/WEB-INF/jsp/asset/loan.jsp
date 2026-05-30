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
        <div class="card-body pt-2 px-3 px-md-4">
          <div class="table-responsive">
            <table class="table align-middle homes-table">
              <thead>
                <tr class="text-muted small">
                  <th>대출명</th>
                  <th style="width:140px;" class="text-nowrap text-end">최초금액</th>
                  <th style="width:140px;" class="text-nowrap text-end">현재잔액</th>
                  <th style="width:70px;"  class="text-nowrap text-center">금리</th>
                  <th style="width:70px;"  class="text-nowrap text-center">기간</th>
                  <th style="width:100px;" class="text-nowrap">시작일</th>
                  <th style="width:100px;" class="text-nowrap">종료일</th>
                  <th style="width:80px;"  class="text-nowrap text-center">상태</th>
                  <th style="width:100px;" class="text-nowrap">수정자</th>
                  <th style="width:110px;" class="text-nowrap">수정일</th>
                  <th style="width:80px;"></th>
                </tr>
              </thead>
              <tbody>
                <c:choose>
                  <c:when test="${empty loanList}">
                    <tr>
                      <td colspan="11">
                        <div class="homes-empty">등록된 대출이 없습니다.</div>
                      </td>
                    </tr>
                  </c:when>
                  <c:otherwise>
                    <c:forEach var="l" items="${loanList}">
                      <tr onclick="location.href='${pageContext.request.contextPath}/asset/loan/form?loanSeq=${l.loanSeq}'"
                          style="cursor:pointer;">
                        <td>
                          <div class="fw-semibold text-truncate" style="max-width:240px;">
                            <c:out value="${l.loanNm}"/>
                          </div>
                          <c:if test="${not empty l.memo}">
                            <div class="text-muted small text-truncate" style="max-width:240px;">
                              <c:out value="${l.memo}"/>
                            </div>
                          </c:if>
                        </td>
                        <td class="text-end text-nowrap">
                          <fmt:formatNumber value="${l.loanAmount}" pattern="#,##0"/> 원
                        </td>
                        <td class="text-end text-nowrap fw-semibold text-danger">
                          <fmt:formatNumber value="${l.currentBalance}" pattern="#,##0"/> 원
                        </td>
                        <td class="text-center text-nowrap">
                          <c:choose>
                            <c:when test="${not empty l.interestRate}">
                              <fmt:formatNumber value="${l.interestRate}" pattern="#,##0.##"/>%
                            </c:when>
                            <c:otherwise>-</c:otherwise>
                          </c:choose>
                        </td>
                        <td class="text-center text-nowrap">
                          <c:choose>
                            <c:when test="${not empty l.loanMonths}">${l.loanMonths}개월</c:when>
                            <c:otherwise>-</c:otherwise>
                          </c:choose>
                        </td>
                        <td class="text-muted small text-nowrap">${l.startYmd}</td>
                        <td class="text-muted small text-nowrap">${l.endYmd}</td>
                        <td class="text-center text-nowrap">
                          <c:choose>
                            <c:when test="${l.closeYn == 'Y'}">
                              <span class="badge bg-warning-subtle text-warning">완납/종료</span>
                            </c:when>
                            <c:otherwise>
                              <span class="badge bg-danger-subtle text-danger">상환중</span>
                            </c:otherwise>
                          </c:choose>
                        </td>
                        <td class="text-nowrap small"><c:out value="${l.updId}"/></td>
                        <td class="text-muted text-nowrap small">${l.updDtStr}</td>
                        <td class="text-nowrap" onclick="event.stopPropagation();">
                          <a href="${pageContext.request.contextPath}/asset/loan/form?loanSeq=${l.loanSeq}"
                             class="btn btn-xs btn-outline-primary homes-pill px-2 py-0" style="font-size:12px;">수정</a>
                          <c:if test="${sessionScope.LoginVO.userAuth == 'manager'}">
                            <button type="button"
                                    class="btn btn-xs btn-outline-danger homes-pill px-2 py-0"
                                    style="font-size:12px;"
                                    data-loan-seq="${l.loanSeq}"
                                    onclick="deleteLoan(this)">삭제</button>
                          </c:if>
                        </td>
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
