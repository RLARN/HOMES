package com.eksystems.homes.push.web;

import com.eksystems.homes.login.vo.LoginVO;
import com.eksystems.homes.push.mapper.PushMapper;
import com.eksystems.homes.push.service.VapidKeyService;
import com.eksystems.homes.push.vo.PushSubscriptionVO;
import jakarta.servlet.http.HttpSession;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/push")
public class PushController {

    private final VapidKeyService vapidKeyService;
    private final PushMapper      pushMapper;

    public PushController(VapidKeyService vapidKeyService, PushMapper pushMapper) {
        this.vapidKeyService = vapidKeyService;
        this.pushMapper      = pushMapper;
    }

    /** VAPID 공개키 반환 (프론트에서 구독 시 필요) */
    @GetMapping("/vapidPublicKey")
    public Map<String, String> vapidPublicKey() {
        return Map.of("publicKey", vapidKeyService.getPublicKeyBase64());
    }

    /** 브라우저 push 구독 정보 저장/갱신 */
    @PostMapping("/subscribe")
    public Map<String, Object> subscribe(@RequestBody Map<String, Object> body,
                                         HttpSession session) {
        LoginVO loginUser = (LoginVO) session.getAttribute("LoginVO");
        if (loginUser == null) {
            return Map.of("success", false, "message", "로그인 필요");
        }

        try {
            @SuppressWarnings("unchecked")
            Map<String, String> keys = (Map<String, String>) body.get("keys");

            PushSubscriptionVO vo = new PushSubscriptionVO();
            vo.setFamilyId(loginUser.getFamilyId());
            vo.setUserId(loginUser.getUserId());
            vo.setUserAuth(loginUser.getUserAuth());
            vo.setEndpoint((String) body.get("endpoint"));
            vo.setP256dh(keys.get("p256dh"));
            vo.setAuth(keys.get("auth"));

            pushMapper.upsertSubscription(vo);
            return Map.of("success", true);
        } catch (Exception e) {
            return Map.of("success", false, "message", e.getMessage());
        }
    }

    /** 구독 취소 */
    @DeleteMapping("/unsubscribe")
    public Map<String, Object> unsubscribe(HttpSession session) {
        LoginVO loginUser = (LoginVO) session.getAttribute("LoginVO");
        if (loginUser == null) {
            return Map.of("success", false, "message", "로그인 필요");
        }
        pushMapper.deleteSubscription(loginUser.getFamilyId(), loginUser.getUserId());
        return Map.of("success", true);
    }
}
