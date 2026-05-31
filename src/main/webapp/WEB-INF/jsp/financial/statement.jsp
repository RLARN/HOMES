<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<!doctype html>
<html lang="ko">
<head>
  <%@ include file="/WEB-INF/jsp/common/head.jsp" %>
  <title>재무제표명세서 | HOMES</title>
  <style>
    /* ── 명세서 공통 ── */
    .stmt-wrap { max-width: 900px; }
    .stmt-box  { border: 1px solid #e2e8f0; border-radius: 10px; overflow: hidden; margin-bottom: 1.5rem; }
    .stmt-box-title {
      background: #f8fafc; padding: .6rem 1.2rem;
      font-weight: 700; font-size: 13px; color: #334155;
      border-bottom: 1px solid #e2e8f0; display: flex; align-items: center; gap: .4rem;
    }
    .stmt-box-title .badge-ref {
      font-size: 10px; font-weight: 500; background: #e2e8f0; color: #64748b;
      padding: 2px 7px; border-radius: 20px; margin-left: .3rem;
    }

    /* ── 명세 테이블 ── */
    .st { width: 100%; border-collapse: collapse; font-size: 13px; }
    .st th  { background: #f1f5f9; padding: .5rem 1rem; font-weight: 600; color: #64748b;
               border-bottom: 1px solid #e2e8f0; white-space: nowrap; }
    .st td  { padding: .45rem 1rem; border-bottom: 1px solid #f1f5f9; }
    .st tr:last-child td { border-bottom: none; }
    .st .grp td { background: #f8fafc; font-weight: 600; font-size: 12px;
                  color: #475569; padding: .32rem 1rem; }
    .st .sub td { padding-left: 2rem; color: #374151; }
    .st .tot td { background: #f0fdf4; font-weight: 700; border-top: 2px solid #bbf7d0; }
    .st .tot-exp td { background: #fff7ed; border-top: 2px solid #fed7aa; }
    .st .manual-badge { font-size: 10px; background: #dbeafe; color: #1e40af;
                        padding: 1px 6px; border-radius: 10px; margin-left: 4px; }

    /* ── 색상 ── */
    .c-pos  { color: #16a34a; }
    .c-neg  { color: #dc2626; }
    .c-blue { color: #0ea5e9; }
    .c-gray { color: #94a3b8; }

    /* ── 순손익 바 ── */
    .net-bar {
      border-radius: 10px; padding: 1rem 1.4rem;
      display: flex; justify-content: space-between; align-items: center;
      border: 2px solid;
    }

    /* ── 참고 accordion ── */
    .ref-section { border: 1px solid #e2e8f0; border-radius: 10px; margin-bottom: 1.2rem;
                   box-shadow: 0 1px 3px rgba(0,0,0,.04); }
    .ref-toggle  { background: #f8fafc; border: none; width: 100%; text-align: left;
                   padding: .6rem 1rem; font-size: 13px; font-weight: 600; color: #475569;
                   cursor: pointer; display: flex; justify-content: space-between; align-items: center;
                   border-radius: 10px; border-bottom: 1px solid #e2e8f0; }
    .ref-toggle:hover { background: #f1f5f9; }
    .ref-body { padding: 0; display: block; }
    .ref-body.closed { display: none; }

    /* ── 인쇄 ── */
    @media print {
      body { background: white !important; font-size: 11px !important; }
      .homes-sidebar, .homes-header, .no-print, .homes-footer { display: none !important; }
      .homes-shell { display: block !important; }
      .homes-main  { width: 100% !important; margin: 0 !important; }
      .homes-main-body { padding: 1rem !important; }
      .stmt-wrap { max-width: 100%; }
      .stmt-box  { page-break-inside: avoid; }
      .ref-body, .ref-body.closed { display: block !important; }
      .ref-toggle::after { display: none; }
      .print-header { display: block !important; }
      .net-bar { border-width: 1px !important; }
    }
    .print-header { display: none; text-align: center; margin-bottom: 1.2rem; }
    .print-header h2 { font-size: 20px; font-weight: 800; letter-spacing: -.5px; }
    .print-header p  { font-size: 12px; color: #666; margin: .2rem 0 0; }
  </style>
</head>
<body class="homes-bg">
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>

<div class="homes-shell d-lg-flex">
  <%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

  <main class="homes-main flex-grow-1 d-flex flex-column">
    <div class="homes-main-body px-3 px-md-4 py-4">
    <div class="stmt-wrap">

      <!-- 인쇄용 헤더 -->
      <div class="print-header">
        <h2>재무제표 명세서</h2>
        <p>${dispPeriod} &nbsp;|&nbsp; 수지계정 기준 손익 &nbsp;|&nbsp; 출력일: <jsp:useBean id="now" class="java.util.Date"/><fmt:formatDate value="${now}" pattern="yyyy.MM.dd"/></p>
      </div>

      <!-- 페이지 헤더 -->
      <div class="d-flex align-items-start justify-content-between gap-2 mb-4 no-print">
        <div>
          <div class="homes-badge mb-2">Financial</div>
          <h1 class="h4 fw-bold mb-1">재무제표 명세서</h1>
          <div class="text-muted small">수지계정 기준 손익 · 자산현황 · 참고자료</div>
        </div>
        <div class="d-flex gap-2 mt-1 flex-wrap">
          <c:if test="${mode == 'monthly'}">
            <%-- 최신본/전표처리본 토글 --%>
            <c:if test="${hasSnapshot}">
              <div class="btn-group" role="group">
                <a href="${pageContext.request.contextPath}/financial/statement?mode=${mode}&period=${period}&viewMode=live"
                   class="btn homes-pill btn-sm ${viewMode == 'live' ? 'btn-primary' : 'btn-outline-primary'}">
                  ⚡ 최신본
                </a>
                <a href="${pageContext.request.contextPath}/financial/statement?mode=${mode}&period=${period}&viewMode=snapshot"
                   class="btn homes-pill btn-sm ${viewMode == 'snapshot' ? 'btn-warning' : 'btn-outline-warning'}">
                  <span class="material-symbols-rounded ms-sm">push_pin</span>전표처리본
                </a>
              </div>
            </c:if>
            <button id="snapshotBtn" class="btn btn-outline-primary homes-pill px-3 d-flex align-items-center gap-1" onclick="doSnapshot()">
              <span class="material-symbols-rounded ms-sm">push_pin</span>전표처리
            </button>
          </c:if>
          <button class="btn btn-outline-secondary homes-pill px-3 d-flex align-items-center gap-1" onclick="window.print()">
            <span class="material-symbols-rounded ms-sm">print</span>인쇄 / PDF
          </button>
        </div>
      </div>

      <!-- 기간 선택 -->
      <div class="card homes-card mb-4 no-print">
        <div class="card-body py-3">
          <form method="get" action="${pageContext.request.contextPath}/financial/statement"
                id="periodForm" class="d-flex gap-2 align-items-center flex-wrap">
            <div class="btn-group">
              <input type="radio" class="btn-check" name="mode" value="monthly" id="modeM"
                     ${mode=='monthly'?'checked':''} onchange="switchMode('monthly')">
              <label class="btn btn-outline-primary btn-sm" for="modeM">월간</label>
              <input type="radio" class="btn-check" name="mode" value="annual" id="modeA"
                     ${mode=='annual'?'checked':''} onchange="switchMode('annual')">
              <label class="btn btn-outline-primary btn-sm" for="modeA">연간</label>
            </div>
            <!-- 월간 입력 -->
            <input type="month" id="inpMonth" name="period"
                   value="${mode=='monthly' ? period.substring(0,4).concat('-').concat(period.substring(4,6)) : ''}"
                   class="form-control form-control-sm" style="width:150px; ${mode=='annual'?'display:none':''}"
                   onchange="this.form.submit()">
            <!-- 연간 입력 -->
            <input type="number" id="inpYear" name="period"
                   value="${mode=='annual' ? period : ''}"
                   min="2000" max="2099" class="form-control form-control-sm" style="width:100px; ${mode=='monthly'?'display:none':''}"
                   onchange="this.form.submit()">
            <button class="btn btn-primary btn-sm homes-pill px-3">조회</button>
          </form>
        </div>
      </div>

      <!-- 기간 표시 -->
      <div class="d-flex align-items-center gap-2 mb-3 flex-wrap">
        <span class="homes-badge">${mode=='monthly'?'월간':'연간'}</span>
        <h5 class="mb-0 fw-bold">${dispPeriod}</h5>
        <c:if test="${months>1}"><span class="text-muted small">(12개월 합산)</span></c:if>
        <c:choose>
          <c:when test="${useSnapshot}">
            <span class="badge bg-warning text-dark d-inline-flex align-items-center gap-1" style="font-size:11px;"><span class="material-symbols-rounded" style="font-size:12px;font-variation-settings:'FILL' 1,'wght' 400,'GRAD' 0,'opsz' 20;">push_pin</span>전표처리본</span>
          </c:when>
          <c:when test="${hasSnapshot}">
            <span class="badge bg-primary-subtle text-primary border" style="font-size:11px;">⚡ 최신본</span>
          </c:when>
        </c:choose>
      </div>

      <%-- ═══════════════════════════════════════════════════════
           ① 수지계정 손익계산서  ← 핵심
      ════════════════════════════════════════════════════════ --%>
      <div class="stmt-box">
        <div class="stmt-box-title d-flex align-items-center gap-1"><span class="material-symbols-rounded ms-sm">receipt_long</span>손익계산서 — 수지계정 기준</div>
        <table class="st">
          <thead>
            <tr>
              <th style="width:30%">수지계정</th>
              <th style="width:25%">수입원</th>
              <th class="text-end" style="width:15%">수입 (원)</th>
              <th class="text-end" style="width:15%">지출 (원)</th>
              <th class="text-end" style="width:15%">잔액 (원)</th>
            </tr>
          </thead>
          <tbody>
            <c:choose>
              <c:when test="${empty ccList}">
                <tr><td colspan="5" class="text-center text-muted py-4 fst-italic">등록된 수지계정가 없습니다.</td></tr>
              </c:when>
              <c:otherwise>
                <c:forEach var="cc" items="${ccList}" varStatus="st">
                  <c:set var="hasIncome"  value="${cc.totalIncomeAmt  > 0}"/>
                  <c:set var="hasExpense" value="${cc.totalExpenseAmt > 0}"/>
                  <c:set var="hasDetail"  value="${not empty plansByCC[cc.ccSeq] or not empty livingByCC[cc.ccSeq] or not empty manualIncListByCC[cc.ccSeq] or not empty manualExpListByCC[cc.ccSeq] or not empty cc.incomePlanNm}"/>
                  <%-- CC 요약 행 --%>
                  <tr class="cc-row" style="cursor:${hasDetail?'pointer':'default'};"
                      onclick="${hasDetail?'toggleDetail(this, '.concat(st.index).concat(')'):''}">
                    <td class="fw-semibold">
                      <c:if test="${hasDetail}">
                        <span class="toggle-arrow me-1" style="font-size:11px; color:#0ea5e9;">▼</span>
                      </c:if>
                      ${cc.ccNm}
                      <c:if test="${cc.ccType=='AUTO'}">
                        <span class="c-gray" style="font-size:10px;"> [자동]</span>
                      </c:if>
                    </td>
                    <td class="c-gray small">
                      <c:if test="${not empty cc.incomePlanNm}">${cc.incomePlanNm}<c:if test="${months>1}"> ×${months}</c:if></c:if>
                      <c:if test="${not empty manualIncomeByCC[cc.ccSeq] and manualIncomeByCC[cc.ccSeq]>0}">
                        <span class="manual-badge">+수기수입</span>
                      </c:if>
                      <c:if test="${not empty manualExpenseByCC[cc.ccSeq] and manualExpenseByCC[cc.ccSeq]>0}">
                        <span class="manual-badge" style="background:#fde8e8; color:#dc2626;">+수기지출</span>
                      </c:if>
                    </td>
                    <td class="text-end ${hasIncome?'c-pos':'c-gray'}">
                      <c:choose><c:when test="${hasIncome}"><fmt:formatNumber value="${cc.totalIncomeAmt}" pattern="#,##0"/></c:when>
                      <c:otherwise>—</c:otherwise></c:choose>
                    </td>
                    <td class="text-end ${hasExpense?'c-neg':'c-gray'}">
                      <c:choose><c:when test="${hasExpense}"><fmt:formatNumber value="${cc.totalExpenseAmt}" pattern="#,##0"/></c:when>
                      <c:otherwise>—</c:otherwise></c:choose>
                    </td>
                    <td class="text-end fw-semibold ${cc.balance>=0?'c-pos':'c-neg'}">
                      <fmt:formatNumber value="${cc.balance}" pattern="#,##0"/>
                    </td>
                  </tr>
                  <%-- CC 상세 행들 (기본 숨김) --%>
                  <c:if test="${hasDetail}">
                  <tr class="cc-detail-${st.index}">
                    <td colspan="5" style="padding:0; background:#fafbfc;">
                      <table style="width:100%; font-size:12px; border-collapse:collapse;">
                        <%-- 수입원 (정기수입 plan) --%>
                        <c:if test="${not empty cc.incomePlanNm}">
                          <tr style="border-bottom:1px solid #f1f5f9;">
                            <td style="padding:.35rem 1rem .35rem 2.5rem; color:#64748b; width:40%;">
                              <span style="color:#16a34a;">↗</span> ${cc.incomePlanNm}
                              <span style="color:#94a3b8; font-size:11px;">[정기수입<c:if test="${months>1}"> ×${months}</c:if>]</span>
                            </td>
                            <td style="padding:.35rem 1rem; text-align:right; color:#16a34a; width:20%;">
                              <fmt:formatNumber value="${cc.incomeMonthlyAmt * months}" pattern="#,##0"/>
                            </td>
                            <td style="width:20%;"></td>
                            <td style="width:20%;"></td>
                          </tr>
                        </c:if>
                        <%-- 수기 수입 --%>
                        <c:forEach var="mi" items="${manualIncListByCC[cc.ccSeq]}">
                          <tr style="border-bottom:1px solid #f1f5f9;">
                            <td style="padding:.35rem 1rem .35rem 2.5rem; color:#64748b;">
                              <span style="color:#16a34a;">↗</span>
                              <c:choose>
                                <c:when test="${not empty mi.title}"><c:out value="${mi.title}"/></c:when>
                                <c:otherwise>수기수입 (${mi.flowYymm.substring(0,4)}.${mi.flowYymm.substring(4,6)})</c:otherwise>
                              </c:choose>
                              <c:if test="${not empty mi.memo}"><span style="color:#94a3b8;"> — <c:out value="${mi.memo}"/></span></c:if>
                              <span style="color:#94a3b8; font-size:11px;">[수기·${mi.flowYymm.substring(0,4)}.${mi.flowYymm.substring(4,6)}]</span>
                            </td>
                            <td style="padding:.35rem 1rem; text-align:right; color:#16a34a;">
                              <fmt:formatNumber value="${mi.actualAmt}" pattern="#,##0"/>
                            </td>
                            <td></td><td></td>
                          </tr>
                        </c:forEach>
                        <%-- 정기지출·저축·투자 --%>
                        <c:forEach var="plan" items="${plansByCC[cc.ccSeq]}">
                          <tr style="border-bottom:1px solid #f1f5f9;">
                            <td style="padding:.35rem 1rem .35rem 2.5rem; color:#64748b;">
                              <span style="color:#dc2626;">↘</span> ${plan.planNm}
                              <span style="color:#94a3b8; font-size:11px;">
                                [<c:choose>
                                  <c:when test="${plan.flowType=='SAVING'}">저축</c:when>
                                  <c:when test="${plan.flowType=='INVEST'}">투자</c:when>
                                  <c:otherwise>정기지출</c:otherwise>
                                </c:choose><c:if test="${months>1}"> ×${months}</c:if>]
                              </span>
                            </td>
                            <td></td>
                            <td style="padding:.35rem 1rem; text-align:right; color:#dc2626;">
                              <fmt:formatNumber value="${plan.amount * months}" pattern="#,##0"/>
                            </td>
                            <td></td>
                          </tr>
                        </c:forEach>
                        <%-- 생활비 항목 --%>
                        <c:forEach var="lv" items="${livingByCC[cc.ccSeq]}">
                          <tr style="border-bottom:1px solid #f1f5f9;">
                            <td style="padding:.35rem 1rem .35rem 2.5rem; color:#64748b;">
                              <span style="color:#dc2626;">↘</span> ${lv.itemNm}
                              <span style="color:#94a3b8; font-size:11px;">[생활비·${lv.catNm}]</span>
                            </td>
                            <td></td>
                            <td style="padding:.35rem 1rem; text-align:right; color:#dc2626;">
                              <fmt:formatNumber value="${lv.budgetAmt}" pattern="#,##0"/>
                              <span style="color:#94a3b8;">(예산)</span>
                            </td>
                            <td></td>
                          </tr>
                        </c:forEach>
                        <%-- 수기 지출 --%>
                        <c:forEach var="me" items="${manualExpListByCC[cc.ccSeq]}">
                          <tr style="border-bottom:1px solid #f1f5f9;">
                            <td style="padding:.35rem 1rem .35rem 2.5rem; color:#64748b;">
                              <span style="color:#dc2626;">↘</span>
                              <c:choose>
                                <c:when test="${not empty me.title}"><c:out value="${me.title}"/></c:when>
                                <c:otherwise>수기지출 (${me.flowYymm.substring(0,4)}.${me.flowYymm.substring(4,6)})</c:otherwise>
                              </c:choose>
                              <c:if test="${not empty me.memo}"><span style="color:#94a3b8;"> — <c:out value="${me.memo}"/></span></c:if>
                              <span style="color:#94a3b8; font-size:11px;">[수기·${me.flowYymm.substring(0,4)}.${me.flowYymm.substring(4,6)}]</span>
                            </td>
                            <td></td>
                            <td style="padding:.35rem 1rem; text-align:right; color:#dc2626;">
                              <fmt:formatNumber value="${me.actualAmt}" pattern="#,##0"/>
                            </td>
                            <td></td>
                          </tr>
                        </c:forEach>
                      </table>
                    </td>
                  </tr>
                  </c:if>
                </c:forEach>
              </c:otherwise>
            </c:choose>

            <%-- 합계 행 --%>
            <tr style="background:#f8fafc; font-weight:700; border-top:2px solid #e2e8f0;">
              <td colspan="2">합 계</td>
              <td class="text-end c-pos fs-6">
                <fmt:formatNumber value="${ccIncomeTotal}" pattern="#,##0"/>
              </td>
              <td class="text-end c-neg fs-6">
                <fmt:formatNumber value="${ccExpenseTotal}" pattern="#,##0"/>
              </td>
              <td class="text-end fs-6 ${ccNetBalance>=0?'c-pos':'c-neg'}">
                <fmt:formatNumber value="${ccNetBalance}" pattern="#,##0"/>
              </td>
            </tr>
          </tbody>
        </table>

        <%-- 순손익 강조 --%>
        <div class="net-bar m-3"
             style="background:${ccNetBalance>=0?'#f0fdf4':'#fef2f2'}; border-color:${ccNetBalance>=0?'#86efac':'#fca5a5'};">
          <div>
            <div class="fw-bold" style="font-size:15px;">순손익 (수입 − 지출)</div>
            <div class="text-muted small">${dispPeriod} · 수지계정 기준</div>
          </div>
          <div class="fw-bold" style="font-size: 1.5rem; color:${ccNetBalance>=0?'#16a34a':'#dc2626'}">
            ${ccNetBalance>=0?'+':''}<fmt:formatNumber value="${ccNetBalance}" pattern="#,##0"/> 원
          </div>
        </div>
      </div>

      <%-- ═══════════════════════════════════════════════════════
           ② 재무상태표 (자산 현황)
      ════════════════════════════════════════════════════════ --%>
      <div class="stmt-box">
        <div class="stmt-box-title d-flex align-items-center gap-1"><span class="material-symbols-rounded ms-sm">account_balance</span>재무상태표 — 현재 기준 (순자산)</div>
        <div class="row g-0">
          <div class="col-12 col-md-6" style="border-right:1px solid #e2e8f0;">
            <table class="st">
              <thead><tr><th colspan="2">자산</th></tr></thead>
              <tbody>
                <c:if test="${empty assetList}">
                  <tr><td colspan="2" class="text-center c-gray py-3 fst-italic">자산 없음</td></tr>
                </c:if>
                <c:set var="liquidTotal" value="0"/>
                <c:forEach var="a" items="${assetList}">
                  <c:if test="${a.liquidYn=='Y'}"><c:set var="liquidTotal" value="${liquidTotal+a.amount}"/></c:if>
                </c:forEach>
                <c:if test="${liquidTotal>0}">
                  <tr class="grp"><td colspan="2">유동자산</td></tr>
                  <c:forEach var="a" items="${assetList}">
                    <c:if test="${a.liquidYn=='Y'}">
                      <tr class="sub">
                        <td>${a.assetNm}</td>
                        <td class="text-end c-pos"><fmt:formatNumber value="${a.amount}" pattern="#,##0"/></td>
                      </tr>
                    </c:if>
                  </c:forEach>
                </c:if>
                <c:set var="fixedTotal" value="0"/>
                <c:forEach var="a" items="${assetList}">
                  <c:if test="${a.liquidYn!='Y'}"><c:set var="fixedTotal" value="${fixedTotal+a.amount}"/></c:if>
                </c:forEach>
                <c:if test="${fixedTotal>0}">
                  <tr class="grp"><td colspan="2">비유동자산</td></tr>
                  <c:forEach var="a" items="${assetList}">
                    <c:if test="${a.liquidYn!='Y'}">
                      <tr class="sub">
                        <td>${a.assetNm}</td>
                        <td class="text-end c-pos"><fmt:formatNumber value="${a.amount}" pattern="#,##0"/></td>
                      </tr>
                    </c:if>
                  </c:forEach>
                </c:if>
                <tr class="tot">
                  <td>자산 합계</td>
                  <td class="text-end c-pos"><fmt:formatNumber value="${summary.totalAssetAmount}" pattern="#,##0"/> 원</td>
                </tr>
              </tbody>
            </table>
          </div>
          <div class="col-12 col-md-6">
            <table class="st">
              <thead><tr><th colspan="2">부채</th></tr></thead>
              <tbody>
                <c:choose>
                  <c:when test="${empty loanList}">
                    <tr><td colspan="2" class="text-center c-gray py-3 fst-italic">부채 없음</td></tr>
                  </c:when>
                  <c:otherwise>
                    <c:forEach var="loan" items="${loanList}">
                      <tr class="sub">
                        <td>${loan.loanNm}</td>
                        <td class="text-end c-neg"><fmt:formatNumber value="${loan.currentBalance}" pattern="#,##0"/></td>
                      </tr>
                    </c:forEach>
                  </c:otherwise>
                </c:choose>
                <tr class="tot-exp">
                  <td>부채 합계</td>
                  <td class="text-end c-neg"><fmt:formatNumber value="${summary.totalLoanBalance}" pattern="#,##0"/> 원</td>
                </tr>
              </tbody>
            </table>
            <div class="p-3 d-flex justify-content-between align-items-center"
                 style="background:#eff6ff; border-top:2px solid #bfdbfe;">
              <span class="fw-bold">순자산 (자산 − 부채)</span>
              <span class="fw-bold fs-5 ${summary.netAssetAmount>=0?'c-pos':'c-neg'}">
                <fmt:formatNumber value="${summary.netAssetAmount}" pattern="#,##0"/> 원
              </span>
            </div>
          </div>
        </div>
      </div>

      <%-- ═══════════════════════════════════════════════════════
           ③ 참고자료
      ════════════════════════════════════════════════════════ --%>
      <div class="stmt-box-title mb-2" style="border-radius:8px; border:1px dashed #cbd5e1; background:#f8fafc;">
        <span class="material-symbols-rounded ms-sm">attach_file</span>추가정보 <span class="badge-ref">수지계정 미 지정시 손익계산 별도 관리 </span>
      </div>

      <%-- 수기 등록 수입 (수지계정별) --%>
      <c:if test="${not empty incomeEntries}">
      <div class="ref-section">
        <button class="ref-toggle" onclick="toggleRef(this)">
          <span class="d-flex align-items-center gap-1"><span class="material-symbols-rounded ms-sm" style="color:#16a34a;">add_circle</span>수기 등록 수입 상세 (${incomeEntries.size()}건 · 수지계정별 손익에 포함됨)</span>
          <span class="ref-arrow">▲</span>
        </button>
        <div class="ref-body">
          <table class="st">
            <thead><tr><th>수지계정</th><th>제목</th><th>년월</th><th class="text-end">금액 (원)</th><th>메모</th></tr></thead>
            <tbody>
              <c:forEach var="inc" items="${incomeEntries}">
                <tr>
                  <td><c:out value="${inc.ccNm}"/></td>
                  <td class="fw-semibold"><c:out value="${inc.title}"/></td>
                  <td class="c-gray small">${inc.flowYymm.substring(0,4)}년 ${inc.flowYymm.substring(4,6)}월</td>
                  <td class="text-end c-pos"><fmt:formatNumber value="${inc.actualAmt}" pattern="#,##0"/></td>
                  <td class="c-gray small"><c:out value="${inc.memo}"/></td>
                </tr>
              </c:forEach>
            </tbody>
          </table>
        </div>
      </div>
      </c:if>

      <%-- 정기수입 --%>
      <div class="ref-section">
        <button class="ref-toggle" onclick="toggleRef(this)">
          <span class="d-flex align-items-center gap-1"><span class="material-symbols-rounded ms-sm">move_to_inbox</span>정기수입 계획 (${incomePlans.size()}건
            <c:if test="${months>1}"> · ×${months}개월</c:if>)</span>
          <span class="ref-arrow">▲</span>
        </button>
        <div class="ref-body">
          <c:choose>
            <c:when test="${empty incomePlans}">
              <p class="text-center c-gray py-3 fst-italic mb-0">데이터 없음</p>
            </c:when>
            <c:otherwise>
              <table class="st">
                <thead><tr><th>항목명</th><th>유형</th><th class="text-end">월 금액</th><th class="text-end">기간 합계</th></tr></thead>
                <tbody>
                  <c:set var="ipTotal" value="0"/>
                  <c:forEach var="p" items="${incomePlans}">
                    <c:set var="ipTotal" value="${ipTotal + p.amount * months}"/>
                    <tr>
                      <td>${p.planNm}</td>
                      <td class="c-gray small">${p.planTypeNm}</td>
                      <td class="text-end"><fmt:formatNumber value="${p.amount}" pattern="#,##0"/></td>
                      <td class="text-end c-pos"><fmt:formatNumber value="${p.amount * months}" pattern="#,##0"/></td>
                    </tr>
                  </c:forEach>
                  <tr class="tot"><td colspan="3" class="text-end">합계</td>
                    <td class="text-end c-pos"><fmt:formatNumber value="${ipTotal}" pattern="#,##0"/></td></tr>
                </tbody>
              </table>
            </c:otherwise>
          </c:choose>
        </div>
      </div>

      <%-- 정기지출 (EXPENSE/SAVING/INVEST 통합) --%>
      <div class="ref-section">
        <button class="ref-toggle" onclick="toggleRef(this)">
          <span class="d-flex align-items-center gap-1"><span class="material-symbols-rounded ms-sm">outbox</span>정기지출·저축·투자 계획 (${expensePlans.size() + savingPlans.size() + investPlans.size()}건
            <c:if test="${months>1}"> · ×${months}개월</c:if>)</span>
          <span class="ref-arrow">▲</span>
        </button>
        <div class="ref-body">
          <c:set var="anyExpense" value="${not empty expensePlans or not empty savingPlans or not empty investPlans}"/>
          <c:choose>
            <c:when test="${!anyExpense}">
              <p class="text-center c-gray py-3 fst-italic mb-0">데이터 없음</p>
            </c:when>
            <c:otherwise>
              <table class="st">
                <thead><tr><th>항목명</th><th>구분</th><th class="text-end">월 금액</th><th class="text-end">기간 합계</th></tr></thead>
                <tbody>
                  <c:set var="epTotal" value="0"/>
                  <c:if test="${not empty expensePlans}">
                    <tr class="grp"><td colspan="4">정기지출</td></tr>
                    <c:forEach var="p" items="${expensePlans}">
                      <c:set var="epTotal" value="${epTotal + p.amount * months}"/>
                      <tr class="sub"><td>${p.planNm}</td><td class="c-gray small">${p.planTypeNm}</td>
                        <td class="text-end"><fmt:formatNumber value="${p.amount}" pattern="#,##0"/></td>
                        <td class="text-end c-neg"><fmt:formatNumber value="${p.amount * months}" pattern="#,##0"/></td></tr>
                    </c:forEach>
                  </c:if>
                  <c:if test="${not empty savingPlans}">
                    <tr class="grp"><td colspan="4">저축</td></tr>
                    <c:forEach var="p" items="${savingPlans}">
                      <c:set var="epTotal" value="${epTotal + p.amount * months}"/>
                      <tr class="sub"><td>${p.planNm}</td><td class="c-gray small">${p.planTypeNm}</td>
                        <td class="text-end"><fmt:formatNumber value="${p.amount}" pattern="#,##0"/></td>
                        <td class="text-end c-blue"><fmt:formatNumber value="${p.amount * months}" pattern="#,##0"/></td></tr>
                    </c:forEach>
                  </c:if>
                  <c:if test="${not empty investPlans}">
                    <tr class="grp"><td colspan="4">투자</td></tr>
                    <c:forEach var="p" items="${investPlans}">
                      <c:set var="epTotal" value="${epTotal + p.amount * months}"/>
                      <tr class="sub"><td>${p.planNm}</td><td class="c-gray small">${p.planTypeNm}</td>
                        <td class="text-end"><fmt:formatNumber value="${p.amount}" pattern="#,##0"/></td>
                        <td class="text-end c-blue"><fmt:formatNumber value="${p.amount * months}" pattern="#,##0"/></td></tr>
                    </c:forEach>
                  </c:if>
                  <tr class="tot-exp"><td colspan="3" class="text-end">합계</td>
                    <td class="text-end c-neg"><fmt:formatNumber value="${epTotal}" pattern="#,##0"/></td></tr>
                </tbody>
              </table>
            </c:otherwise>
          </c:choose>
        </div>
      </div>

      <%-- 생활비 예산 vs 실적 --%>
      <c:if test="${not empty livingExpenses}">
      <div class="ref-section">
        <button class="ref-toggle" onclick="toggleRef(this)">
          <span class="d-flex align-items-center gap-1"><span class="material-symbols-rounded ms-sm">home</span>생활비 예산 vs 실적 (${dispPeriod})</span>
          <span class="ref-arrow">▲</span>
        </button>
        <div class="ref-body">
          <table class="st">
            <thead>
              <tr>
                <th>카테고리</th>
                <th class="text-end">예산</th>
                <th class="text-end">실적</th>
                <th class="text-end">차이</th>
                <th class="text-end" style="width:80px;">달성률</th>
              </tr>
            </thead>
            <tbody>
              <c:set var="lb" value="0"/><c:set var="la" value="0"/>
              <c:forEach var="e" items="${livingExpenses}">
                <c:if test="${e.totalBudgetAmt > 0}">
                  <c:set var="diff" value="${e.totalActualAmt - e.totalBudgetAmt}"/>
                  <c:set var="rate" value="${e.totalBudgetAmt>0 ? (e.totalActualAmt*100/e.totalBudgetAmt) : 0}"/>
                  <c:set var="lb" value="${lb + e.totalBudgetAmt}"/>
                  <c:set var="la" value="${la + e.totalActualAmt}"/>
                  <tr>
                    <td>${e.catNm}</td>
                    <td class="text-end"><fmt:formatNumber value="${e.totalBudgetAmt}" pattern="#,##0"/></td>
                    <td class="text-end ${e.totalActualAmt>e.totalBudgetAmt?'c-neg':'c-pos'}">
                      <c:choose>
                        <c:when test="${e.totalActualAmt>0}"><fmt:formatNumber value="${e.totalActualAmt}" pattern="#,##0"/></c:when>
                        <c:otherwise><span class="c-gray">미입력</span></c:otherwise>
                      </c:choose>
                    </td>
                    <td class="text-end ${diff>0?'c-neg':'c-pos'}">
                      ${diff>0?'+':''}<fmt:formatNumber value="${diff}" pattern="#,##0"/>
                    </td>
                    <td class="text-end">
                      <div class="progress" style="height:5px;">
                        <div class="progress-bar ${rate>100?'bg-danger':rate>80?'bg-warning':'bg-success'}"
                             style="width:${rate>100?100:rate}%"></div>
                      </div>
                      <small class="${rate>100?'c-neg':'c-gray'}">${rate}%</small>
                    </td>
                  </tr>
                </c:if>
              </c:forEach>
              <tr class="tot">
                <td>합계</td>
                <td class="text-end"><fmt:formatNumber value="${lb}" pattern="#,##0"/></td>
                <td class="text-end ${la>lb?'c-neg':'c-pos'}"><fmt:formatNumber value="${la}" pattern="#,##0"/></td>
                <c:set var="ld" value="${la-lb}"/>
                <td class="text-end ${ld>0?'c-neg':'c-pos'}">${ld>0?'+':''}<fmt:formatNumber value="${ld}" pattern="#,##0"/></td>
                <td></td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
      </c:if>

      <!-- 인쇄 안내 -->
      <div class="alert alert-light border no-print mt-2" style="font-size:12px;">
        <span class="material-symbols-rounded ms-sm">lightbulb</span> <strong>[인쇄 / PDF]</strong>를 누르면 브라우저 인쇄창이 열립니다.
        PDF 저장은 프린터에서 <strong>"PDF로 저장"</strong>을 선택하세요.
      </div>

    </div><%-- stmt-wrap --%>
    </div><%-- homes-main-body --%>
    <%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
  </main>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
function doSnapshot() {
  const period = '${period}';
  const disp   = '${dispPeriod}';
  if (!confirm(disp + ' 전표처리를 진행하시겠습니까?\n이미 처리된 경우 덮어씁니다.')) return;

  const btn = document.getElementById('snapshotBtn');
  btn.disabled = true;
  btn.textContent = '처리 중...';

  fetch('${pageContext.request.contextPath}/asset/snapshot/' + period, { method: 'POST' })
    .then(r => r.json())
    .then(res => {
      if (res.success) {
        btn.textContent = res.message;
        btn.classList.replace('btn-outline-primary', 'btn-success');
        // 전표처리 완료 후 페이지 새로고침해서 토글 버튼 표시
        setTimeout(() => {
          location.href = location.pathname + '?mode=${mode}&period=${period}&viewMode=snapshot';
        }, 1000);
      } else {
        alert('전표처리 실패: ' + res.message);
        btn.disabled = false;
        btn.innerHTML = '<span class="material-symbols-rounded ms-sm">push_pin</span>전표처리';
      }
    })
    .catch(() => {
      alert('전표처리 중 오류가 발생했습니다.');
      btn.disabled = false;
      btn.innerHTML = '<span class="material-symbols-rounded ms-sm">push_pin</span>전표처리';
    });
}

function switchMode(mode) {
  const mEl = document.getElementById('inpMonth');
  const aEl = document.getElementById('inpYear');
  if (mode === 'annual') {
    mEl.style.display = 'none'; mEl.name = '';
    aEl.style.display = '';     aEl.name = 'period';
  } else {
    aEl.style.display = 'none'; aEl.name = '';
    mEl.style.display = '';     mEl.name = 'period';
  }
}

// 월간 제출 시 YYYY-MM → YYYYMM 변환
document.getElementById('periodForm').addEventListener('submit', function() {
  const mEl = document.getElementById('inpMonth');
  if (mEl.style.display !== 'none' && mEl.value && mEl.value.includes('-')) {
    mEl.value = mEl.value.replace('-', '');
  }
});

function toggleRef(btn) {
  const body  = btn.nextElementSibling;
  const arrow = btn.querySelector('.ref-arrow');
  const closing = body.classList.toggle('closed');
  arrow.textContent = closing ? '▼' : '▲';
}

function toggleDetail(row, idx) {
  const details = document.querySelectorAll('.cc-detail-' + idx);
  const arrow   = row.querySelector('.toggle-arrow');
  const isOpen  = details[0] && details[0].style.display !== 'none';
  details.forEach(d => d.style.display = isOpen ? 'none' : '');
  if (arrow) arrow.textContent = isOpen ? '▶' : '▼';
  if (arrow) arrow.style.color = isOpen ? '#94a3b8' : '#0ea5e9';
}

// 페이지 로드 시 ref-toggle의 border-radius 조정 (열린 상태)
document.querySelectorAll('.ref-toggle').forEach(btn => {
  btn.style.borderRadius = '10px 10px 0 0';
});
</script>
</body>
</html>
