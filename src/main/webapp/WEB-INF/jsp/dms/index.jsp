<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<!doctype html>
<html lang="ko">
<head>
  <%@ include file="/WEB-INF/jsp/common/head.jsp" %>
  <style>
    /* ══════════════════════════════════════════════
       DMS – Google Drive style
    ══════════════════════════════════════════════ */
    .dms-shell        { display:flex; height:calc(100vh - 56px); overflow:hidden; }
    .dms-left         { width:220px; flex-shrink:0; border-right:1px solid #e5e7eb;
                        background:#f9fafb; overflow-y:auto; padding:12px 0; }
    .dms-right        { flex:1; display:flex; flex-direction:column; overflow:hidden; }
    .dms-topbar       { display:flex; align-items:center; gap:8px; padding:10px 16px;
                        border-bottom:1px solid #e5e7eb; background:#fff; flex-shrink:0; }
    .dms-content      { flex:1; overflow-y:auto; padding:16px; }
    .dms-quota-bar    { height:6px; background:#e5e7eb; border-radius:3px; overflow:hidden; margin-top:2px; }
    .dms-quota-fill   { height:100%; border-radius:3px; background:#3b82f6; transition:width .4s; }
    .dms-quota-fill.warn  { background:#f59e0b; }
    .dms-quota-fill.danger{ background:#ef4444; }

    /* 폴더 트리 */
    .tree-item        { display:flex; align-items:center; gap:6px; padding:5px 12px;
                        cursor:pointer; font-size:13px; color:#374151; border-radius:6px; margin:1px 6px;
                        white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
    .tree-item:hover  { background:#eff6ff; }
    .tree-item.active { background:#dbeafe; color:#1d4ed8; font-weight:600; }
    .tree-children    { padding-left:12px; }
    .tree-toggle      { width:14px; text-align:center; flex-shrink:0; font-size:11px; }
    .tree-icon        { font-size:14px; flex-shrink:0; }
    .tree-root        { padding:6px 16px 4px; font-size:11px; font-weight:600;
                        color:#9ca3af; text-transform:uppercase; letter-spacing:.5px; }

    /* breadcrumb */
    .dms-breadcrumb   { display:flex; align-items:center; gap:4px; flex-wrap:wrap; flex:1; }
    .dms-bc-item      { font-size:14px; color:#6b7280; cursor:pointer; padding:2px 4px;
                        border-radius:4px; }
    .dms-bc-item:hover{ background:#f3f4f6; color:#1f2937; }
    .dms-bc-item.current { color:#1f2937; font-weight:600; cursor:default; }
    .dms-bc-item.current:hover { background:none; }
    .dms-bc-sep       { color:#d1d5db; font-size:13px; }

    /* 그리드 */
    .dms-grid         { display:grid;
                        grid-template-columns: repeat(auto-fill, minmax(130px, 1fr));
                        gap:12px; }
    .dms-card         { background:#fff; border:1px solid #e5e7eb; border-radius:10px;
                        padding:14px 10px; text-align:center; cursor:pointer;
                        transition:all .15s; position:relative; user-select:none; }
    .dms-card:hover   { border-color:#93c5fd; box-shadow:0 2px 8px rgba(59,130,246,.12); }
    .dms-card.selected{ border-color:#3b82f6; background:#eff6ff; }
    .dms-card-icon    { font-size:36px; line-height:1; margin-bottom:8px; }
    .dms-card-name    { font-size:12px; color:#1f2937; word-break:break-all;
                        display:-webkit-box; -webkit-line-clamp:2; -webkit-box-orient:vertical;
                        overflow:hidden; line-height:1.3; }
    .dms-card-meta    { font-size:10px; color:#9ca3af; margin-top:4px; }
    .dms-card-actions { position:absolute; top:6px; right:6px; display:none; gap:3px; }
    .dms-card:hover .dms-card-actions { display:flex; }
    .dms-act-btn      { width:24px; height:24px; border:none; border-radius:4px; background:#f3f4f6;
                        font-size:12px; cursor:pointer; display:flex; align-items:center; justify-content:center; }
    .dms-act-btn:hover{ background:#dbeafe; }

    /* 빈 상태 */
    .dms-empty        { text-align:center; padding:60px 20px; color:#9ca3af; }
    .dms-empty-icon   { font-size:48px; margin-bottom:12px; }

    /* 드래그 오버 */
    .dms-content.dragover { background:#eff6ff; outline:2px dashed #3b82f6; outline-offset:-4px; }

    /* 업로드 진행 */
    .upload-progress  { position:fixed; bottom:20px; right:20px; width:280px;
                        background:#fff; border:1px solid #e5e7eb; border-radius:12px;
                        box-shadow:0 4px 20px rgba(0,0,0,.12); padding:14px 16px; z-index:9999;
                        display:none; }
    .upload-progress.show { display:block; }

    /* 뷰어 모달 */
    #viewerModal .modal-dialog { max-width:90vw; max-height:90vh; }
    #viewerModal .modal-body   { padding:0; overflow:hidden; }
    #viewerModal .viewer-wrap  { width:100%; height:75vh; display:flex;
                                 align-items:center; justify-content:center;
                                 background:#000; overflow:auto; }
    #viewerModal .viewer-wrap img { max-width:100%; max-height:75vh; object-fit:contain; }
    #viewerModal .viewer-wrap iframe { width:100%; height:75vh; border:none; }
    #viewerModal .viewer-wrap video,
    #viewerModal .viewer-wrap audio { max-width:100%; }
    #viewerModal .viewer-wrap pre { color:#e5e7eb; padding:16px; font-size:13px; max-height:75vh;
                                    overflow:auto; width:100%; }

    /* 모바일 */
    @media (max-width:767px) {
      .dms-left { display:none; }
      .dms-grid { grid-template-columns: repeat(auto-fill, minmax(100px, 1fr)); gap:8px; }
    }
  </style>
</head>
<body class="homes-bg" style="overflow:hidden;">
  <%@ include file="/WEB-INF/jsp/common/header.jsp" %>

  <div class="homes-shell d-lg-flex" style="height:calc(100vh - 56px); overflow:hidden;">
    <%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

    <!-- DMS 레이아웃 -->
    <main class="flex-grow-1 d-flex flex-column" style="overflow:hidden;">
      <div class="dms-shell">

        <!-- ═══ 왼쪽 폴더 트리 ═══ -->
        <div class="dms-left">
          <div class="tree-root">Drive</div>
          <div class="tree-item active" onclick="navigate(null)" id="tree-root-item">
            <span class="tree-icon material-symbols-rounded ms-btn">home</span>
            <span>내 드라이브</span>
          </div>
          <div id="folderTree" class="tree-children"></div>

          <!-- 쿼터 -->
          <div style="padding:16px 14px 0; margin-top:auto;">
            <div style="font-size:11px; color:#6b7280; margin-bottom:4px;">
              저장공간 <strong id="quotaUsed">${quota.usedText}</strong> / ${quota.totalText}
            </div>
            <div class="dms-quota-bar">
              <div class="dms-quota-fill <c:if test="${quota.usedPct >= 90}">danger</c:if><c:if test="${quota.usedPct >= 70 && quota.usedPct < 90}">warn</c:if>"
                   id="quotaFill" style="width:${quota.usedPct}%"></div>
            </div>
            <div style="font-size:10px; color:#9ca3af; margin-top:2px;">${quota.usedPct}% 사용중</div>
          </div>
        </div>

        <!-- ═══ 오른쪽 컨텐츠 ═══ -->
        <div class="dms-right">

          <!-- 상단 바 -->
          <div class="dms-topbar">
            <!-- breadcrumb -->
            <div class="dms-breadcrumb">
              <span class="dms-bc-item" onclick="navigate(null)">내 드라이브</span>
              <c:forEach var="crumb" items="${breadcrumb}">
                <span class="dms-bc-sep">›</span>
                <c:choose>
                  <c:when test="${crumb.folderSeq == currentFolderSeq}">
                    <span class="dms-bc-item current">${crumb.folderNm}</span>
                  </c:when>
                  <c:otherwise>
                    <span class="dms-bc-item" onclick="navigate(${crumb.folderSeq})">${crumb.folderNm}</span>
                  </c:otherwise>
                </c:choose>
              </c:forEach>
            </div>

            <!-- 버튼들 -->
            <button class="btn btn-primary btn-sm homes-pill px-3 d-flex align-items-center gap-1" onclick="showCreateFolder()">
              <span class="material-symbols-rounded ms-sm">create_new_folder</span>새 폴더
            </button>
            <label class="btn btn-outline-primary btn-sm homes-pill px-3 mb-0 d-flex align-items-center gap-1" style="cursor:pointer;">
              <span class="material-symbols-rounded ms-sm">upload</span>업로드
              <input type="file" id="fileInput" multiple hidden onchange="handleFileSelect(this.files)">
            </label>
          </div>

          <!-- 파일/폴더 그리드 -->
          <div class="dms-content" id="dmsContent"
               ondragover="event.preventDefault(); this.classList.add('dragover')"
               ondragleave="this.classList.remove('dragover')"
               ondrop="handleDrop(event)">

            <c:if test="${empty folders && empty files}">
              <div class="dms-empty">
                <div class="dms-empty-icon"><span class="material-symbols-rounded ms-lg">folder_open</span></div>
                <div style="font-weight:600; color:#6b7280;">폴더가 비어있습니다</div>
                <div class="small mt-1">파일을 드래그하거나 업로드 버튼을 눌러 추가하세요</div>
              </div>
            </c:if>

            <div class="dms-grid" id="dmsGrid">

              <!-- 폴더 카드 -->
              <c:forEach var="folder" items="${folders}">
                <div class="dms-card" id="folder-card-${folder.folderSeq}"
                     ondblclick="navigate(${folder.folderSeq})"
                     onclick="selectCard(this)">
                  <div class="dms-card-actions">
                    <button class="dms-act-btn" title="이름 변경"
                            onclick="event.stopPropagation(); renameFolder(${folder.folderSeq}, '${folder.folderNm}')">
                      <span class="material-symbols-rounded ms-sm">edit</span></button>
                    <button class="dms-act-btn" title="삭제"
                            onclick="event.stopPropagation(); deleteFolder(${folder.folderSeq}, '${folder.folderNm}')">
                      <span class="material-symbols-rounded ms-sm">delete</span></button>
                  </div>
                  <div class="dms-card-icon"><span class="material-symbols-rounded" style="font-size:36px;font-variation-settings:'FILL' 1,'wght' 400,'GRAD' 0,'opsz' 48;color:#f59e0b;">folder</span></div>
                  <div class="dms-card-name">${folder.folderNm}</div>
                </div>
              </c:forEach>

              <!-- 파일 카드 -->
              <c:forEach var="file" items="${files}">
                <div class="dms-card" id="file-card-${file.fileSeq}"
                     ondblclick="openViewer(${file.fileSeq}, '${file.fileNm}', '${file.mimeType}', ${file.viewable})"
                     onclick="selectCard(this)"
                     title="${file.fileNm}&#10;크기: ${file.fileSizeText}&#10;업로더: ${file.regId}&#10;날짜: ${file.regDt}">
                  <div class="dms-card-actions">
                    <c:if test="${file.viewable}">
                      <button class="dms-act-btn" title="보기"
                              onclick="event.stopPropagation(); openViewer(${file.fileSeq}, '${file.fileNm}', '${file.mimeType}', true)">
                        <span class="material-symbols-rounded ms-sm">visibility</span></button>
                    </c:if>
                    <button class="dms-act-btn" title="이름 변경"
                            onclick="event.stopPropagation(); renameFile(${file.fileSeq}, '${file.fileNm}')">
                      <span class="material-symbols-rounded ms-sm">edit</span></button>
                    <button class="dms-act-btn" title="다운로드"
                            onclick="event.stopPropagation(); downloadFile(${file.fileSeq})">
                      <span class="material-symbols-rounded ms-sm">download</span></button>
                    <button class="dms-act-btn" title="삭제"
                            onclick="event.stopPropagation(); deleteFile(${file.fileSeq}, '${file.fileNm}')">
                      <span class="material-symbols-rounded ms-sm">delete</span></button>
                  </div>
                  <div class="dms-card-icon">${file.fileIcon}</div>
                  <div class="dms-card-name" id="file-nm-${file.fileSeq}">${file.fileNm}</div>
                  <div class="dms-card-meta">${file.fileSizeText} · ${file.regId}</div>
                </div>
              </c:forEach>

            </div>
          </div>
        </div>
      </div>
    </main>
  </div><!-- homes-shell -->

  <!-- ══════════ 업로드 진행 ══════════ -->
  <div class="upload-progress" id="uploadProgress">
    <div style="font-size:13px; font-weight:600; margin-bottom:8px;display:flex;align-items:center;gap:6px;">
      <span class="material-symbols-rounded ms-sm">upload</span>업로드 중...</div>
    <div style="font-size:12px; color:#6b7280;" id="uploadProgressText"></div>
    <div class="progress mt-2" style="height:6px;">
      <div class="progress-bar" id="uploadProgressBar" style="width:0%"></div>
    </div>
  </div>

  <!-- ══════════ 새 폴더 모달 ══════════ -->
  <div class="modal fade" id="createFolderModal" tabindex="-1">
    <div class="modal-dialog modal-sm modal-dialog-centered">
      <div class="modal-content">
        <div class="modal-header border-0 pb-0">
          <h6 class="modal-title fw-bold d-flex align-items-center gap-1"><span class="material-symbols-rounded ms-sm">create_new_folder</span>새 폴더 만들기</h6>
          <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
        </div>
        <div class="modal-body">
          <input type="text" class="form-control" id="newFolderName" placeholder="폴더 이름"
                 maxlength="100" onkeydown="if(event.key==='Enter') confirmCreateFolder()">
        </div>
        <div class="modal-footer border-0 pt-0">
          <button class="btn btn-secondary btn-sm" data-bs-dismiss="modal">취소</button>
          <button class="btn btn-primary btn-sm" onclick="confirmCreateFolder()">만들기</button>
        </div>
      </div>
    </div>
  </div>

  <!-- ══════════ 이름 변경 모달 ══════════ -->
  <div class="modal fade" id="renameFolderModal" tabindex="-1">
    <div class="modal-dialog modal-sm modal-dialog-centered">
      <div class="modal-content">
        <div class="modal-header border-0 pb-0">
          <h6 class="modal-title fw-bold d-flex align-items-center gap-1"><span class="material-symbols-rounded ms-sm">drive_file_rename_outline</span>폴더 이름 변경</h6>
          <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
        </div>
        <div class="modal-body">
          <input type="hidden" id="renameFolderSeq">
          <input type="text" class="form-control" id="renameFolderName" placeholder="새 이름"
                 maxlength="100" onkeydown="if(event.key==='Enter') confirmRenameFolder()">
        </div>
        <div class="modal-footer border-0 pt-0">
          <button class="btn btn-secondary btn-sm" data-bs-dismiss="modal">취소</button>
          <button class="btn btn-primary btn-sm" onclick="confirmRenameFolder()">변경</button>
        </div>
      </div>
    </div>
  </div>

  <!-- ══════════ 파일명 수정 모달 ══════════ -->
  <div class="modal fade" id="renameFileModal" tabindex="-1">
    <div class="modal-dialog modal-sm modal-dialog-centered">
      <div class="modal-content">
        <div class="modal-header border-0 pb-0">
          <h6 class="modal-title fw-bold d-flex align-items-center gap-1"><span class="material-symbols-rounded ms-sm">drive_file_rename_outline</span>파일 이름 변경</h6>
          <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
        </div>
        <div class="modal-body">
          <input type="hidden" id="renameFileSeq">
          <input type="text" class="form-control" id="renameFileName" placeholder="새 파일명"
                 maxlength="200" onkeydown="if(event.key==='Enter') confirmRenameFile()">
          <div class="form-text text-muted mt-1" id="renameFileInfo" style="font-size:11px;"></div>
        </div>
        <div class="modal-footer border-0 pt-0">
          <button class="btn btn-secondary btn-sm" data-bs-dismiss="modal">취소</button>
          <button class="btn btn-primary btn-sm" onclick="confirmRenameFile()">변경</button>
        </div>
      </div>
    </div>
  </div>

  <!-- ══════════ 파일 뷰어 모달 ══════════ -->
  <div class="modal fade" id="viewerModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered" style="max-width:90vw;">
      <div class="modal-content" style="background:#1f2937; border:none;">
        <div class="modal-header border-0 py-2 px-3">
          <span class="text-white fw-semibold small" id="viewerFileName" style="flex:1; overflow:hidden; text-overflow:ellipsis; white-space:nowrap;"></span>
          <div class="d-flex gap-2">
            <button class="btn btn-outline-light btn-sm d-flex align-items-center gap-1" id="viewerDownloadBtn" onclick="downloadFileFromViewer()">
              <span class="material-symbols-rounded ms-sm">download</span>다운로드</button>
            <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
          </div>
        </div>
        <div class="modal-body p-0">
          <div class="viewer-wrap" id="viewerWrap"></div>
        </div>
      </div>
    </div>
  </div>

  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

  <script>
  const CTX    = '${pageContext.request.contextPath}';
  let currentFolderSeq = <c:choose><c:when test="${currentFolderSeq != null}">${currentFolderSeq}</c:when><c:otherwise>null</c:otherwise></c:choose>;
  let viewerFileSeq = null;
  const TREE_DATA = ${treeJson};

  // ─── 네비게이션 ──────────────────────────────────────────────────
  function navigate(folderSeq) {
    const url = CTX + '/dms' + (folderSeq ? '?folderSeq=' + folderSeq : '');
    HOMES.go(url);
  }

  // ─── 카드 선택 ───────────────────────────────────────────────────
  function selectCard(el) {
    document.querySelectorAll('.dms-card.selected').forEach(c => c.classList.remove('selected'));
    el.classList.add('selected');
  }

  // ─── 폴더 트리 토글 ──────────────────────────────────────────────
  function toggleTree(folderSeq, el) {
    const children = document.getElementById('tree-children-' + folderSeq);
    if (!children) return;
    const isOpen = children.style.display !== 'none';
    children.style.display = isOpen ? 'none' : '';
    el.innerHTML = isOpen ? '<span class="material-symbols-rounded" style="font-size:13px;font-variation-settings:\'FILL\' 0,\'wght\' 400,\'GRAD\' 0,\'opsz\' 20;">chevron_right</span>'
                          : '<span class="material-symbols-rounded" style="font-size:13px;font-variation-settings:\'FILL\' 0,\'wght\' 400,\'GRAD\' 0,\'opsz\' 20;">expand_more</span>';
  }

  // ─── 새 폴더 ─────────────────────────────────────────────────────
  function showCreateFolder() {
    document.getElementById('newFolderName').value = '';
    new bootstrap.Modal(document.getElementById('createFolderModal')).show();
    setTimeout(() => document.getElementById('newFolderName').focus(), 400);
  }

  function confirmCreateFolder() {
    const nm = document.getElementById('newFolderName').value.trim();
    if (!nm) return;
    fetch(CTX + '/dms/folder/create', {
      method: 'POST',
      headers: {'Content-Type':'application/json'},
      body: JSON.stringify({folderNm: nm, parentSeq: currentFolderSeq})
    })
    .then(r => r.json())
    .then(d => {
      if (d.ok) { bootstrap.Modal.getInstance(document.getElementById('createFolderModal')).hide(); navigate(currentFolderSeq); }
      else alert(d.message || '오류 발생');
    });
  }

  // ─── 폴더 이름 변경 ──────────────────────────────────────────────
  function renameFolder(seq, currentName) {
    document.getElementById('renameFolderSeq').value = seq;
    document.getElementById('renameFolderName').value = currentName;
    new bootstrap.Modal(document.getElementById('renameFolderModal')).show();
    setTimeout(() => { const el = document.getElementById('renameFolderName'); el.focus(); el.select(); }, 400);
  }

  function confirmRenameFolder() {
    const seq = document.getElementById('renameFolderSeq').value;
    const nm  = document.getElementById('renameFolderName').value.trim();
    if (!nm) return;
    fetch(CTX + '/dms/folder/rename', {
      method: 'POST',
      headers: {'Content-Type':'application/json'},
      body: JSON.stringify({folderSeq: seq, folderNm: nm})
    })
    .then(r => r.json())
    .then(d => {
      if (d.ok) { bootstrap.Modal.getInstance(document.getElementById('renameFolderModal')).hide(); navigate(currentFolderSeq); }
      else alert(d.message || '오류 발생');
    });
  }

  // ─── 폴더 삭제 ───────────────────────────────────────────────────
  function deleteFolder(seq, nm) {
    if (!confirm('"' + nm + '" 폴더를 삭제하시겠습니까?\n하위 폴더와 파일이 모두 삭제됩니다.')) return;
    fetch(CTX + '/dms/folder/' + seq, {method:'DELETE'})
    .then(r => r.json())
    .then(d => { if (d.ok) navigate(currentFolderSeq); else alert(d.message); });
  }

  // ─── 파일명 수정 ─────────────────────────────────────────────────
  function renameFile(seq, currentName) {
    document.getElementById('renameFileSeq').value  = seq;
    document.getElementById('renameFileName').value = currentName;
    document.getElementById('renameFileInfo').textContent = '로딩 중...';
    new bootstrap.Modal(document.getElementById('renameFileModal')).show();
    // 파일 정보 (업로더·날짜) 비동기 로드
    fetch(CTX + '/dms/file/' + seq + '/info')
      .then(r => r.json())
      .then(d => {
        if (d.ok) {
          document.getElementById('renameFileInfo').textContent =
            '업로더: ' + d.regId + '  |  ' + d.regDt + '  |  ' + d.fileSize;
        } else {
          document.getElementById('renameFileInfo').textContent = '';
        }
      })
      .catch(() => { document.getElementById('renameFileInfo').textContent = ''; });
    setTimeout(() => {
      const el = document.getElementById('renameFileName');
      el.focus();
      // 확장자 앞까지 선택
      const dot = el.value.lastIndexOf('.');
      el.setSelectionRange(0, dot > 0 ? dot : el.value.length);
    }, 400);
  }

  function confirmRenameFile() {
    const seq = document.getElementById('renameFileSeq').value;
    const nm  = document.getElementById('renameFileName').value.trim();
    if (!nm) return;
    fetch(CTX + '/dms/file/rename', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({fileSeq: seq, fileNm: nm})
    })
    .then(r => r.json())
    .then(d => {
      if (d.ok) {
        bootstrap.Modal.getInstance(document.getElementById('renameFileModal')).hide();
        // 카드 이름 즉시 갱신 (새로고침 없이)
        const nmEl = document.getElementById('file-nm-' + seq);
        if (nmEl) nmEl.textContent = d.fileNm;
        // title 속성도 업데이트
        const card = document.getElementById('file-card-' + seq);
        if (card) {
          const oldTitle = card.getAttribute('title') || '';
          card.setAttribute('title', oldTitle.replace(/^[^\n]*/, d.fileNm));
        }
      } else {
        alert(d.message || '이름 변경 실패');
      }
    });
  }

  // ─── 파일 삭제 ───────────────────────────────────────────────────
  function deleteFile(seq, nm) {
    if (!confirm('"' + nm + '" 파일을 삭제하시겠습니까?')) return;
    fetch(CTX + '/dms/file/' + seq, {method:'DELETE'})
    .then(r => r.json())
    .then(d => { if (d.ok) { updateQuota(d.quota); removeCard('file-card-' + seq); } else alert(d.message); });
  }

  function removeCard(id) {
    const el = document.getElementById(id);
    if (el) { el.style.transition='opacity .3s'; el.style.opacity='0'; setTimeout(() => el.remove(), 300); }
  }

  // ─── 다운로드 ─────────────────────────────────────────────────────
  function downloadFile(seq) {
    window.location.href = CTX + '/dms/file/' + seq + '/download';
  }
  function downloadFileFromViewer() {
    if (viewerFileSeq) downloadFile(viewerFileSeq);
  }

  // ─── 파일 뷰어 ───────────────────────────────────────────────────
  function openViewer(seq, nm, mimeType, viewable) {
    if (!viewable) { downloadFile(seq); return; }
    viewerFileSeq = seq;
    document.getElementById('viewerFileName').textContent = nm;
    const wrap = document.getElementById('viewerWrap');
    wrap.innerHTML = '<div class="text-white p-4">로딩 중...</div>';
    const url = CTX + '/dms/file/' + seq + '/view';

    if (mimeType && mimeType.startsWith('image/')) {
      wrap.innerHTML = '<img src="' + url + '" alt="' + escHtml(nm) + '">';
    } else if (mimeType === 'application/pdf') {
      wrap.innerHTML = '<iframe src="' + url + '"></iframe>';
    } else if (mimeType && mimeType.startsWith('video/')) {
      wrap.innerHTML = '<video controls style="max-width:100%;max-height:75vh;"><source src="' + url + '" type="' + mimeType + '">브라우저가 지원하지 않습니다.</video>';
    } else if (mimeType && mimeType.startsWith('audio/')) {
      wrap.innerHTML = '<audio controls style="margin:40px;"><source src="' + url + '" type="' + mimeType + '">브라우저가 지원하지 않습니다.</audio>';
    } else if (mimeType && mimeType.startsWith('text/')) {
      fetch(url).then(r => r.text()).then(txt => {
        wrap.innerHTML = '<pre>' + escHtml(txt) + '</pre>';
      });
    } else {
      wrap.innerHTML = '<div class="text-white p-4 text-center"><div><span class="material-symbols-rounded" style="font-size:52px;font-variation-settings:\'FILL\' 1,\'wght\' 300,\'GRAD\' 0,\'opsz\' 48;">description</span></div><div class="mt-2">' + escHtml(nm) + '</div><div class="mt-3"><a href="' + CTX + '/dms/file/' + seq + '/download" class="btn btn-outline-light btn-sm d-inline-flex align-items-center gap-1"><span class="material-symbols-rounded" style="font-size:15px;font-variation-settings:\'FILL\' 1,\'wght\' 400,\'GRAD\' 0,\'opsz\' 20;">download</span>다운로드</a></div></div>';
    }
    new bootstrap.Modal(document.getElementById('viewerModal')).show();
  }

  // 뷰어 닫을 때 미디어 정지
  document.getElementById('viewerModal').addEventListener('hide.bs.modal', () => {
    const wrap = document.getElementById('viewerWrap');
    wrap.querySelectorAll('video,audio').forEach(el => el.pause());
    wrap.innerHTML = '';
  });

  // ─── 업로드 ──────────────────────────────────────────────────────
  function handleFileSelect(fileList) {
    uploadFiles(Array.from(fileList));
    document.getElementById('fileInput').value = '';
  }

  function handleDrop(e) {
    e.preventDefault();
    document.getElementById('dmsContent').classList.remove('dragover');
    const files = Array.from(e.dataTransfer.files);
    if (files.length) uploadFiles(files);
  }

  function uploadFiles(files) {
    const fd = new FormData();
    files.forEach(f => fd.append('files', f));
    if (currentFolderSeq) fd.append('folderSeq', currentFolderSeq);

    const prog = document.getElementById('uploadProgress');
    const bar  = document.getElementById('uploadProgressBar');
    const txt  = document.getElementById('uploadProgressText');
    prog.classList.add('show');
    txt.textContent = files.map(f => f.name).join(', ');
    bar.style.width = '30%';

    const xhr = new XMLHttpRequest();
    xhr.open('POST', CTX + '/dms/file/upload');
    xhr.upload.onprogress = e => { if (e.lengthComputable) bar.style.width = Math.round(e.loaded*100/e.total) + '%'; };
    xhr.onload = () => {
      bar.style.width = '100%';
      if (xhr.status >= 400) {
        prog.classList.remove('show');
        alert('업로드 실패 (HTTP ' + xhr.status + ')\n' + xhr.responseText.substring(0, 200));
        return;
      }
      try {
        const d = JSON.parse(xhr.responseText);
        if (d.quota) updateQuota(d.quota);
        if (d.errors && d.errors.length) alert('일부 파일 업로드 실패:\n' + d.errors.join('\n'));
        setTimeout(() => { prog.classList.remove('show'); navigate(currentFolderSeq); }, 500);
      } catch(err) {
        prog.classList.remove('show');
        alert('서버 응답 오류:\n' + xhr.responseText.substring(0, 300));
      }
    };
    xhr.onerror = () => { prog.classList.remove('show'); alert('네트워크 오류 - 업로드 실패'); };
    xhr.send(fd);
  }

  // ─── 쿼터 갱신 ───────────────────────────────────────────────────
  function updateQuota(q) {
    const fill = document.getElementById('quotaFill');
    const used = document.getElementById('quotaUsed');
    if (!fill || !q) return;
    fill.style.width = q.usedPct + '%';
    fill.className = 'dms-quota-fill' + (q.usedPct >= 90 ? ' danger' : q.usedPct >= 70 ? ' warn' : '');
    if (used) used.textContent = q.usedText;
  }

  // ─── 유틸 ────────────────────────────────────────────────────────
  function escHtml(str) {
    return String(str).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
  }

  // ─── 폴더 트리 JS 렌더링 ─────────────────────────────────────────
  function renderTree(nodes, container, depth) {
    nodes.forEach(function(f) {
      var hasChildren = f.children && f.children.length > 0;
      var item = document.createElement('div');
      item.className = 'tree-item' + (currentFolderSeq == f.folderSeq ? ' active' : '');
      item.setAttribute('data-folder-seq', f.folderSeq);
      item.style.paddingLeft = (12 + depth * 10) + 'px';
      var chevron = '<span class="material-symbols-rounded" style="font-size:13px;font-variation-settings:\'FILL\' 0,\'wght\' 400,\'GRAD\' 0,\'opsz\' 20;">chevron_right</span>';
      item.innerHTML =
        '<span class="tree-toggle" style="width:14px;text-align:center;flex-shrink:0;">'
          + (hasChildren ? chevron : '&nbsp;') + '</span>'
        + '<span class="tree-icon material-symbols-rounded" style="font-size:16px;font-variation-settings:\'FILL\' 1,\'wght\' 400,\'GRAD\' 0,\'opsz\' 20;color:#f59e0b;">folder</span>'
        + '<span style="overflow:hidden;text-overflow:ellipsis;">' + escHtml(f.folderNm) + '</span>';
      item.addEventListener('click', function(e) { e.stopPropagation(); navigate(f.folderSeq); });
      container.appendChild(item);

      if (hasChildren) {
        var sub = document.createElement('div');
        sub.className = 'tree-children';
        sub.id = 'tree-children-' + f.folderSeq;
        sub.style.display = 'none';
        container.appendChild(sub);
        renderTree(f.children, sub, depth + 1);

        item.querySelector('.tree-toggle').addEventListener('click', function(e) {
          e.stopPropagation();
          var isOpen = sub.style.display !== 'none';
          sub.style.display = isOpen ? 'none' : '';
          this.innerHTML = isOpen
            ? '<span class="material-symbols-rounded" style="font-size:13px;font-variation-settings:\'FILL\' 0,\'wght\' 400,\'GRAD\' 0,\'opsz\' 20;">chevron_right</span>'
            : '<span class="material-symbols-rounded" style="font-size:13px;font-variation-settings:\'FILL\' 0,\'wght\' 400,\'GRAD\' 0,\'opsz\' 20;">expand_more</span>';
        });
      }
    });
  }

  document.addEventListener('DOMContentLoaded', function() {
    // 트리 렌더링
    var treeContainer = document.getElementById('folderTree');
    if (treeContainer && TREE_DATA.length > 0) renderTree(TREE_DATA, treeContainer, 0);

    // 루트 하이라이트
    if (!currentFolderSeq) {
      var rootItem = document.getElementById('tree-root-item');
      if (rootItem) rootItem.classList.add('active');
    } else {
      var rootItem = document.getElementById('tree-root-item');
      if (rootItem) rootItem.classList.remove('active');
    }
  });
  </script>
</body>
</html>
