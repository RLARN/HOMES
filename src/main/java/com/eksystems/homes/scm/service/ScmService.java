package com.eksystems.homes.scm.service;

import java.util.List;
import com.eksystems.homes.scm.vo.ScmVO;

import jakarta.servlet.http.HttpSession;

public interface ScmService {
	List<ScmVO> getDepositRequestList(ScmVO scmVO);
	List<ScmVO> searchDepositRequests(String familyId, String keyword);
	Long createDepositRequest(HttpSession session, String familyId, String storeInfo, Long amount, String reason, String requesterId);
	ScmVO getDepositRequestDetail(String familyId, Long depReqSeq);
	void updateDepositStatus(String familyId, Long depReqSeq, String reqStatus, String updId);
	void deleteDepositRequest(String familyId, Long depReqSeq);
}
