package com.dvcguide.server.admin.service;

import com.dvcguide.server.admin.entity.RagSyncJob;
import com.dvcguide.server.admin.repository.RagSyncJobRepository;
import com.dvcguide.server.common.model.ProcedureStatus;
import com.dvcguide.server.integration.rag.RagSyncClient;
import com.dvcguide.server.procedure.entity.Procedure;
import com.dvcguide.server.procedure.repository.ProcedureRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Objects;

@Service
@RequiredArgsConstructor
public class RagSyncService {
    private final RagSyncJobRepository jobs;
    private final ProcedureRepository procedures;
    private final ProcedureSourceService sources;

    @Transactional
    public void enqueue(Procedure procedure) {
        procedure = procedures.lockById(procedure.getId()).orElseThrow();
        int id = procedure.getId();
        var job = jobs.lockById(id).orElseGet(() -> {
            var created = new RagSyncJob();
            created.setProcedureId(id);
            return created;
        });
        job.setDesiredVersion(procedure.getPhienBan());
        job.setStatus(RagSyncJob.Status.PENDING);
        job.setAttempts(0);
        job.setLastError(null);
        job.setNextAttemptAt(Instant.now());
        jobs.save(job);
    }

    public record Claim(int id, RagSyncClient.Payload payload) {}

    @Transactional
    public Claim claim(int id) {
        var job = jobs.lockById(id).orElse(null);
        Instant now = Instant.now();
        if (job == null || job.getStatus() == RagSyncJob.Status.SYNCED || job.getNextAttemptAt().isAfter(now)
                || job.getLeaseUntil() != null && job.getLeaseUntil().isAfter(now)) return null;
        var procedure = procedures.findById(id).orElse(null);
        if (procedure == null) return null;
        boolean active = procedure.getTrangThai() == ProcedureStatus.dang_dung;
        job.setDesiredVersion(procedure.getPhienBan());
        job.setStatus(RagSyncJob.Status.PROCESSING);
        job.setAttempts(job.getAttempts() + 1);
        job.setLeaseUntil(now.plusSeconds(600));
        return new Claim(id, new RagSyncClient.Payload(procedure.getPhienBan(), procedure.getMaThuTuc(), active,
                active ? sources.export(procedure) : null));
    }

    @Transactional
    public void acknowledge(Claim claim, RagSyncClient.Result result) {
        var job = jobs.lockById(claim.id()).orElseThrow();
        if (result == null || result.procedureId() != claim.id() || result.version() != claim.payload().version()
                || !result.code().equals(claim.payload().code()) || result.active() != claim.payload().active()
                || result.chunkCount() < 0) throw new IllegalStateException("AI-service trả kết quả đồng bộ không khớp.");
        if (job.getIndexedVersion() != null && job.getIndexedVersion() > result.version()) return;
        job.setIndexedVersion(result.version());
        job.setChunkCount(result.chunkCount());
        job.setIndexedAt(Instant.now());
        job.setLastError(null);
        job.setLeaseUntil(null);
        job.setStatus(Objects.equals(job.getDesiredVersion(), result.version()) ? RagSyncJob.Status.SYNCED : RagSyncJob.Status.PENDING);
    }

    @Transactional
    public void fail(Claim claim, String message) {
        var job = jobs.lockById(claim.id()).orElseThrow();
        job.setLeaseUntil(null);
        if (!Objects.equals(job.getDesiredVersion(), claim.payload().version())) return;
        job.setStatus(RagSyncJob.Status.FAILED);
        job.setLastError(message);
        job.setNextAttemptAt(Instant.now().plusSeconds(Math.min(300, 5L << Math.min(6, job.getAttempts() - 1))));
    }

    @Transactional
    public void failBeforeClaim(int id) {
        var job = jobs.lockById(id).orElseThrow();
        job.setStatus(RagSyncJob.Status.FAILED);
        job.setLeaseUntil(null);
        job.setLastError("Không dựng được dữ liệu nguồn cho RAG. Hãy kiểm tra nội dung thủ tục rồi đồng bộ lại.");
        job.setNextAttemptAt(Instant.now().plusSeconds(60));
    }

    @Transactional
    public void reconcile(int page) {
        for (var procedure : procedures.findAll(PageRequest.of(page, 200))) {
            var job = jobs.findById(procedure.getId()).orElse(null);
            if (job == null || !Objects.equals(job.getDesiredVersion(), procedure.getPhienBan())) enqueue(procedure);
        }
    }
}
