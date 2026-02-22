package com.eksystems.homes.login.service;

import jakarta.servlet.http.HttpSession;

import org.springframework.stereotype.Service;

import com.eksystems.homes.login.vo.LoginVO;

@Service
public interface LoginService {

    LoginVO getLogin(HttpSession session,
                     String familyId,
                     String userId,
                     String userPwd);
}
