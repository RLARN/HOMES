package com.eksystems.homes.scm.service;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.eksystems.homes.push.service.WebPushService;
import com.eksystems.homes.scm.mapper.ScmMapper;
import com.eksystems.homes.scm.vo.ScmVO;

import jakarta.servlet.http.HttpSession;

@Service
public class ScmImpl implements ScmService {

    private final ScmMapper      scmMapper;
    private final WebPushService webPushService;

    public ScmImpl(ScmMapper scmMapper, WebPushService webPushService) {
        this.scmMapper      = scmMapper;
        this.webPushService = webPushService;
    }

    @Override
    @Transactional
    public void createDepositRequest(HttpSession session, String familyId, String storeInfo, Long amount, String reason, String requesterId) {

        ScmVO vo = new ScmVO();
        vo.setAmount(amount);
        vo.setReqDesc(reason);
        vo.setStoreInfo(storeInfo); // 기본 상태
        vo.setRegId(requesterId); // 로그인 붙이면 세팅
        vo.setFamilyId(familyId);
        vo.setReqStatus("STANDBY");
        scmMapper.insertDepositRequest(vo);

        // 관리자에게 웹 푸시 알림 발송 (비동기, 실패해도 요청은 정상 처리)
        webPushService.sendToManagers(
                familyId,
                "새 입금요청이 등록되었습니다",
                String.format("%s · %,d원", storeInfo, amount),
                "/scm/deposit/depositRequest"
        );
    }

    @Override
    public List<ScmVO> getDepositRequestList(ScmVO scmVO) {
        return scmMapper.selectDepositRequestList(scmVO);
    }
    @Override
    public ScmVO getDepositRequestDetail(String familyId, Long depReqSeq) {
        return scmMapper.selectDepositRequestDetail(familyId, depReqSeq);
    }

    @Override
    @Transactional
    public void updateDepositStatus(String familyId, Long depReqSeq, String reqStatus, String updId) {
        scmMapper.updateDepositStatus(familyId, depReqSeq, reqStatus, updId);
    }

    @Override
    @Transactional
    public void deleteDepositRequest(String familyId, Long depReqSeq) {
        scmMapper.deleteDepositRequest(familyId, depReqSeq);
    }

}
