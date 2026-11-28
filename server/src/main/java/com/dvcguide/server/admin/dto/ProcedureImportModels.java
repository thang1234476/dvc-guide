package com.dvcguide.server.admin.dto;

import com.dvcguide.server.common.model.ProcedureStatus;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;
import java.util.Map;
import com.fasterxml.jackson.databind.JsonNode;

/**
 * Preview and confirmation contracts for an import. Row numbers are one-based.
 * A preview never implies that the records have already been persisted.
 */
public final class ProcedureImportModels {
    private ProcedureImportModels() {}

    public enum DuplicatePolicy {
        SKIP_EXISTING,
        UPDATE_EXISTING
    }

    public enum RowAction {
        CREATE,
        UPDATE,
        SKIP,
        INVALID
    }

    public record Request(
            @NotNull @Size(min = 1, max = 10000) List<@NotNull JsonNode> procedures,
            @NotNull DuplicatePolicy duplicatePolicy,
            @NotNull ProcedureStatus status) {}

    public record Confirmation(@NotNull @Valid Request request,
                               @NotNull @Size(max = 10000) Map<String, Integer> expectedVersions) {}

    public record Issue(int rowNumber, String procedureCode, String field, String message) {}

    public record Row(int rowNumber, String code, String name, Integer existingProcedureId,
                      Integer existingVersion, RowAction action, List<Issue> issues) {}

    public record Preview(int total, int createCount, int updateCount, int skipCount, int invalidCount,
                          List<Row> rows) {}

    public record Result(int total, int createdCount, int updatedCount, int skippedCount, int failedCount,
                         List<Issue> issues) {}
}
