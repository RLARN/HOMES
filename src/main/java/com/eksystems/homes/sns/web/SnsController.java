package com.eksystems.homes.sns.web;

import com.eksystems.homes.login.vo.LoginVO;
import com.eksystems.homes.sns.service.SnsService;
import jakarta.servlet.http.HttpSession;
import org.springframework.core.io.PathResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.nio.file.Path;
import java.util.List;
import java.util.Map;

@Controller
@RequestMapping("/sns")
public class SnsController {

    private final SnsService snsService;

    public SnsController(SnsService snsService) {
        this.snsService = snsService;
    }

    // ── 피드 메인 ───────────────────────────────────────────────────
    @GetMapping({"", "/"})
    public String feed(Model model, HttpSession session) {
        LoginVO login = (LoginVO) session.getAttribute("LoginVO");
        Map<String, Object> feed = snsService.getFeed(login.getFamilyId(), 1, login.getUserId());
        model.addAttribute("feed", feed);
        return "sns/feed";
    }

    // ── 추가 피드 로드 (무한스크롤) ──────────────────────────────────
    @GetMapping("/more")
    @ResponseBody
    public Map<String, Object> more(@RequestParam(defaultValue = "2") int page,
                                    HttpSession session) {
        LoginVO login = (LoginVO) session.getAttribute("LoginVO");
        return snsService.getFeed(login.getFamilyId(), page, login.getUserId());
    }

    // ── 게시글 상세 ─────────────────────────────────────────────────
    @GetMapping("/post/{postSeq}")
    public String detail(@PathVariable Long postSeq, Model model, HttpSession session) {
        LoginVO login = (LoginVO) session.getAttribute("LoginVO");
        Map<String, Object> data = snsService.getPostDetail(login.getFamilyId(), postSeq, login.getUserId());
        if (data == null) return "redirect:/sns";
        model.addAttribute("data", data);
        return "sns/detail";
    }

    // ── 게시글 작성 ─────────────────────────────────────────────────
    @PostMapping("/post")
    @ResponseBody
    public Map<String, Object> createPost(
            @RequestParam(required = false) String content,
            @RequestParam(required = false) List<MultipartFile> images,
            HttpSession session) {
        LoginVO login = (LoginVO) session.getAttribute("LoginVO");
        try {
            boolean noContent = content == null || content.isBlank();
            boolean noImages  = images == null || images.stream().allMatch(MultipartFile::isEmpty);
            if (noContent && noImages) {
                return Map.of("ok", false, "message", "내용 또는 사진을 입력해주세요.");
            }
            var post = snsService.createPost(login.getFamilyId(), content, images, login.getUserId());
            return Map.of("ok", true, "postSeq", post.getPostSeq());
        } catch (Exception e) {
            return Map.of("ok", false, "message", e.getMessage() != null ? e.getMessage() : "오류 발생");
        }
    }

    // ── 게시글 수정 ─────────────────────────────────────────────────
    @PutMapping("/post/{postSeq}")
    @ResponseBody
    public Map<String, Object> updatePost(@PathVariable Long postSeq,
                                          @RequestBody Map<String, String> body,
                                          HttpSession session) {
        LoginVO login = (LoginVO) session.getAttribute("LoginVO");
        try {
            snsService.updatePost(login.getFamilyId(), postSeq, body.getOrDefault("content", ""));
            return Map.of("ok", true);
        } catch (Exception e) {
            return Map.of("ok", false, "message", e.getMessage() != null ? e.getMessage() : "오류 발생");
        }
    }

    // ── 게시글 삭제 ─────────────────────────────────────────────────
    @DeleteMapping("/post/{postSeq}")
    @ResponseBody
    public Map<String, Object> deletePost(@PathVariable Long postSeq, HttpSession session) {
        LoginVO login = (LoginVO) session.getAttribute("LoginVO");
        snsService.deletePost(login.getFamilyId(), postSeq, login.getUserId());
        return Map.of("ok", true);
    }

    // ── 댓글 등록 ───────────────────────────────────────────────────
    @PostMapping("/post/{postSeq}/comment")
    @ResponseBody
    public Map<String, Object> addComment(@PathVariable Long postSeq,
                                          @RequestBody Map<String, String> body,
                                          HttpSession session) {
        LoginVO login = (LoginVO) session.getAttribute("LoginVO");
        String content = body.getOrDefault("content", "").trim();
        if (content.isBlank()) return Map.of("ok", false, "message", "댓글 내용을 입력해주세요.");
        try {
            var comment = snsService.addComment(login.getFamilyId(), postSeq, content, login.getUserId());
            return Map.of("ok", true,
                    "commentSeq",    comment.getCommentSeq(),
                    "content",       comment.getContent(),
                    "regId",         comment.getRegId(),
                    "regDtText",     comment.getRegDtText(),
                    "avatarColor",   comment.getAvatarColor(),
                    "avatarInitial", comment.getAvatarInitial());
        } catch (Exception e) {
            return Map.of("ok", false, "message", e.getMessage() != null ? e.getMessage() : "오류 발생");
        }
    }

    // ── 댓글 삭제 ───────────────────────────────────────────────────
    @DeleteMapping("/comment/{commentSeq}")
    @ResponseBody
    public Map<String, Object> deleteComment(@PathVariable Long commentSeq, HttpSession session) {
        LoginVO login = (LoginVO) session.getAttribute("LoginVO");
        snsService.deleteComment(login.getFamilyId(), commentSeq);
        return Map.of("ok", true);
    }

    // ── 좋아요 토글 ─────────────────────────────────────────────────
    @PostMapping("/post/{postSeq}/like")
    @ResponseBody
    public Map<String, Object> toggleLike(@PathVariable Long postSeq, HttpSession session) {
        LoginVO login = (LoginVO) session.getAttribute("LoginVO");
        return snsService.toggleLike(login.getFamilyId(), postSeq, login.getUserId());
    }

    // ── 이미지 서빙 ─────────────────────────────────────────────────
    @GetMapping("/img/{familyId}/{storedNm}")
    public ResponseEntity<Resource> img(@PathVariable String familyId,
                                        @PathVariable String storedNm,
                                        HttpSession session) {
        LoginVO login = (LoginVO) session.getAttribute("LoginVO");
        if (!login.getFamilyId().equals(familyId)) return ResponseEntity.status(403).build();

        Path path = snsService.resolveImg(familyId, storedNm);
        Resource res = new PathResource(path);
        if (!res.exists()) return ResponseEntity.notFound().build();

        MediaType mt = MediaType.IMAGE_JPEG;
        String lower = storedNm.toLowerCase();
        if (lower.endsWith(".png"))  mt = MediaType.IMAGE_PNG;
        else if (lower.endsWith(".gif"))  mt = MediaType.IMAGE_GIF;
        else if (lower.endsWith(".webp")) mt = MediaType.valueOf("image/webp");

        return ResponseEntity.ok()
                .header(HttpHeaders.CACHE_CONTROL, "max-age=86400")
                .contentType(mt)
                .body(res);
    }
}
