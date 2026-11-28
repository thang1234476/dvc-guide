package com.dvcguide.server.admin.service;

import com.dvcguide.server.admin.entity.ProcedureSource;
import com.dvcguide.server.catalog.entity.ProcedureField;
import com.dvcguide.server.procedure.entity.Procedure;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import jakarta.persistence.EntityManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Objects;

@Service
@RequiredArgsConstructor
public class ProcedurePayloadProjection {
    private final EntityManager db;
    private final ObjectMapper json;

    public ObjectNode project(Procedure row, ObjectNode payload) {
        payload.put("ma_thu_tuc", row.getMaThuTuc());
        payload.put("ten", row.getTen());
        payload.put("doi_tuong", row.getDoiTuong());
        payload.put("yeu_cau_dieu_kien", row.getDieuKien());
        if (row.getCapThucHien() != null) payload.put("cap_thuc_hien", row.getCapThucHien().name());
        var agencies = payload.path("co_quan").isObject() ? (ObjectNode) payload.get("co_quan") : json.createObjectNode();
        agencies.put("thuc_hien", row.getCoQuanThucHienGoc()); payload.set("co_quan", agencies);
        var ids = db.createQuery("select l.linhVucId from ProcedureFieldLink l where l.thuTucId = :id order by l.thuTu, l.linhVucId", Integer.class)
                .setParameter("id", row.getId()).getResultList();
        setFields(payload, ids);
        return payload;
    }

    public void setFields(ObjectNode p, List<Integer> ids) {
        var original = p.path("linh_vuc").deepCopy();
        var fields = p.putArray("linh_vuc");
        for (int id : ids) {
            var field = db.find(ProcedureField.class, id);
            ObjectNode item = null;
            for (var candidate : original) {
                String sourceId = candidate.path("id").asText("");
                String code = sourceId.length() <= 30 ? sourceId : ProcedureContentWriter.key(sourceId, 28);
                if ((Objects.equals(field.getMa(), code) || Objects.equals(field.getMa(), ProcedureContentWriter.key(sourceId + "|" + candidate.path("ten").asText(), 28)))
                        && field.getTen().equals(candidate.path("ten").asText())) {
                    item = ((ObjectNode) candidate).deepCopy(); break;
                }
            }
            if (item == null) item = originalField(field);
            if (item == null) item = json.createObjectNode().put("id", field.getMa());
            item.put("ten", field.getTen());
            fields.add(item);
        }
    }

    private ObjectNode originalField(ProcedureField field) {
        for (var source : db.createQuery("select s from ProcedureSource s order by s.procedureId", ProcedureSource.class).getResultList()) {
            for (var candidate : source.getPayload().path("linh_vuc")) {
                if (!candidate.isObject() || !field.getTen().equals(candidate.path("ten").asText())) continue;
                String id = candidate.path("id").asText("");
                String code = id.length() <= 30 ? id : ProcedureContentWriter.key(id, 28);
                if (Objects.equals(field.getMa(), code) || Objects.equals(field.getMa(), ProcedureContentWriter.key(id + "|" + field.getTen(), 28))) {
                    return ((ObjectNode) candidate).deepCopy();
                }
            }
        }
        return null;
    }

}
