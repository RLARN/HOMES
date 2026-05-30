<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>^HOMES Login</title>

  <!-- CSS: /static/css 아래에 두고 contextPath로 접근 -->
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/homes-login.css" />
</head>
<body>
  <div class="login-wrapper">
    <div class="brand-area">
      <!--<img src="${pageContext.request.contextPath}/assets/logo-homes-horizontal.png" alt="^HOMES" /-->
	  <h1>^HOMES</h1>
      <p>Home Organization &amp; Management<br/>for Enhanced Synergy</p>
    </div>

    <div class="login-card">
      <canvas class="login-dot-field" id="loginDotField" aria-hidden="true"></canvas>
      <div class="login-content">
      <h2>Sign in to HOMES</h2>

      <!-- action은 나중에 로그인 엔드포인트 만들면 변경 -->
	  <form id="loginForm" autocomplete="on">
	      <input type="text"
	             id="familyId"
	             name="familyId"
	             placeholder="Family Code"
	             required
	             autocomplete="organization"
	             class="form-control mb-2"/>

	      <input type="text"
	             id="userId"
	             name="userId"
	             placeholder="Email or ID"
	             required
	             autocomplete="username"
	             class="form-control mb-2"/>

	      <input type="password"
	             id="userPwd"
	             name="userPwd"
	             placeholder="Password"
	             required
	             autocomplete="current-password"
	             class="form-control mb-3"/>

	      <!-- Bootstrap Alert -->
	      <div id="loginAlert" class="alert alert-danger d-none" role="alert">
	          아이디 또는 비밀번호가 올바르지 않습니다.
	      </div>

	      <button type="submit" class="btn btn-primary w-100">
	          Login
	      </button>
	  </form>

      <div class="login-footer">
        <a href="${pageContext.request.contextPath}/forgot-password">Forgot password?</a>
      </div>
      </div>
    </div>
  </div>
</body>
<style>
	* {
	  box-sizing: border-box;
	  font-family: 'Pretendard', 'Inter', sans-serif;
	}

	body {
	  margin: 0;
	  background: #f6f8fb;
	}

	.login-wrapper {
	  display: flex;
	  min-height: 100vh;
	}

	.brand-area {
	  flex: 1;
	  background: linear-gradient(135deg, #1e3a8a, #1e40af);
	  color: #fff;
	  padding: 60px;
	  display: flex;
	  flex-direction: column;
	  justify-content: center;
	}

	.brand-area img {
	  width: 240px;
	  margin-bottom: 24px;
	}

	.brand-area p {
	  font-size: 16px;
	  opacity: 0.85;
	}

	.login-card {
	  flex: 1;
	  position: relative;
	  overflow: hidden;
	  background:
	    radial-gradient(circle at 20% 20%, rgba(56, 189, 248, .10), transparent 26%),
	    radial-gradient(circle at 78% 72%, rgba(30, 58, 138, .10), transparent 28%),
	    #fff;
	  display: flex;
	  flex-direction: column;
	  justify-content: center;
	  padding: 60px;
	}

	.login-dot-field {
	  position: absolute;
	  inset: 0;
	  width: 100%;
	  height: 100%;
	  z-index: 0;
	  pointer-events: none;
	}

	.login-card::after {
	  content: "";
	  position: absolute;
	  inset: 0;
	  z-index: 1;
	  pointer-events: none;
	  background:
	    linear-gradient(90deg, rgba(255,255,255,.96), rgba(255,255,255,.76) 50%, rgba(255,255,255,.92)),
	    radial-gradient(circle at 56% 48%, transparent 0, rgba(255,255,255,.62) 76%);
	}

	.login-content {
	  position: relative;
	  z-index: 2;
	  width: 100%;
	}

	.login-card h2 {
	  margin-bottom: 24px;
	  color: #1f2937;
	}

	.login-card input {
	  width: 100%;
	  padding: 14px;
	  margin-bottom: 16px;
	  border-radius: 10px;
	  border: 1px solid #d1d5db;
	  font-size: 16px; /* iOS zoom 방지 */
	}

	.login-card input:focus {
	  outline: none;
	  border-color: #4caf6a;
	  box-shadow: 0 0 0 2px rgba(76, 175, 106, 0.15);
	}

	.login-card button {
	  margin-top: 8px;
	  padding: 14px;
	  border-radius: 10px;
	  border: none;
	  background: #1e3a8a;
	  color: #fff;
	  font-size: 15px;
	  cursor: pointer;
	}

	.login-card button:hover {
	  background: #1e40af;
	}

	.login-footer {
	  margin-top: 16px;
	  text-align: right;
	}

	.login-footer a {
	  font-size: 13px;
	  color: #6b7280;
	  text-decoration: none;
	}

	/* 📱 Mobile */
	@media (max-width: 768px) {
	  .login-wrapper {
	    flex-direction: column;
	  }

	  .brand-area {
	    padding: 32px;
	    align-items: center;
	    text-align: center;
	  }

	  .login-card {
	    padding: 32px;
	  }
	}

</style>
</html>
<script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">

<script>
$(function () {

    // familyId: localStorage에서 마지막 입력값 복원
    var savedFamilyId = localStorage.getItem('homes_familyId');
    if (savedFamilyId) {
        $('#familyId').val(savedFamilyId);
    }

    $('#loginForm').on('submit', function (e) {
        e.preventDefault();

        $('#loginAlert').addClass('d-none');

        var familyId = $('#familyId').val();
        var userId   = $('#userId').val();
        var userPwd  = $('#userPwd').val();

        $.ajax({
            url: '${pageContext.request.contextPath}/loginProcess',
            type: 'POST',
            data: { familyId: familyId, userId: userId, userPwd: userPwd },
            success: function (res) {
                if (res === true) {
                    // 로그인 성공 시 familyId 저장
                    localStorage.setItem('homes_familyId', familyId);
                    location.href = '${pageContext.request.contextPath}/main';
                } else {
                    $('#loginAlert').removeClass('d-none');
                }
            },
            error: function () {
                $('#loginAlert').text('서버 오류가 발생했습니다.').removeClass('d-none');
            }
        });
    });

});
</script>
<script>
(function () {
  const canvas = document.getElementById('loginDotField');
  const card = document.querySelector('.login-card');
  if (!canvas || !card) return;

  const ctx = canvas.getContext('2d');
  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
  let width = 0;
  let height = 0;
  let dots = [];
  let rafId = 0;
  let startTime = 0;
  const pointer = { x: 0, y: 0 };

  function resize() {
    const rect = card.getBoundingClientRect();
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    width = Math.max(1, rect.width);
    height = Math.max(1, rect.height);
    canvas.width = Math.floor(width * dpr);
    canvas.height = Math.floor(height * dpr);
    canvas.style.width = width + 'px';
    canvas.style.height = height + 'px';
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    buildDots();
  }

  function buildDots() {
    const gap = width < 520 ? 24 : 28;
    const cols = Math.ceil(width / gap) + 4;
    const rows = Math.ceil(height / gap) + 4;
    const offsetX = (width - (cols - 1) * gap) / 2;
    const offsetY = (height - (rows - 1) * gap) / 2;
    dots = [];

    for (let row = 0; row < rows; row += 1) {
      for (let col = 0; col < cols; col += 1) {
        dots.push({
          x: offsetX + col * gap,
          y: offsetY + row * gap,
          row: row,
          col: col
        });
      }
    }
  }

  function draw(now) {
    if (!startTime) startTime = now || 1;
    const elapsed = reduceMotion.matches ? 0 : (now - startTime) * .001;
    ctx.clearRect(0, 0, width, height);
    const cx = width * .56 + pointer.x * 42;
    const cy = height * .50 + pointer.y * 34;
    const waveX = width * (.14 + ((elapsed * .105) % 1.18));
    const waveY = height * (.18 + ((elapsed * .073) % 1.12));

    for (let i = 0; i < dots.length; i += 1) {
      const dot = dots[i];
      const curvedWaveX = waveX + Math.sin(dot.y * .018 + elapsed * 1.4) * 58 + Math.sin(dot.y * .006 - elapsed * .9) * 34;
      const curvedWaveY = waveY + Math.cos(dot.x * .014 - elapsed * 1.15) * 45;
      const verticalWave = Math.max(0, 1 - Math.abs(dot.x - curvedWaveX) / 165);
      const horizontalWave = Math.max(0, 1 - Math.abs(dot.y - curvedWaveY) / 150);
      const radialWave = (Math.sin(Math.hypot(dot.x - cx, dot.y - cy) * .022 - elapsed * 2.65) + 1) * .5;
      const diagonalWave = (Math.sin((dot.col * .38) + (dot.row * .47) - elapsed * 2.05) + 1) * .5;
      const centerDist = Math.hypot((dot.x - cx) / width, (dot.y - cy) / height);
      const pointerLift = Math.max(0, 1 - centerDist * 3.2);
      const lift =
        Math.pow(verticalWave, 2.35) * .52 +
        Math.pow(horizontalWave, 2.4) * .26 +
        Math.pow(radialWave, 3.2) * .14 +
        diagonalWave * .13 +
        pointerLift * .55;
      const z = Math.min(1, lift);

      const perspective = 1 + z * .16;
      const px = cx + (dot.x - cx) * perspective + pointer.x * z * 12;
      const py = cy + (dot.y - cy) * perspective - z * 18 + pointer.y * z * 10;
      const radius = 1.35 + z * 3.7;
      const alpha = .16 + z * .54;

      ctx.beginPath();
      ctx.fillStyle = 'rgba(30, 58, 138, ' + alpha + ')';
      ctx.arc(px, py, radius, 0, Math.PI * 2);
      ctx.fill();

      if (z > .36) {
        ctx.beginPath();
        ctx.fillStyle = 'rgba(56, 189, 248, ' + (z * .16) + ')';
        ctx.arc(px - radius * .33, py - radius * .38, Math.max(.7, radius * .38), 0, Math.PI * 2);
        ctx.fill();

        ctx.beginPath();
        ctx.strokeStyle = 'rgba(37, 99, 235, ' + (z * .16) + ')';
        ctx.lineWidth = 1;
        ctx.arc(px, py, radius + 5 * z, 0, Math.PI * 2);
        ctx.stroke();
      }
    }

    rafId = window.requestAnimationFrame(draw);
  }

  card.addEventListener('mousemove', function (event) {
    const rect = card.getBoundingClientRect();
    pointer.x = ((event.clientX - rect.left) / rect.width - .5) * 2;
    pointer.y = ((event.clientY - rect.top) / rect.height - .5) * 2;
  });

  card.addEventListener('mouseleave', function () {
    pointer.x = 0;
    pointer.y = 0;
  });

  window.addEventListener('resize', resize);
  resize();
  rafId = window.requestAnimationFrame(draw);

  window.addEventListener('beforeunload', function () {
    window.cancelAnimationFrame(rafId);
  });
})();
</script>
