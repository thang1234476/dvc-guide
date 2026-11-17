package com.dvcguide.server.dossier.service;

import com.dvcguide.server.account.repository.UserAccountRepository;
import com.dvcguide.server.common.exception.ResourceNotFoundException;
import com.dvcguide.server.common.model.ChecklistStatus;
import com.dvcguide.server.common.model.DossierStatus;
import com.dvcguide.server.common.response.PageResponse;
import com.dvcguide.server.dossier.entity.ChecklistItem;
import com.dvcguide.server.dossier.entity.Dossier;
import com.dvcguide.server.procedure.dto.ProcedureDetail;
import com.dvcguide.server.procedure.entity.ProcedureAgency;
import com.dvcguide.server.procedure.entity.ProcedureCase;
import com.dvcguide.server.procedure.entity.RequiredDocument;
import com.dvcguide.server.procedure.service.ProcedureService;
import jakarta.persistence.EntityManager;
import jakarta.persistence.LockModeType;
import jakarta.validation.constraints.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class DossierService {
    private final EntityManager db;
    private final ProcedureService procedures;
    private final UserAccountRepository users;

    public record Create(@NotBlank @Size(max = 255) String name, @Positive int procedureId, Integer caseId) {}

    public record Update(@NotBlank @Size(max = 255) String name, Integer caseId, @NotNull DossierStatus status,
                         Integer intendedAgencyId, Integer actualAgencyId, LocalDate submittedDate,
                         @Size(max = 100) String reference, LocalDate appointmentDate, @Size(max = 16000) String notes) {}

    public record ChecklistUpdate(@NotNull ChecklistStatus status) {}

    public record Progress(long available, long missing, long unknown) {}

    public record ChecklistEntry(int documentId, String name, String group, Boolean required, Short originals,
                                 Short copies, String notes, String docxUrl, String pdfUrl, ChecklistStatus status) {}

    public record DossierView(String id, String name, int procedureId, String procedureName,
                              Integer caseId, String caseName, DossierStatus status, Integer intendedAgencyId,
                              Integer actualAgencyId, LocalDate submittedDate, String reference, LocalDate appointmentDate,
                              String notes, Instant updatedAt, Progress progress) {}

    public PageResponse<DossierView> list(String userId, int page, int size) {
        long total = db.createQuery("select count(d) from Dossier d where d.nguoiDungId = :user", Long.class)
                .setParameter("user", userId).getSingleResult();
        var rows = db.createQuery("""
                select d.id from Dossier d where d.nguoiDungId = :user order by d.capNhatLuc desc, d.id
                """, String.class).setParameter("user", userId).setFirstResult(page * size)
                .setMaxResults(size).getResultList();
        return new PageResponse<>(views(rows), page, size, total, (int) Math.ceil(total / (double) size));
    }

    public DossierView detail(String userId, String id) {
        owned(userId, id, LockModeType.NONE);
        return views(List.of(id)).get(0);
    }

    public ProcedureDetail procedure(String userId, String id) {
        return procedures.detailIncludingInactive(owned(userId, id, LockModeType.NONE).getThuTucId(), userId);
    }

    @Transactional
    public DossierView create(String userId, Create input) {
        users.lockById(userId).orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy tài khoản."));
        procedures.findPublished(input.procedureId());
        checkCase(input.procedureId(), input.caseId());
        Dossier row = new Dossier();
        row.setNguoiDungId(userId);
        row.setTenHoSo(input.name().strip());
        row.setThuTucId(input.procedureId());
        row.setTruongHopId(input.caseId());
        db.persist(row);
        db.flush();
        return views(List.of(row.getId())).get(0);
    }

    @Transactional
    public DossierView update(String userId, String id, Update input) {
        var row = owned(userId, id, LockModeType.PESSIMISTIC_WRITE);
        checkCase(row.getThuTucId(), input.caseId());
        checkAgency(row, input.intendedAgencyId(), row.getCoQuanDuDinhId());
        checkAgency(row, input.actualAgencyId(), row.getCoQuanThucTeId());
        row.setTenHoSo(input.name().strip());
        row.setTruongHopId(input.caseId());
        row.setTrangThai(input.status());
        row.setCoQuanDuDinhId(input.intendedAgencyId());
        row.setCoQuanThucTeId(input.actualAgencyId());
        row.setNgayNop(input.submittedDate());
        row.setMaHoSo(input.reference());
        row.setNgayHen(input.appointmentDate());
        row.setGhiChu(input.notes());
        db.flush();
        return views(List.of(id)).get(0);
    }

    @Transactional
    public void delete(String userId, String id) {
        db.remove(owned(userId, id, LockModeType.PESSIMISTIC_WRITE));
    }

    public List<ChecklistEntry> checklist(String userId, String id) {
        var row = owned(userId, id, LockModeType.NONE);
        return db.createQuery("""
                select new com.dvcguide.server.dossier.service.DossierService$ChecklistEntry(
                    r.id, r.tenGiayTo, r.nhom, r.batBuoc, r.soLuongBanChinh, r.soLuongBanSao, r.ghiChu,
                    f.fileDocxUrl, f.filePdfUrl, coalesce(c.trangThai,
                        com.dvcguide.server.common.model.ChecklistStatus.chua_ro))
                from RequiredDocument r left join FormTemplate f on f.id = r.bieuMauId
                left join ChecklistItem c on c.thanhPhanId = r.id and c.hoSoId = :id
                where r.thuTucId = :procedureId and (r.truongHopId is null or r.truongHopId = :caseId)
                order by r.thuTu, r.id
                """, ChecklistEntry.class).setParameter("id", id).setParameter("procedureId", row.getThuTucId())
                .setParameter("caseId", row.getTruongHopId()).getResultList();
    }

    @Transactional
    public void mark(String userId, String id, int documentId, ChecklistStatus status) {
        var row = owned(userId, id, LockModeType.PESSIMISTIC_WRITE);
        var doc = db.find(RequiredDocument.class, documentId);
        if (doc == null || !Objects.equals(doc.getThuTucId(), row.getThuTucId())
                || (doc.getTruongHopId() != null && !Objects.equals(doc.getTruongHopId(), row.getTruongHopId()))) {
            throw new ResourceNotFoundException("Giấy tờ không thuộc trường hợp của hồ sơ.");
        }
        var item = db.find(ChecklistItem.class, new ChecklistItem.Key(id, documentId));
        if (item == null) {
            item = new ChecklistItem();
            item.setHoSoId(id);
            item.setThanhPhanId(documentId);
            item.setTrangThai(status);
            db.persist(item);
        } else {
            item.setTrangThai(status);
        }
    }

    private List<DossierView> views(List<String> ids) {
        if (ids.isEmpty()) {
            return List.of();
        }
        Map<String, DossierView> byId = db.createQuery("""
                select d, p.ten, t.ten,
                    sum(case when c.trangThai = com.dvcguide.server.common.model.ChecklistStatus.da_co then 1 else 0 end),
                    sum(case when c.trangThai = com.dvcguide.server.common.model.ChecklistStatus.chua_co then 1 else 0 end),
                    sum(case when r.id is not null and
                        (c.trangThai is null or c.trangThai = com.dvcguide.server.common.model.ChecklistStatus.chua_ro)
                        then 1 else 0 end)
                from Dossier d join Procedure p on p.id = d.thuTucId
                left join ProcedureCase t on t.id = d.truongHopId
                left join RequiredDocument r on r.thuTucId = d.thuTucId
                    and (r.truongHopId is null or r.truongHopId = d.truongHopId)
                left join ChecklistItem c on c.hoSoId = d.id and c.thanhPhanId = r.id
                where d.id in :ids group by d, p.ten, t.ten
                """, Object[].class).setParameter("ids", ids).getResultList().stream()
                .map(this::view).collect(Collectors.toMap(DossierView::id, item -> item));
        return ids.stream().map(byId::get).filter(Objects::nonNull).toList();
    }

    private DossierView view(Object[] data) {
        var d = (Dossier) data[0];
        return new DossierView(d.getId(), d.getTenHoSo(), d.getThuTucId(), (String) data[1], d.getTruongHopId(),
                (String) data[2], d.getTrangThai(), d.getCoQuanDuDinhId(), d.getCoQuanThucTeId(), d.getNgayNop(),
                d.getMaHoSo(), d.getNgayHen(), d.getGhiChu(), d.getCapNhatLuc(),
                new Progress(((Number) data[3]).longValue(), ((Number) data[4]).longValue(), ((Number) data[5]).longValue()));
    }

    private Dossier owned(String userId, String id, LockModeType lock) {
        return db.createQuery("select d from Dossier d where d.id = :id and d.nguoiDungId = :user", Dossier.class)
                .setParameter("id", id).setParameter("user", userId).setLockMode(lock).getResultList().stream()
                .findFirst().orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hồ sơ."));
    }

    private void checkCase(int procedureId, Integer caseId) {
        if (caseId != null) {
            var candidate = db.find(ProcedureCase.class, caseId);
            if (candidate == null || candidate.getThuTucId() != procedureId) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Trường hợp không thuộc thủ tục này.");
            }
        }
    }

    private void checkAgency(Dossier row, Integer agencyId, Integer existingId) {
        if (agencyId != null && !agencyId.equals(existingId)
                && db.find(ProcedureAgency.class, new ProcedureAgency.Key(row.getThuTucId(), agencyId)) == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Cơ quan chưa được gắn với thủ tục này.");
        }
    }
}
