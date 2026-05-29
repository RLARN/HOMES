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

        <!-- Page Header -->
        <div class="d-flex flex-column flex-md-row align-items-md-center justify-content-between gap-2 mb-3">
          <div>
            <div class="homes-badge mb-2">SCM</div>
            <h1 class="h4 fw-bold mb-1">입금요청</h1>
            <div class="text-muted small">금액과 사유를 입력하고 상신하세요. 오른쪽에서 기존 요청을 검색할 수 있어요.</div>
          </div>
        </div>

        <div class="row g-3">
          <!-- =======================
               Left: 입력(상신)
          ======================= -->
          <div class="col-12 col-xl-4">
            <div class="card homes-card homes-form-card">
              <div class="card-header bg-transparent border-0 pt-3 px-3 px-md-4">
                <div class="fw-semibold">입금요청 신청서</div>
              </div>

              <div class="card-body pt-2 px-3 px-md-4">
				<form id="depositForm"
				      method="post">

				  <!-- 구매처 -->
				  <div class="mb-3">
				    <label class="form-label fw-semibold">
				      구매처(제품) <span class="text-danger">*</span>
				    </label>
				    <input type="text"
				           class="form-control"
				           name="storeInfo"
				           required>
				    <div class="invalid-feedback">
				      구매처를 입력하세요.
				    </div>
				  </div>

				  <!-- 금액 -->
				  <div class="mb-3">
				    <label class="form-label fw-semibold">
				      금액 <span class="text-danger">*</span>
				    </label>
				    <div class="input-group">
				      <span class="input-group-text">₩</span>
				      <input type="text"
				             class="form-control"
				             id="amount"
				             name="amount"
				             required
				             inputmode="numeric"
				             pattern="[0-9,]+"
				             placeholder="예) 32,000">
				      <div class="invalid-feedback">
				        숫자만 입력하세요.
				      </div>
				    </div>
				  </div>

				  <!-- 사유 -->
				  <div class="mb-3">
				    <label class="form-label fw-semibold">사유</label>
				    <textarea class="form-control"
				              name="reqDesc"
				              rows="4"></textarea>
				  </div>

				  <div class="d-grid gap-2">
				    <button class="btn btn-primary homes-pill" type="submit">
				      상신
				    </button>
				    <button class="btn btn-outline-secondary homes-pill" type="reset">
				      초기화
				    </button>
				  </div>
				</form>
              </div>
            </div>
          </div>

          <!-- =======================
               Right: 리스트(검색)
          ======================= -->
          <div class="col-12 col-xl-8">
            <div class="card homes-card">
              <div class="card-header bg-transparent border-0 pt-3 px-3 px-md-4">
                <div class="d-flex flex-column flex-md-row align-items-md-center justify-content-between gap-2">
                  <div>
                    <div class="fw-semibold">기존 입금요청 리스트</div>
                    <div class="text-muted small">백엔드에서 SCM_DEPOSIT_REQUEST_LIST 조회</div>
                  </div>
                </div>

                <!-- 검색 -->
                <form method="get" action="${pageContext.request.contextPath}/scm/purchase/request" class="mt-3">
                  <div class="row g-2 align-items-center">
                    <div class="col-12 col-md-8">
                      <input type="search"
                             class="form-control homes-search-light"
                             name="q"
                             placeholder="검색(사유/상태/금액 등) — 예: 장보기, 32000"
                             value="${param.q}">
                    </div>
                    <div class="col-6 col-md-2">
                      <select class="form-select" name="status">
                        <option value="">전체상태</option>
                        <option value="REQUEST" ${param.status == 'REQUEST' ? 'selected' : ''}>요청</option>
                        <option value="APPROVED" ${param.status == 'APPROVED' ? 'selected' : ''}>승인</option>
                        <option value="REJECTED" ${param.status == 'REJECTED' ? 'selected' : ''}>반려</option>
                      </select>
                    </div>
                    <div class="col-6 col-md-2 d-grid">
                      <button class="btn btn-outline-primary homes-pill" type="submit">검색</button>
                    </div>
                  </div>
                </form>
              </div>

              <div class="card-body pt-2 px-3 px-md-4">
                <div class="table-responsive">
                  <table class="table align-middle homes-table">
                    <thead>
                      <tr class="text-muted small">
                        <th style="width: 120px;">요청일</th>
                        <th>구매처(제품)</th>
                        <th style="width: 140px;" class="text-end text-nowrap">금액</th>
                        <th style="width: 90px;" class="text-center text-nowrap">상태</th>
                        <th style="width: 90px;" class="text-center text-nowrap">상세</th>
						<c:if test="${sessionScope.LoginVO.userAuth eq 'manager'}">
 							<th style="width: 90px;" class="text-center text-nowrap">결재</th>
 							<th style="width: 70px;" class="text-center text-nowrap">삭제</th>
						</c:if>
                      </tr>
                    </thead>
                    <tbody>
                      <c:choose>
                        <c:when test="${empty requestList}">
                          <tr>
                            <td colspan="5">
                              <div class="homes-empty">
                                아직 등록된 입금요청이 없어요.
                                <span class="text-muted">(좌측에서 작성 후 상신)</span>
                              </div>
                            </td>
                          </tr>
                        </c:when>

                        <c:otherwise>
                          <c:forEach var="row" items="${requestList}">
                            <tr>
                              <!-- 날짜 -->
                              <td class="text-muted small">
                                <c:out value="${row.requestDt}" />
                              </td>

                              <!-- 구매처 -->
                              <td>
                                <div class="fw-semibold text-truncate" style="max-width: 520px;">
                                  <c:out value="${row.storeInfo}" />
                                </div>
                                <div class="text-muted small">
                                  <c:out value="${row.regId}" />
                                </div>
                              </td>

                              <!-- 금액 -->
                              <td class="text-end fw-bold">
                                <fmt:formatNumber value="${row.amount}" pattern="#,##0" />&nbsp;원
                              </td>

                              <!-- 상태 -->
                              <td class="text-center">
                                <span class="badge rounded-pill
                                  ${row.reqStatus == 'APPROVED' ? 'text-bg-success' :
                                    (row.reqStatus == 'REJECT' ? 'text-bg-danger' : 'text-bg-secondary')}">
                                  <!--<c:out value="${row.reqStatus}" />-->
                                </span>
                              </td>

                              <!-- 상세 -->
							  <td class="text-center text-nowrap">
							    <button type="button"
							            class="btn btn-sm btn-outline-secondary homes-pill"
							            data-bs-toggle="modal"
							            data-bs-target="#depositDetailModal"
							            data-dep-req-seq="${row.depReqSeq}">
							      보기
							    </button>
							  </td>
							  <!-- 결재/삭제 버튼 (MANAGER만) -->
							  <c:if test="${sessionScope.LoginVO.userAuth eq 'manager'}">
							  <td class="text-center text-nowrap">
							    <button type="button"
							            class="btn btn-sm btn-primary homes-pill"
							            data-dep-req-seq="${row.depReqSeq}"
							            onclick="approveDeposit(this)">
							      결재
							    </button>
							  </td>
							  <td class="text-center text-nowrap">
							    <button type="button"
							            class="btn btn-sm btn-outline-danger homes-pill"
							            data-dep-req-seq="${row.depReqSeq}"
							            onclick="deleteDeposit(this)">
							      삭제
							    </button>
							  </td>
							  </c:if>
                            </tr>
                          </c:forEach>
                        </c:otherwise>
                      </c:choose>
                    </tbody>
                  </table>
                </div>

                <!-- 페이징 자리(나중에) -->
                <c:if test="${not empty page}">
                  <div class="d-flex justify-content-center mt-3">
                    ${page}
                  </div>
                </c:if>
              </div>
            </div>
          </div>
        </div>

      </div>

      <%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
    </main>
  </div>

  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

  <script>
  let _approveSeq = null;

  function approveDeposit(btn) {
    _approveSeq = btn.getAttribute('data-dep-req-seq');
    document.getElementById('ap_seq').textContent = '#' + _approveSeq;
    bootstrap.Modal.getOrCreateInstance(document.getElementById('approveModal')).show();
  }

  async function deleteDeposit(btn) {
    if (!confirm('삭제하면 복구할 수 없습니다. 삭제하시겠습니까?')) return;
    const seq = btn.getAttribute('data-dep-req-seq');
    try {
      const res = await fetch(HOMES.ctx + '/scm/deposit/depositRequest/deleteAjax', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'Accept': 'application/json' },
        body: new URLSearchParams({ depReqSeq: seq })
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

  async function submitApprove(status) {
    bootstrap.Modal.getInstance(document.getElementById('approveModal')).hide();
    try {
      const res = await fetch(HOMES.ctx + '/scm/deposit/depositRequest/approveAjax', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'Accept': 'application/json' },
        body: new URLSearchParams({ depReqSeq: _approveSeq, reqStatus: status })
      });
      const data = await res.json();
      if (data.success) {
        const label = { APPROVED: '결재완료', REJECT: '반려', STANDBY: '대기' }[status] || status;
        if (HOMES.toast) HOMES.toast(label + ' 처리되었습니다.', 'success');
        setTimeout(() => location.reload(), 800);
      } else {
        if (HOMES.toast) HOMES.toast(data.message || '처리 실패', 'danger');
      }
    } catch (e) {
      if (HOMES.toast) HOMES.toast('오류: ' + e.message, 'danger');
    }
  }
  </script>

  <script>
  /**
   * [공통] ContextPath / 유틸
   */
  window.HOMES = window.HOMES || {};
  HOMES.ctx = '${pageContext.request.contextPath}';
  HOMES.qs  = (sel) => document.querySelector(sel);
  HOMES.qsa = (sel) => Array.from(document.querySelectorAll(sel));
  </script>

  <script>
  /**
   * [UI] Bootstrap Toast 표시
   * - HOMES.toast("메시지", "success|danger|warning|info")
   */
  (function () {
    const toastEl = document.getElementById('appToast');
    const toastBodyEl = document.getElementById('appToastBody');
    if (!toastEl || !toastBodyEl) return;

    // 부트스트랩 토스트 인스턴스 1개만 재사용
    const toast = bootstrap.Toast.getOrCreateInstance(toastEl, { delay: 2200, autohide: true });

    function setToastStyle(type) {
      // 배경색은 부트스트랩 클래스 활용 (직접 색상 하드코딩 X)
      // text-white / bg-* 조합
      toastEl.classList.remove('text-bg-success', 'text-bg-danger', 'text-bg-warning', 'text-bg-info', 'text-bg-secondary');
      if (type === 'success') toastEl.classList.add('text-bg-success');
      else if (type === 'danger') toastEl.classList.add('text-bg-danger');
      else if (type === 'warning') toastEl.classList.add('text-bg-warning');
      else if (type === 'info') toastEl.classList.add('text-bg-info');
      else toastEl.classList.add('text-bg-secondary');
    }

    HOMES.toast = function (message, type) {
      toastBodyEl.textContent = message || '';
      setToastStyle(type);
      toast.show();
    };
  })();
  </script>

  <script>
  /**
   * [폼] AJAX 상신 + Bootstrap 5 Validation
   */
  (function () {
    'use strict';

    const form = document.getElementById('depositForm');
    if (!form) return;

    form.addEventListener('submit', async function (event) {
      event.preventDefault();
      event.stopPropagation();
      form.classList.add('was-validated');

      if (!form.checkValidity()) return;

      const submitBtn = form.querySelector('[type=submit]');
      const origText  = submitBtn.textContent;
      submitBtn.disabled = true;
      submitBtn.textContent = '처리 중...';

      try {
        const res = await fetch(HOMES.ctx + '/scm/deposit/depositRequest/saveAjax', {
          method:  'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'Accept': 'application/json' },
          body:    new URLSearchParams({
            storeInfo: form.storeInfo.value,
            amount:    HOMES.amountOnlyDigits(),
            reqDesc:   form.reqDesc.value
          })
        });

        const data = await res.json();

        if (data.success) {
          if (HOMES.toast) HOMES.toast(data.message || '상신되었습니다.', 'success');
          form.reset();
          form.classList.remove('was-validated');
          // 목록 새로고침
          setTimeout(() => location.reload(), 800);
        } else {
          if (HOMES.toast) HOMES.toast(data.message || '저장에 실패했습니다.', 'danger');
        }
      } catch (e) {
        if (HOMES.toast) HOMES.toast('네트워크 오류: ' + e.message, 'danger');
      } finally {
        submitBtn.disabled = false;
        submitBtn.textContent = origText;
      }
    }, false);
  })();
  </script>

  <script>
  /**
   * [입력] 금액: 숫자만 허용 + 천단위 콤마(화면용)
   * - 서버 전송 직전에는 콤마 제거(숫자만)
   */
  (function () {
    const formEl = document.getElementById('depositForm');
    const amountEl = document.getElementById('amount');
    if (!formEl || !amountEl) return;

    function onlyDigits(v) {
      return (v || '').replace(/[^\d]/g, '');
    }
    function commaize(d) {
      if (!d) return '';
      return d.replace(/\B(?=(\d{3})+(?!\d))/g, ',');
    }

    // 입력 시: 문자 제거 + 콤마
    amountEl.addEventListener('input', function () {
      const d = onlyDigits(this.value);
      this.value = commaize(d);
    });

    // 붙여넣기 대응
    amountEl.addEventListener('paste', function () {
      setTimeout(() => {
        const d = onlyDigits(amountEl.value);
        amountEl.value = commaize(d);
      }, 0);
    });

    // 외부에서 필요할 수 있으니 공통에 노출(ajax submit에서 씀)
    HOMES.amountOnlyDigits = () => onlyDigits(amountEl.value);
    HOMES.amountCommaize = (v) => commaize(onlyDigits(v));
  })();
  </script>

  <script>
  document.addEventListener('DOMContentLoaded', function () {

    const modalEl = document.getElementById('depositDetailModal');
    if (!modalEl) {
      console.error('[DETAIL] modal not found');
      return;
    }

    console.log('[DETAIL] modal bind OK');

    const STATUS_NM = {
      APPROVAL: '결재중',
      APPROVED: '결재완료',
      REJECT: '반려됨',
      STANDBY: '결재대기',
      REQ: '요청'
    };

    function bind(id, v) {
      const el = document.getElementById(id);
      if (el) el.textContent = v ?? '';
    }

    modalEl.addEventListener('show.bs.modal', async function (e) {
      const btn = e.relatedTarget;
      const seq = btn?.getAttribute('data-dep-req-seq');

      console.log('[DETAIL] open seq=', seq);

      const loading = document.getElementById('depositDetailLoading');
      const body    = document.getElementById('depositDetailBody');
      const error   = document.getElementById('depositDetailError');

      loading.classList.remove('d-none');
      body.classList.add('d-none');
      error.classList.add('d-none');

      try {
        const url = '/scm/deposit/depositRequest/detailJson?id=' + encodeURIComponent(seq);
        console.log('[DETAIL] fetch', url);

        const res = await fetch(url, { headers: { 'Accept': 'application/json' }});
        if (!res.ok) throw new Error('HTTP ' + res.status);

        const data = await res.json();
        console.log('[DETAIL] data=', data);

        bind('dd_depReqSeq', data.depReqSeq);
        bind('dd_reqStatus', STATUS_NM[data.reqStatus] || data.reqStatus);
        bind('dd_amount', data.amount ? data.amount + '원' : '');
        bind('dd_regDt', data.regDt);
        bind('dd_reqDesc', data.reqDesc);
        bind('dd_purItemSeq', data.purItemSeq);
        bind('dd_storeInfo', data.storeInfo);
        bind('dd_regId', data.regId);

        loading.classList.add('d-none');
        body.classList.remove('d-none');

      } catch (err) {
        console.error('[DETAIL ERROR]', err);
        loading.classList.add('d-none');
        error.classList.remove('d-none');
      }
    });
  });
  </script>


  <script>
  /**
   * [상세조회] 모달 열릴 때 JSON fetch로 상세 데이터 채우기
   * - 버튼에 data-dep-req-seq="..." 있어야 함
   * - 컨트롤러: GET /scm/deposit/depositRequest/detailJson?id=...
   *
   * ✅ ctx/HOMES 전역에 의존하지 않음 (가장 안정적)
   */
  (function () {
    const modalEl = document.getElementById('depositDetailModal');
    if (!modalEl) {
      console.error('[DETAIL] #depositDetailModal not found');
      return;
    }

    const STATUS_NM = {
      APPROVAL: '결재중',
      APPROVED: '결재완료',
      REJECT: '반려됨',
      STANDBY: '결재대기',
      REQ: '요청'
    };

    function bindText(id, v) {
      const el = document.getElementById(id);
      if (!el) {
        console.warn('[DETAIL] missing element id=', id);
        return;
      }
      el.textContent = (v == null ? '' : String(v));
    }

    function setVisible(el, show) {
      if (!el) return;
      el.classList.toggle('d-none', !show);
    }

    modalEl.addEventListener('show.bs.modal', async function (event) {
      const btn = event.relatedTarget;
      const depReqSeq = btn ? btn.getAttribute('data-dep-req-seq') : null;

      console.log('[DETAIL] open depReqSeq=', depReqSeq);

      const loadingEl = document.getElementById('depositDetailLoading');
      const bodyEl    = document.getElementById('depositDetailBody');
      const errEl     = document.getElementById('depositDetailError');

      setVisible(loadingEl, true);
      setVisible(bodyEl, false);
      setVisible(errEl, false);

      try {
        if (!depReqSeq) throw new Error('NO_ID');

        // ✅ 절대경로로 고정 (ctx/HOMES 의존 제거)
        const url = '/scm/deposit/depositRequest/detailJson?id=' + encodeURIComponent(depReqSeq);
        console.log('[DETAIL] fetch url=', url);

        const res = await fetch(url, {
          method: 'GET',
          headers: { 'Accept': 'application/json' }
        });

        console.log('[DETAIL] status=', res.status);

        // 200이 아니면 에러
        if (!res.ok) {
          const t = await res.text().catch(() => '');
          console.error('[DETAIL] not ok, body=', t.slice(0, 300));
          throw new Error('HTTP_' + res.status);
        }

        // ✅ JSON이 아닌 게 내려오는지 체크 (로그인 리다이렉트/에러페이지 등)
        const ct = (res.headers.get('content-type') || '').toLowerCase();
        if (!ct.includes('application/json')) {
          const t = await res.text().catch(() => '');
          console.error('[DETAIL] not json, ct=', ct, 'body=', t.slice(0, 300));
          throw new Error('NOT_JSON');
        }

        const data = await res.json();
        console.log('[DETAIL] data=', data);

        bindText('dd_depReqSeq', data.depReqSeq);
        bindText('dd_reqStatus', STATUS_NM[data.reqStatus] || data.reqStatus);
        bindText('dd_amount', data.amount ? (data.amount + ' 원') : '');
        bindText('dd_regDt', data.regDt);
        bindText('dd_reqDesc', data.reqDesc);
        bindText('dd_purItemSeq', '정보없음');
        bindText('dd_storeInfo', data.storeInfo);
        bindText('dd_regId', data.regId);

        setVisible(loadingEl, false);
        setVisible(bodyEl, true);

      } catch (e) {
        console.error('[DETAIL MODAL] error:', e);
        setVisible(loadingEl, false);
        setVisible(errEl, true);

        // HOMES.toast 있으면 띄우고, 없으면 무시
        try {
          if (window.HOMES && typeof HOMES.toast === 'function') {
            HOMES.toast('상세 조회에 실패했습니다.', 'danger');
          }
        } catch (_) {}
      }
    });
  })();
  </script>

  <!--추가화면들-->
  <!-- Bootstrap Toast Container (우측 상단) -->
  <div class="toast-container position-fixed top-0 end-0 p-3" style="z-index: 1080;">
    <div id="appToast" class="toast align-items-center border-0" role="alert" aria-live="assertive" aria-atomic="true">
      <div class="d-flex">
        <div id="appToastBody" class="toast-body">
          <!-- 메시지 -->
        </div>
        <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Close"></button>
      </div>
    </div>
  </div>
  
  <!-- 결재 모달 -->
  <div class="modal fade" id="approveModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
      <div class="modal-content" style="border-radius:18px;">
        <div class="modal-header">
          <h5 class="modal-title">결재</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
        </div>
        <div class="modal-body">
          <p class="mb-1 text-muted small">요청번호 <span id="ap_seq" class="fw-semibold text-dark"></span></p>
          <p class="mb-0">처리 방법을 선택하세요.</p>
        </div>
        <div class="modal-footer gap-2">
          <button type="button" class="btn btn-success homes-pill px-4" onclick="submitApprove('APPROVED')">결재완료</button>
          <button type="button" class="btn btn-danger  homes-pill px-4" onclick="submitApprove('REJECT')">반려</button>
          <button type="button" class="btn btn-secondary homes-pill px-4" onclick="submitApprove('STANDBY')">대기</button>
        </div>
      </div>
    </div>
  </div>

  <!-- 입금요청 상세 모달 -->
  <div class="modal fade" id="depositDetailModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-scrollable">
      <div class="modal-content" style="border-radius: 18px;">
        <div class="modal-header">
          <h5 class="modal-title">입금요청 상세</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>

        <div class="modal-body">
          <div id="depositDetailLoading" class="text-muted small">불러오는 중...</div>

          <div id="depositDetailBody" class="d-none">
            <div class="row g-3">
              <div class="col-md-6">
                <div class="text-muted small">요청번호</div>
                <div class="fw-semibold" id="dd_depReqSeq"></div>
              </div>
              <div class="col-md-6">
                <div class="text-muted small">상태</div>
                <div class="fw-semibold" id="dd_reqStatus"></div>
              </div>

              <div class="col-md-6">
                <div class="text-muted small">금액</div>
                <div class="fw-semibold" id="dd_amount"></div>
              </div>
              <div class="col-md-6">
                <div class="text-muted small">등록일</div>
                <div class="fw-semibold" id="dd_regDt"></div>
              </div>

              <div class="col-12">
                <div class="text-muted small">사유</div>
                <div class="fw-semibold" id="dd_reqDesc" style="white-space: pre-wrap;"></div>
              </div>

              <div class="col-md-6">
                <div class="text-muted small">구매항목</div>
                <div class="fw-semibold" id="dd_purItemSeq"></div>
              </div>
              <div class="col-md-6">
                <div class="text-muted small">구매처(제품)</div>
                <div class="fw-semibold" id="dd_storeInfo"></div>
              </div>

              <div class="col-md-6">
                <div class="text-muted small">요청자(ID)</div>
                <div class="fw-semibold" id="dd_regId"></div>
              </div>
            </div>
          </div>

          <div id="depositDetailError" class="alert alert-danger d-none mt-3 mb-0">
            상세 조회에 실패했습니다.
          </div>
        </div>

        <div class="modal-footer">
          <button class="btn btn-light homes-pill" data-bs-dismiss="modal" type="button">닫기</button>
        </div>
      </div>
    </div>
  </div>
  
</body>
</html>
