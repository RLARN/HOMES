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

      <div class="d-flex flex-column flex-md-row align-items-md-center justify-content-between gap-2 mb-3">
        <div>
          <div class="homes-badge mb-2">Asset</div>
          <h1 class="h4 fw-bold mb-1">
            <c:choose>
              <c:when test="${empty plan.planSeq}">정기수입 등록</c:when>
              <c:otherwise>정기수입 수정</c:otherwise>
            </c:choose>
          </h1>
          <div class="text-muted small">반복 수입 항목을 입력합니다.</div>
        </div>
        <a class="btn btn-outline-secondary homes-pill px-3"
           href="${pageContext.request.contextPath}/asset/income">목록</a>
      </div>

      <div class="card homes-card">
        <div class="card-body px-3 px-md-4 py-4">
          <form method="post" action="${pageContext.request.contextPath}/asset/income/save">
            <input type="hidden" name="planSeq" value="${plan.planSeq}">
            <input type="hidden" name="flowType" value="INCOME">

            <div class="row g-3">

              <!-- 수입명 -->
              <div class="col-12 col-md-8">
                <label class="form-label fw-semibold">수입명 <span class="text-danger">*</span></label>
                <input type="text" class="form-control" name="planNm"
                       value="<c:out value='${plan.planNm}'/>"
                       maxlength="200" required placeholder="예: 이현정 월급">
              </div>

              <!-- 유형 -->
              <div class="col-12 col-md-4">
                <label class="form-label fw-semibold">수입 유형 <span class="text-danger">*</span></label>
                <select class="form-select" name="planType" required>
                  <option value="">선택</option>
                  <c:forEach var="t" items="${typeList}">
                    <option value="${t.planType}"
                      <c:if test="${t.planType == plan.planType}">selected</c:if>>
                      <c:out value="${t.planTypeNm}"/>
                    </option>
                  </c:forEach>
                </select>
              </div>

              <!-- 금액 -->
              <div class="col-12 col-md-4">
                <label class="form-label fw-semibold">금액 (원) <span class="text-danger">*</span></label>
                <input type="text" class="form-control amount-input" name="amountStr" id="amountStr"
                       value="<fmt:formatNumber value='${plan.amount}' pattern='#,##0'/>"
                       required placeholder="0" inputmode="numeric">
              </div>

              <!-- 사이클 -->
              <div class="col-12">
                <label class="form-label fw-semibold">반복 사이클 <span class="text-danger">*</span></label>
                <div class="d-flex align-items-center gap-2 flex-wrap">
                  <span class="text-muted">매</span>
                  <input type="number" class="form-control" name="cycleNum" id="cycleNum"
                         value="${not empty plan.cycleNum ? plan.cycleNum : 1}"
                         min="1" max="999" required style="width:80px;">
                  <select class="form-select" name="cycleUnit" id="cycleUnit"
                          style="width:100px;" onchange="updateCycleFields()">
                    <option value="DAY"   ${plan.cycleUnit == 'DAY'   ? 'selected' : ''}>일</option>
                    <option value="MONTH" ${plan.cycleUnit != 'DAY' and plan.cycleUnit != 'YEAR' ? 'selected' : ''} ${plan.cycleUnit == 'MONTH' ? 'selected' : ''}>개월</option>
                    <option value="YEAR"  ${plan.cycleUnit == 'YEAR'  ? 'selected' : ''}>년</option>
                  </select>
                  <!-- 기준월 (YEAR 단위만) -->
                  <span id="baseMonthWrap" style="display:none;" class="d-flex align-items-center gap-1">
                    <input type="number" class="form-control" name="cycleBaseMonth" id="cycleBaseMonth"
                           value="${plan.cycleBaseMonth}" min="1" max="12" style="width:70px;" placeholder="월">
                    <span class="text-muted">월</span>
                  </span>
                  <!-- 기준일 (MONTH/YEAR 단위) -->
                  <span id="baseDayWrap" style="display:none;" class="d-flex align-items-center gap-1">
                    <input type="number" class="form-control" name="cycleBaseDay" id="cycleBaseDay"
                           value="${plan.cycleBaseDay}" min="1" max="31" style="width:70px;" placeholder="일">
                    <span class="text-muted">일</span>
                  </span>
                </div>
                <div class="form-text" id="cyclePreview">사이클을 선택하면 미리보기가 표시됩니다.</div>
              </div>

              <!-- 시작일 / 종료일 -->
              <div class="col-12 col-md-4">
                <label class="form-label fw-semibold">시작일</label>
                <input type="date" class="form-control" name="startYmd" value="${plan.startYmd}">
              </div>
              <div class="col-12 col-md-4">
                <label class="form-label fw-semibold">종료일</label>
                <input type="date" class="form-control" name="endYmd" value="${plan.endYmd}">
              </div>

              <!-- 사용여부 -->
              <div class="col-12 col-md-4">
                <label class="form-label fw-semibold">사용여부</label>
                <div class="d-flex align-items-center gap-3 mt-1">
                  <div class="form-check form-switch">
                    <input class="form-check-input" type="checkbox" id="useYnCheck"
                           onchange="document.getElementById('useYnHidden').value = this.checked ? 'Y' : 'N';"
                           ${plan.useYn != 'N' ? 'checked' : ''}>
                    <label class="form-check-label" for="useYnCheck" id="useYnLabel">
                      ${plan.useYn != 'N' ? 'ON (사용중)' : 'OFF (중지)'}
                    </label>
                  </div>
                  <input type="hidden" name="useYn" id="useYnHidden" value="${plan.useYn != 'N' ? 'Y' : 'N'}">
                </div>
              </div>

              <!-- 메모 -->
              <div class="col-12">
                <label class="form-label fw-semibold">메모</label>
                <textarea class="form-control" name="memo" rows="2"
                          maxlength="1000"><c:out value="${plan.memo}"/></textarea>
              </div>

            </div>

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
  // 금액 포맷팅
  document.getElementById('amountStr').addEventListener('input', function () {
    const raw = this.value.replace(/[^0-9]/g, '');
    this.value = raw ? Number(raw).toLocaleString('ko-KR') : '';
  });

  // 사용여부 라벨 업데이트
  document.getElementById('useYnCheck').addEventListener('change', function () {
    document.getElementById('useYnLabel').textContent = this.checked ? 'ON (사용중)' : 'OFF (중지)';
  });

  // 사이클 필드 표시/미리보기
  function updateCycleFields() {
    const unit      = document.getElementById('cycleUnit').value;
    const num       = document.getElementById('cycleNum').value;
    const baseDay   = document.getElementById('cycleBaseDay').value;
    const baseMonth = document.getElementById('cycleBaseMonth').value;

    document.getElementById('baseMonthWrap').style.display = unit === 'YEAR'  ? '' : 'none';
    document.getElementById('baseDayWrap').style.display   = unit !== 'DAY'   ? '' : 'none';

    const unitTxt  = unit === 'DAY' ? '일' : unit === 'MONTH' ? '개월' : '년';
    let preview = '매 ' + num + unitTxt;
    if (unit === 'YEAR' && baseMonth) preview += ' ' + baseMonth + '월';
    if (unit !== 'DAY'  && baseDay)   preview += ' ' + baseDay   + '일';
    document.getElementById('cyclePreview').textContent = '미리보기: ' + preview;
  }

  // 기준일/월 변경 시도 미리보기 갱신
  ['cycleNum','cycleUnit','cycleBaseDay','cycleBaseMonth'].forEach(function(id) {
    const el = document.getElementById(id);
    if (el) el.addEventListener('input', updateCycleFields);
    if (el) el.addEventListener('change', updateCycleFields);
  });

  // 초기화
  updateCycleFields();
</script>
</body>
</html>
