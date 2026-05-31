<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<c:set var="post"     value="${data.post}"/>
<c:set var="comments" value="${data.comments}"/>
<!doctype html>
<html lang="ko">
<head>
  <%@ include file="/WEB-INF/jsp/common/head.jsp" %>
  <style>
    /* ── 상세 레이아웃 ─────────────────────────────────────── */
    .detail-wrap    { max-width: 640px; margin: 0 auto; padding: 0 0 80px; }

    /* ── 게시글 카드 ────────────────────────────────────────── */
    .post-card      { background:#fff; border-radius:16px; box-shadow:0 2px 12px rgba(0,0,0,.07);
                      margin-bottom:16px; overflow:hidden; }
    .post-header    { display:flex; align-items:center; gap:10px; padding:14px 16px 10px; }
    .post-avatar    { width:42px; height:42px; border-radius:50%; display:flex;
                      align-items:center; justify-content:center; font-weight:700;
                      font-size:17px; color:#fff; flex-shrink:0; }
    .post-author    { font-weight:600; font-size:14px; color:#111827; }
    .post-date      { font-size:12px; color:#9ca3af; }
    .post-menu      { margin-left:auto; }
    .post-menu .dropdown-toggle::after { display:none; }
    .post-menu .btn-icon { border:none; background:none; color:#9ca3af; font-size:20px;
                           cursor:pointer; padding:4px 8px; border-radius:6px; }
    .post-menu .btn-icon:hover { background:#f3f4f6; color:#374151; }

    /* ── 이미지 그리드 (상세: 전체 표시) ───────────────────── */
    .img-gallery    { display:grid; gap:3px; }
    .img-gallery.n1 { grid-template-columns:1fr; }
    .img-gallery.n2 { grid-template-columns:1fr 1fr; }
    .img-gallery.n3 { grid-template-columns:1fr 1fr; }
    .img-gallery.n3 .cell:first-child { grid-column:1/-1; }
    .img-gallery.n4,
    .img-gallery.many { grid-template-columns:1fr 1fr 1fr; }
    .img-gallery .cell { overflow:hidden; background:#f3f4f6; cursor:pointer; }
    .img-gallery.n1 .cell { max-height:560px; }
    .img-gallery.n2 .cell { height:260px; }
    .img-gallery.n3 .cell { height:200px; }
    .img-gallery.n3 .cell:first-child { height:300px; }
    .img-gallery.n4 .cell,
    .img-gallery.many .cell { height:180px; }
    .img-gallery .cell img { width:100%; height:100%; object-fit:cover;
                              transition:transform .25s; display:block; }
    .img-gallery .cell:hover img { transform:scale(1.03); }

    /* ── 텍스트 / 수정 ─────────────────────────────────────── */
    .post-content   { padding:12px 16px; font-size:15px; color:#1f2937;
                      white-space:pre-wrap; word-break:break-word; line-height:1.65; }
    .edit-textarea  { width:100%; border:1px solid #d1d5db; border-radius:10px; padding:10px 12px;
                      font-size:16px; resize:none; color:#1f2937; line-height:1.65;
                      font-family:inherit; outline:none; }
    .edit-textarea:focus { border-color:#3b82f6; box-shadow:0 0 0 3px rgba(59,130,246,.12); }

    /* ── 액션바 ─────────────────────────────────────────────── */
    .post-actions   { display:flex; align-items:center; gap:16px; padding:10px 16px 14px; }
    .post-action-btn{ display:flex; align-items:center; gap:5px; border:none; background:none;
                      color:#6b7280; font-size:14px; cursor:pointer; padding:4px 8px;
                      border-radius:8px; transition:all .15s; }
    .post-action-btn:hover { background:#f3f4f6; color:#374151; }
    .post-action-btn.liked { color:#ef4444; }
    .post-action-btn .icon { font-size:20px; line-height:1; }

    /* ── 댓글 영역 ──────────────────────────────────────────── */
    .comments-card  { background:#fff; border-radius:16px; box-shadow:0 2px 12px rgba(0,0,0,.07);
                      padding:16px; margin-bottom:16px; }
    .comments-title { font-weight:700; font-size:15px; color:#111827; margin-bottom:14px; }
    .comment-item   { display:flex; gap:10px; margin-bottom:16px; }
    .comment-avatar { width:34px; height:34px; border-radius:50%; display:flex;
                      align-items:center; justify-content:center; font-weight:700;
                      font-size:13px; color:#fff; flex-shrink:0; }
    .comment-body   { flex:1; }
    .comment-author { font-weight:600; font-size:13px; color:#111827; }
    .comment-date   { font-size:11px; color:#9ca3af; margin-left:6px; }
    .comment-text   { font-size:14px; color:#374151; margin-top:3px; line-height:1.5;
                      white-space:pre-wrap; word-break:break-word; }
    .comment-del    { border:none; background:none; color:#d1d5db; font-size:13px;
                      cursor:pointer; padding:2px 4px; border-radius:4px; }
    .comment-del:hover { color:#ef4444; background:#fef2f2; }
    .empty-comments { text-align:center; color:#9ca3af; font-size:14px; padding:20px 0; }

    /* ── 댓글 작성 ──────────────────────────────────────────── */
    .compose-comment{ display:flex; gap:10px; align-items:flex-start; margin-top:14px;
                      padding-top:14px; border-top:1px solid #f3f4f6; }
    .compose-comment-avatar { width:34px; height:34px; border-radius:50%; display:flex;
                              align-items:center; justify-content:center; font-weight:700;
                              font-size:13px; color:#fff; flex-shrink:0; }
    .comment-input  { flex:1; border:1px solid #e5e7eb; border-radius:20px; padding:8px 14px;
                      font-size:16px; outline:none; resize:none; font-family:inherit;
                      line-height:1.4; max-height:120px; overflow-y:auto; }
    .comment-input:focus { border-color:#3b82f6; box-shadow:0 0 0 3px rgba(59,130,246,.1); }
    .btn-comment-submit { padding:8px 16px; border-radius:20px; font-size:13px; font-weight:600;
                          white-space:nowrap; }

    /* ── 라이트박스 ──────────────────────────────────────────── */
    #lightbox       { display:none; position:fixed; inset:0; background:rgba(0,0,0,.92);
                      z-index:9999; align-items:center; justify-content:center; flex-direction:column; }
    #lightbox.show  { display:flex; }
    #lightbox img   { max-width:92vw; max-height:88vh; object-fit:contain; border-radius:6px; }
    .lb-close       { position:absolute; top:16px; right:20px; color:#fff; font-size:28px;
                      cursor:pointer; background:none; border:none; line-height:1; }
    .lb-prev,.lb-next { position:absolute; top:50%; transform:translateY(-50%);
                        color:#fff; font-size:36px; cursor:pointer; background:none; border:none;
                        padding:10px; opacity:.8; transition:opacity .2s; }
    .lb-prev:hover,.lb-next:hover { opacity:1; }
    .lb-prev { left:12px; } .lb-next { right:12px; }
    .lb-counter { color:#fff; font-size:13px; margin-top:10px; opacity:.7; }

    /* ── 뒤로가기 ────────────────────────────────────────────── */
    .back-btn { display:inline-flex; align-items:center; gap:6px; color:#6b7280; font-size:14px;
                border:none; background:none; cursor:pointer; padding:4px 0; margin-bottom:12px; }
    .back-btn:hover { color:#1f2937; }

    .spinner { display:inline-block; width:14px; height:14px; border:2px solid #e5e7eb;
               border-top-color:#3b82f6; border-radius:50%; animation:spin .7s linear infinite; }
    @keyframes spin { to { transform:rotate(360deg); } }
  </style>
</head>
<body class="homes-bg">
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>

<div class="homes-shell d-lg-flex">
  <%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

  <main class="homes-main flex-grow-1 d-flex flex-column">
    <div class="homes-main-body px-3 px-md-4 py-4">

      <div class="detail-wrap">

        <!-- 뒤로가기 -->
        <button class="back-btn" onclick="HOMES.go('${pageContext.request.contextPath}/sns')">
          <span class="material-symbols-rounded ms-btn" style="font-variation-settings:'FILL' 0,'wght' 400,'GRAD' 0,'opsz' 20;">arrow_back</span>피드로 돌아가기
        </button>

        <!-- ══ 게시글 ══ -->
        <div class="post-card" id="postCard">
          <div class="post-header">
            <div class="post-avatar" style="background:${post.avatarColor}">${post.avatarInitial}</div>
            <div>
              <div class="post-author">${post.regId}</div>
              <div class="post-date">${post.regDtText}</div>
            </div>
            <div class="post-menu dropdown ms-auto">
              <button class="btn-icon dropdown-toggle" data-bs-toggle="dropdown">
                <span class="material-symbols-rounded ms-btn" style="font-variation-settings:'FILL' 0,'wght' 400,'GRAD' 0,'opsz' 20;">more_horiz</span>
              </button>
              <ul class="dropdown-menu dropdown-menu-end shadow-sm border-0" style="border-radius:10px;">
                <li><a class="dropdown-item d-flex align-items-center gap-2" href="#" onclick="startEdit(); return false;">
                  <span class="material-symbols-rounded ms-sm">edit</span>수정</a></li>
                <li><hr class="dropdown-divider"></li>
                <li><a class="dropdown-item text-danger d-flex align-items-center gap-2" href="#" onclick="deletePost(); return false;">
                  <span class="material-symbols-rounded ms-sm">delete</span>삭제</a></li>
              </ul>
            </div>
          </div>

          <!-- 이미지 전체 표시 -->
          <c:if test="${not empty post.images}">
            <c:set var="imgCnt" value="${fn:length(post.images)}"/>
            <c:set var="galleryClass" value="${imgCnt == 1 ? 'n1' : imgCnt == 2 ? 'n2' : imgCnt == 3 ? 'n3' : imgCnt == 4 ? 'n4' : 'many'}"/>
            <div class="img-gallery ${galleryClass}" id="imgGallery">
              <c:forEach var="img" items="${post.images}" varStatus="st">
                <div class="cell" onclick="openLightbox(${st.index})">
                  <img src="${pageContext.request.contextPath}/sns/img/${post.familyId}/${img.storedNm}"
                       alt="${img.fileNm}" loading="lazy">
                </div>
              </c:forEach>
            </div>
          </c:if>

          <!-- 텍스트 (보기 / 수정 모드) -->
          <div id="postContentView" class="post-content">${post.content}</div>
          <div id="postContentEdit" style="display:none; padding:12px 16px;">
            <textarea class="edit-textarea" id="editTextarea" rows="4"
                      oninput="autoResize(this)">${post.content}</textarea>
            <div class="d-flex gap-2 mt-2 justify-content-end">
              <button class="btn btn-light btn-sm homes-pill" onclick="cancelEdit()">취소</button>
              <button class="btn btn-primary btn-sm homes-pill" onclick="saveEdit()">저장</button>
            </div>
          </div>

          <!-- 액션바 -->
          <div class="post-actions">
            <button class="post-action-btn ${post.liked ? 'liked' : ''}" id="likeBtn"
                    onclick="toggleLike()">
              <span class="icon material-symbols-rounded ms-btn" id="likeIcon">${post.liked ? 'favorite' : 'favorite_border'}</span>
              <span id="likeCount">${post.likeCount}</span>
            </button>
            <span class="post-action-btn" style="cursor:default;">
              <span class="icon material-symbols-rounded ms-btn" style="font-variation-settings:'FILL' 0,'wght' 400,'GRAD' 0,'opsz' 20;">chat_bubble</span>
              <span id="commentCountBadge">${fn:length(comments)}</span>
            </span>
          </div>
        </div>

        <!-- ══ 댓글 ══ -->
        <div class="comments-card">
          <div class="comments-title">댓글 <span id="commentCountTitle">${fn:length(comments)}</span>개</div>

          <div id="commentList">
            <c:choose>
              <c:when test="${empty comments}">
                <div class="empty-comments" id="emptyComments">첫 댓글을 남겨보세요 😊</div>
              </c:when>
              <c:otherwise>
                <c:forEach var="cmt" items="${comments}">
                  <div class="comment-item" id="cmt-${cmt.commentSeq}">
                    <div class="comment-avatar" style="background:${cmt.avatarColor}">${cmt.avatarInitial}</div>
                    <div class="comment-body">
                      <div>
                        <span class="comment-author">${cmt.regId}</span>
                        <span class="comment-date">${cmt.regDtText}</span>
                        <button class="comment-del float-end" title="삭제"
                                onclick="deleteComment(${cmt.commentSeq})">
                          <span class="material-symbols-rounded" style="font-size:14px;font-variation-settings:'FILL' 0,'wght' 400,'GRAD' 0,'opsz' 20;">close</span>
                        </button>
                      </div>
                      <div class="comment-text">${cmt.content}</div>
                    </div>
                  </div>
                </c:forEach>
              </c:otherwise>
            </c:choose>
          </div>

          <!-- 댓글 작성 -->
          <div class="compose-comment">
            <div class="compose-comment-avatar" id="myCommentAvatar">
              ${fn:toUpperCase(fn:substring(sessionScope.LoginVO.userId,0,1))}
            </div>
            <textarea class="comment-input" id="commentInput"
                      placeholder="댓글을 입력하세요..."
                      oninput="autoResize(this)"
                      onkeydown="if((event.ctrlKey||event.metaKey)&&event.key==='Enter') submitComment()"></textarea>
            <button class="btn btn-primary btn-comment-submit" onclick="submitComment()">등록</button>
          </div>
        </div>

      </div><!-- detail-wrap -->
    </div><!-- homes-main-body -->
    <%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
  </main>
</div>

<!-- 라이트박스 -->
<div id="lightbox">
  <button class="lb-close" onclick="closeLightbox()">
    <span class="material-symbols-rounded" style="font-size:28px;font-variation-settings:'FILL' 0,'wght' 300,'GRAD' 0,'opsz' 24;">close</span>
  </button>
  <button class="lb-prev" onclick="lbMove(-1)">
    <span class="material-symbols-rounded" style="font-size:40px;font-variation-settings:'FILL' 0,'wght' 300,'GRAD' 0,'opsz' 40;">chevron_left</span>
  </button>
  <img id="lbImg" src="" alt="">
  <button class="lb-next" onclick="lbMove(1)">
    <span class="material-symbols-rounded" style="font-size:40px;font-variation-settings:'FILL' 0,'wght' 300,'GRAD' 0,'opsz' 40;">chevron_right</span>
  </button>
  <div class="lb-counter" id="lbCounter"></div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
const CTX      = '${pageContext.request.contextPath}';
const POST_SEQ = ${post.postSeq};
const MY_ID    = '${sessionScope.LoginVO.userId}';

// ── 아바타 색 적용 ───────────────────────────────────────────────
const AVATAR_COLORS = ['#3b82f6','#10b981','#f59e0b','#ec4899','#8b5cf6','#ef4444'];
function avatarColor(id) {
  if (!id) return '#6b7280';
  let h = 0; for (let c of id) h = (h*31 + c.charCodeAt(0)) | 0;
  return AVATAR_COLORS[Math.abs(h) % AVATAR_COLORS.length];
}
document.getElementById('myCommentAvatar').style.background = avatarColor(MY_ID);

// ── 게시글 수정 ──────────────────────────────────────────────────
function startEdit() {
  document.getElementById('postContentView').style.display = 'none';
  document.getElementById('postContentEdit').style.display = 'block';
  const ta = document.getElementById('editTextarea');
  autoResize(ta);
  ta.focus();
}
function cancelEdit() {
  document.getElementById('postContentView').style.display = 'block';
  document.getElementById('postContentEdit').style.display = 'none';
}
function saveEdit() {
  const content = document.getElementById('editTextarea').value.trim();
  fetch(CTX + '/sns/post/' + POST_SEQ, {
    method: 'PUT',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({content: content})
  })
  .then(r => r.json())
  .then(d => {
    if (!d.ok) { alert(d.message || '수정 실패'); return; }
    document.getElementById('postContentView').textContent = content;
    cancelEdit();
  });
}

// ── 게시글 삭제 ──────────────────────────────────────────────────
function deletePost() {
  if (!confirm('이 게시물을 삭제할까요?')) return;
  fetch(CTX + '/sns/post/' + POST_SEQ, { method:'DELETE' })
    .then(r => r.json())
    .then(d => { if (d.ok) HOMES.go(CTX + '/sns'); });
}

// ── 좋아요 ───────────────────────────────────────────────────────
function toggleLike() {
  fetch(CTX + '/sns/post/' + POST_SEQ + '/like', { method:'POST' })
    .then(r => r.json())
    .then(d => {
      const btn   = document.getElementById('likeBtn');
      const icon  = document.getElementById('likeIcon');
      const count = document.getElementById('likeCount');
      if (d.liked) { btn.classList.add('liked'); icon.textContent = 'favorite'; }
      else          { btn.classList.remove('liked'); icon.textContent = 'favorite_border'; }
      count.textContent = d.likeCount;
    });
}

// ── 댓글 등록 ────────────────────────────────────────────────────
function submitComment() {
  const input = document.getElementById('commentInput');
  const content = (input.value || '').trim();
  if (!content) { input.focus(); return; }

  const btn = document.querySelector('.btn-comment-submit');
  btn.disabled = true;
  btn.innerHTML = '<span class="spinner"></span>';

  fetch(CTX + '/sns/post/' + POST_SEQ + '/comment', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({content: content})
  })
  .then(r => r.json())
  .then(d => {
    btn.disabled = false; btn.textContent = '등록';
    if (!d.ok) { alert(d.message || '오류 발생'); return; }
    input.value = '';
    input.style.height = '';
    appendComment(d);
    updateCommentCount(1);
    document.getElementById('emptyComments') && document.getElementById('emptyComments').remove();
  })
  .catch(() => { btn.disabled=false; btn.textContent='등록'; });
}

function appendComment(c) {
  const list = document.getElementById('commentList');
  const el = document.createElement('div');
  el.className = 'comment-item';
  el.id = 'cmt-' + c.commentSeq;
  el.innerHTML =
    '<div class="comment-avatar" style="background:' + c.avatarColor + '">' + escHtml(c.avatarInitial) + '</div>'
    + '<div class="comment-body">'
    + '<div><span class="comment-author">' + escHtml(c.regId) + '</span>'
    + '<span class="comment-date">' + escHtml(c.regDtText) + '</span>'
    + '<button class="comment-del float-end" onclick="deleteComment(' + c.commentSeq + ')"><span class="material-symbols-rounded" style="font-size:14px;font-variation-settings:\'FILL\' 0,\'wght\' 400,\'GRAD\' 0,\'opsz\' 20;">close</span></button></div>'
    + '<div class="comment-text">' + escHtml(c.content) + '</div>'
    + '</div>';
  list.appendChild(el);
}

// ── 댓글 삭제 ────────────────────────────────────────────────────
function deleteComment(seq) {
  if (!confirm('댓글을 삭제할까요?')) return;
  fetch(CTX + '/sns/comment/' + seq, { method:'DELETE' })
    .then(r => r.json())
    .then(d => {
      if (!d.ok) return;
      const el = document.getElementById('cmt-' + seq);
      if (el) { el.style.transition='opacity .3s'; el.style.opacity='0'; setTimeout(()=>el.remove(),300); }
      updateCommentCount(-1);
    });
}

function updateCommentCount(delta) {
  const t1 = document.getElementById('commentCountTitle');
  const t2 = document.getElementById('commentCountBadge');
  [t1, t2].forEach(el => { if (el) el.textContent = Math.max(0, parseInt(el.textContent||'0') + delta); });
}

// ── 라이트박스 ───────────────────────────────────────────────────
const lbUrls = [
  <c:forEach var="img" items="${post.images}" varStatus="st">
    '${pageContext.request.contextPath}/sns/img/${post.familyId}/${img.storedNm}'<c:if test="${!st.last}">,</c:if>
  </c:forEach>
];
let lbIdx = 0;

function openLightbox(idx) {
  if (!lbUrls.length) return;
  lbIdx = idx;
  document.getElementById('lbImg').src = lbUrls[lbIdx];
  document.getElementById('lbCounter').textContent = (lbIdx+1) + ' / ' + lbUrls.length;
  document.getElementById('lightbox').classList.add('show');
  document.body.style.overflow = 'hidden';
}
function closeLightbox() {
  document.getElementById('lightbox').classList.remove('show');
  document.body.style.overflow = '';
}
function lbMove(dir) {
  lbIdx = (lbIdx + dir + lbUrls.length) % lbUrls.length;
  document.getElementById('lbImg').src = lbUrls[lbIdx];
  document.getElementById('lbCounter').textContent = (lbIdx+1) + ' / ' + lbUrls.length;
}
document.getElementById('lightbox').addEventListener('click', function(e) {
  if (e.target === this) closeLightbox();
});
document.addEventListener('keydown', function(e) {
  const lb = document.getElementById('lightbox');
  if (!lb.classList.contains('show')) return;
  if (e.key === 'Escape')      closeLightbox();
  if (e.key === 'ArrowLeft')   lbMove(-1);
  if (e.key === 'ArrowRight')  lbMove(1);
});

// ── 유틸 ─────────────────────────────────────────────────────────
function autoResize(el) {
  el.style.height = 'auto';
  el.style.height = el.scrollHeight + 'px';
}
function escHtml(str) {
  return String(str||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
}
</script>
</body>
</html>
