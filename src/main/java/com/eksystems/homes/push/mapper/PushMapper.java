package com.eksystems.homes.push.mapper;

import com.eksystems.homes.push.vo.PushSubscriptionVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface PushMapper {

    void upsertSubscription(PushSubscriptionVO vo);

    void deleteSubscription(@Param("familyId") String familyId,
                            @Param("userId") String userId);

    List<PushSubscriptionVO> selectManagerSubscriptions(@Param("familyId") String familyId);
}
