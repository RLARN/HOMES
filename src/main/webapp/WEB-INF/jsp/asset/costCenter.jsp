<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<!doctype html>
<html lang="ko">
<head>
  <%@ include file="/WEB-INF/jsp/common/head.jsp" %>
  <title>수지계정관리 | HOMES</title>
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
          <h1 class="h4 fw-bold mb-1">수지계정 관리</h1>
          <div class="text-muted small">지출이 어디서 나가는지 수지계정를 관리합니다.
            정기지출 등록 시 자동으로 생성됩니다.</div>
        </div>
        <button class="btn btn-primary homes-pill px-3" onclick="openModal(null)">+ 수동 등록</button>
      </div>

      <!-- 에러 메시지 -->
      <c:if test="${not empty error}">
        <div class="alert alert-danger alert-dismissible fade show" role="alert">
          <span class="material-symbols-rounded ms-sm">warning</span><strong>삭제 불가:</strong> ${error}
          <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
      </c:if>

      <!-- 요약 카드 -->
      <div class="row g-3 mb-4">
        <div class="col-6 col-md-3">
          <div class="card homes-card h-100">
            <div class="card-body">
              <div class="text-muted small mb-1">전체 수지계정</div>
              <div class="fw-bold fs-5">${ccList.size()} 건</div>
            </div>
          </div>
        </div>
        <div class="col-6 col-md-3">
          <div class="card homes-card h-100">
            <div class="card-body">
              <div class="text-muted small mb-1">활성 월 합계</div>
              <div class="fw-bold fs-5 text-primary">
                <fmt:formatNumber value="${totalAmt}" pattern="#,##0"/> 원
              </div>
            </div>
          </div>
        </div>
        <div class="col-6 col-md-3">
          <div class="card homes-card h-100">
            <div class="card-body">
              <div class="text-muted small mb-1">자동 생성 (정기지출)</div>
              <c:set var="autoCnt" value="0"/>
              <c:forEach var="cc" items="${ccList}">
                <c:if test="${cc.ccType == 'AUTO'}"><c:set var="autoCnt" value="${autoCnt+1}"/></c:if>
              </c:forEach>
              <div class="fw-bold fs-5 text-muted">${autoCnt} 건</div>
            </div>
          </div>
        </div>
        <div class="col-6 col-md-3">
          <div class="card homes-card h-100">
            <div class="card-body">
              <div class="text-muted small mb-1">수동 등록</div>
              <c:set var="manualCnt" value="0"/>
              <c:forEach var="cc" items="${ccList}">
                <c:if test="${cc.ccType == 'MANUAL'}"><c:set var="manualCnt" value="${manualCnt+1}"/></c:if>
              </c:forEach>
              <div class="fw-bold fs-5 text-info">${manualCnt} 건</div>
            </div>
          </div>
        </div>
      </div>

      <!-- 필터 탭 -->
      <div class="d-flex gap-2 mb-3 flex-wrap">
        <a href="${pageContext.request.contextPath}/asset/costcenter"
           class="btn btn-sm homes-pill ${empty useYn ? 'btn-primary' : 'btn-outline-secondary'}">전체</a>
        <a href="${pageContext.request.contextPath}/asset/costcenter?useYn=Y"
           class="btn btn-sm homes-pill ${useYn == 'Y' ? 'btn-primary' : 'btn-outline-secondary'}">사용중</a>
        <a href="${pageContext.request.contextPath}/asset/costcenter?useYn=N"
           class="btn btn-sm homes-pill ${useYn == 'N' ? 'btn-secondary' : 'btn-outline-secondary'}">중지됨</a>
      </div>

      <!-- 목록 테이블 -->
      <div class="card homes-card">
        <div class="card-body p-0">
          <c:choose>
            <c:when test="${empty ccList}">
              <div class="text-center text-muted py-5">
                등록된 수지계정가 없습니다.<br>
                정기지출을 등록하면 자동으로 생성되거나,
                [+ 수동 등록] 버튼으로 직접 추가할 수 있습니다.
              </div>
            </c:when>
            <c:otherwise>
              <div class="homes-ag-wrap">
                <div id="ccGrid" class="ag-theme-alpine"></div>
              </div>
            </c:otherwise>
          </c:choose>
        </div>
      </div>

      <!-- 안내 박스 -->
      <div class="alert alert-info mt-4 small" style="border-radius:12px;">
        <span class="material-symbols-rounded ms-sm">lightbulb</span><strong>수지계정 안내</strong><br>
        • <strong>자동 생성</strong>: 정기지출 등록 시 동일한 수지계정가 자동으로 생성됩니다. 정기지출 삭제 시 함께 삭제됩니다.<br>
        • <strong>수동 등록</strong>: 직접 수지계정를 만들어 수입원을 연결할 수 있습니다.<br>
        • <strong>삭제 불가</strong>: 정기지출에서 수지계정로 사용 중이거나, 수지계정에 수입원으로 연결된 정기수입은 삭제할 수 없습니다.
      </div>

    </div>
    <%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
  </main>
</div>

<!-- ── 등록/수정 모달 ── -->
<div class="modal fade" id="ccModal" tabindex="-1">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="ccModalTitle">수지계정 등록</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <input type="hidden" id="ccSeq"/>
        <div class="mb-3">
          <label class="form-label fw-semibold">수지계정명 <span class="text-danger">*</span></label>
          <input type="text" class="form-control" id="ccNm" placeholder="예) 생활비 통장" maxlength="200"/>
        </div>
        <div class="mb-3">
          <label class="form-label fw-semibold">월 금액</label>
          <div class="input-group">
            <span class="input-group-text">₩</span>
            <input type="text" class="form-control text-end" id="monthlyAmt"
                   placeholder="0" oninput="fmtAmt(this)"/>
            <span class="input-group-text">원</span>
          </div>
        </div>
        <div class="mb-3">
          <label class="form-label fw-semibold">수입원 연결 <span class="text-muted small">(선택)</span></label>
          <select class="form-select" id="incomePlanSeq">
            <option value="">-- 선택 안함 --</option>
            <c:forEach var="inc" items="${incomeList}">
              <option value="${inc.planSeq}">${inc.planNm}
                (<fmt:formatNumber value="${inc.amount}" pattern="#,##0"/>원)</option>
            </c:forEach>
          </select>
          <div class="form-text">이 수지계정의 재원이 되는 정기수입을 연결하세요.</div>
        </div>
        <div class="mb-3">
          <label class="form-label fw-semibold">사용여부</label>
          <div class="form-check form-switch mt-1">
            <input class="form-check-input" type="checkbox" id="useYnCheck" checked>
            <label class="form-check-label" for="useYnCheck" id="useYnLabel">ON (사용중)</label>
          </div>
        </div>
        <div class="mb-2">
          <label class="form-label fw-semibold">메모</label>
          <input type="text" class="form-control" id="ccMemo" maxlength="500"/>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">취소</button>
        <button type="button" class="btn btn-primary" onclick="saveCc()">저장</button>
      </div>
    </div>
  </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
const ctx     = '${pageContext.request.contextPath}';
const ccModal = new bootstrap.Modal(document.getElementById('ccModal'));

/* ── CC 목록 데이터 embed ── */
const ccRowData = [];
<c:forEach var="cc" items="${ccList}">
(function(){
  function d(s){const el=document.createElement('textarea');el.innerHTML=s;return el.value;}
  ccRowData.push({
    ccSeq:         ${cc.ccSeq},
    ccType:        '${cc.ccType}',
    ccNm:          d('<c:out value="${cc.ccNm}"/>'),
    monthlyAmt:    ${cc.monthlyAmt},
    incomePlanSeq: ${empty cc.incomePlanSeq ? 'null' : cc.incomePlanSeq},
    incomePlanNm:  d('<c:out value="${cc.incomePlanNm}"/>'),
    useYn:         '${cc.useYn}',
    usedCount:     ${cc.usedCount},
    memo:          d('<c:out value="${cc.memo}"/>'),
  });
})();
</c:forEach>

if (ccRowData.length) {
  agGrid.createGrid(document.getElementById('ccGrid'), {
    columnDefs: [
      { field: 'ccType', headerName: '구분', width: 90,
        cellRenderer: p => p.value === 'AUTO'
          ? '<span class="badge bg-light text-secondary border" style="font-size:11px;">자동</span>'
          : '<span class="badge bg-info-subtle text-info border" style="font-size:11px;">수동</span>' },
      { field: 'ccNm', headerName: '수지계정명', flex: 1, minWidth: 140,
        cellRenderer: p => {
          const sub = p.data.ccType === 'AUTO' ? ' <span class="text-muted ms-1" style="font-size:11px;">(정기지출 연동)</span>' : '';
          return '<span class="fw-semibold">' + p.data.ccNm + '</span>' + sub;
        }
      },
      { field: 'monthlyAmt', headerName: '금액단위', width: 140, type: 'rightAligned',
        valueFormatter: p => Number(p.value).toLocaleString('ko-KR') + ' 원' },
      { field: 'incomePlanNm', headerName: '수입원 연결', width: 160,
        cellRenderer: p => p.value
          ? '<span class="badge bg-success-subtle text-success border">' + p.value + '</span>'
          : '<span class="text-muted">-</span>' },
      { field: 'useYn', headerName: '사용', width: 75,
        cellStyle: { justifyContent: 'center' },
        cellRenderer: p => p.value === 'Y'
          ? '<span class="badge bg-success">ON</span>'
          : '<span class="badge bg-secondary">OFF</span>' },
      { field: 'usedCount', headerName: '사용수', width: 85,
        cellStyle: { justifyContent: 'center' },
        cellRenderer: p => p.value > 0
          ? '<span class="badge bg-warning text-dark">' + p.value + '건 사용</span>'
          : '<span class="text-muted" style="font-size:12px;">미사용</span>' },
      { headerName: '관리', width: 120, sortable: false,
        cellStyle: { justifyContent: 'center' },
        cellRenderer: p => {
          const el = document.createElement('div');
          el.className = 'd-flex gap-1 justify-content-center';
          const editBtn = document.createElement('button');
          editBtn.className = 'btn btn-sm btn-outline-secondary homes-pill px-2';
          editBtn.textContent = '수정';
          editBtn.onclick = () => openModal(p.data.ccSeq, p.data.ccNm, p.data.monthlyAmt, p.data.incomePlanSeq, p.data.useYn, p.data.memo);
          el.appendChild(editBtn);
          if (p.data.usedCount === 0) {
            const delBtn = document.createElement('button');
            delBtn.className = 'btn btn-sm btn-outline-danger homes-pill px-2';
            delBtn.textContent = '삭제';
            delBtn.onclick = () => deleteCc(p.data.ccSeq, p.data.ccNm);
            el.appendChild(delBtn);
          }
          return el;
        }
      },
    ],
    rowData: ccRowData,
    defaultColDef: { sortable: true, resizable: true, suppressMovable: true },
    domLayout: 'autoHeight',
    suppressCellFocus: true,
  });
}

function fmtAmt(el) {
  const raw = el.value.replace(/[^0-9]/g, '');
  el.value = raw ? Number(raw).toLocaleString('ko-KR') : '';
}
function parseAmt(s) {
  return parseInt((s || '').replace(/[^0-9]/g, '') || '0', 10);
}

document.getElementById('useYnCheck').addEventListener('change', function () {
  document.getElementById('useYnLabel').textContent = this.checked ? 'ON (사용중)' : 'OFF (중지)';
});

function openModal(ccSeq, ccNm, monthlyAmt, incomePlanSeq, useYn, memo) {
  document.getElementById('ccSeq').value          = ccSeq || '';
  document.getElementById('ccNm').value           = ccNm  || '';
  document.getElementById('monthlyAmt').value     = monthlyAmt ? Number(monthlyAmt).toLocaleString('ko-KR') : '';
  document.getElementById('incomePlanSeq').value  = incomePlanSeq || '';
  document.getElementById('ccMemo').value         = memo || '';
  const on = !useYn || useYn === 'Y';
  document.getElementById('useYnCheck').checked   = on;
  document.getElementById('useYnLabel').textContent = on ? 'ON (사용중)' : 'OFF (중지)';
  document.getElementById('ccModalTitle').textContent = ccSeq ? '수지계정 수정' : '수지계정 등록';
  ccModal.show();
  setTimeout(() => document.getElementById('ccNm').focus(), 300);
}

function saveCc() {
  const ccNm = document.getElementById('ccNm').value.trim();
  if (!ccNm) { alert('수지계정명을 입력하세요.'); return; }

  const incomePlanSeqVal = document.getElementById('incomePlanSeq').value;
  const payload = {
    ccSeq:          document.getElementById('ccSeq').value || null,
    ccNm:           ccNm,
    monthlyAmt:     parseAmt(document.getElementById('monthlyAmt').value),
    incomePlanSeq:  incomePlanSeqVal || null,
    useYn:          document.getElementById('useYnCheck').checked ? 'Y' : 'N',
    memo:           document.getElementById('ccMemo').value.trim()
  };

  fetch(ctx + '/asset/costcenter/save', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload)
  }).then(r => r.json()).then(res => {
    if (res.success) { ccModal.hide(); location.reload(); }
    else alert('저장 실패: ' + (res.message || '알 수 없는 오류'));
  });
}

function deleteCc(ccSeq, ccNm) {
  if (!confirm('[' + ccNm + '] 수지계정를 삭제하시겠습니까?\n사용 중인 경우 삭제되지 않습니다.')) return;
  fetch(ctx + '/asset/costcenter/delete', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ ccSeq })
  }).then(r => r.json()).then(res => {
    if (res.success) {
      location.reload();
    } else {
      alert('삭제 불가\n\n' + (res.message || '알 수 없는 오류'));
    }
  });
}
</script>
</body>
</html>
