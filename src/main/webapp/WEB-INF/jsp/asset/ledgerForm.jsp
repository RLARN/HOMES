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
              <c:when test="${empty asset.assetSeq}">자산 등록</c:when>
              <c:otherwise>자산 수정</c:otherwise>
            </c:choose>
          </h1>
          <div class="text-muted small">자산 정보를 입력하고 저장합니다.</div>
        </div>
        <a class="btn btn-outline-secondary homes-pill px-3"
           href="${pageContext.request.contextPath}/asset/ledger">목록</a>
      </div>

      <!-- 폼 카드 -->
      <div class="card homes-card">
        <div class="card-body px-3 px-md-4 py-4">
          <form id="assetForm" method="post"
                action="${pageContext.request.contextPath}/asset/ledger/save">
            <input type="hidden" name="assetSeq" value="${asset.assetSeq}">

            <div class="row g-3">

              <!-- 자산명 -->
              <div class="col-12">
                <label class="form-label fw-semibold">자산명 <span class="text-danger">*</span></label>
                <input type="text" class="form-control" name="assetNm"
                       value="<c:out value='${asset.assetNm}'/>"
                       maxlength="200" required placeholder="예: KB 주택청약종합저축">
              </div>

              <!-- 자산형태 / 유동성 -->
              <div class="col-12 col-md-6">
                <label class="form-label fw-semibold">자산형태 <span class="text-danger">*</span></label>
                <select class="form-select" name="assetType" required>
                  <option value="">선택하세요</option>
                  <c:forEach var="t" items="${typeList}">
                    <option value="${t.assetType}"
                      <c:if test="${t.assetType == asset.assetType}">selected</c:if>>
                      <c:out value="${t.assetTypeNm}"/>
                    </option>
                  </c:forEach>
                </select>
              </div>

              <div class="col-12 col-md-6">
                <label class="form-label fw-semibold">유동성 여부 <span class="text-danger">*</span></label>
                <select class="form-select" name="liquidYn" required>
                  <option value="Y" <c:if test="${asset.liquidYn != 'N'}">selected</c:if>>유동 (현금화 용이)</option>
                  <option value="N" <c:if test="${asset.liquidYn == 'N'}">selected</c:if>>비유동 (묶여 있음)</option>
                </select>
              </div>

              <!-- 수지계정 등록 (유동자산 선택 시 표시) -->
              <div class="col-12" id="ccRegisterWrap"
                   style="display:${asset.liquidYn != 'N' ? 'block' : 'none'};">
                <div class="p-3 rounded border border-primary-subtle bg-primary-subtle d-flex align-items-start gap-3">
                  <div class="form-check form-switch mt-1">
                    <input class="form-check-input" type="checkbox"
                           name="registerAsCostCenter" id="registerAsCostCenter"
                           value="Y"
                           ${not empty linkedCc ? 'checked' : ''}>
                  </div>
                  <div>
                    <label class="form-check-label fw-semibold" for="registerAsCostCenter">
                      수지계정로 등록
                    </label>
                    <div class="text-muted small mt-1">
                      체크하면 이 유동자산을 수지계정로 등록하여 정기지출의 재원으로 연결할 수 있습니다.
                      <c:if test="${not empty linkedCc}">
                        <span class="badge bg-success ms-1">현재 등록됨</span>
                      </c:if>
                    </div>
                  </div>
                </div>
              </div>

              <!-- 금액 -->
              <div class="col-12 col-md-6">
                <label class="form-label fw-semibold">금액 (원) <span class="text-danger">*</span></label>
                <input type="text" class="form-control" name="amountStr" id="amountStr"
                       value="<fmt:formatNumber value='${asset.amount}' pattern='#,##0'/>"
                       required placeholder="0"
                       inputmode="numeric">
                <div class="form-text">콤마 포함 입력 가능합니다. 예: 10,000,000</div>
              </div>

              <!-- 메모 -->
              <div class="col-12">
                <label class="form-label fw-semibold">메모</label>
                <textarea class="form-control" name="memo" rows="3"
                          maxlength="1000" placeholder="참고 사항을 입력하세요."><c:out value="${asset.memo}"/></textarea>
              </div>

              <!-- 구분선: 예상 증감률 -->
              <div class="col-12"><hr class="my-1"></div>

              <div class="col-12">
                <label class="form-label fw-semibold">예상 증감률 설정</label>
                <div class="text-muted small mb-2">
                  자산변동예상 계산에 반영됩니다. 양수(+)는 가치 상승, 음수(-)는 가치 하락.
                  <span class="text-primary">예: 부동산 +3% / 1년, 자동차 -15% / 1년</span>
                </div>
                <div class="row g-2 align-items-center p-3 bg-light rounded">
                  <!-- 증감률 -->
                  <div class="col-12 col-md-4">
                    <label class="form-label small fw-semibold mb-1">증감률 (%)</label>
                    <div class="input-group">
                      <input type="number" class="form-control" name="expectedRateStr"
                             id="expectedRateStr"
                             value="${asset.expectedRate}"
                             step="0.01" min="-100" max="999"
                             placeholder="예: 3.00 또는 -15.00">
                      <span class="input-group-text">%</span>
                    </div>
                    <div class="form-text">비워두면 예측에서 제외됩니다.</div>
                  </div>

                  <!-- 사이클 -->
                  <div class="col-12 col-md-8">
                    <label class="form-label small fw-semibold mb-1">증감 사이클</label>
                    <div class="d-flex align-items-center gap-2 flex-wrap">
                      <span class="text-muted small">매</span>
                      <input type="number" class="form-control" name="rateCycleNumStr" id="rateCycleNum"
                             value="${not empty asset.rateCycleNum ? asset.rateCycleNum : 1}"
                             min="1" max="99" style="width:70px;">
                      <select class="form-select" name="rateCycleUnit" id="rateCycleUnit"
                              style="width:100px;" onchange="updateRatePreview()">
                        <option value="YEAR"  ${empty asset.rateCycleUnit or asset.rateCycleUnit == 'YEAR'  ? 'selected' : ''}>년</option>
                        <option value="MONTH" ${asset.rateCycleUnit == 'MONTH' ? 'selected' : ''}>개월</option>
                      </select>
                      <span class="text-muted small">마다 위 비율만큼 변동</span>
                    </div>
                    <div class="form-text text-primary fw-semibold" id="ratePreview"></div>
                  </div>
                </div>
              </div>

              <!-- 구분선: 말소 -->
              <div class="col-12"><hr class="my-1"></div>

              <!-- 말소 여부 -->
              <div class="col-12">
                <label class="form-label fw-semibold">말소 여부</label>
                <div class="d-flex gap-3">
                  <div class="form-check">
                    <input class="form-check-input" type="radio" name="disposeYn"
                           id="disposeN" value="N"
                           <c:if test="${asset.disposeYn != 'Y'}">checked</c:if>
                           onchange="toggleDispose(this.value)">
                    <label class="form-check-label" for="disposeN">보유중</label>
                  </div>
                  <div class="form-check">
                    <input class="form-check-input" type="radio" name="disposeYn"
                           id="disposeY" value="Y"
                           <c:if test="${asset.disposeYn == 'Y'}">checked</c:if>
                           onchange="toggleDispose(this.value)">
                    <label class="form-check-label text-warning fw-semibold" for="disposeY">말소됨</label>
                  </div>
                </div>
              </div>

              <!-- 말소 상세 (말소 시 표시) -->
              <div class="col-12" id="disposeSection"
                   style="display:${asset.disposeYn == 'Y' ? 'block' : 'none'};">
                <div class="row g-3 p-3 bg-warning-subtle rounded">
                  <div class="col-12 col-md-4">
                    <label class="form-label fw-semibold">말소일</label>
                    <input type="date" class="form-control" name="disposeYmd"
                           value="${asset.disposeYmd}">
                  </div>
                  <div class="col-12 col-md-8">
                    <label class="form-label fw-semibold">말소 사유</label>
                    <input type="text" class="form-control" name="disposeReason"
                           value="<c:out value='${asset.disposeReason}'/>"
                           maxlength="1000" placeholder="예: 자동차 매각, 계약 종료 등">
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
  function toggleDispose(val) {
    document.getElementById('disposeSection').style.display = val === 'Y' ? 'block' : 'none';
  }

  // 유동성 여부 변경 → 수지계정 체크박스 표시/숨김
  (function () {
    const liquidSel = document.querySelector('select[name="liquidYn"]');
    const ccWrap    = document.getElementById('ccRegisterWrap');
    const ccChk     = document.getElementById('registerAsCostCenter');
    if (!liquidSel || !ccWrap) return;

    liquidSel.addEventListener('change', function () {
      const isLiquid = this.value === 'Y';
      ccWrap.style.display = isLiquid ? 'block' : 'none';
      if (!isLiquid) ccChk.checked = false; // 비유동이면 체크 해제
    });
  })();

  // 금액 입력 포맷팅
  (function () {
    const amtInput = document.getElementById('amountStr');
    if (!amtInput) return;
    amtInput.addEventListener('input', function () {
      const raw = this.value.replace(/[^0-9]/g, '');
      if (raw === '') { this.value = ''; return; }
      this.value = Number(raw).toLocaleString('ko-KR');
    });
  })();

  // 증감률 미리보기
  function updateRatePreview() {
    const rate      = parseFloat(document.getElementById('expectedRateStr').value);
    const num       = parseInt(document.getElementById('rateCycleNum').value) || 1;
    const unit      = document.getElementById('rateCycleUnit').value;
    const amtRaw    = document.getElementById('amountStr').value.replace(/[^0-9]/g, '');
    const preview   = document.getElementById('ratePreview');

    if (isNaN(rate) || !amtRaw) { preview.textContent = ''; return; }

    const amt      = parseInt(amtRaw);
    const unitTxt  = unit === 'YEAR' ? '년' : '개월';
    const perCycle = amt * rate / 100;
    const perMonth = unit === 'YEAR' ? perCycle / (12 * num) : perCycle / num;

    const sign = perMonth >= 0 ? '+' : '';
    preview.textContent = '미리보기: 매 ' + num + unitTxt + ' ' + (rate >= 0 ? '+' : '') + rate + '%'
      + ' → 월 ' + sign + Math.round(perMonth).toLocaleString('ko-KR') + '원 반영';
    preview.className = 'form-text fw-semibold ' + (perMonth >= 0 ? 'text-success' : 'text-danger');
  }

  ['expectedRateStr', 'rateCycleNum', 'rateCycleUnit', 'amountStr'].forEach(id => {
    const el = document.getElementById(id);
    if (el) { el.addEventListener('input', updateRatePreview); el.addEventListener('change', updateRatePreview); }
  });
  updateRatePreview();
</script>
</body>
</html>
