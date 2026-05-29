package com.eksystems.homes.common.advice;

import com.eksystems.homes.push.service.VapidKeyService;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ModelAttribute;

@ControllerAdvice
public class GlobalModelAdvice {

    private final VapidKeyService vapidKeyService;

    public GlobalModelAdvice(VapidKeyService vapidKeyService) {
        this.vapidKeyService = vapidKeyService;
    }

    @ModelAttribute("vapidPublicKey")
    public String vapidPublicKey() {
        return vapidKeyService.getPublicKeyBase64();
    }
}
