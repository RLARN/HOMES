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
          <h1 class="h4 fw-bold mb-1">자산원장관리</h1>
          <div class="text-muted small">현재 보유 자산을 등록하고 상태를 관리합니다.</div>
        </div>
        <a class="btn btn-primary homes-pill px-3"
           href="${pageContext.request.contextPath}/asset/ledger/form">자산 등록</a>
      </div>

      <!-- 요약 카드 -->
      <div class="row g-3 mb-4">
        <div class="col-12 col-sm-4">
          <div class="card homes-card h-100">
            <div class="card-body">
              <div class="text-muted small mb-1">총 자산</div>
              <div class="fw-bold fs-5">
                <fmt:formatNumber value="${summary.totalAssetAmount}" pattern="#,##0"/> 원
              </div>
              <div class="text-muted" style="font-size:11px;">보유중 자산 합계 (말소 제외)</div>
            </div>
          </div>
        </div>
        <div class="col-12 col-sm-4">
          <div class="card homes-card h-100">
            <div class="card-body">
              <div class="text-muted small mb-1">유동 자산</div>
              <div class="fw-bold fs-5 text-success">
                <fmt:formatNumber value="${summary.totalLiquidAssetAmount}" pattern="#,##0"/> 원
              </div>
              <div class="text-muted" style="font-size:11px;">현금화 용이 자산</div>
            </div>
          </div>
        </div>
        <div class="col-12 col-sm-4">
          <div class="card homes-card h-100">
            <div class="card-body">
              <div class="text-muted small mb-1">투자 자산</div>
              <div class="fw-bold fs-5 text-primary">
                <fmt:formatNumber value="${summary.totalInvestAmount}" pattern="#,##0"/> 원
              </div>
              <div class="text-muted" style="font-size:11px;">주식·펀드·코인·연금</div>
            </div>
          </div>
        </div>
      </div>

      <!-- 필터 -->
      <div class="d-flex gap-2 mb-3 flex-wrap">
        <a href="${pageContext.request.contextPath}/asset/ledger"
           class="btn btn-sm homes-pill ${empty disposeYn ? 'btn-primary' : 'btn-outline-secondary'}">전체</a>
        <a href="${pageContext.request.contextPath}/asset/ledger?disposeYn=N"
           class="btn btn-sm homes-pill ${disposeYn == 'N' ? 'btn-primary' : 'btn-outline-secondary'}">보유중</a>
        <a href="${pageContext.request.contextPath}/asset/ledger?disposeYn=Y"
           class="btn btn-sm homes-pill ${disposeYn == 'Y' ? 'btn-warning' : 'btn-outline-secondary'}">말소됨</a>
      </div>

      <!-- 자산 목록 -->
      <div class="card homes-card">
        <div class="card-body pt-2 px-3 px-md-4">
          <div class="table-responsive">
            <table class="table align-middle homes-table">
              <thead>
                <tr class="text-muted small">
                  <th>자산명</th>
                  <th style="width:120px;" class="text-nowrap">자산형태</th>
                  <th style="width:80px;"  class="text-nowrap text-center">유동성</th>
                  <th style="width:150px;" class="text-nowrap text-end">금액</th>
                  <th style="width:80px;"  class="text-nowrap text-center">상태</th>
                  <th style="width:100px;" class="text-nowrap">말소일</th>
                  <th style="width:100px;" class="text-nowrap">수정자</th>
                  <th style="width:110px;" class="text-nowrap">수정일</th>
                  <th style="width:80px;"></th>
                </tr>
              </thead>
              <tbody>
                <c:choose>
                  <c:when test="${empty assetList}">
                    <tr>
                      <td colspan="9">
                        <div class="homes-empty">등록된 자산이 없습니다.</div>
                      </td>
                    </tr>
                  </c:when>
                  <c:otherwise>
                    <c:forEach var="a" items="${assetList}">
                      <tr onclick="location.href='${pageContext.request.contextPath}/asset/ledger/form?assetSeq=${a.assetSeq}'"
                          style="cursor:pointer;">
                        <td>
                          <div class="fw-semibold text-truncate" style="max-width:280px;">
                            <c:out value="${a.assetNm}"/>
                          </div>
                          <c:if test="${not empty a.memo}">
                            <div class="text-muted small text-truncate" style="max-width:280px;">
                              <c:out value="${a.memo}"/>
                            </div>
                          </c:if>
                        </td>
                        <td class="text-nowrap"><c:out value="${a.assetTypeNm}"/></td>
                        <td class="text-center text-nowrap">
                          <c:choose>
                            <c:when test="${a.liquidYn == 'Y'}">
                              <span class="badge bg-success-subtle text-success">유동</span>
                            </c:when>
                            <c:otherwise>
                              <span class="badge bg-secondary-subtle text-secondary">비유동</span>
                            </c:otherwise>
                          </c:choose>
                        </td>
                        <td class="text-end text-nowrap fw-semibold">
                          <fmt:formatNumber value="${a.amount}" pattern="#,##0"/> 원
                        </td>
                        <td class="text-center text-nowrap">
                          <c:choose>
                            <c:when test="${a.disposeYn == 'Y'}">
                              <span class="badge bg-warning-subtle text-warning">말소됨</span>
                            </c:when>
                            <c:otherwise>
                              <span class="badge bg-primary-subtle text-primary">보유중</span>
                            </c:otherwise>
                          </c:choose>
                        </td>
                        <td class="text-muted text-nowrap small">
                          <c:if test="${not empty a.disposeYmd}">
                            <c:out value="${a.disposeYmd}"/>
                          </c:if>
                        </td>
                        <td class="text-nowrap small"><c:out value="${a.updId}"/></td>
                        <td class="text-muted text-nowrap small">${a.updDtStr}</td>
                        <td class="text-nowrap" onclick="event.stopPropagation();">
                          <a href="${pageContext.request.contextPath}/asset/ledger/form?assetSeq=${a.assetSeq}"
                             class="btn btn-xs btn-outline-primary homes-pill px-2 py-0" style="font-size:12px;">수정</a>
                          <c:if test="${sessionScope.LoginVO.userAuth == 'manager'}">
                            <button type="button"
                                    class="btn btn-xs btn-outline-danger homes-pill px-2 py-0"
                                    style="font-size:12px;"
                                    data-asset-seq="${a.assetSeq}"
                                    onclick="deleteAsset(this)">삭제</button>
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

async function deleteAsset(btn) {
  if (!confirm('삭제하면 복구할 수 없습니다. 삭제하시겠습니까?')) return;
  const seq = btn.getAttribute('data-asset-seq');
  try {
    const res = await fetch(HOMES.ctx + '/asset/ledger/delete', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'Accept': 'application/json' },
      body: new URLSearchParams({ assetSeq: seq })
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
