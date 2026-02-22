package com.eksystems.homes.scm.mapper;

import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import com.eksystems.homes.scm.vo.ScmVO;

@Mapper
public interface ScmMapper {

    int insertDepositRequest(ScmVO vo);

	List<ScmVO> selectDepositRequestList(ScmVO scmVO);
	
	ScmVO selectDepositRequestDetail(@Param("familyId") String familyId,
            @Param("depReqSeq") Long depReqSeq);

}