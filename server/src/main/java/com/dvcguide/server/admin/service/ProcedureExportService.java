package com.dvcguide.server.admin.service;

import com.dvcguide.server.common.exception.ResourceNotFoundException;
import com.dvcguide.server.common.model.ProcedureStatus;
import com.dvcguide.server.procedure.repository.ProcedureRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true, isolation = Isolation.REPEATABLE_READ)
public class ProcedureExportService {
    private final ProcedureRepository procedures;
    private final ProcedureSourceService sources;
    private final ObjectMapper json;

    public ObjectNode content(int id) {
        return sources.export(procedures.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy thủ tục.")));
    }

    public byte[] one(int id) {
        return serialize(List.of(content(id)));
    }

    public byte[] all(boolean activeOnly) {
        var rows = activeOnly ? procedures.findByTrangThaiOrderById(ProcedureStatus.dang_dung)
                : procedures.findAll(Sort.by("id"));
        return serialize(rows.stream().map(sources::export).toList());
    }

    private byte[] serialize(Object value) {
        try { return json.writerWithDefaultPrettyPrinter().writeValueAsBytes(value); }
        catch (com.fasterxml.jackson.core.JsonProcessingException error) { throw new IllegalStateException("Không xuất được dữ liệu JSON.", error); }
    }
}
