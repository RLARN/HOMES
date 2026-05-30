<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<!doctype html>
<html lang="ko">
<head>
  <%@ include file="/WEB-INF/jsp/common/head.jsp" %>
  <title>생활비관리 | HOMES</title>
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
          <div class="homes-badge mb-2">Budget</div>
          <h1 class="h4 fw-bold mb-1">생활비관리</h1>
          <div class="text-muted small">월별 실제 생활비 지출을 기록하고 예산과 비교합니다.</div>
        </div>
        <div class="d-flex gap-2 align-items-center">
          <a class="btn btn-outline-secondary homes-pill px-3"
             href="${pageContext.request.contextPath}/living/budget">⚙ 기준정보설정</a>
          <button class="btn btn-primary homes-pill px-3" onclick="openThisMonth()">이번달 입력</button>
        </div>
      </div>

      <!-- 월 선택 입력 -->
      <div class="card homes-card mb-4">
        <div class="card-body py-3">
          <div class="d-flex gap-2 align-items-center flex-wrap">
            <label class="fw-semibold mb-0">월 직접 선택</label>
            <input type="month" class="form-control" style="width:180px;" id="monthPicker"
                   value="${thisMonth.substring(0,4)}-${thisMonth.substring(4,6)}"/>
            <button class="btn btn-outline-primary homes-pill px-3" onclick="goToMonth()">해당 월 입력</button>
          </div>
        </div>
      </div>

      <!-- 월별 목록 -->
      <div class="card homes-card">
        <div class="card-body p-0">
          <div class="table-responsive">
            <table class="table align-middle homes-table mb-0">
              <thead class="table-light">
                <tr>
                  <th style="width:120px;">년월</th>
                  <th class="text-end">예산</th>
                  <th class="text-end">실제 지출</th>
                  <th class="text-end">잔액(예산-실제)</th>
                  <th style="width:60px;" class="text-center">달성률</th>
                  <th style="width:80px;" class="text-center">관리</th>
                </tr>
              </thead>
              <tbody>
                <c:choose>
                  <c:when test="${empty expenseList}">
                    <tr>
                      <td colspan="6" class="text-center text-muted py-5">
                        등록된 내역이 없습니다.<br>
                        <button class="btn btn-sm btn-primary homes-pill mt-2" onclick="openThisMonth()">이번달 입력 시작</button>
                      </td>
                    </tr>
                  </c:when>
                  <c:otherwise>
                    <c:forEach var="exp" items="${expenseList}">
                      <c:set var="remain" value="${exp.totalBudgetAmt - exp.totalActualAmt}"/>
                      <c:set var="pct"    value="${exp.totalBudgetAmt > 0 ? (exp.totalActualAmt * 100 / exp.totalBudgetAmt) : 0}"/>
                      <c:set var="isThis" value="${exp.expYymm == thisMonth}"/>
                      <tr class="${isThis ? 'table-primary' : ''}"
                          style="cursor:pointer;"
                          onclick="location.href='${pageContext.request.contextPath}/living/expense/${exp.expYymm}'">
                        <td>
                          <span class="fw-semibold">
                            ${exp.expYymm.substring(0,4)}년 ${exp.expYymm.substring(4,6)}월
                          </span>
                          <c:if test="${isThis}">
                            <span class="badge bg-primary ms-1" style="font-size:10px;">이번달</span>
                          </c:if>
                        </td>
                        <td class="text-end text-muted">
                          <fmt:formatNumber value="${exp.totalBudgetAmt}" pattern="#,##0"/> 원
                        </td>
                        <td class="text-end fw-semibold">
                          <fmt:formatNumber value="${exp.totalActualAmt}" pattern="#,##0"/> 원
                        </td>
                        <td class="text-end">
                          <c:choose>
                            <c:when test="${remain >= 0}">
                              <span class="text-success fw-semibold">
                                <fmt:formatNumber value="${remain}" pattern="#,##0"/> 원
                              </span>
                            </c:when>
                            <c:otherwise>
                              <span class="text-danger fw-semibold">
                                -<fmt:formatNumber value="${-remain}" pattern="#,##0"/> 원
                              </span>
                            </c:otherwise>
                          </c:choose>
                        </td>
                        <td class="text-center">
                          <div class="d-flex align-items-center gap-1 justify-content-center">
                            <div class="progress flex-grow-1" style="height:6px; min-width:50px;">
                              <div class="progress-bar ${pct > 100 ? 'bg-danger' : 'bg-primary'}"
                                   style="width:${pct > 100 ? 100 : pct}%"></div>
                            </div>
                            <small class="${pct > 100 ? 'text-danger' : 'text-muted'}">${pct}%</small>
                          </div>
                        </td>
                        <td class="text-center">
                          <a class="btn btn-sm btn-outline-primary homes-pill"
                             href="${pageContext.request.contextPath}/living/expense/${exp.expYymm}"
                             onclick="event.stopPropagation()">입력</a>
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

    </div><%-- homes-main-body --%>
    <%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
  </main>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
const ctx       = '${pageContext.request.contextPath}';
const thisMonth = '${thisMonth}';

function openThisMonth() {
  location.href = ctx + '/living/expense/' + thisMonth;
}

function goToMonth() {
  const val = document.getElementById('monthPicker').value; // YYYY-MM
  if (!val) return;
  const yymm = val.replace('-', '');
  location.href = ctx + '/living/expense/' + yymm;
}
</script>
</body>
</html>
