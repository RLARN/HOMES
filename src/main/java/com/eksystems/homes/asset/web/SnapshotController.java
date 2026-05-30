package com.eksystems.homes.asset.web;

import com.eksystems.homes.asset.service.SnapshotService;
import com.eksystems.homes.login.vo.LoginVO;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.http.HttpSession;
import java.util.Map;

@RestController
@RequestMapping("/asset/snapshot")
public class SnapshotController {

    private final SnapshotService snapshotService;

    public SnapshotController(SnapshotService snapshotService) {
        this.snapshotService = snapshotService;
    }

    /** 전표처리 AJAX: POST /asset/snapshot/{yymm} */
    @PostMapping("/{yymm}")
    public Map<String, Object> snapshot(@PathVariable String yymm, HttpSession session) {
        try {
            LoginVO login = (LoginVO) session.getAttribute("LoginVO");
            snapshotService.snapshot(login.getFamilyId(), yymm, login.getUserId());
            return Map.of("success", true, "message", yymm.substring(0, 4) + "년 " + yymm.substring(4, 6) + "월 전표처리 완료");
        } catch (Exception e) {
            return Map.of("success", false, "message", e.getMessage());
        }
    }
}
