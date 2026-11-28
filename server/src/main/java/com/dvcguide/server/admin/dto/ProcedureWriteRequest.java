package com.dvcguide.server.admin.dto;

import com.dvcguide.server.common.model.AdministrativeLevel;
import com.dvcguide.server.common.model.ProcedureStatus;
import com.fasterxml.jackson.databind.JsonNode;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.util.List;

public record ProcedureWriteRequest(
        @NotBlank @Size(max = 50) String code,
        @NotBlank @Size(max = 1000) String name,
        AdministrativeLevel level,
        @NotNull ProcedureStatus status,
        @Positive Integer version,
        @Size(max = 16000) String originalAgency,
        @Size(max = 16000) String audience,
        @Size(max = 16000) String conditions,
        @Size(max = 1000) String portalUrl,
        @Size(max = 500) String source,
        @NotNull @Size(max = 50) List<@NotNull @Positive Integer> fieldIds,
        JsonNode content) {
    public ProcedureWriteRequest(String code, String name, AdministrativeLevel level, ProcedureStatus status,
            Integer version, String originalAgency, String audience, String conditions, String portalUrl,
            String source, List<Integer> fieldIds) {
        this(code, name, level, status, version, originalAgency, audience, conditions, portalUrl, source, fieldIds, null);
    }
}
