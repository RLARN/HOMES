package com.eksystems.homes.login.mapper;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.eksystems.homes.login.vo.LoginVO;


@Mapper
public interface LoginMapper {

    LoginVO selectLoginUser(@Param("familyId") String familyId,
                            @Param("userId") String userId,
                            @Param("userPwd") String userPwd
                            );

    int updateLastLogin(@Param("familyId") String familyId,
                        @Param("username") String username);
}