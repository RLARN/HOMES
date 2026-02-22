package com.eksystems.homes.scm.service;

import java.util.List;
import com.eksystems.homes.scm.vo.ScmVO;

import jakarta.servlet.http.HttpSession;

public interface ScmService {
	List<ScmVO> getDepositRequestList(ScmVO scmVO);
	void createDepositRequest(HttpSession session, String familyId, String storeInfo, Long amount, String reason, String requesterId);
	ScmVO getDepositRequestDetail(String familyId, Long depReqSeq);
}
