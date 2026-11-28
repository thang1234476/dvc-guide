package com.dvcguide.server.admin.service;

import com.dvcguide.server.admin.repository.RagSyncJobRepository;
import com.dvcguide.server.admin.entity.RagSyncJob;
import com.dvcguide.server.integration.rag.RagSyncClient;
import com.dvcguide.server.procedure.repository.ProcedureRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.concurrent.atomic.AtomicBoolean;

@Component
@RequiredArgsConstructor
public class RagSyncWorker {
    private final RagSyncJobRepository jobs;
    private final RagSyncService sync;
    private final RagSyncClient client;
    private final ProcedureRepository procedures;
    private final AtomicBoolean running = new AtomicBoolean();
    @Value("${integration.rag-sync.enabled:true}") private boolean enabled;
    private Instant nextReconcile = Instant.EPOCH;

    @Scheduled(fixedDelayString = "${integration.rag-sync.poll-ms:3000}", initialDelayString = "${integration.rag-sync.initial-delay-ms:5000}")
    public void scheduled() {
        if (enabled) runOnce();
    }

    public void runOnce() {
        if (!running.compareAndSet(false, true)) return;
        try {
            if (nextReconcile.isBefore(Instant.now())) {
                long count = procedures.count();
                for (int page = 0; page * 200L < count; page++) sync.reconcile(page);
                nextReconcile = Instant.now().plusSeconds(60);
            }
            for (int id : jobs.due(Instant.now(), RagSyncJob.Status.SYNCED, PageRequest.of(0, 20))) {
                RagSyncService.Claim claim;
                try { claim = sync.claim(id); }
                catch (RuntimeException error) { sync.failBeforeClaim(id); continue; }
                if (claim == null) continue;
                try {
                    sync.acknowledge(claim, client.sync(claim.id(), claim.payload()));
                } catch (Exception exception) {
                    sync.fail(claim, exception instanceof IllegalStateException ? exception.getMessage()
                            : "Chưa kết nối hoặc chưa cập nhật được AI-service. Hệ thống sẽ tự thử lại.");
                }
            }
        } finally {
            running.set(false);
        }
    }
}
