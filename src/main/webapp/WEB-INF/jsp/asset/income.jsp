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
          <h1 class="h4 fw-bold mb-1">정기수입관리</h1>
          <div class="text-muted small">월급, 배당금 등 반복적으로 들어오는 수입을 관리합니다.</div>
        </div>
        <a class="btn btn-primary homes-pill px-3"
           href="${pageContext.request.contextPath}/asset/income/form">수입 등록</a>
      </div>

      <!-- 삭제 실패 에러 -->
      <c:if test="${not empty param.error}">
        <div class="alert alert-danger alert-dismissible fade show" role="alert">
          <strong>⚠ 삭제 불가:</strong> ${param.error}
          <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
      </c:if>

      <!-- 요약 카드 -->
      <div class="row g-3 mb-4">
        <div class="col-12 col-sm-4">
          <div class="card homes-card h-100">
            <div class="card-body">
              <div class="text-muted small mb-1">활성 수입 합계</div>
              <div class="fw-bold fs-5 text-success">
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
              <div class="fw-bold fs-5 text-success">${activeCnt} 건</div>
              <div class="text-muted" style="font-size:11px;">사용중(ON) 항목</div>
            </div>
          </div>
        </div>
      </div>

      <!-- 필터 -->
      <div class="d-flex gap-2 mb-3 flex-wrap">
        <a href="${pageContext.request.contextPath}/asset/income"
           class="btn btn-sm homes-pill ${empty useYn ? 'btn-primary' : 'btn-outline-secondary'}">전체</a>
        <a href="${pageContext.request.contextPath}/asset/income?useYn=Y"
           class="btn btn-sm homes-pill ${useYn == 'Y' ? 'btn-success' : 'btn-outline-secondary'}">사용중</a>
        <a href="${pageContext.request.contextPath}/asset/income?useYn=N"
           class="btn btn-sm homes-pill ${useYn == 'N' ? 'btn-secondary' : 'btn-outline-secondary'}">중지됨</a>
      </div>

      <!-- 목록 -->
      <div class="card homes-card">
        <div class="card-body pt-2 px-3 px-md-4">
          <div class="table-responsive">
            <table class="table align-middle homes-table">
              <thead>
                <tr class="text-muted small">
                  <th style="width:60px;" class="text-center">ON/OFF</th>
                  <th>수입명</th>
                  <th style="width:110px;" class="text-nowrap">유형</th>
                  <th style="width:150px;" class="text-nowrap text-end">금액</th>
                  <th style="width:160px;" class="text-nowrap">사이클</th>
                  <th style="width:100px;" class="text-nowrap">시작일</th>
                  <th style="width:100px;" class="text-nowrap">종료일</th>
                  <th style="width:90px;" class="text-nowrap">수정자</th>
                  <th style="width:100px;" class="text-nowrap">수정일</th>
                  <th style="width:80px;"></th>
                </tr>
              </thead>
              <tbody>
                <c:choose>
                  <c:when test="${empty planList}">
                    <tr><td colspan="10"><div class="homes-empty">등록된 정기수입이 없습니다.</div></td></tr>
                  </c:when>
                  <c:otherwise>
                    <c:forEach var="p" items="${planList}">
                      <tr class="${p.useYn == 'N' ? 'text-muted' : ''}">
                        <td class="text-center" onclick="event.stopPropagation();">
                          <div class="form-check form-switch d-flex justify-content-center m-0">
                            <input class="form-check-input use-toggle" type="checkbox"
                                   data-plan-seq="${p.planSeq}"
                                   data-url="${pageContext.request.contextPath}/asset/income/toggle"
                                   ${p.useYn == 'Y' ? 'checked' : ''}
                                   style="cursor:pointer;">
                          </div>
                        </td>
                        <td onclick="location.href='${pageContext.request.contextPath}/asset/income/form?planSeq=${p.planSeq}'" style="cursor:pointer;">
                          <div class="fw-semibold"><c:out value="${p.planNm}"/></div>
                          <c:if test="${not empty p.memo}">
                            <div class="text-muted small text-truncate" style="max-width:260px;"><c:out value="${p.memo}"/></div>
                          </c:if>
                        </td>
                        <td class="text-nowrap">
                          <span class="badge bg-success-subtle text-success"><c:out value="${p.planTypeNm}"/></span>
                        </td>
                        <td class="text-end text-nowrap fw-semibold text-success">
                          <fmt:formatNumber value="${p.amount}" pattern="#,##0"/> 원
                        </td>
                        <td class="small text-nowrap"><c:out value="${p.cycleDesc}"/></td>
                        <td class="text-muted small text-nowrap">${p.startYmd}</td>
                        <td class="text-muted small text-nowrap">${p.endYmd}</td>
                        <td class="small text-nowrap"><c:out value="${p.updId}"/></td>
                        <td class="text-muted small text-nowrap">${p.updDtStr}</td>
                        <td class="text-nowrap" onclick="event.stopPropagation();">
                          <a href="${pageContext.request.contextPath}/asset/income/form?planSeq=${p.planSeq}"
                             class="btn btn-xs btn-outline-primary homes-pill px-2 py-0" style="font-size:12px;">수정</a>
                          <c:if test="${sessionScope.LoginVO.userAuth == 'MANAGER'}">
                            <form method="post" action="${pageContext.request.contextPath}/asset/income/delete"
                                  class="d-inline" onsubmit="return confirm('삭제하시겠습니까?');">
                              <input type="hidden" name="planSeq" value="${p.planSeq}">
                              <button type="submit" class="btn btn-xs btn-outline-danger homes-pill px-2 py-0" style="font-size:12px;">삭제</button>
                            </form>
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

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
  document.querySelectorAll('.use-toggle').forEach(function (el) {
    el.addEventListener('change', function () {
      const planSeq = this.dataset.planSeq;
      const url     = this.dataset.url;
      const cb      = this;
      fetch(url, {
        method: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'planSeq=' + planSeq
      })
      .then(r => r.json())
      .then(data => {
        if (!data.success) { cb.checked = !cb.checked; alert(data.message); }
        else { location.reload(); }
      })
      .catch(() => { cb.checked = !cb.checked; alert('오류가 발생했습니다.'); });
    });
  });
</script>
</body>
</html>
