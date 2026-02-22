package com.eksystems.homes.scm.service;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.eksystems.homes.scm.mapper.ScmMapper;
import com.eksystems.homes.scm.vo.ScmVO;

import jakarta.servlet.http.HttpSession;

@Service
public class ScmImpl implements ScmService {

    private final ScmMapper scmMapper;

    public ScmImpl(ScmMapper scmMapper) {
        this.scmMapper = scmMapper;
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
    }

    @Override
    public List<ScmVO> getDepositRequestList(ScmVO scmVO) {
        return scmMapper.selectDepositRequestList(scmVO);
    }
    @Override
    public ScmVO getDepositRequestDetail(String familyId, Long depReqSeq) {
        return scmMapper.selectDepositRequestDetail(familyId, depReqSeq);
    }

}
