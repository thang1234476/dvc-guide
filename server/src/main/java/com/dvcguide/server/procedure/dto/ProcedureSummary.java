package com.dvcguide.server.procedure.dto;

import com.dvcguide.server.common.model.AdministrativeLevel;
import com.dvcguide.server.common.model.ProcedureStatus;
import com.dvcguide.server.procedure.entity.Procedure;

import java.time.Instant;
import java.util.List;

public record ProcedureSummary(int id, String code, String name, AdministrativeLevel level,
                               ProcedureStatus status, int version, Instant updatedAt,
                               List<Field> fields, boolean saved) {

    public record Field(int id, String code, String name) {}

    public static ProcedureSummary from(Procedure row, List<Field> fields, boolean saved) {
        return new ProcedureSummary(row.getId(), row.getMaThuTuc(), row.getTen(), row.getCapThucHien(),
                row.getTrangThai(), row.getPhienBan(), row.getCapNhatLuc(), fields, saved);
    }
}
