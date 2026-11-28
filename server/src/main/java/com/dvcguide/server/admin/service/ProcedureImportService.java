package com.dvcguide.server.admin.service;

import com.dvcguide.server.admin.dto.CleanProcedureData;
import com.dvcguide.server.admin.dto.ProcedureImportModels.Request;
import com.dvcguide.server.admin.dto.ProcedureImportModels.Confirmation;
import com.dvcguide.server.admin.dto.ProcedureImportModels.Preview;
import com.dvcguide.server.admin.dto.ProcedureImportModels.Result;
import com.dvcguide.server.admin.dto.ProcedureImportModels.Row;
import com.dvcguide.server.admin.dto.ProcedureImportModels.RowAction;
import com.dvcguide.server.admin.dto.ProcedureImportModels.Issue;
import com.dvcguide.server.admin.dto.ProcedureImportModels.DuplicatePolicy;
import com.dvcguide.server.admin.entity.ChangeLog;
import com.dvcguide.server.admin.entity.ProcedureSource;
import com.dvcguide.server.admin.repository.AdministratorRepository;
import com.dvcguide.server.common.model.*;
import com.dvcguide.server.common.util.VietnameseText;
import com.dvcguide.server.procedure.entity.*;
import com.dvcguide.server.procedure.repository.ProcedureRepository;
import com.fasterxml.jackson.databind.*;
import jakarta.persistence.EntityManager;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.web.server.ResponseStatusException;

import java.util.*;

@Service
public class ProcedureImportService {
    private final ProcedureRepository procedures;
    private final AdministratorRepository admins;
    private final ProcedureSourceService sources;
    private final RagSyncService ragSync;
    private final EntityManager db;
    private final ObjectMapper json;
    private final ProcedureContentWriter content;
    private final TransactionTemplate transaction;

    public ProcedureImportService(ProcedureRepository procedures, AdministratorRepository admins, ProcedureSourceService sources,
            RagSyncService ragSync, EntityManager db, ObjectMapper json, ProcedureContentWriter content, PlatformTransactionManager manager) {
        this.procedures = procedures; this.admins = admins; this.sources = sources; this.ragSync = ragSync;
        this.db = db; this.json = json; this.content = content;
        transaction = new TransactionTemplate(manager);
        transaction.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRES_NEW);
    }

    @Transactional(readOnly = true)
    public Preview preview(Request input) {
        var seen = new HashSet<String>();
        var rows = new ArrayList<Row>();
        for (int i = 0; i < input.procedures().size(); i++) {
            JsonNode raw = input.procedures().get(i);
            String code = raw.path("ma_thu_tuc").asText("").strip();
            var issues = content.validate(raw, i + 1, code);
            if (!seen.add(code)) issues.add(new Issue(i + 1, code, "ma_thu_tuc", "Mã thủ tục lặp lại trong cùng file."));
            var existing = code.isBlank() ? null : procedures.findByMaThuTuc(code).orElse(null);
            RowAction action = !issues.isEmpty() ? RowAction.INVALID : existing == null ? RowAction.CREATE
                    : input.duplicatePolicy() == DuplicatePolicy.SKIP_EXISTING ? RowAction.SKIP : RowAction.UPDATE;
            rows.add(new Row(i + 1, code, raw.path("ten").asText(""), existing == null ? null : existing.getId(),
                    existing == null ? null : existing.getPhienBan(), action, issues));
        }
        return new Preview(rows.size(), count(rows, RowAction.CREATE), count(rows, RowAction.UPDATE), count(rows, RowAction.SKIP), count(rows, RowAction.INVALID), rows);
    }

    public Result confirm(Confirmation input, String email) {
        int actor = admins.findByEmailIgnoreCase(email).orElseThrow().getId();
        var preview = preview(input.request());
        int created = 0, updated = 0, skipped = 0, failed = 0;
        var issues = new ArrayList<Issue>();
        for (Row row : preview.rows()) {
            if (row.action() == RowAction.INVALID) { failed++; issues.addAll(row.issues()); continue; }
            if (row.action() == RowAction.SKIP) { skipped++; continue; }
            try {
                Integer expected = input.expectedVersions().get(row.code());
                if (expected == null || expected < 0) throw conflict();
                boolean added = Boolean.TRUE.equals(transaction.execute(status -> importRow(
                        input.request().procedures().get(row.rowNumber() - 1), input.request(), expected, actor)));
                if (added) created++; else updated++;
            } catch (Exception error) {
                failed++;
                String message = error instanceof ResponseStatusException ex ? ex.getReason()
                        : "Không lưu được bản ghi. Hãy kiểm tra dữ liệu và thử nhập lại.";
                issues.add(new Issue(row.rowNumber(), row.code(), "database", message));
            }
        }
        return new Result(preview.total(), created, updated, skipped, failed, issues);
    }

    private boolean importRow(JsonNode raw, Request input, int expected, int actor) {
        var clean = json.convertValue(raw, CleanProcedureData.class);
        String code = clean.code().strip();
        var found = procedures.findByMaThuTuc(code).orElse(null);
        boolean added = found == null;
        var row = found == null ? new Procedure() : procedures.lockById(found.getId()).orElseThrow();
        if (added ? expected != 0 : row.getPhienBan() != expected) throw conflict();
        JsonNode before = added ? null : Optional.ofNullable(db.find(ProcedureSource.class, row.getId())).map(ProcedureSource::getPayload).orElse(null);
        row.setMaThuTuc(code); row.setTen(clean.name()); row.setTenKhongDau(VietnameseText.forSearch(clean.name()));
        row.setDoiTuong(clean.audience()); row.setDieuKien(clean.conditions());
        row.setCoQuanThucHienGoc(clean.agencies() == null ? null : clean.agencies().implementing());
        row.setTrangThai(input.status());
        row.setCapThucHien(ProcedureContentWriter.level(clean.originalLevel()));
        if (!added) row.setPhienBan(row.getPhienBan() + 1);
        procedures.saveAndFlush(row);
        int id = row.getId();
        content.replace(id, clean);
        sources.store(id, raw);
        var log = new ChangeLog(); log.setQuanTriId(actor); log.setBang("thu_tuc"); log.setBanGhiId(Integer.toString(id));
        log.setHanhDong(added ? ChangeAction.tao : ChangeAction.sua); log.setDuLieuTruoc(before); log.setDuLieuSau(raw.deepCopy()); db.persist(log);
        db.flush(); ragSync.enqueue(row);
        return added;
    }

    private static int count(List<Row> rows, RowAction action) { return (int) rows.stream().filter(r -> r.action() == action).count(); }
    private static ResponseStatusException conflict() { return new ResponseStatusException(HttpStatus.CONFLICT, "Dữ liệu đã thay đổi sau khi xem trước. Hãy xem trước lại trước khi nhập."); }
}
