package com.eksystems.homes.note.web;

import com.eksystems.homes.login.vo.LoginVO;
import com.eksystems.homes.note.service.NoteService;
import com.eksystems.homes.note.vo.NoteVO;
import jakarta.servlet.http.HttpSession;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.List;

@Controller
@RequestMapping("/note")
public class NoteController {

    private final NoteService noteService;

    public NoteController(NoteService noteService) {
        this.noteService = noteService;
    }

    @GetMapping("/list")
    public String list(@RequestParam(required = false) String q,
                       HttpSession session,
                       Model model) {
        LoginVO loginUser = (LoginVO) session.getAttribute("LoginVO");

        NoteVO cond = new NoteVO();
        cond.setFamilyId(loginUser.getFamilyId());
        cond.setTitle(q);

        List<NoteVO> noteList = noteService.getNoteList(cond);
        model.addAttribute("noteList", noteList);
        model.addAttribute("q", q);
        return "note/list";
    }

    @GetMapping("/detail")
    public String detail(@RequestParam("noteSeq") Long noteSeq,
                         HttpSession session,
                         Model model,
                         RedirectAttributes redirectAttributes) {
        LoginVO loginUser = (LoginVO) session.getAttribute("LoginVO");
        NoteVO note = noteService.getNoteDetail(loginUser.getFamilyId(), noteSeq);

        if (note == null) {
            redirectAttributes.addFlashAttribute("message", "메모를 찾을 수 없습니다.");
            return "redirect:/note/list";
        }

        model.addAttribute("note", note);
        return "note/detail";
    }

    @GetMapping("/form")
    public String form(@RequestParam(required = false) Long noteSeq,
                       HttpSession session,
                       Model model,
                       RedirectAttributes redirectAttributes) {
        LoginVO loginUser = (LoginVO) session.getAttribute("LoginVO");

        if (noteSeq != null) {
            NoteVO note = noteService.getNoteDetail(loginUser.getFamilyId(), noteSeq);
            if (note == null) {
                redirectAttributes.addFlashAttribute("message", "메모를 찾을 수 없습니다.");
                return "redirect:/note/list";
            }
            model.addAttribute("note", note);
        } else {
            model.addAttribute("note", new NoteVO());
        }

        return "note/form";
    }

    @PostMapping("/save")
    public String save(@RequestParam(required = false) Long noteSeq,
                       @RequestParam String title,
                       @RequestParam String content,
                       HttpSession session,
                       RedirectAttributes redirectAttributes) {
        LoginVO loginUser = (LoginVO) session.getAttribute("LoginVO");

        NoteVO note = new NoteVO();
        note.setNoteSeq(noteSeq);
        note.setFamilyId(loginUser.getFamilyId());
        note.setTitle(title);
        note.setContent(content);
        note.setRegId(loginUser.getUserId());
        note.setUpdId(loginUser.getUserId());

        noteService.saveNote(note);

        redirectAttributes.addFlashAttribute("message", "메모가 저장되었습니다.");
        return "redirect:/note/detail?noteSeq=" + note.getNoteSeq();
    }

    @PostMapping("/delete")
    public String delete(@RequestParam Long noteSeq,
                         HttpSession session,
                         RedirectAttributes redirectAttributes) {
        LoginVO loginUser = (LoginVO) session.getAttribute("LoginVO");
        noteService.deleteNote(loginUser.getFamilyId(), noteSeq, loginUser.getUserId());

        redirectAttributes.addFlashAttribute("message", "메모가 삭제되었습니다.");
        return "redirect:/note/list";
    }
}
