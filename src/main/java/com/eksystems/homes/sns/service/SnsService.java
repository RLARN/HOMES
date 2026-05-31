package com.eksystems.homes.sns.service;

import com.eksystems.homes.sns.mapper.SnsMapper;
import com.eksystems.homes.sns.vo.SnsCommentVO;
import com.eksystems.homes.sns.vo.SnsPostImgVO;
import com.eksystems.homes.sns.vo.SnsPostVO;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class SnsService {

    private static final Logger log = LoggerFactory.getLogger(SnsService.class);
    private static final int PAGE_SIZE = 10;

    @Value("${sns.upload.path:C:/homes-uploads/sns}")
    private String uploadBasePath;

    private final SnsMapper snsMapper;

    public SnsService(SnsMapper snsMapper) {
        this.snsMapper = snsMapper;
    }

    /** 피드 조회 (페이지) — 이미지·좋아요·댓글수 배치 조회 */
    public Map<String, Object> getFeed(String familyId, int page, String userId) {
        int offset = (page - 1) * PAGE_SIZE;
        List<SnsPostVO> posts = snsMapper.selectPosts(familyId, offset, PAGE_SIZE);

        if (!posts.isEmpty()) {
            List<Long> postSeqs = posts.stream().map(SnsPostVO::getPostSeq).toList();
            List<SnsPostImgVO> allImgs = snsMapper.selectImgsByPosts(familyId, postSeqs);
            Map<Long, List<SnsPostImgVO>> imgMap = allImgs.stream()
                    .collect(Collectors.groupingBy(SnsPostImgVO::getPostSeq));
            posts.forEach(p -> {
                p.setImages(imgMap.getOrDefault(p.getPostSeq(), List.of()));
                p.setLikeCount(snsMapper.countLikes(p.getPostSeq()));
                p.setLiked(snsMapper.isLiked(p.getPostSeq(), familyId, userId) > 0);
                p.setCommentCount(snsMapper.countCommentsByPost(p.getPostSeq()));
            });
        }

        int total = snsMapper.countPosts(familyId);
        boolean hasMore = offset + posts.size() < total;

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("posts",   posts);
        result.put("page",    page);
        result.put("hasMore", hasMore);
        result.put("total",   total);
        return result;
    }

    /** 게시글 상세 조회 (이미지 + 댓글 + 좋아요) */
    public Map<String, Object> getPostDetail(String familyId, Long postSeq, String userId) {
        SnsPostVO post = snsMapper.selectPost(familyId, postSeq);
        if (post == null) return null;

        post.setImages(snsMapper.selectImgsByPost(postSeq));
        post.setLikeCount(snsMapper.countLikes(postSeq));
        post.setLiked(snsMapper.isLiked(postSeq, familyId, userId) > 0);
        post.setCommentCount(snsMapper.countCommentsByPost(postSeq));

        List<SnsCommentVO> comments = snsMapper.selectCommentsByPost(postSeq, familyId);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("post",     post);
        result.put("comments", comments);
        return result;
    }

    /** 게시글 작성 */
    @Transactional
    public SnsPostVO createPost(String familyId, String content,
                                List<MultipartFile> images, String userId) throws IOException {
        SnsPostVO post = new SnsPostVO();
        post.setFamilyId(familyId);
        post.setContent(content);
        post.setRegId(userId);
        snsMapper.insertPost(post);

        if (images != null) {
            int order = 0;
            for (MultipartFile mf : images) {
                if (mf == null || mf.isEmpty()) continue;
                String storedNm = saveFile(familyId, mf);
                SnsPostImgVO img = new SnsPostImgVO();
                img.setPostSeq(post.getPostSeq());
                img.setFamilyId(familyId);
                img.setFileNm(mf.getOriginalFilename());
                img.setStoredNm(storedNm);
                img.setSortOrder(order++);
                img.setRegId(userId);
                snsMapper.insertImg(img);
            }
        }

        // 이미지 포함해서 반환
        post.setImages(snsMapper.selectImgsByPost(post.getPostSeq()));
        return post;
    }

    /** 게시글 삭제 */
    @Transactional
    public void deletePost(String familyId, Long postSeq, String userId) {
        SnsPostVO post = snsMapper.selectPost(familyId, postSeq);
        if (post == null) return;
        // 본인 또는 같은 family 삭제 허용 (familyId 격리로 충분)
        List<SnsPostImgVO> imgs = snsMapper.selectImgsByPost(postSeq);
        snsMapper.deleteImgsByPost(postSeq);
        snsMapper.deletePost(familyId, postSeq);
        imgs.forEach(img -> deletePhysical(familyId, img.getStoredNm()));
    }

    /** 게시글 수정 (텍스트만) */
    @Transactional
    public void updatePost(String familyId, Long postSeq, String content) {
        SnsPostVO post = new SnsPostVO();
        post.setPostSeq(postSeq);
        post.setFamilyId(familyId);
        post.setContent(content);
        snsMapper.updatePost(post);
    }

    /** 댓글 등록 */
    public SnsCommentVO addComment(String familyId, Long postSeq, String content, String userId) {
        SnsCommentVO comment = new SnsCommentVO();
        comment.setPostSeq(postSeq);
        comment.setFamilyId(familyId);
        comment.setContent(content.trim());
        comment.setRegId(userId);
        snsMapper.insertComment(comment);
        return comment;
    }

    /** 댓글 삭제 */
    public void deleteComment(String familyId, Long commentSeq) {
        snsMapper.deleteComment(commentSeq, familyId);
    }

    /** 좋아요 토글 */
    public Map<String, Object> toggleLike(String familyId, Long postSeq, String userId) {
        boolean liked = snsMapper.isLiked(postSeq, familyId, userId) > 0;
        if (liked) {
            snsMapper.deleteLike(postSeq, familyId, userId);
        } else {
            snsMapper.insertLike(postSeq, familyId, userId);
        }
        int count = snsMapper.countLikes(postSeq);
        return Map.of("liked", !liked, "likeCount", count);
    }

    /** 이미지 서빙 경로 */
    public Path resolveImg(String familyId, String storedNm) {
        return Paths.get(uploadBasePath, familyId, storedNm).toAbsolutePath().normalize();
    }

    // ── private ──────────────────────────────────────────────────
    private String saveFile(String familyId, MultipartFile mf) throws IOException {
        String orig = mf.getOriginalFilename() == null ? "img" : mf.getOriginalFilename();
        String ext  = orig.contains(".") ? orig.substring(orig.lastIndexOf('.')) : "";
        String name = UUID.randomUUID() + ext;
        Path dir = Paths.get(uploadBasePath, familyId).toAbsolutePath().normalize();
        Files.createDirectories(dir);
        mf.transferTo(dir.resolve(name));
        return name;
    }

    private void deletePhysical(String familyId, String storedNm) {
        try {
            Files.deleteIfExists(Paths.get(uploadBasePath, familyId, storedNm).toAbsolutePath());
        } catch (Exception e) {
            log.warn("[SNS] 파일 삭제 실패: {}", storedNm);
        }
    }
}
