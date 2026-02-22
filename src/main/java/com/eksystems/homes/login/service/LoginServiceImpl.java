package com.eksystems.homes.login.service;

import jakarta.servlet.http.HttpSession;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import com.eksystems.homes.login.mapper.LoginMapper;
import com.eksystems.homes.login.vo.LoginVO;

@Service
public class LoginServiceImpl implements LoginService {

    private final LoginMapper loginMapper;

    public LoginServiceImpl(LoginMapper loginMapper) {
        this.loginMapper = loginMapper;
    }

    @Override
    public LoginVO getLogin(HttpSession session,
                            String familyId,
                            String userId,
                            String userPwd) {

        // 2) ⭐ MyBatis는 여기서만 사용
        LoginVO user = loginMapper.selectLoginUser(familyId, userId, userPwd);

        // 3) 세션 처리 (Service 책임)
        //user.setUserPwd(null); // 비밀번호 제거
        session.setAttribute("userId", user);
        session.setAttribute("userNm", user);
        session.setAttribute("familyId", familyId);

        return user;
    }
}
