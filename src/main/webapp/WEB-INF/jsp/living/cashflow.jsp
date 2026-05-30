<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<!doctype html>
<html lang="ko">
<head>
  <%@ include file="/WEB-INF/jsp/common/head.jsp" %>
  <title>수기 현금흐름 | HOMES</title>
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
          <h1 class="h4 fw-bold mb-1">수기 현금흐름</h1>
          <div class="text-muted small">수지계정별 수입·지출을 직접 등록합니다.</div>
        </div>
        <div class="d-flex gap-2 align-items-center flex-wrap">
          <!-- 년월 이동 -->
          <form method="get" action="${pageContext.request.contextPath}/living/cashflow"
                class="d-flex gap-1 align-items-center">
            <input type="month" class="form-control form-control-sm" name="yymm" style="width:150px;"
                   value="${yymm.substring(0,4)}-${yymm.substring(4,6)}"
                   onchange="this.value=this.value.replace('-',''); this.form.submit();">
            <button class="btn btn-sm btn-outline-secondary homes-pill px-3">이동</button>
          </form>
          <button class="btn btn-primary homes-pill px-3" onclick="openModal(null)">+ 등록</button>
        </div>
      </div>

      <!-- 요약 카드 -->
      <div class="row g-3 mb-4">
        <div class="col-6 col-md-3">
          <div class="card homes-card h-100">
            <div class="card-body">
              <div class="text-muted small mb-1">${dispYymm}</div>
              <div class="fw-bold" style="font-size:13px; color:#64748b;">조회 기준</div>
            </div>
          </div>
        </div>
        <div class="col-6 col-md-3">
          <div class="card homes-card h-100">
            <div class="card-body">
              <div class="text-muted small mb-1">수입 합계</div>
              <div class="fw-bold fs-5 text-success">
                <fmt:formatNumber value="${incomeTotal}" pattern="#,##0"/> 원
              </div>
            </div>
          </div>
        </div>
        <div class="col-6 col-md-3">
          <div class="card homes-card h-100">
            <div class="card-body">
              <div class="text-muted small mb-1">지출 합계</div>
              <div class="fw-bold fs-5 text-danger">
                <fmt:formatNumber value="${expenseTotal}" pattern="#,##0"/> 원
              </div>
            </div>
          </div>
        </div>
        <div class="col-6 col-md-3">
          <div class="card homes-card h-100">
            <div class="card-body">
              <div class="text-muted small mb-1">순손익</div>
              <div class="fw-bold fs-5 ${netBalance >= 0 ? 'text-success' : 'text-danger'}">
                ${netBalance >= 0 ? '+' : ''}<fmt:formatNumber value="${netBalance}" pattern="#,##0"/> 원
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 목록 -->
      <div class="card homes-card">
        <div class="card-body p-0">
          <div class="table-responsive">
            <table class="table align-middle homes-table mb-0">
              <thead class="table-light">
                <tr>
                  <th style="width:80px;">구분</th>
                  <th style="width:140px;" class="text-nowrap">수지계정</th>
                  <th>제목</th>
                  <th class="text-end" style="width:150px;">금액</th>
                  <th style="width:90px;" class="text-nowrap">등록일</th>
                  <th style="width:80px;" class="text-center">관리</th>
                </tr>
              </thead>
              <tbody>
                <c:choose>
                  <c:when test="${empty cashflowList}">
                    <tr>
                      <td colspan="6" class="text-center text-muted py-5 fst-italic">
                        등록된 내역이 없습니다. [+ 등록] 버튼을 눌러 추가하세요.
                      </td>
                    </tr>
                  </c:when>
                  <c:otherwise>
                    <c:set var="prevType" value=""/>
                    <c:forEach var="cf" items="${cashflowList}">
                      <!-- 구분 헤더 행 -->
                      <c:if test="${cf.flowType != prevType}">
                        <tr class="table-secondary">
                          <td colspan="6" class="fw-semibold" style="font-size:13px;">
                            <c:choose>
                              <c:when test="${cf.flowType == 'INCOME'}">💰 수입</c:when>
                              <c:otherwise>💸 지출</c:otherwise>
                            </c:choose>
                          </td>
                        </tr>
                        <c:set var="prevType" value="${cf.flowType}"/>
                      </c:if>
                      <tr>
                        <td>
                          <span class="badge ${cf.flowType == 'INCOME' ? 'bg-success' : 'bg-danger'}">
                            ${cf.flowType == 'INCOME' ? '수입' : '지출'}
                          </span>
                        </td>
                        <td class="fw-semibold text-nowrap"><c:out value="${cf.ccNm}"/></td>
                        <td>
                          <c:choose>
                            <c:when test="${not empty cf.title}">
                              <span class="fw-semibold"><c:out value="${cf.title}"/></span>
                              <c:if test="${not empty cf.memo}">
                                <div class="text-muted small text-truncate" style="max-width:260px;"><c:out value="${cf.memo}"/></div>
                              </c:if>
                            </c:when>
                            <c:otherwise>
                              <span class="text-muted small"><c:out value="${cf.memo}"/></span>
                            </c:otherwise>
                          </c:choose>
                        </td>
                        <td class="text-end fw-semibold text-nowrap ${cf.flowType == 'INCOME' ? 'text-success' : 'text-danger'}">
                          <fmt:formatNumber value="${cf.actualAmt}" pattern="#,##0"/> 원
                        </td>
                        <td class="text-muted small text-nowrap">${cf.regDtStr}</td>
                        <td class="text-center text-nowrap">
                          <button class="btn btn-sm btn-link p-0 text-muted me-1"
                                  onclick="openModal(${cf.cfSeq}, ${cf.ccSeq}, '${cf.flowType}', ${cf.actualAmt}, '<c:out value="${cf.title}"/>', '<c:out value="${cf.memo}"/>')"
                                  title="수정">✏️</button>
                          <button class="btn btn-sm btn-link p-0 text-danger"
                                  onclick="deleteCf(${cf.cfSeq})"
                                  title="삭제">🗑</button>
                        </td>
                      </tr>
                    </c:forEach>
                    <!-- 합계 -->
                    <tr class="table-light fw-bold">
                      <td colspan="3" class="text-end">수입 합계</td>
                      <td class="text-end text-success">
                        <fmt:formatNumber value="${incomeTotal}" pattern="#,##0"/> 원
                      </td>
                      <td colspan="2"></td>
                    </tr>
                    <tr class="table-light fw-bold">
                      <td colspan="3" class="text-end">지출 합계</td>
                      <td class="text-end text-danger">
                        <fmt:formatNumber value="${expenseTotal}" pattern="#,##0"/> 원
                      </td>
                      <td colspan="2"></td>
                    </tr>
                    <tr class="fw-bold" style="background:#f0fdf4; border-top:2px solid #bbf7d0;">
                      <td colspan="3" class="text-end">순손익</td>
                      <td class="text-end fs-6 ${netBalance >= 0 ? 'text-success' : 'text-danger'}">
                        ${netBalance >= 0 ? '+' : ''}<fmt:formatNumber value="${netBalance}" pattern="#,##0"/> 원
                      </td>
                      <td colspan="2"></td>
                    </tr>
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

<!-- 등록/수정 모달 -->
<div class="modal fade" id="cfModal" tabindex="-1">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="cfModalTitle">수기 현금흐름 등록</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <input type="hidden" id="cfSeq"/>
        <!-- 구분 (수입/지출) -->
        <div class="mb-3">
          <label class="form-label fw-semibold">구분 <span class="text-danger">*</span></label>
          <div class="d-flex gap-3">
            <div class="form-check">
              <input class="form-check-input" type="radio" name="cfFlowType" id="ftIncome"
                     value="INCOME" checked onchange="onFlowTypeChange()">
              <label class="form-check-label text-success fw-semibold" for="ftIncome">💰 수입</label>
            </div>
            <div class="form-check">
              <input class="form-check-input" type="radio" name="cfFlowType" id="ftExpense"
                     value="EXPENSE" onchange="onFlowTypeChange()">
              <label class="form-check-label text-danger fw-semibold" for="ftExpense">💸 지출</label>
            </div>
          </div>
        </div>
        <!-- 수지계정 -->
        <div class="mb-3">
          <label class="form-label fw-semibold">수지계정 <span class="text-danger">*</span></label>
          <select class="form-select" id="cfCcSeq" onchange="onCcChange(this)">
            <option value="">-- 선택 --</option>
            <c:forEach var="cc" items="${costCenterList}">
              <option value="${cc.ccSeq}" data-monthly="${cc.monthlyAmt}">${cc.ccNm}</option>
            </c:forEach>
          </select>
        </div>
        <!-- 제목 -->
        <div class="mb-3">
          <label class="form-label fw-semibold">제목 <span class="text-danger">*</span></label>
          <input type="text" class="form-control" id="cfTitle" placeholder="예: 5월 월급, 카드값 납부" maxlength="200" required/>
        </div>
        <!-- 금액 -->
        <div class="mb-3">
          <label class="form-label fw-semibold" id="amtLabel">금액</label>
          <div class="input-group">
            <span class="input-group-text">₩</span>
            <input type="text" class="form-control text-end" id="cfAmt" placeholder="0"
                   oninput="fmtAmt(this)"/>
            <span class="input-group-text">원</span>
          </div>
          <div class="form-text">수지계정 선택 시 월 금액이 자동입력됩니다.</div>
        </div>
        <!-- 메모 -->
        <div class="mb-2">
          <label class="form-label fw-semibold">메모</label>
          <input type="text" class="form-control" id="cfMemo" placeholder="메모 (선택)" maxlength="500"/>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">취소</button>
        <button type="button" class="btn btn-primary" id="cfSaveBtn" onclick="saveCf()">저장</button>
      </div>
    </div>
  </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
const ctx   = '${pageContext.request.contextPath}';
const yymm  = '${yymm}';
const modal = new bootstrap.Modal(document.getElementById('cfModal'));

function fmtAmt(el) {
  const raw = el.value.replace(/[^0-9]/g, '');
  el.value  = raw ? Number(raw).toLocaleString('ko-KR') : '';
}
function parseAmt(s) {
  return parseInt((s||'').replace(/[^0-9]/g,'') || '0', 10);
}

function onFlowTypeChange() {
  const isIncome = document.getElementById('ftIncome').checked;
  document.getElementById('amtLabel').textContent    = isIncome ? '수입 금액' : '지출 금액';
  document.getElementById('cfSaveBtn').className     = 'btn ' + (isIncome ? 'btn-success' : 'btn-danger');
}

function onCcChange(sel) {
  const monthly = sel.options[sel.selectedIndex]?.dataset?.monthly;
  if (monthly && Number(monthly) > 0) {
    document.getElementById('cfAmt').value = Number(monthly).toLocaleString('ko-KR');
  }
}

function openModal(seq, ccSeq, flowType, amt, title, memo) {
  document.getElementById('cfSeq').value   = seq   || '';
  document.getElementById('cfCcSeq').value = ccSeq || '';
  document.getElementById('cfAmt').value   = amt ? Number(amt).toLocaleString('ko-KR') : '';
  document.getElementById('cfTitle').value = title || '';
  document.getElementById('cfMemo').value  = memo  || '';

  const isIncome = !flowType || flowType === 'INCOME';
  document.getElementById('ftIncome').checked  = isIncome;
  document.getElementById('ftExpense').checked = !isIncome;
  onFlowTypeChange();

  document.getElementById('cfModalTitle').textContent = seq ? '수기 현금흐름 수정' : '수기 현금흐름 등록';
  modal.show();
  setTimeout(() => document.getElementById('cfTitle').focus(), 300);
}

function saveCf() {
  const ccSeq  = document.getElementById('cfCcSeq').value;
  const title  = document.getElementById('cfTitle').value.trim();
  const amt    = parseAmt(document.getElementById('cfAmt').value);
  if (!ccSeq)  { alert('수지계정을 선택하세요.'); return; }
  if (!title)  { alert('제목을 입력하세요.'); return; }
  const flowType = document.querySelector('input[name="cfFlowType"]:checked').value;
  const payload  = {
    cfSeq:     document.getElementById('cfSeq').value || null,
    ccSeq:     ccSeq,
    title:     title,
    flowType:  flowType,
    flowYymm:  yymm,
    actualAmt: amt,
    memo:      document.getElementById('cfMemo').value.trim()
  };
  fetch(ctx + '/living/cashflow/save', {
    method: 'POST', headers: {'Content-Type': 'application/json'},
    body: JSON.stringify(payload)
  }).then(r => r.json()).then(res => {
    if (res.success) { modal.hide(); location.reload(); }
    else alert('저장 실패: ' + (res.message || ''));
  });
}

function deleteCf(seq) {
  if (!confirm('삭제하시겠습니까?')) return;
  fetch(ctx + '/living/cashflow/delete', {
    method: 'POST', headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({cfSeq: seq})
  }).then(r => r.json()).then(res => {
    if (res.success) location.reload();
    else alert('실패: ' + (res.message || ''));
  });
}

// 년월 input 값 YYYYMM 형식으로 변환 후 제출
document.querySelector('input[name="yymm"]').addEventListener('change', function() {
  this.value = this.value.replace('-', '');
});
</script>
</body>
</html>
