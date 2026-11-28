package com.dvcguide.server.admin.dto;

import com.dvcguide.server.integration.ai.AiServiceClient;
import com.dvcguide.server.procedure.dto.ProcedureSummary;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.util.List;

/**
 * Contracts for synchronizing procedure versions with RAG and inspecting test answers.
 */
public final class AiSourceModels {
    private AiSourceModels() {}

    public enum SourceStatus {
        NOT_INDEXED,
        UP_TO_DATE,
        OUTDATED,
        EXCLUDED,
        FAILED
    }

    public record Target(@Positive int procedureId, @Positive int expectedVersion) {}

    public record SyncRequest(
            @NotNull @Size(min = 1, max = 1000) List<@NotNull @Valid Target> targets) {}

    public record SourceState(int procedureId, String code, int procedureVersion, Integer indexedVersion,
                              int chunkCount, SourceStatus status, String message) {}

    public record SyncResult(List<SourceState> procedures) {}

    public record TestRequest(@NotBlank @Size(max = 2000) String question, @Positive Integer procedureId) {}

    public record TestResponse(String question, AiServiceClient.Answer result,
                               List<ProcedureSummary> sources) {}
}
