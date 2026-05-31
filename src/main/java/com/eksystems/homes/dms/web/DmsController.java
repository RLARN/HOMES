package com.eksystems.homes.dms.web;

import com.eksystems.homes.dms.service.DmsService;
import com.eksystems.homes.dms.vo.DmsFileVO;
import com.eksystems.homes.dms.vo.DmsFolderVO;
import com.eksystems.homes.login.vo.LoginVO;
import com.fasterxml.jackson.databind.ObjectMapper;
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

import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.nio.file.Path;
import java.util.*;

@Controller
@RequestMapping("/dms")
public class DmsController {

    private final DmsService dmsService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public DmsController(DmsService dmsService) {
        this.dmsService = dmsService;
    }

    // ── 메인 페이지 ────────────────────────────────────────────────
    @GetMapping({"", "/"})
    public String index(@RequestParam(required = false) Long folderSeq, Model model, HttpSession session) {
        LoginVO login = (LoginVO) session.getAttribute("LoginVO");

        List<DmsFolderVO> folders = dmsService.getChildFolders(login.getFamilyId(), folderSeq);
        List<DmsFileVO>   files   = dmsService.getFiles(login.getFamilyId(), folderSeq);
        List<DmsFolderVO> tree    = dmsService.getFolderTree(login.getFamilyId());
        List<DmsFolderVO> breadcrumb = folderSeq != null
                ? dmsService.getBreadcrumb(login.getFamilyId(), folderSeq) : List.of();
        Map<String, Object> quota = dmsService.getQuotaInfo(login.getFamilyId());

        // 트리를 JSON 문자열로 변환 (JSP에서 JS 변수로 사용)
        String treeJson;
        try { treeJson = objectMapper.writeValueAsString(tree); } catch (Exception e) { treeJson = "[]"; }

        model.addAttribute("folders",    folders);
        model.addAttribute("files",      files);
        model.addAttribute("treeJson",   treeJson);
        model.addAttribute("breadcrumb", breadcrumb);
        model.addAttribute("quota",      quota);
        model.addAttribute("currentFolderSeq", folderSeq);
        if (folderSeq != null) {
            model.addAttribute("currentFolder", dmsService.getFolder(login.getFamilyId(), folderSeq));
        }
        return "dms/index";
    }

    // ── 폴더 생성 ──────────────────────────────────────────────────
    @PostMapping("/folder/create")
    @ResponseBody
    public Map<String, Object> createFolder(@RequestBody Map<String, Object> body, HttpSession session) {
        LoginVO login = (LoginVO) session.getAttribute("LoginVO");
        String folderNm  = String.valueOf(body.getOrDefault("folderNm", "")).trim();
        Long   parentSeq = toLongOrNull(body.get("parentSeq"));

        if (folderNm.isBlank()) return error("폴더 이름을 입력하세요.");
        DmsFolderVO created = dmsService.createFolder(login.getFamilyId(), parentSeq, folderNm, login.getUserId());
        return Map.of("ok", true, "folderSeq", created.getFolderSeq(), "folderNm", created.getFolderNm());
    }

    // ── 폴더 이름 변경 ─────────────────────────────────────────────
    @PostMapping("/folder/rename")
    @ResponseBody
    public Map<String, Object> renameFolder(@RequestBody Map<String, Object> body, HttpSession session) {
        LoginVO login = (LoginVO) session.getAttribute("LoginVO");
        Long   folderSeq = toLongOrNull(body.get("folderSeq"));
        String newName   = String.valueOf(body.getOrDefault("folderNm", "")).trim();
        if (folderSeq == null || newName.isBlank()) return error("파라미터 오류");
        dmsService.renameFolder(login.getFamilyId(), folderSeq, newName, login.getUserId());
        return Map.of("ok", true);
    }

    // ── 폴더 삭제 ──────────────────────────────────────────────────
    @DeleteMapping("/folder/{folderSeq}")
    @ResponseBody
    public Map<String, Object> deleteFolder(@PathVariable Long folderSeq, HttpSession session) {
        LoginVO login = (LoginVO) session.getAttribute("LoginVO");
        List<DmsFileVO> deleted = dmsService.deleteFolder(login.getFamilyId(), folderSeq);
        deleted.forEach(f -> dmsService.deletePhysicalFile(login.getFamilyId(), f.getStoredNm()));
        return Map.of("ok", true, "deletedFiles", deleted.size());
    }

    // ── 파일 업로드 ────────────────────────────────────────────────
    @PostMapping("/file/upload")
    @ResponseBody
    public Map<String, Object> uploadFiles(@RequestParam("files") List<MultipartFile> files,
                                           @RequestParam(required = false) Long folderSeq,
                                           HttpSession session) {
        LoginVO login = (LoginVO) session.getAttribute("LoginVO");
        List<Map<String, Object>> uploaded = new ArrayList<>();
        List<String> errors = new ArrayList<>();
        for (MultipartFile mf : files) {
            try {
                DmsFileVO saved = dmsService.uploadFile(login.getFamilyId(), folderSeq, mf, login.getUserId());
                uploaded.add(Map.of(
                        "fileSeq",  saved.getFileSeq(),
                        "fileNm",   saved.getFileNm(),
                        "fileSize", saved.getFileSizeText(),
                        "mimeType", saved.getMimeType()
                ));
            } catch (IllegalStateException e) {
                errors.add(mf.getOriginalFilename() + ": " + e.getMessage());
            } catch (Exception e) {
                errors.add(mf.getOriginalFilename() + ": 업로드 실패");
            }
        }
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("ok",      errors.isEmpty());
        result.put("uploaded", uploaded);
        if (!errors.isEmpty()) result.put("errors", errors);
        result.put("quota", dmsService.getQuotaInfo(login.getFamilyId()));
        return result;
    }

    // ── 파일명 수정 ────────────────────────────────────────────────
    @PostMapping("/file/rename")
    @ResponseBody
    public Map<String, Object> renameFile(@RequestBody Map<String, Object> body, HttpSession session) {
        LoginVO login = (LoginVO) session.getAttribute("LoginVO");
        Long   fileSeq = toLongOrNull(body.get("fileSeq"));
        String fileNm  = String.valueOf(body.getOrDefault("fileNm", "")).trim();
        if (fileSeq == null || fileNm.isBlank()) return error("파라미터 오류");
        try {
            dmsService.renameFile(login.getFamilyId(), fileSeq, fileNm, login.getUserId());
            return Map.of("ok", true, "fileNm", fileNm);
        } catch (Exception e) {
            return error(e.getMessage());
        }
    }

    // ── 파일 정보 조회 (업로더/날짜) ──────────────────────────────
    @GetMapping("/file/{fileSeq}/info")
    @ResponseBody
    public Map<String, Object> fileInfo(@PathVariable Long fileSeq, HttpSession session) {
        LoginVO login = (LoginVO) session.getAttribute("LoginVO");
        var file = dmsService.getFile(login.getFamilyId(), fileSeq);
        if (file == null) return error("파일을 찾을 수 없습니다.");
        return Map.of(
            "ok",       true,
            "fileSeq",  file.getFileSeq(),
            "fileNm",   file.getFileNm(),
            "fileSize", file.getFileSizeText(),
            "mimeType", file.getMimeType() != null ? file.getMimeType() : "",
            "regId",    file.getRegId() != null ? file.getRegId() : "",
            "regDt",    file.getRegDt() != null ? file.getRegDt().toString().replace("T", " ") : ""
        );
    }

    // ── 파일 삭제 ──────────────────────────────────────────────────
    @DeleteMapping("/file/{fileSeq}")
    @ResponseBody
    public Map<String, Object> deleteFile(@PathVariable Long fileSeq, HttpSession session) {
        LoginVO login = (LoginVO) session.getAttribute("LoginVO");
        DmsFileVO file = dmsService.deleteFile(login.getFamilyId(), fileSeq);
        if (file == null) return error("파일을 찾을 수 없습니다.");
        dmsService.deletePhysicalFile(login.getFamilyId(), file.getStoredNm());
        return Map.of("ok", true, "quota", dmsService.getQuotaInfo(login.getFamilyId()));
    }

    // ── 파일 다운로드 ──────────────────────────────────────────────
    @GetMapping("/file/{fileSeq}/download")
    public ResponseEntity<Resource> download(@PathVariable Long fileSeq, HttpSession session)
            throws UnsupportedEncodingException {
        LoginVO login = (LoginVO) session.getAttribute("LoginVO");
        DmsFileVO file = dmsService.getFile(login.getFamilyId(), fileSeq);
        if (file == null) return ResponseEntity.notFound().build();

        Path path = dmsService.resolvePhysicalPath(login.getFamilyId(), file.getStoredNm());
        Resource res = new PathResource(path);
        String encodedName = URLEncoder.encode(file.getFileNm(), "UTF-8").replace("+", "%20");

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename*=UTF-8''" + encodedName)
                .contentType(MediaType.APPLICATION_OCTET_STREAM)
                .body(res);
    }

    // ── 파일 인라인 뷰어 ──────────────────────────────────────────
    @GetMapping("/file/{fileSeq}/view")
    public ResponseEntity<Resource> view(@PathVariable Long fileSeq, HttpSession session) {
        LoginVO login = (LoginVO) session.getAttribute("LoginVO");
        DmsFileVO file = dmsService.getFile(login.getFamilyId(), fileSeq);
        if (file == null) return ResponseEntity.notFound().build();

        Path path = dmsService.resolvePhysicalPath(login.getFamilyId(), file.getStoredNm());
        Resource res = new PathResource(path);
        MediaType mt;
        try {
            mt = MediaType.parseMediaType(file.getMimeType());
        } catch (Exception e) {
            mt = MediaType.APPLICATION_OCTET_STREAM;
        }
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "inline")
                .contentType(mt)
                .body(res);
    }

    // ── 쿼터 조회 ──────────────────────────────────────────────────
    @GetMapping("/quota")
    @ResponseBody
    public Map<String, Object> quota(HttpSession session) {
        LoginVO login = (LoginVO) session.getAttribute("LoginVO");
        return dmsService.getQuotaInfo(login.getFamilyId());
    }

    // ── 폴더 목록 (AJAX) ──────────────────────────────────────────
    @GetMapping("/folder/list")
    @ResponseBody
    public List<DmsFolderVO> folderList(@RequestParam(required = false) Long parentSeq, HttpSession session) {
        LoginVO login = (LoginVO) session.getAttribute("LoginVO");
        return dmsService.getChildFolders(login.getFamilyId(), parentSeq);
    }

    // ── util ───────────────────────────────────────────────────────
    private Map<String, Object> error(String msg) {
        return Map.of("ok", false, "message", msg);
    }

    private Long toLongOrNull(Object v) {
        if (v == null) return null;
        if (v instanceof Number n) return n.longValue();
        try { return Long.parseLong(String.valueOf(v).trim()); } catch (Exception e) { return null; }
    }
}
