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
        <div class="card-body pt-2 px-3 px-md-4">
          <div class="table-responsive">
            <table class="table align-middle homes-table">
              <thead>
                <tr class="text-muted small">
                  <th style="width:60px;" class="text-center">ON/OFF</th>
                  <th>지출명</th>
                  <th style="width:110px;" class="text-nowrap">유형</th>
                  <th style="width:80px;"  class="text-nowrap text-center">구분</th>
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
                    <tr><td colspan="11"><div class="homes-empty">등록된 정기지출이 없습니다.</div></td></tr>
                  </c:when>
                  <c:otherwise>
                    <c:forEach var="p" items="${planList}">
                      <tr class="${p.useYn == 'N' ? 'text-muted' : ''}">
                        <td class="text-center" onclick="event.stopPropagation();">
                          <div class="form-check form-switch d-flex justify-content-center m-0">
                            <input class="form-check-input use-toggle" type="checkbox"
                                   data-plan-seq="${p.planSeq}"
                                   data-url="${pageContext.request.contextPath}/asset/expense/toggle"
                                   ${p.useYn == 'Y' ? 'checked' : ''}
                                   style="cursor:pointer;">
                          </div>
                        </td>
                        <td onclick="HOMES.go('${pageContext.request.contextPath}/asset/expense/form?planSeq=${p.planSeq}')" style="cursor:pointer;">
                          <div class="fw-semibold"><c:out value="${p.planNm}"/></div>
                          <c:if test="${not empty p.memo}">
                            <div class="text-muted small text-truncate" style="max-width:240px;"><c:out value="${p.memo}"/></div>
                          </c:if>
                        </td>
                        <td class="text-nowrap">
                          <span class="badge bg-danger-subtle text-danger"><c:out value="${p.planTypeNm}"/></span>
                        </td>
                        <td class="text-center text-nowrap">
                          <c:choose>
                            <c:when test="${p.flowType == 'SAVING'}">
                              <span class="badge bg-primary-subtle text-primary" style="font-size:10px;">저축</span>
                            </c:when>
                            <c:when test="${p.flowType == 'INVEST'}">
                              <span class="badge bg-warning-subtle text-warning" style="font-size:10px;">투자</span>
                            </c:when>
                            <c:otherwise>
                              <span class="badge bg-danger-subtle text-danger" style="font-size:10px;">지출</span>
                            </c:otherwise>
                          </c:choose>
                        </td>
                        <td class="text-end text-nowrap fw-semibold text-danger">
                          <fmt:formatNumber value="${p.amount}" pattern="#,##0"/> 원
                        </td>
                        <td class="small text-nowrap"><c:out value="${p.cycleDesc}"/></td>
                        <td class="text-muted small text-nowrap">${p.startYmd}</td>
                        <td class="text-muted small text-nowrap">${p.endYmd}</td>
                        <td class="small text-nowrap"><c:out value="${p.updId}"/></td>
                        <td class="text-muted small text-nowrap">${p.updDtStr}</td>
                        <td class="text-nowrap" onclick="event.stopPropagation();">
                          <a href="${pageContext.request.contextPath}/asset/expense/form?planSeq=${p.planSeq}"
                             class="btn btn-xs btn-outline-primary homes-pill px-2 py-0" style="font-size:12px;">수정</a>
                          <c:if test="${sessionScope.LoginVO.userAuth == 'MANAGER'}">
                            <form method="post" action="${pageContext.request.contextPath}/asset/expense/delete"
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
