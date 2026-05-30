package com.eksystems.homes.main.web;

import com.eksystems.homes.asset.service.AssetService;
import com.eksystems.homes.asset.vo.AssetSummaryVO;
import com.eksystems.homes.assistant.service.GeminiService;
import com.eksystems.homes.login.vo.LoginVO;
import com.eksystems.homes.note.service.NoteService;
import com.eksystems.homes.note.vo.NoteVO;
import com.eksystems.homes.scm.service.ScmService;
import com.eksystems.homes.scm.vo.ScmVO;
import jakarta.servlet.http.HttpSession;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import java.util.List;

@Controller
@RequiredArgsConstructor
public class MainController {

    private final ScmService scmService;
    private final GeminiService geminiService;
    private final AssetService assetService;
    private final NoteService noteService;

    @Value("${google.calendar.client-id:}")
    private String googleCalendarClientId;

    @Value("${google.calendar.api-key:}")
    private String googleCalendarApiKey;

    @GetMapping({"/", "/main"})
    public String main(HttpSession session, Model model) {

        LoginVO loginUser = (LoginVO) session.getAttribute("LoginVO");
        String familyId = loginUser.getFamilyId();

        // ── SCM (입금요청) ─────────────────────────────────────
        ScmVO cond = new ScmVO();
        cond.setFamilyId(familyId);
        cond.setRegId(loginUser.getUserId());

        List<ScmVO> requestList = scmService.getDepositRequestList(cond);

        long requestedTotal = requestList.stream()
                .mapToLong(v -> v.getAmount() == null ? 0L : v.getAmount())
                .sum();
        long requestedStandbyCount = requestList.stream()
                .filter(v -> "STANDBY".equals(v.getReqStatus()))
                .count();

        // ── 자산 요약 ──────────────────────────────────────────
        AssetSummaryVO assetSummary = assetService.getAssetSummary(familyId);

        // ── 공유 메모 건수 ─────────────────────────────────────
        NoteVO noteCond = new NoteVO();
        noteCond.setFamilyId(familyId);
        long noteCount = noteService.getNoteList(noteCond).size();

        // ── 일일 명언 ─────────────────────────────────────────
        String dailyQuote = geminiService.generateDailyQuote(loginUser.getUserNm());

        model.addAttribute("requestedTotal", requestedTotal);
        model.addAttribute("requestedStandbyCount", requestedStandbyCount);
        model.addAttribute("assetSummary", assetSummary);
        model.addAttribute("noteCount", noteCount);
        model.addAttribute("dailyQuote", dailyQuote);

        return "main/main";
    }

    @GetMapping("/calendar/google")
    public String googleCalendar(Model model) {
        model.addAttribute("googleCalendarClientId", googleCalendarClientId);
        model.addAttribute("googleCalendarApiKey", googleCalendarApiKey);
        return "calendar/googleCalendar";
    }
}
