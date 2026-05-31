package com.eksystems.homes.dms.service;

import com.eksystems.homes.dms.mapper.DmsMapper;
import com.eksystems.homes.dms.vo.DmsFileVO;
import com.eksystems.homes.dms.vo.DmsFolderVO;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.*;

@Service
public class DmsService {

    private static final Logger log = LoggerFactory.getLogger(DmsService.class);

    @Value("${dms.upload.path:./uploads/dms}")
    private String uploadBasePath;

    @Value("${dms.quota.bytes:1073741824}")   // 1 GB
    private long quotaBytes;

    private final DmsMapper dmsMapper;

    public DmsService(DmsMapper dmsMapper) {
        this.dmsMapper = dmsMapper;
    }

    // ══════════════════════════ 폴더 ══════════════════════════════

    public DmsFolderVO createFolder(String familyId, Long parentSeq, String folderNm, String userId) {
        DmsFolderVO folder = new DmsFolderVO();
        folder.setFamilyId(familyId);
        folder.setParentSeq(parentSeq);
        folder.setFolderNm(folderNm.trim());
        folder.setRegId(userId);
        folder.setUpdId(userId);
        dmsMapper.insertFolder(folder);
        return folder;
    }

    public void renameFolder(String familyId, Long folderSeq, String newName, String userId) {
        DmsFolderVO folder = new DmsFolderVO();
        folder.setFamilyId(familyId);
        folder.setFolderSeq(folderSeq);
        folder.setFolderNm(newName.trim());
        folder.setUpdId(userId);
        dmsMapper.updateFolderName(folder);
    }

    @Transactional
    public List<DmsFileVO> deleteFolder(String familyId, Long folderSeq) {
        // 하위 폴더 포함 모든 folderSeq 수집
        List<Long> allSeqs = dmsMapper.selectDescendantFolderSeqs(familyId, folderSeq);
        if (allSeqs.isEmpty()) allSeqs = List.of(folderSeq);

        // 물리 파일 목록 수집 (삭제 전)
        List<DmsFileVO> files = dmsMapper.selectFilesByFolderSeqs(familyId, allSeqs);

        // DB 삭제 (파일 → 폴더 순, CASCADE가 없을 때 대비)
        dmsMapper.deleteFilesByFolderSeqs(familyId, allSeqs);
        dmsMapper.deleteFolder(familyId, folderSeq); // CTE CASCADE 없으면 루트만 제거

        // 하위 폴더도 직접 제거 (MariaDB FK CASCADE 미설정 시)
        for (Long seq : allSeqs) {
            if (!seq.equals(folderSeq)) {
                dmsMapper.deleteFolder(familyId, seq);
            }
        }

        return files; // 컨트롤러에서 물리 파일 삭제
    }

    public List<DmsFolderVO> getFolderTree(String familyId) {
        List<DmsFolderVO> all = dmsMapper.selectAllFolders(familyId);
        return buildTree(all, null);
    }

    public List<DmsFolderVO> getChildFolders(String familyId, Long parentSeq) {
        return dmsMapper.selectFoldersByParent(familyId, parentSeq);
    }

    public DmsFolderVO getFolder(String familyId, Long folderSeq) {
        return dmsMapper.selectFolder(familyId, folderSeq);
    }

    /** 루트~현재 폴더까지의 breadcrumb 경로 */
    public List<DmsFolderVO> getBreadcrumb(String familyId, Long folderSeq) {
        LinkedList<DmsFolderVO> crumbs = new LinkedList<>();
        Long cur = folderSeq;
        while (cur != null) {
            DmsFolderVO f = dmsMapper.selectFolder(familyId, cur);
            if (f == null) break;
            crumbs.addFirst(f);
            cur = f.getParentSeq();
        }
        return crumbs;
    }

    // ══════════════════════════ 파일 ══════════════════════════════

    @Transactional
    public DmsFileVO uploadFile(String familyId, Long folderSeq, MultipartFile mf, String userId)
            throws IOException {

        long usedBytes = dmsMapper.selectTotalUsedBytes(familyId);
        if (usedBytes + mf.getSize() > quotaBytes) {
            throw new IllegalStateException("저장 공간이 부족합니다. (할당: 1GB, 사용중: "
                    + formatSize(usedBytes) + ")");
        }

        String originalName = mf.getOriginalFilename();
        if (originalName == null) originalName = "unnamed";
        String ext = "";
        int dotIdx = originalName.lastIndexOf('.');
        if (dotIdx >= 0) ext = originalName.substring(dotIdx);   // ".pdf" etc.

        String storedNm = UUID.randomUUID() + ext;
        // transferTo()는 절대경로 필요 — 상대경로면 toAbsolutePath()로 변환
        Path dir = Paths.get(uploadBasePath, familyId).toAbsolutePath().normalize();
        Files.createDirectories(dir);
        Path dest = dir.resolve(storedNm);
        mf.transferTo(dest);   // Path 버전 사용 (File 버전보다 안정적)

        String mime = mf.getContentType();
        if (mime == null || mime.isBlank()) {
            mime = Files.probeContentType(dest);
        }

        DmsFileVO file = new DmsFileVO();
        file.setFamilyId(familyId);
        file.setFolderSeq(folderSeq);
        file.setFileNm(originalName);
        file.setStoredNm(storedNm);
        file.setFileSize(mf.getSize());
        file.setMimeType(mime != null ? mime : "application/octet-stream");
        file.setRegId(userId);
        file.setUpdId(userId);
        dmsMapper.insertFile(file);
        return file;
    }

    public void renameFile(String familyId, Long fileSeq, String newName, String userId) {
        String trimmed = newName == null ? "" : newName.trim();
        if (trimmed.isBlank()) throw new IllegalArgumentException("파일 이름을 입력해주세요.");
        dmsMapper.updateFileName(familyId, fileSeq, trimmed, userId);
    }

    public DmsFileVO getFile(String familyId, Long fileSeq) {
        return dmsMapper.selectFile(familyId, fileSeq);
    }

    public List<DmsFileVO> getFiles(String familyId, Long folderSeq) {
        return dmsMapper.selectFilesByFolder(familyId, folderSeq);
    }

    @Transactional
    public DmsFileVO deleteFile(String familyId, Long fileSeq) {
        DmsFileVO file = dmsMapper.selectFile(familyId, fileSeq);
        if (file == null) return null;
        dmsMapper.deleteFile(familyId, fileSeq);
        return file;
    }

    // ══════════════════════════ 쿼터 ══════════════════════════════

    public Map<String, Object> getQuotaInfo(String familyId) {
        long used  = dmsMapper.selectTotalUsedBytes(familyId);
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("usedBytes",  used);
        m.put("totalBytes", quotaBytes);
        m.put("freeBytes",  Math.max(0, quotaBytes - used));
        m.put("usedPct",    Math.min(100, Math.round(used * 100.0 / quotaBytes)));
        m.put("usedText",   formatSize(used));
        m.put("totalText",  formatSize(quotaBytes));
        return m;
    }

    // ══════════════════════════ 물리 파일 삭제 ════════════════════

    public void deletePhysicalFile(String familyId, String storedNm) {
        try {
            Path path = Paths.get(uploadBasePath, familyId, storedNm).toAbsolutePath().normalize();
            Files.deleteIfExists(path);
        } catch (Exception e) {
            log.warn("[DMS] 물리 파일 삭제 실패: {}/{}", familyId, storedNm);
        }
    }

    public Path resolvePhysicalPath(String familyId, String storedNm) {
        return Paths.get(uploadBasePath, familyId, storedNm).toAbsolutePath().normalize();
    }

    // ══════════════════════════ private ══════════════════════════

    private List<DmsFolderVO> buildTree(List<DmsFolderVO> all, Long parentSeq) {
        List<DmsFolderVO> nodes = new ArrayList<>();
        for (DmsFolderVO f : all) {
            boolean match = (parentSeq == null)
                    ? f.getParentSeq() == null
                    : parentSeq.equals(f.getParentSeq());
            if (match) {
                f.setChildren(buildTree(all, f.getFolderSeq()));
                nodes.add(f);
            }
        }
        return nodes;
    }

    private String formatSize(long bytes) {
        if (bytes < 1024) return bytes + " B";
        if (bytes < 1024 * 1024) return String.format("%.1f KB", bytes / 1024.0);
        if (bytes < 1024L * 1024 * 1024) return String.format("%.1f MB", bytes / (1024.0 * 1024));
        return String.format("%.2f GB", bytes / (1024.0 * 1024 * 1024));
    }
}
