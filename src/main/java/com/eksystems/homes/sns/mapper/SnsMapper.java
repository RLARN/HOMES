package com.eksystems.homes.sns.mapper;

import com.eksystems.homes.sns.vo.SnsCommentVO;
import com.eksystems.homes.sns.vo.SnsPostImgVO;
import com.eksystems.homes.sns.vo.SnsPostVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface SnsMapper {
    void insertPost(SnsPostVO post);
    void updatePost(SnsPostVO post);
    void insertImg(SnsPostImgVO img);

    List<SnsPostVO> selectPosts(@Param("familyId") String familyId,
                                @Param("offset") int offset,
                                @Param("limit") int limit);
    List<SnsPostImgVO> selectImgsByPost(@Param("postSeq") Long postSeq);
    List<SnsPostImgVO> selectImgsByPosts(@Param("familyId") String familyId,
                                         @Param("postSeqs") List<Long> postSeqs);

    SnsPostVO selectPost(@Param("familyId") String familyId, @Param("postSeq") Long postSeq);
    int countPosts(@Param("familyId") String familyId);

    void deletePost(@Param("familyId") String familyId, @Param("postSeq") Long postSeq);
    void deleteImgsByPost(@Param("postSeq") Long postSeq);

    List<SnsPostVO> searchPosts(@Param("familyId") String familyId, @Param("keyword") String keyword);

    // ── 댓글 ──────────────────────────────────────────────────────
    void insertComment(SnsCommentVO comment);
    List<SnsCommentVO> selectCommentsByPost(@Param("postSeq") Long postSeq,
                                            @Param("familyId") String familyId);
    SnsCommentVO selectComment(@Param("commentSeq") Long commentSeq,
                               @Param("familyId") String familyId);
    void deleteComment(@Param("commentSeq") Long commentSeq,
                       @Param("familyId") String familyId);
    int countCommentsByPost(@Param("postSeq") Long postSeq);

    // ── 좋아요 ──────────────────────────────────────────────────────
    void insertLike(@Param("postSeq") Long postSeq,
                    @Param("familyId") String familyId,
                    @Param("regId") String regId);
    void deleteLike(@Param("postSeq") Long postSeq,
                    @Param("familyId") String familyId,
                    @Param("regId") String regId);
    int countLikes(@Param("postSeq") Long postSeq);
    int isLiked(@Param("postSeq") Long postSeq,
                @Param("familyId") String familyId,
                @Param("regId") String regId);
    List<Integer> countLikesByPosts(@Param("familyId") String familyId,
                                    @Param("postSeqs") List<Long> postSeqs);
    List<Integer> isLikedByPosts(@Param("familyId") String familyId,
                                 @Param("postSeqs") List<Long> postSeqs,
                                 @Param("regId") String regId);
}
