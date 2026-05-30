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
              <c:when test="${empty plan.planSeq}">정기지출 등록</c:when>
              <c:otherwise>정기지출 수정</c:otherwise>
            </c:choose>
          </h1>
          <div class="text-muted small">반복 지출 항목을 입력합니다.</div>
        </div>
        <a class="btn btn-outline-secondary homes-pill px-3"
           href="${pageContext.request.contextPath}/asset/expense">목록</a>
      </div>

      <div class="card homes-card">
        <div class="card-body px-3 px-md-4 py-4">
          <form method="post" action="${pageContext.request.contextPath}/asset/expense/save">
            <input type="hidden" name="planSeq" value="${plan.planSeq}">
            <input type="hidden" name="livingTotalLinkYn" id="livingTotalLinkYn" value="${not empty plan.livingTotalLinkYn ? plan.livingTotalLinkYn : 'N'}">

            <div class="row g-3">

              <!-- 지출명 -->
              <div class="col-12 col-md-8">
                <label class="form-label fw-semibold">지출명 <span class="text-danger">*</span></label>
                <input type="text" class="form-control" name="planNm"
                       value="<c:out value='${plan.planNm}'/>"
                       maxlength="200" required placeholder="예: 국민은행 대출이자">
              </div>

              <!-- 지출 구분: 먼저 선택 → 유형 필터링 -->
              <div class="col-12 col-md-4">
                <label class="form-label fw-semibold">지출 구분 <span class="text-danger">*</span></label>
                <select class="form-select" name="flowType" id="flowTypeSelect"
                        onchange="onFlowTypeChange(this.value)" required>
                  <option value="EXPENSE" ${plan.flowType != 'SAVING' and plan.flowType != 'INVEST' ? 'selected' : ''}>지출 (소비/지급)</option>
                  <option value="SAVING"  ${plan.flowType == 'SAVING'  ? 'selected' : ''}>저축 (적금/예금)</option>
                  <option value="INVEST"  ${plan.flowType == 'INVEST'  ? 'selected' : ''}>투자 (주식/펀드 등)</option>
                </select>
              </div>

              <!-- 지출 유형: 구분에 맞는 항목만 표시 -->
              <div class="col-12 col-md-4">
                <label class="form-label fw-semibold">지출 유형 <span class="text-danger">*</span></label>
                <select class="form-select" name="planType" id="planTypeSelect" required>
                  <option value="">선택</option>
                  <c:forEach var="t" items="${typeList}">
                    <option value="${t.planType}"
                            data-flow-type="${t.flowType}"
                            <c:if test="${t.planType == plan.planType}">selected</c:if>>
                      <c:out value="${t.planTypeNm}"/>
                    </option>
                  </c:forEach>
                </select>
              </div>

              <!-- 대출 선택 (대출 유형 선택 시 표시) -->
              <div class="col-12 col-md-8" id="loanSelectWrap" style="display:none;">
                <label class="form-label fw-semibold">대출 <span class="text-danger">*</span></label>
                <select class="form-select" name="loanSeq" id="loanSeqSelect">
                  <option value="">대출 선택</option>
                  <c:forEach var="loan" items="${loanList}">
                    <option value="${loan.loanSeq}"
                      <c:if test="${plan.loanSeq == loan.loanSeq}">selected</c:if>>
                      <c:out value="${loan.loanNm}"/>
                      (<fmt:formatNumber value="${loan.currentBalance}" pattern="#,##0"/>원 잔액)
                    </option>
                  </c:forEach>
                </select>
              </div>

              <!-- 생활비 기준정보 불러오기 -->
              <c:if test="${not empty livingCatList}">
              <div class="col-12 col-md-8">
                <div class="d-flex align-items-center justify-content-between mb-1">
                  <label class="form-label fw-semibold mb-0">생활비 기준정보에서 불러오기 <span class="text-muted small">(선택)</span></label>
                  <div class="form-check mb-0 ms-3">
                    <input class="form-check-input" type="checkbox" id="allLivingChk"
                           onchange="onAllLivingChange(this)">
                    <label class="form-check-label small fw-semibold text-primary" for="allLivingChk">
                      생활비 연동
                    </label>
                  </div>
                </div>
                <select class="form-select" id="livingItemSelect" onchange="onLivingItemChange(this)">
                  <option value="">-- 생활비 항목 선택 시 금액 자동입력 --</option>
                  <c:forEach var="cat" items="${livingCatList}">
                    <c:if test="${not empty cat.items}">
                      <optgroup label="${cat.catNm}">
                        <c:forEach var="item" items="${cat.items}">
                          <option value="${item.budgetAmt}" data-nm="${item.itemNm}">
                            ${item.itemNm} — <fmt:formatNumber value="${item.budgetAmt}" pattern="#,##0"/>원
                          </option>
                        </c:forEach>
                      </optgroup>
                    </c:if>
                  </c:forEach>
                </select>
                <div class="form-text" id="livingHint">선택하면 지출명·금액이 자동으로 채워집니다. 직접 수정도 가능합니다.</div>
              </div>
              </c:if>

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
                    <option value="MONTH" ${plan.cycleUnit == 'YEAR' ? '' : 'selected'} ${plan.cycleUnit == 'MONTH' ? 'selected' : ''}>개월</option>
                    <option value="YEAR"  ${plan.cycleUnit == 'YEAR'  ? 'selected' : ''}>년</option>
                  </select>
                  <span id="baseMonthWrap" style="display:none;" class="d-flex align-items-center gap-1">
                    <input type="number" class="form-control" name="cycleBaseMonth" id="cycleBaseMonth"
                           value="${plan.cycleBaseMonth}" min="1" max="12" style="width:70px;" placeholder="월">
                    <span class="text-muted">월</span>
                  </span>
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
                           onchange="document.getElementById('useYnHidden').value = this.checked ? 'Y' : 'N';
                                     document.getElementById('useYnLabel').textContent = this.checked ? 'ON (사용중)' : 'OFF (중지)';"
                           ${plan.useYn != 'N' ? 'checked' : ''}>
                    <label class="form-check-label" for="useYnCheck" id="useYnLabel">
                      ${plan.useYn != 'N' ? 'ON (사용중)' : 'OFF (중지)'}
                    </label>
                  </div>
                  <input type="hidden" name="useYn" id="useYnHidden" value="${plan.useYn != 'N' ? 'Y' : 'N'}">
                </div>
              </div>

              <!-- ── 수지계정 ── -->
              <div class="col-12">
                <label class="form-label fw-semibold">수지계정</label>
                <div class="form-text mb-2">
                  이 지출이 어느 수지계정에서 나가는지 지정합니다.
                  <a href="${pageContext.request.contextPath}/asset/costcenter" target="_blank"
                     class="text-primary">수지계정 관리 →</a>
                </div>
                <input type="hidden" name="costCenterType" value="CC"/>
                <select class="form-select" name="costCenterSeq" id="costCenterSeq" style="max-width:400px;">
                  <option value="">-- 선택 안함 --</option>
                  <c:forEach var="cc" items="${costCenterList}">
                    <option value="${cc.ccSeq}"
                      <c:if test="${plan.costCenterType == 'CC' and plan.costCenterSeq == cc.ccSeq}">selected</c:if>>
                      <c:out value="${cc.ccNm}"/>
                      (<fmt:formatNumber value="${cc.monthlyAmt}" pattern="#,##0"/>원)
                      <c:if test="${cc.ccType == 'AUTO'}"> [자동]</c:if>
                    </option>
                  </c:forEach>
                </select>
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
  document.getElementById('amountStr').addEventListener('input', function () {
    const raw = this.value.replace(/[^0-9]/g, '');
    this.value = raw ? Number(raw).toLocaleString('ko-KR') : '';
  });

  function onLivingItemChange(sel) {
    const opt = sel.options[sel.selectedIndex];
    if (!opt.value) return;
    const amt = Number(opt.value);
    const nm  = opt.dataset.nm || '';
    if (amt > 0) {
      document.getElementById('amountStr').value = amt.toLocaleString('ko-KR');
    }
    const planNmEl = document.querySelector('input[name="planNm"]');
    if (planNmEl && !planNmEl.value) {
      planNmEl.value = nm;
    }
  }

  function onAllLivingChange(chk) {
    const sel     = document.getElementById('livingItemSelect');
    const hint    = document.getElementById('livingHint');
    const amtEl   = document.getElementById('amountStr');
    const planNmEl = document.querySelector('input[name="planNm"]');

    document.getElementById('livingTotalLinkYn').value = chk.checked ? 'Y' : 'N';

    if (chk.checked) {
      // 드롭다운 비활성화
      sel.disabled = true;
      sel.value    = '';

      // 모든 option의 value 합산 (optgroup header 제외)
      let total = 0;
      Array.from(sel.options).forEach(opt => {
        const v = Number(opt.value);
        if (v > 0) total += v;
      });

      amtEl.value = total.toLocaleString('ko-KR');
      if (planNmEl && !planNmEl.value) {
        planNmEl.value = '생활비 전체';
      }
      hint.textContent = '생활비 전체 합계 금액이 입력되었습니다. 지출명은 직접 수정 가능합니다.';
      hint.style.color = '#0d6efd';
    } else {
      sel.disabled = false;
      amtEl.value  = '';
      hint.textContent = '선택하면 지출명·금액이 자동으로 채워집니다. 직접 수정도 가능합니다.';
      hint.style.color = '';
    }
  }

  // ── 대출 유형 선택 시 대출 필수 선택 표시 ─────────────────
  function onPlanTypeChange(planType) {
    const wrap    = document.getElementById('loanSelectWrap');
    const loanSel = document.getElementById('loanSeqSelect');
    const isLoan  = planType && planType.indexOf('LOAN') !== -1;
    wrap.style.display = isLoan ? '' : 'none';
    loanSel.required   = isLoan;
    if (!isLoan) loanSel.value = '';
  }

  document.getElementById('planTypeSelect').addEventListener('change', function () {
    onPlanTypeChange(this.value);
  });

  // ── 지출 구분 → 유형 필터링 ────────────────────────────
  function onFlowTypeChange(flowType) {
    const planTypeSel    = document.getElementById('planTypeSelect');
    const currentPlanType = planTypeSel.value;
    let   firstMatch     = '';

    Array.from(planTypeSel.options).forEach(opt => {
      if (!opt.value) return; // "선택" 옵션은 항상 표시
      const match = opt.dataset.flowType === flowType;
      opt.style.display = match ? '' : 'none';
      opt.disabled      = !match;
      if (match && !firstMatch) firstMatch = opt.value;
    });

    // 현재 선택된 유형이 새 구분과 안 맞으면 초기화
    const currentOpt = planTypeSel.options[planTypeSel.selectedIndex];
    if (currentOpt && currentOpt.value && currentOpt.dataset.flowType !== flowType) {
      planTypeSel.value = '';
      onPlanTypeChange('');
    }
  }

  // 초기화: 페이지 로드 시 현재 flowType에 맞게 유형 필터 적용
  (function initFlowType() {
    const flowType = document.getElementById('flowTypeSelect').value;
    onFlowTypeChange(flowType);
  })();

  // 페이지 로드 시 초기화
  (function initLoanSelect() {
    onPlanTypeChange(document.getElementById('planTypeSelect').value);
  })();

  // 수정 시 생활비 전체 체크박스 상태 복원
  (function initAllLivingChk() {
    const chk = document.getElementById('allLivingChk');
    if (!chk) return;
    if (document.getElementById('livingTotalLinkYn').value === 'Y') {
      chk.checked = true;
      onAllLivingChange(chk);
    }
  })();

  // 수지계정: 단순 select로 변경되어 별도 JS 불필요

  function updateCycleFields() {
    const unit      = document.getElementById('cycleUnit').value;
    const num       = document.getElementById('cycleNum').value;
    const baseDay   = document.getElementById('cycleBaseDay').value;
    const baseMonth = document.getElementById('cycleBaseMonth').value;

    document.getElementById('baseMonthWrap').style.display = unit === 'YEAR'  ? '' : 'none';
    document.getElementById('baseDayWrap').style.display   = unit !== 'DAY'   ? '' : 'none';

    const unitTxt = unit === 'DAY' ? '일' : unit === 'MONTH' ? '개월' : '년';
    let preview = '매 ' + num + unitTxt;
    if (unit === 'YEAR' && baseMonth) preview += ' ' + baseMonth + '월';
    if (unit !== 'DAY'  && baseDay)   preview += ' ' + baseDay   + '일';
    document.getElementById('cyclePreview').textContent = '미리보기: ' + preview;
  }

  ['cycleNum','cycleUnit','cycleBaseDay','cycleBaseMonth'].forEach(function(id) {
    const el = document.getElementById(id);
    if (el) el.addEventListener('input', updateCycleFields);
    if (el) el.addEventListener('change', updateCycleFields);
  });

  updateCycleFields();
</script>
</body>
</html>
