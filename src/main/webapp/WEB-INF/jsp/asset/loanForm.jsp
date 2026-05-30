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
          <h1 class="h4 fw-bold mb-1">
            <c:choose>
              <c:when test="${empty loan.loanSeq}">대출 등록</c:when>
              <c:otherwise>대출 수정</c:otherwise>
            </c:choose>
          </h1>
          <div class="text-muted small">대출 정보를 입력하고 저장합니다.</div>
        </div>
        <a class="btn btn-outline-secondary homes-pill px-3"
           href="${pageContext.request.contextPath}/asset/loan">목록</a>
      </div>

      <!-- 폼 카드 -->
      <div class="card homes-card">
        <div class="card-body px-3 px-md-4 py-4">
          <form id="loanForm" method="post"
                action="${pageContext.request.contextPath}/asset/loan/save">
            <input type="hidden" name="loanSeq" value="${loan.loanSeq}">

            <div class="row g-3">

              <!-- 대출명 -->
              <div class="col-12">
                <label class="form-label fw-semibold">대출명 <span class="text-danger">*</span></label>
                <input type="text" class="form-control" name="loanNm"
                       value="<c:out value='${loan.loanNm}'/>"
                       maxlength="200" required placeholder="예: 국민은행 주택담보대출">
              </div>

              <!-- 최초 대출금액 / 현재 잔액 -->
              <div class="col-12 col-md-6">
                <label class="form-label fw-semibold">최초 대출금액 (원) <span class="text-danger">*</span></label>
                <input type="text" class="form-control amount-input" name="loanAmountStr" id="loanAmountStr"
                       value="<fmt:formatNumber value='${loan.loanAmount}' pattern='#,##0'/>"
                       required placeholder="0" inputmode="numeric">
              </div>

              <div class="col-12 col-md-6">
                <label class="form-label fw-semibold">현재 잔액 (원) <span class="text-danger">*</span></label>
                <input type="text" class="form-control amount-input" name="currentBalanceStr" id="currentBalanceStr"
                       value="<fmt:formatNumber value='${loan.currentBalance}' pattern='#,##0'/>"
                       required placeholder="0" inputmode="numeric">
              </div>

              <!-- 금리 / 대출기간 -->
              <div class="col-12 col-md-4">
                <label class="form-label fw-semibold">금리 (%)</label>
                <input type="number" class="form-control" name="interestRateStr"
                       value="${loan.interestRate}"
                       step="0.01" min="0" max="99.99" placeholder="예: 3.50">
              </div>

              <div class="col-12 col-md-4">
                <label class="form-label fw-semibold">대출기간 (개월)</label>
                <input type="number" class="form-control" name="loanMonthsStr"
                       value="${loan.loanMonths}"
                       min="1" placeholder="예: 360">
              </div>

              <!-- 시작일 / 종료일 -->
              <div class="col-12 col-md-4">
                <label class="form-label fw-semibold">시작일</label>
                <input type="date" class="form-control" name="startYmd"
                       value="${loan.startYmd}">
              </div>

              <div class="col-12 col-md-4">
                <label class="form-label fw-semibold">종료(만기)일</label>
                <input type="date" class="form-control" name="endYmd"
                       value="${loan.endYmd}">
              </div>

              <!-- 메모 -->
              <div class="col-12">
                <label class="form-label fw-semibold">메모</label>
                <textarea class="form-control" name="memo" rows="3"
                          maxlength="1000" placeholder="참고 사항을 입력하세요."><c:out value="${loan.memo}"/></textarea>
              </div>

              <!-- 구분선 -->
              <div class="col-12"><hr class="my-1"></div>

              <!-- 종료 여부 -->
              <div class="col-12">
                <label class="form-label fw-semibold">종료 여부</label>
                <div class="d-flex gap-3">
                  <div class="form-check">
                    <input class="form-check-input" type="radio" name="closeYn"
                           id="closeN" value="N"
                           <c:if test="${loan.closeYn != 'Y'}">checked</c:if>
                           onchange="toggleClose(this.value)">
                    <label class="form-check-label" for="closeN">상환중</label>
                  </div>
                  <div class="form-check">
                    <input class="form-check-input" type="radio" name="closeYn"
                           id="closeY" value="Y"
                           <c:if test="${loan.closeYn == 'Y'}">checked</c:if>
                           onchange="toggleClose(this.value)">
                    <label class="form-check-label text-warning fw-semibold" for="closeY">완납/종료</label>
                  </div>
                </div>
              </div>

              <!-- 종료 상세 -->
              <div class="col-12" id="closeSection"
                   style="display:${loan.closeYn == 'Y' ? 'block' : 'none'};">
                <div class="row g-3 p-3 bg-warning-subtle rounded">
                  <div class="col-12 col-md-4">
                    <label class="form-label fw-semibold">종료일</label>
                    <input type="date" class="form-control" name="closeYmd"
                           value="${loan.closeYmd}">
                  </div>
                  <div class="col-12 col-md-8">
                    <label class="form-label fw-semibold">종료 사유</label>
                    <input type="text" class="form-control" name="closeReason"
                           value="<c:out value='${loan.closeReason}'/>"
                           maxlength="1000" placeholder="예: 완납, 대환대출, 계약 종료 등">
                  </div>
                </div>
              </div>

            </div><!-- /row -->

            <div class="d-flex justify-content-end gap-2 mt-4">
              <button type="button" class="btn btn-outline-secondary homes-pill px-3"
                      onclick="history.back();">취소</button>
              <button type="submit" class="btn btn-primary homes-pill px-3">저장</button>
            </div>
          </form>
        </div>
      </div>

    </div>
    <%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
  </main>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
  function toggleClose(val) {
    document.getElementById('closeSection').style.display = val === 'Y' ? 'block' : 'none';
  }

  // 금액 입력 포맷팅
  document.querySelectorAll('.amount-input').forEach(function (el) {
    el.addEventListener('input', function () {
      const raw = this.value.replace(/[^0-9]/g, '');
      if (raw === '') { this.value = ''; return; }
      this.value = Number(raw).toLocaleString('ko-KR');
    });
  });
</script>
</body>
</html>
