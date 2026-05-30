package com.eksystems.homes.common.batch;

import com.eksystems.homes.asset.service.SnapshotService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Component
public class SnapshotBatch {

    private static final Logger log = LoggerFactory.getLogger(SnapshotBatch.class);

    private final SnapshotService snapshotService;

    public SnapshotBatch(SnapshotService snapshotService) {
        this.snapshotService = snapshotService;
    }

    /**
     * 매월 말일 23:00 자동 전표처리.
     * 28~31일에 실행되며, 실제 말일인지 체크 후 수행.
     */
    @Scheduled(cron = "0 0 23 28-31 * ?")
    public void autoSnapshot() {
        LocalDate today = LocalDate.now();
        if (today.getDayOfMonth() != today.lengthOfMonth()) return;

        String yymm = today.format(DateTimeFormatter.ofPattern("yyyyMM"));
        List<String> familyIds = snapshotService.getAllFamilyIds();

        log.info("[SnapshotBatch] 자동 전표처리 시작 - {} / {} families", yymm, familyIds.size());

        for (String familyId : familyIds) {
            try {
                if (!snapshotService.hasSnapshot(familyId, yymm)) {
                    snapshotService.snapshot(familyId, yymm, "SYSTEM");
                    log.info("[SnapshotBatch] 완료 - familyId={}, yymm={}", familyId, yymm);
                } else {
                    log.info("[SnapshotBatch] 이미 처리됨 - familyId={}, yymm={}", familyId, yymm);
                }
            } catch (Exception e) {
                log.error("[SnapshotBatch] 오류 - familyId={}, yymm={}", familyId, yymm, e);
            }
        }
    }
}
