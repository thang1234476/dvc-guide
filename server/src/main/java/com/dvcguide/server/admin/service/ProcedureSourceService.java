package com.dvcguide.server.admin.service;

import com.dvcguide.server.admin.entity.ProcedureSource;
import com.dvcguide.server.admin.dto.ProcedureWriteRequest;
import com.dvcguide.server.procedure.dto.ProcedureDetail;
import com.dvcguide.server.procedure.entity.Procedure;
import com.dvcguide.server.procedure.service.ProcedureService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import jakarta.persistence.EntityManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Objects;
import java.util.UUID;
import java.nio.charset.StandardCharsets;

@Service
@RequiredArgsConstructor
public class ProcedureSourceService {
    private final EntityManager db;
    private final ObjectMapper json;
    private final ProcedureService procedures;
    private final ProcedurePayloadProjection projection;

    public void store(int id, JsonNode payload) {
        var source = db.find(ProcedureSource.class, id);
        if (source == null) {
            source = new ProcedureSource();
            source.setProcedureId(id);
            source.setPayload(payload.deepCopy());
            db.persist(source);
        }
        source.setPayload(payload.deepCopy());
    }

    public ObjectNode export(Procedure row) {
        var saved = db.find(ProcedureSource.class, row.getId());
        ObjectNode p = saved == null ? json.createObjectNode() : (ObjectNode) saved.getPayload().deepCopy();
        var detail = saved == null ? procedures.detailAdmin(row.getId()) : null;
        projection.project(row, p);
        if (saved == null) fillChildren(p, detail);
        if (!p.hasNonNull("id")) p.put("id", UUID.nameUUIDFromBytes(("dvc-guide:procedure:" + row.getId()).getBytes(StandardCharsets.UTF_8)).toString());
        completeNewPayload(p);
        return p;
    }

    public ObjectNode prepare(ProcedureWriteRequest input, ObjectNode before) {
        if (input.content() != null && !input.content().isObject()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Nội dung thủ tục phải là một đối tượng JSON.");
        }
        ObjectNode p = input.content() == null ? before.deepCopy() : ((ObjectNode) input.content()).deepCopy();
        if (p.hasNonNull("co_quan") && !p.get("co_quan").isObject()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "co_quan phải là một đối tượng JSON.");
        }
        if (before.hasNonNull("id") && p.hasNonNull("id") && !before.get("id").equals(p.get("id"))) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Không được thay đổi ID nguồn của thủ tục.");
        }
        if (before.has("id")) p.set("id", before.get("id"));
        p.put("ma_thu_tuc", input.code().strip());
        p.put("ten", input.name().strip());
        syncText(p, "doi_tuong", input.audience());
        syncText(p, "yeu_cau_dieu_kien", input.conditions());
        if (input.level() != null) p.put("cap_thuc_hien", input.level().name());
        else if (input.content() == null || ProcedureContentWriter.level(p.path("cap_thuc_hien").asText()) != null) p.put("cap_thuc_hien", "");
        if (!p.path("co_quan").isObject()) p.set("co_quan", json.createObjectNode());
        syncText((ObjectNode) p.get("co_quan"), "thuc_hien", input.originalAgency());
        projection.setFields(p, input.fieldIds());
        completeNewPayload(p);
        return p;
    }

    private void syncText(ObjectNode p, String key, String value) {
        String existing = p.path(key).isTextual() ? p.get(key).asText() : null;
        if (!Objects.equals(normalized(existing), normalized(value)) || !p.has(key)) p.put(key, value);
    }

    private String normalized(String value) { return value == null || value.isBlank() ? null : value.strip(); }

    private void completeNewPayload(ObjectNode p) {
        if (!p.has("schema_version")) p.put("schema_version", "1.0");
        if (!p.hasNonNull("id")) p.put("id", UUID.randomUUID().toString());
        for (String key : List.of("so_quyet_dinh", "cap_thuc_hien", "loai_thu_tuc")) if (!p.has(key)) p.put(key, "");
        for (String key : List.of("linh_vuc", "trinh_tu", "cach_thuc", "ho_so", "can_cu", "ket_qua", "tu_khoa")) if (!p.has(key)) p.putArray(key);
    }

    private void fillChildren(ObjectNode p, ProcedureDetail detail) {
        var steps = p.putArray("trinh_tu");
        detail.steps().forEach(step -> steps.add(step.description() == null ? step.title() : step.description()));
        var documents = p.putArray("ho_so");
        for (var d : detail.documents()) {
            var document = documents.addObject().put("nhom", d.group()).put("ten", d.name()).put("truong_hop", d.originalCase());
            document.set("so_ban_chinh", json.valueToTree(d.originals()));
            document.set("so_ban_sao", json.valueToTree(d.copies()));
            var forms = document.putArray("mau_don");
            for (var f : d.forms()) {
                forms.addObject().put("ten", f.name()).put("file_id", f.code())
                        .put("url", f.docxUrl() == null ? f.pdfUrl() : f.docxUrl());
            }
        }
        var submissions = p.putArray("cach_thuc");
        for (var s : detail.submissions()) {
            var submission = submissions.addObject().put("hinh_thuc", s.channel().name()).put("hinh_thuc_goc", s.originalChannel());
            var duration = submission.putObject("thoi_han").put("don_vi", s.durationUnit()).put("goc", s.originalDuration());
            duration.set("so", json.valueToTree(s.duration()));
            var fees = submission.putArray("le_phi");
            for (var f : s.fees()) {
                var fee = fees.addObject().put("mien_phi", f.free()).put("tien_te", f.currency()).put("ghi_chu", f.notes());
                fee.set("so_tien", json.valueToTree(f.amount()));
            }
        }
        var results = p.putArray("ket_qua");
        detail.results().forEach(r -> results.addObject().put("ten", r));
        var laws = p.putArray("can_cu");
        detail.legalBases().forEach(law -> laws.addObject().put("ma", law.reference()).put("ten", law.name()));
    }
}
