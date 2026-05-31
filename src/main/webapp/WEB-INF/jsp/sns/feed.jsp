<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<!doctype html>
<html lang="ko">
<head>
  <%@ include file="/WEB-INF/jsp/common/head.jsp" %>
  <style>
    /* ── 피드 레이아웃 ─────────────────────────────────────── */
    .sns-wrap       { max-width: 600px; margin: 0 auto; padding: 0 0 80px; }

    /* ── 작성 박스 ─────────────────────────────────────────── */
    .compose-card   { background:#fff; border-radius:16px; box-shadow:0 2px 12px rgba(0,0,0,.07);
                      padding:16px; margin-bottom:20px; }
    .compose-avatar { width:38px; height:38px; border-radius:50%; display:flex;
                      align-items:center; justify-content:center; font-weight:700;
                      font-size:15px; color:#fff; flex-shrink:0; }
    .compose-input  { border:none; outline:none; width:100%; resize:none; font-size:16px;
                      background:transparent; color:#1f2937; min-height:60px; }
    .compose-input::placeholder { color:#9ca3af; }
    .compose-divider{ border:none; border-top:1px solid #f3f4f6; margin:12px 0; }
    .compose-actions{ display:flex; align-items:center; justify-content:space-between; }
    .img-preview-strip { display:flex; gap:8px; flex-wrap:wrap; margin-top:10px; }
    .img-preview-item  { position:relative; width:72px; height:72px; border-radius:8px;
                         overflow:hidden; background:#f3f4f6; flex-shrink:0; }
    .img-preview-item img { width:100%; height:100%; object-fit:cover; }
    .img-preview-del   { position:absolute; top:3px; right:3px; width:18px; height:18px;
                         background:rgba(0,0,0,.55); border:none; border-radius:50%;
                         color:#fff; font-size:10px; cursor:pointer; display:flex;
                         align-items:center; justify-content:center; }

    /* ── 포스트 카드 ────────────────────────────────────────── */
    .post-card      { background:#fff; border-radius:16px; box-shadow:0 2px 12px rgba(0,0,0,.07);
                      margin-bottom:20px; overflow:hidden; cursor:pointer;
                      transition:box-shadow .15s; }
    .post-card:hover{ box-shadow:0 4px 20px rgba(0,0,0,.12); }
    .post-header    { display:flex; align-items:center; gap:10px; padding:14px 16px 10px; }
    .post-avatar    { width:40px; height:40px; border-radius:50%; display:flex;
                      align-items:center; justify-content:center; font-weight:700;
                      font-size:16px; color:#fff; flex-shrink:0; }
    .post-author    { font-weight:600; font-size:14px; color:#111827; }
    .post-date      { font-size:12px; color:#9ca3af; }
    .post-menu      { margin-left:auto; }
    .post-content   { padding:0 16px 12px; font-size:15px; color:#1f2937;
                      white-space:pre-wrap; word-break:break-word; line-height:1.6; }

    /* ── 이미지 그리드 (피드: 최대 4장 표시 + more overlay) ─── */
    .img-grid       { display:grid; gap:2px; }
    .img-grid.n1    { grid-template-columns:1fr; }
    .img-grid.n2    { grid-template-columns:1fr 1fr; }
    .img-grid.n3    { grid-template-columns:1fr 1fr; grid-template-rows:auto auto; }
    .img-grid.n4    { grid-template-columns:1fr 1fr; }
    .img-grid .cell { overflow:hidden; background:#f3f4f6; position:relative; }
    .img-grid.n1 .cell { max-height:500px; }
    .img-grid.n2 .cell { height:240px; }
    .img-grid.n3 .cell { height:200px; }
    .img-grid.n3 .cell:first-child { grid-column:1/-1; height:280px; }
    .img-grid.n4 .cell { height:200px; }
    .img-grid .cell img { width:100%; height:100%; object-fit:cover;
                          transition:transform .25s; display:block; }
    .img-grid .cell:hover img { transform:scale(1.03); }
    .img-more-overlay { position:absolute; inset:0; background:rgba(0,0,0,.45);
                        display:flex; align-items:center; justify-content:center;
                        color:#fff; font-size:22px; font-weight:700; pointer-events:none; }

    /* ── 하단 액션바 (하트·댓글) ────────────────────────────── */
    .post-actions   { display:flex; align-items:center; gap:16px; padding:10px 16px 14px; }
    .post-action-btn{ display:flex; align-items:center; gap:5px; border:none; background:none;
                      color:#6b7280; font-size:14px; cursor:pointer; padding:4px 6px;
                      border-radius:8px; transition:all .15s; }
    .post-action-btn:hover { background:#f3f4f6; color:#374151; }
    .post-action-btn.liked { color:#ef4444; }
    .post-action-btn .icon { font-size:18px; line-height:1; }

    /* ── 삭제 드롭다운 ──────────────────────────────────────── */
    .post-menu .dropdown-toggle::after { display:none; }
    .post-menu .btn-icon { border:none; background:none; color:#9ca3af; font-size:18px;
                           cursor:pointer; padding:4px 8px; border-radius:6px; }
    .post-menu .btn-icon:hover { background:#f3f4f6; color:#374151; }

    /* ── 더 보기 버튼 ───────────────────────────────────────── */
    #loadMoreBtn    { width:100%; padding:12px; border:1px solid #e5e7eb; border-radius:12px;
                      background:#fff; color:#6b7280; font-size:14px; cursor:pointer;
                      transition:all .2s; }
    #loadMoreBtn:hover { background:#f9fafb; border-color:#d1d5db; }

    /* ── 빈 피드 ────────────────────────────────────────────── */
    .empty-feed     { text-align:center; padding:60px 20px; color:#9ca3af; }

    /* ── 업로드 버튼 ────────────────────────────────────────── */
    .btn-photo { display:inline-flex; align-items:center; gap:6px; padding:7px 14px;
                 border:1px solid #e5e7eb; border-radius:20px; background:#f9fafb;
                 color:#374151; font-size:13px; cursor:pointer; transition:all .15s; }
    .btn-photo:hover { background:#eff6ff; border-color:#93c5fd; color:#1d4ed8; }
    .btn-submit { padding:8px 22px; border-radius:20px; font-size:14px; font-weight:600; }

    /* ── 로딩 스피너 ────────────────────────────────────────── */
    .spinner { display:inline-block; width:18px; height:18px; border:2px solid #e5e7eb;
               border-top-color:#3b82f6; border-radius:50%; animation:spin .7s linear infinite; }
    @keyframes spin { to { transform:rotate(360deg); } }

    /* ── 사진수 표시 ─────────────────────────────────────────── */
    .photo-count-badge { font-size:12px; color:#6b7280; margin-top:6px; }
  </style>
</head>
<body class="homes-bg">
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>

<div class="homes-shell d-lg-flex">
  <%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

  <main class="homes-main flex-grow-1 d-flex flex-column">
    <div class="homes-main-body px-3 px-md-4 py-4">

      <!-- 타이틀 -->
      <div class="mb-4">
        <div class="homes-badge mb-2">SNS</div>
        <h1 class="h4 fw-bold mb-1">가족 앨범</h1>
        <div class="text-muted small">우리 가족의 소중한 순간을 공유해요 🏡</div>
      </div>

      <div class="sns-wrap">

        <!-- ══ 글 작성 박스 ══ -->
        <div class="compose-card">
          <div class="d-flex gap-3 align-items-start">
            <div class="compose-avatar" id="myAvatar">
              ${fn:toUpperCase(fn:substring(sessionScope.LoginVO.userId,0,1))}
            </div>
            <div style="flex:1;">
              <textarea class="compose-input" id="composeText"
                        placeholder="오늘 어떤 일이 있었나요? 🌟"
                        rows="3"
                        oninput="autoResize(this)"></textarea>
              <div class="img-preview-strip" id="previewStrip"></div>
              <div class="photo-count-badge" id="photoCountBadge"></div>
            </div>
          </div>
          <hr class="compose-divider">
          <div class="compose-actions">
            <label class="btn-photo mb-0 d-inline-flex align-items-center gap-1" style="cursor:pointer;">
              <span class="material-symbols-rounded ms-btn">add_photo_alternate</span>사진 추가
              <span id="photoLimitHint" style="font-size:11px; color:#9ca3af;">(최대 12장)</span>
              <input type="file" id="imgInput" accept="image/*" multiple hidden
                     onchange="handleImgSelect(this)">
            </label>
            <button class="btn btn-primary btn-submit" onclick="submitPost()">게시</button>
          </div>
        </div>

        <!-- ══ 피드 ══ -->
        <div id="feed">
          <c:forEach var="post" items="${feed.posts}">
            <div class="post-card" id="post-${post.postSeq}"
                 onclick="goToPost(event, ${post.postSeq})">
              <!-- 헤더 -->
              <div class="post-header">
                <div class="post-avatar" style="background:${post.avatarColor}">${post.avatarInitial}</div>
                <div>
                  <div class="post-author">${post.regId}</div>
                  <div class="post-date">${post.regDtText}</div>
                </div>
                <div class="post-menu dropdown" onclick="event.stopPropagation()">
                  <button class="btn-icon dropdown-toggle" data-bs-toggle="dropdown">
                    <span class="material-symbols-rounded ms-btn" style="font-variation-settings:'FILL' 0,'wght' 400,'GRAD' 0,'opsz' 20;">more_horiz</span>
                  </button>
                  <ul class="dropdown-menu dropdown-menu-end shadow-sm border-0" style="border-radius:10px;">
                    <li><a class="dropdown-item d-flex align-items-center gap-2" href="${pageContext.request.contextPath}/sns/post/${post.postSeq}">
                      <span class="material-symbols-rounded ms-sm">edit</span>상세/수정</a></li>
                    <li><a class="dropdown-item text-danger d-flex align-items-center gap-2" href="#"
                           onclick="deletePost(${post.postSeq}); return false;">
                      <span class="material-symbols-rounded ms-sm">delete</span>삭제</a></li>
                  </ul>
                </div>
              </div>

              <!-- 이미지 그리드 (피드: 최대 4장 표시) -->
              <c:if test="${not empty post.images}">
                <c:set var="imgCnt" value="${fn:length(post.images)}"/>
                <c:set var="showCnt" value="${imgCnt > 4 ? 4 : imgCnt}"/>
                <div class="img-grid n${showCnt}">
                  <c:forEach var="img" items="${post.images}" varStatus="st">
                    <c:if test="${st.index < 4}">
                      <div class="cell">
                        <img src="${pageContext.request.contextPath}/sns/img/${post.familyId}/${img.storedNm}"
                             alt="${img.fileNm}" loading="lazy">
                        <c:if test="${st.index == 3 && imgCnt > 4}">
                          <div class="img-more-overlay">+${imgCnt - 4}</div>
                        </c:if>
                      </div>
                    </c:if>
                  </c:forEach>
                </div>
              </c:if>

              <!-- 텍스트 -->
              <c:if test="${not empty post.content}">
                <div class="post-content">${post.content}</div>
              </c:if>

              <!-- 액션바 -->
              <div class="post-actions" onclick="event.stopPropagation()">
                <button class="post-action-btn ${post.liked ? 'liked' : ''}"
                        id="like-btn-${post.postSeq}"
                        onclick="toggleLike(${post.postSeq})">
                  <span class="icon material-symbols-rounded ms-btn" id="like-icon-${post.postSeq}">${post.liked ? 'favorite' : 'favorite_border'}</span>
                  <span id="like-count-${post.postSeq}">${post.likeCount}</span>
                </button>
                <button class="post-action-btn"
                        onclick="HOMES.go('${pageContext.request.contextPath}/sns/post/${post.postSeq}')">
                  <span class="icon material-symbols-rounded ms-btn" style="font-variation-settings:'FILL' 0,'wght' 400,'GRAD' 0,'opsz' 20;">chat_bubble</span>
                  <span id="comment-count-${post.postSeq}">${post.commentCount}</span>
                </button>
              </div>
            </div>
          </c:forEach>
        </div>

        <!-- 더 보기 -->
        <c:if test="${feed.hasMore}">
          <button id="loadMoreBtn" onclick="loadMore()">더 보기</button>
        </c:if>
        <c:if test="${empty feed.posts}">
          <div class="empty-feed">
            <div><span class="material-symbols-rounded ms-lg">photo_camera</span></div>
            <div class="fw-semibold mt-2">아직 게시물이 없어요</div>
            <div class="small mt-1">첫 번째 순간을 공유해보세요!</div>
          </div>
        </c:if>

      </div><!-- sns-wrap -->
    </div><!-- homes-main-body -->
    <%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
  </main>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
const CTX = '${pageContext.request.contextPath}';
let currentPage = 1;
let loadingMore = false;

// ── 게시글 클릭 → 상세 이동 ──────────────────────────────────────
function goToPost(e, seq) {
  if (e.target.closest('.post-actions') || e.target.closest('.post-menu') ||
      e.target.closest('.dropdown-menu')) return;
  HOMES.go(CTX + '/sns/post/' + seq);
}

// ── 이미지 선택 & 미리보기 ────────────────────────────────────────
const MAX_IMGS = 12;
let selectedFiles = [];

function handleImgSelect(input) {
  const newFiles = Array.from(input.files);
  const remain   = MAX_IMGS - selectedFiles.length;
  if (remain <= 0) { alert('사진은 최대 12장까지 첨부할 수 있어요.'); input.value=''; return; }
  const add = newFiles.slice(0, remain);
  if (newFiles.length > remain) alert('최대 12장까지만 첨부 가능해요. ' + remain + '장만 추가됩니다.');
  add.forEach(f => { f._id = Math.random().toString(36).slice(2); selectedFiles.push(f); });
  renderPreviews();
  input.value = '';
}

function renderPreviews() {
  const strip = document.getElementById('previewStrip');
  strip.innerHTML = '';
  selectedFiles.forEach(function(f) {
    const url  = URL.createObjectURL(f);
    const item = document.createElement('div');
    item.className = 'img-preview-item';
    item.innerHTML = '<img src="' + url + '" alt="">'
      + '<button class="img-preview-del" onclick="removeImg(\'' + f._id + '\')" type="button"><span class="material-symbols-rounded" style="font-size:13px;font-variation-settings:\'FILL\' 0,\'wght\' 400,\'GRAD\' 0,\'opsz\' 20;">close</span></button>';
    strip.appendChild(item);
  });
  const badge = document.getElementById('photoCountBadge');
  badge.textContent = selectedFiles.length > 0 ? selectedFiles.length + '장 선택됨' : '';
}

function removeImg(id) {
  selectedFiles = selectedFiles.filter(f => f._id !== id);
  renderPreviews();
}

// ── 글 작성 제출 ──────────────────────────────────────────────────
function submitPost() {
  const text = (document.getElementById('composeText').value || '').trim();
  if (!text && selectedFiles.length === 0) { alert('내용 또는 사진을 입력해주세요.'); return; }

  const fd = new FormData();
  fd.append('content', text);
  selectedFiles.forEach(f => fd.append('images', f));

  const btn = document.querySelector('.btn-submit');
  btn.disabled = true;
  btn.innerHTML = '<span class="spinner"></span>';

  fetch(CTX + '/sns/post', { method:'POST', body: fd })
    .then(r => r.json())
    .then(d => {
      btn.disabled = false; btn.textContent = '게시';
      if (!d.ok) { alert(d.message || '오류 발생'); return; }
      document.getElementById('composeText').value = '';
      selectedFiles = [];
      renderPreviews();
      HOMES.go(CTX + '/sns');
    })
    .catch(() => { btn.disabled=false; btn.textContent='게시'; alert('네트워크 오류'); });
}

// ── 삭제 ─────────────────────────────────────────────────────────
function deletePost(seq) {
  if (!confirm('이 게시물을 삭제할까요?')) return;
  fetch(CTX + '/sns/post/' + seq, { method:'DELETE' })
    .then(r => r.json())
    .then(d => {
      if (d.ok) {
        const el = document.getElementById('post-' + seq);
        if (el) { el.style.transition='opacity .3s'; el.style.opacity='0'; setTimeout(()=>el.remove(),300); }
      }
    });
}

// ── 좋아요 ───────────────────────────────────────────────────────
function toggleLike(seq) {
  fetch(CTX + '/sns/post/' + seq + '/like', { method:'POST' })
    .then(r => r.json())
    .then(d => {
      const btn   = document.getElementById('like-btn-' + seq);
      const count = document.getElementById('like-count-' + seq);
      if (!btn) return;
      if (d.liked) { btn.classList.add('liked'); btn.querySelector('.icon').textContent = 'favorite'; }
      else         { btn.classList.remove('liked'); btn.querySelector('.icon').textContent = 'favorite_border'; }
      if (count) count.textContent = d.likeCount;
    });
}

// ── 더 보기 ───────────────────────────────────────────────────────
function loadMore() {
  if (loadingMore) return;
  loadingMore = true;
  currentPage++;
  const btn = document.getElementById('loadMoreBtn');
  if (btn) btn.innerHTML = '<span class="spinner"></span>';

  fetch(CTX + '/sns/more?page=' + currentPage)
    .then(r => r.json())
    .then(d => {
      loadingMore = false;
      appendPosts(d.posts);
      if (!d.hasMore && btn) btn.remove();
      else if (btn) btn.textContent = '더 보기';
    })
    .catch(() => { loadingMore=false; if(btn) btn.textContent='더 보기'; });
}

function appendPosts(posts) {
  const feed = document.getElementById('feed');
  posts.forEach(function(p) {
    const card = document.createElement('div');
    card.className = 'post-card';
    card.id = 'post-' + p.postSeq;
    card.onclick = function(e) { goToPost(e, p.postSeq); };

    const imgs    = (p.images||[]);
    const showCnt = Math.min(imgs.length, 4);
    let imgHtml   = '';
    if (showCnt > 0) {
      imgHtml = '<div class="img-grid n' + showCnt + '">';
      imgs.slice(0, 4).forEach(function(img, idx) {
        imgHtml += '<div class="cell"><img src="' + CTX + '/sns/img/' + p.familyId + '/' + img.storedNm + '" loading="lazy">';
        if (idx === 3 && imgs.length > 4) imgHtml += '<div class="img-more-overlay">+' + (imgs.length - 4) + '</div>';
        imgHtml += '</div>';
      });
      imgHtml += '</div>';
    }
    const contentHtml = p.content ? '<div class="post-content">' + escHtml(p.content) + '</div>' : '';
    const bg   = avatarColor(p.regId);
    const init = p.regId ? p.regId.substring(0,1).toUpperCase() : '?';
    const likedClass = p.liked ? ' liked' : '';
    const likeIcon   = p.liked ? 'favorite' : 'favorite_border';
    const msBtn = 'class="material-symbols-rounded ms-btn"';
    const msBtnOutline = 'class="material-symbols-rounded ms-btn" style="font-variation-settings:\'FILL\' 0,\'wght\' 400,\'GRAD\' 0,\'opsz\' 20;"';

    card.innerHTML =
      '<div class="post-header">'
      + '<div class="post-avatar" style="background:' + bg + '">' + init + '</div>'
      + '<div><div class="post-author">' + escHtml(p.regId) + '</div>'
      + '<div class="post-date">' + escHtml(p.regDtText||'') + '</div></div>'
      + '<div class="post-menu dropdown" onclick="event.stopPropagation()">'
      + '<button class="btn-icon dropdown-toggle" data-bs-toggle="dropdown"><span ' + msBtnOutline + '>more_horiz</span></button>'
      + '<ul class="dropdown-menu dropdown-menu-end shadow-sm border-0" style="border-radius:10px;">'
      + '<li><a class="dropdown-item d-flex align-items-center gap-2" href="' + CTX + '/sns/post/' + p.postSeq + '"><span ' + msBtn + '>edit</span>상세/수정</a></li>'
      + '<li><a class="dropdown-item text-danger d-flex align-items-center gap-2" href="#" onclick="deletePost(' + p.postSeq + ');return false;"><span ' + msBtn + '>delete</span>삭제</a></li>'
      + '</ul></div></div>'
      + imgHtml + contentHtml
      + '<div class="post-actions" onclick="event.stopPropagation()">'
      + '<button class="post-action-btn' + likedClass + '" id="like-btn-' + p.postSeq + '" onclick="toggleLike(' + p.postSeq + ')">'
      + '<span class="icon ' + (p.liked ? 'material-symbols-rounded ms-btn' : 'material-symbols-rounded ms-btn') + '">' + likeIcon + '</span>'
      + '<span id="like-count-' + p.postSeq + '">' + (p.likeCount||0) + '</span></button>'
      + '<button class="post-action-btn" onclick="HOMES.go(\'' + CTX + '/sns/post/' + p.postSeq + '\')">'
      + '<span class="icon material-symbols-rounded ms-btn" style="font-variation-settings:\'FILL\' 0,\'wght\' 400,\'GRAD\' 0,\'opsz\' 20;">chat_bubble</span>'
      + '<span id="comment-count-' + p.postSeq + '">' + (p.commentCount||0) + '</span></button>'
      + '</div>';

    feed.appendChild(card);
  });
}

// ── 유틸 ─────────────────────────────────────────────────────────
function autoResize(el) {
  el.style.height = 'auto';
  el.style.height = el.scrollHeight + 'px';
}
function escHtml(str) {
  return String(str||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
}
const AVATAR_COLORS = ['#3b82f6','#10b981','#f59e0b','#ec4899','#8b5cf6','#ef4444'];
function avatarColor(id) {
  if (!id) return '#6b7280';
  let h = 0; for (let c of id) h = (h*31 + c.charCodeAt(0)) | 0;
  return AVATAR_COLORS[Math.abs(h) % AVATAR_COLORS.length];
}

// 내 아바타 색 적용
(function() {
  var myId = '${sessionScope.LoginVO.userId}';
  var el = document.getElementById('myAvatar');
  if (el) el.style.background = avatarColor(myId);
})();

// Ctrl+Enter로 게시
document.getElementById('composeText').addEventListener('keydown', function(e) {
  if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') submitPost();
});
</script>
</body>
</html>
