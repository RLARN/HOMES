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
      <h2>Sign in to HOMES</h2>

      <!-- action은 나중에 로그인 엔드포인트 만들면 변경 -->
	  <form id="loginForm">
	      <input type="text"
	             name="familyId"
				 text="aekong House"
	             value="ek"
	             readonly
	             class="form-control mb-2"/>

	      <input type="text"
	             name="userId"
	             placeholder="Email or ID"
	             required
	             class="form-control mb-2"/>

	      <input type="password"
	             name="userPwd"
	             placeholder="Password"
	             required
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
	  background: #fff;
	  display: flex;
	  flex-direction: column;
	  justify-content: center;
	  padding: 60px;
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

    $('#loginForm').on('submit', function (e) {
        e.preventDefault(); // 🔴 기본 submit 막기

        $('#loginAlert').addClass('d-none'); // alert 숨김

        $.ajax({
            url: '${pageContext.request.contextPath}/loginProcess',
            type: 'POST',
            data: {
                familyId: $('input[name="familyId"]').val(),
                userId: $('input[name="userId"]').val(),
                userPwd: $('input[name="userPwd"]').val()
            },
            success: function (res) {
                if (res === true) {
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
