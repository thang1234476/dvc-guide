package com.dvcguide.server.admin.service;

import com.dvcguide.server.admin.entity.Administrator;
import com.dvcguide.server.admin.entity.ChangeLog;
import com.dvcguide.server.admin.repository.AdministratorRepository;
import com.dvcguide.server.catalog.entity.ProcedureField;
import com.dvcguide.server.common.exception.ResourceNotFoundException;
import com.dvcguide.server.common.model.AdministrativeLevel;
import com.dvcguide.server.common.model.ChangeAction;
import com.dvcguide.server.common.model.ProcedureStatus;
import com.dvcguide.server.common.util.VietnameseText;
import com.dvcguide.server.procedure.dto.ProcedureDetail;
import com.dvcguide.server.procedure.dto.ProcedureSummary;
import com.dvcguide.server.procedure.entity.Procedure;
import com.dvcguide.server.procedure.entity.ProcedureFieldLink;
import com.dvcguide.server.procedure.repository.ProcedureRepository;
import com.dvcguide.server.procedure.service.ProcedureService;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.persistence.EntityManager;
import jakarta.validation.constraints.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.net.URI;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Objects;

@Service
@RequiredArgsConstructor
public class AdminProcedureService {
    private final ProcedureRepository procedures;
    private final ProcedureService reader;
    private final AdministratorRepository admins;
    private final EntityManager db;
    private final ObjectMapper json;

    public record Input(@NotBlank @Size(max = 50) String code, @NotBlank @Size(max = 1000) String name,
                        AdministrativeLevel level, @NotNull ProcedureStatus status, Integer version,
                        @Size(max = 16000) String originalAgency, @Size(max = 16000) String audience,
                        @Size(max = 16000) String conditions, @Size(max = 1000) String portalUrl,
                        @Size(max = 500) String source, @NotNull @Size(max = 50) List<@NotNull @Positive Integer> fieldIds) {}

    public record AdminProfile(int id, String email, String displayName, String role) {}

    public AdminProfile profile(String email) {
        Administrator admin = findAdmin(email);
        return new AdminProfile(admin.getId(), admin.getEmail(), admin.getTenHienThi(), admin.getVaiTro().name());
    }

    @Transactional
    public ProcedureDetail create(Input request, String email) {
        validateFields(request);
        Procedure row = new Procedure();
        apply(row, request);
        procedures.saveAndFlush(row);
        setFields(row.getId(), request.fieldIds(), List.of());
        db.flush();
        var after = reader.detailAdmin(row.getId());
        audit(email, ChangeAction.tao, row.getId(), null, after);
        return after;
    }

    @Transactional
    public ProcedureDetail update(int id, Input request, String email) {
        Procedure row = lock(id, request.version());
        validateFields(request);
        var before = reader.detailAdmin(id);
        List<Integer> oldFields = before.procedure().fields().stream().map(ProcedureSummary.Field::id).toList();
        if (editableValues(before).equals(request)) {
            return before;
        }
        apply(row, request);
        row.setPhienBan(row.getPhienBan() + 1);
        setFields(id, request.fieldIds(), oldFields);
        db.flush();
        var after = reader.detailAdmin(id);
        audit(email, row.getTrangThai() == ProcedureStatus.ngung && before.procedure().status() != ProcedureStatus.ngung
                ? ChangeAction.xoa : ChangeAction.sua, id, before, after);
        return after;
    }

    @Transactional
    public void retire(int id, int version, String email) {
        Procedure row = lock(id, version);
        if (row.getTrangThai() == ProcedureStatus.ngung) {
            return;
        }
        var before = reader.detailAdmin(id);
        row.setTrangThai(ProcedureStatus.ngung);
        row.setPhienBan(row.getPhienBan() + 1);
        db.flush();
        audit(email, ChangeAction.xoa, id, before, reader.detailAdmin(id));
    }

    private Input editableValues(ProcedureDetail detail) {
        var p = detail.procedure();
        return new Input(p.code(), p.name(), p.level(), p.status(), p.version(), detail.originalAgency(),
                detail.audience(), detail.conditions(), detail.portalUrl(), detail.source(),
                p.fields().stream().map(ProcedureSummary.Field::id).toList());
    }

    private Procedure lock(int id, Integer expectedVersion) {
        var row = procedures.lockById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy thủ tục."));
        if (!Objects.equals(row.getPhienBan(), expectedVersion)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Phiên bản đã thay đổi. Hãy tải lại thủ tục.");
        }
        return row;
    }

    private void apply(Procedure row, Input request) {
        row.setMaThuTuc(request.code().strip());
        row.setTen(request.name().strip());
        row.setTenKhongDau(VietnameseText.forSearch(row.getTen()));
        row.setCapThucHien(request.level());
        row.setTrangThai(request.status());
        row.setCoQuanThucHienGoc(request.originalAgency());
        row.setDoiTuong(request.audience());
        row.setDieuKien(request.conditions());
        row.setLinkDvc(request.portalUrl());
        row.setNguonDuLieu(request.source());
    }

    private void validateFields(Input request) {
        var ids = request.fieldIds();
        if (new LinkedHashSet<>(ids).size() != ids.size()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Lĩnh vực bị chọn trùng.");
        }
        if (!ids.isEmpty() && db.createQuery("select count(f) from ProcedureField f where f.id in :ids", Long.class)
                .setParameter("ids", ids).getSingleResult() != ids.size()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Có lĩnh vực không tồn tại.");
        }
        String url = request.portalUrl();
        if (url != null && !url.isBlank()) {
            try {
                URI uri = URI.create(url);
                if (("http".equalsIgnoreCase(uri.getScheme()) || "https".equalsIgnoreCase(uri.getScheme()))
                        && uri.getHost() != null) {
                    return;
                }
            } catch (IllegalArgumentException ignored) {
                // Invalid URL handled below.
            }
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Đường dẫn cổng dịch vụ phải là URL HTTP hoặc HTTPS.");
        }
    }

    private void setFields(int id, List<Integer> fieldIds, List<Integer> oldFields) {
        for (int fieldId : oldFields) {
            if (!fieldIds.contains(fieldId)) {
                db.remove(db.find(ProcedureFieldLink.class, new ProcedureFieldLink.Key(id, fieldId)));
            }
        }
        short order = 1;
        for (int fieldId : fieldIds) {
            ProcedureFieldLink link = db.find(ProcedureFieldLink.class, new ProcedureFieldLink.Key(id, fieldId));
            if (link == null) {
                link = new ProcedureFieldLink();
                link.setThuTucId(id);
                link.setLinhVucId(fieldId);
                link.setThuTu(order++);
                db.persist(link);
            } else {
                link.setThuTu(order++);
            }
        }
    }

    private void audit(String email, ChangeAction action, int id, ProcedureDetail before, ProcedureDetail after) {
        ChangeLog log = new ChangeLog();
        log.setQuanTriId(findAdmin(email).getId());
        log.setBang("thu_tuc");
        log.setBanGhiId(Integer.toString(id));
        log.setHanhDong(action);
        log.setDuLieuTruoc(before == null ? null : json.valueToTree(before));
        log.setDuLieuSau(json.valueToTree(after));
        db.persist(log);
    }

    private Administrator findAdmin(String email) {
        return admins.findByEmailIgnoreCase(email)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy tài khoản quản trị."));
    }
}
