package com.dvcguide.server.admin.controller;

import com.dvcguide.server.admin.dto.AiSourceModels;
import com.dvcguide.server.admin.entity.RagSyncJob;
import com.dvcguide.server.admin.repository.RagSyncJobRepository;
import com.dvcguide.server.admin.service.RagSyncService;
import com.dvcguide.server.common.model.ProcedureStatus;
import com.dvcguide.server.common.response.*;
import com.dvcguide.server.procedure.repository.ProcedureRepository;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.Objects;

@RestController
@RequestMapping("/api/v1/admin/rag")
@RequiredArgsConstructor
public class AdminRagSyncController {
    private final ProcedureRepository procedures;
    private final RagSyncJobRepository jobs;
    private final RagSyncService sync;

    public record State(int procedureId, String code, String name, int procedureVersion, Integer indexedVersion,
                        ProcedureStatus publicationStatus, String status, int chunkCount, int attempts,
                        String message, Instant indexedAt, Instant nextAttemptAt) {}

    @GetMapping("/sources")
    @Transactional(readOnly = true)
    public ApiResponse<PageResponse<State>> list(@RequestParam(defaultValue = "0") @Min(0) int page,
            @RequestParam(defaultValue = "20") @Min(1) @Max(100) int size) {
        return ApiResponse.success(PageResponse.from(procedures.findAll(PageRequest.of(page, size, Sort.by("id").descending())).map(p -> {
            var job = jobs.findById(p.getId()).orElse(null);
            String status = job == null ? "NOT_INDEXED" : job.getStatus().name();
            if (job != null && job.getStatus() == RagSyncJob.Status.SYNCED) {
                status = !Objects.equals(job.getIndexedVersion(), p.getPhienBan()) ? "OUTDATED"
                        : p.getTrangThai() == ProcedureStatus.dang_dung ? "UP_TO_DATE" : "EXCLUDED";
            }
            return new State(p.getId(), p.getMaThuTuc(), p.getTen(), p.getPhienBan(), job == null ? null : job.getIndexedVersion(),
                    p.getTrangThai(), status, job == null ? 0 : job.getChunkCount(), job == null ? 0 : job.getAttempts(),
                    job == null ? null : job.getLastError(), job == null ? null : job.getIndexedAt(), job == null ? null : job.getNextAttemptAt());
        })));
    }

    @PostMapping("/sync")
    @ResponseStatus(HttpStatus.ACCEPTED)
    @Transactional
    public ApiResponse<String> retry(@Valid @RequestBody AiSourceModels.SyncRequest input) {
        for (var target : input.targets()) {
            var procedure = procedures.lockById(target.procedureId())
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy thủ tục."));
            if (procedure.getPhienBan() != target.expectedVersion()) {
                throw new ResponseStatusException(HttpStatus.CONFLICT, "Thủ tục đã thay đổi. Hãy tải lại danh sách.");
            }
            sync.enqueue(procedure);
        }
        return ApiResponse.success("Đã đưa vào hàng đợi đồng bộ.");
    }
}
