package com.dvcguide.server.procedure.service;

import com.dvcguide.server.catalog.entity.Agency;
import com.dvcguide.server.catalog.entity.ProcedureField;
import com.dvcguide.server.common.exception.ResourceNotFoundException;
import com.dvcguide.server.common.model.ProcedureStatus;
import com.dvcguide.server.common.response.PageResponse;
import com.dvcguide.server.common.util.VietnameseText;
import com.dvcguide.server.procedure.dto.ProcedureDetail;
import com.dvcguide.server.procedure.dto.ProcedureSummary;
import com.dvcguide.server.procedure.entity.*;
import com.dvcguide.server.procedure.repository.ProcedureRepository;
import jakarta.persistence.EntityManager;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ProcedureService {
    private final ProcedureRepository procedures;
    private final EntityManager db;

    public PageResponse<ProcedureSummary> search(String keyword, List<Integer> fieldIds, boolean savedOnly,
                                                 String userId, int page, int size) {
        if (savedOnly && userId == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Vui lòng đăng nhập để xem thủ tục đã lưu.");
        }
        boolean allFields = fieldIds.isEmpty();
        var rows = procedures.searchPublished(namePattern(keyword), codePattern(keyword), allFields,
                allFields ? List.of(0) : fieldIds, savedOnly, userId,
                PageRequest.of(page, size, Sort.by("ten", "id")));
        return summaries(rows, userId);
    }

    public PageResponse<ProcedureSummary> searchAdmin(String keyword, int page, int size) {
        return summaries(procedures.searchAdmin(namePattern(keyword), codePattern(keyword),
                PageRequest.of(page, size, Sort.by(Sort.Order.desc("capNhatLuc"), Sort.Order.desc("id")))), null);
    }

    public Procedure findPublished(int id) {
        return procedures.findById(id)
                .filter(row -> row.getTrangThai() == ProcedureStatus.dang_dung)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy thủ tục đang áp dụng."));
    }

    public ProcedureDetail detail(int id, String userId) {
        return detail(findPublished(id), userId);
    }

    public ProcedureDetail detailAdmin(int id) {
        return detailIncludingInactive(id, null);
    }

    public ProcedureDetail detailIncludingInactive(int id, String userId) {
        return detail(procedures.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy thủ tục.")), userId);
    }

    public List<ProcedureDetail.Agency> agencies(int id, Integer localityId) {
        findPublished(id);
        return loadAgencies(id, localityId);
    }

    private ProcedureDetail detail(Procedure row, String userId) {
        int id = row.getId();
        var cases = rows(ProcedureCase.class, id, "r.thuTu, r.id").stream()
                .map(c -> new ProcedureDetail.Case(c.getId(), c.getTen(), c.getDieuKien(), c.getCauHoiPhanLoai()))
                .toList();
        var documents = rows(RequiredDocument.class, id, "r.thuTu, r.id");
        var forms = loadForms(documents);
        var steps = rows(ProcedureStep.class, id, "r.thuTu, r.id").stream()
                .map(s -> new ProcedureDetail.Step(s.getId(), s.getHinhThuc(), s.getThuTu(), s.getTieuDe(),
                        s.getMoTa(), s.getAnhHuongDanUrl())).toList();
        var results = rows(ProcedureResult.class, id, "r.thuTu, r.id").stream().map(ProcedureResult::getTen).toList();
        return new ProcedureDetail(summary(row, fields(List.of(id)), favorites(userId, List.of(id))),
                row.getCoQuanThucHienGoc(), row.getDoiTuong(), row.getDieuKien(), row.getLinkDvc(), row.getNguonDuLieu(),
                cases, documents.stream().map(d -> document(d, forms)).toList(),
                steps, loadSubmissions(id), loadAgencies(id, null), results, loadLegalBases(id));
    }

    private ProcedureDetail.Document document(RequiredDocument d, Map<Integer, ProcedureDetail.Form> forms) {
        return new ProcedureDetail.Document(d.getId(), d.getTruongHopId(), d.getNhom(), d.getTenGiayTo(),
                d.getTruongHopGoc(), d.getSoLuongBanChinh(), d.getSoLuongBanSao(), d.getBatBuoc(), d.getGhiChu(),
                d.getBieuMauId() == null ? null : forms.get(d.getBieuMauId()));
    }

    private Map<Integer, ProcedureDetail.Form> loadForms(List<RequiredDocument> documents) {
        var ids = documents.stream().map(RequiredDocument::getBieuMauId).filter(Objects::nonNull).distinct().toList();
        if (ids.isEmpty()) {
            return Map.of();
        }
        var instructions = db.createQuery("""
                select f from FormField f where f.bieuMauId in :ids order by f.thuTu, f.id
                """, FormField.class).setParameter("ids", ids).getResultList().stream()
                .collect(Collectors.groupingBy(FormField::getBieuMauId, Collectors.mapping(f ->
                        new ProcedureDetail.FormInstruction(f.getId(), f.getTenO(), f.getHuongDan(), f.getViDu(),
                                f.getLoiThuongGap(), f.getToaDo()), Collectors.toList())));
        return db.createQuery("select f from FormTemplate f where f.id in :ids", FormTemplate.class)
                .setParameter("ids", ids).getResultList().stream().collect(Collectors.toMap(FormTemplate::getId, f ->
                        new ProcedureDetail.Form(f.getId(), f.getMaBieuMau(), f.getTen(), f.getPhienBan(),
                                f.getNgayHieuLuc(), f.getFileDocxUrl(), f.getFilePdfUrl(), f.getAnhMauUrl(),
                                f.getVanBanId(), instructions.getOrDefault(f.getId(), List.of()))));
    }

    private List<ProcedureDetail.Submission> loadSubmissions(int id) {
        var submissions = rows(SubmissionMethod.class, id, "r.id");
        if (submissions.isEmpty()) {
            return List.of();
        }
        var fees = db.createQuery("select f from Fee f where f.cachThucId in :ids order by f.thuTu, f.id", Fee.class)
                .setParameter("ids", submissions.stream().map(SubmissionMethod::getId).toList())
                .getResultList().stream().collect(Collectors.groupingBy(Fee::getCachThucId, Collectors.mapping(f ->
                        new ProcedureDetail.Fee(f.getId(), f.getMienPhi(), f.getSoTien(), f.getTienTe(), f.getGhiChu()),
                        Collectors.toList())));
        return submissions.stream().map(s -> new ProcedureDetail.Submission(s.getId(), s.getHinhThuc(),
                s.getHinhThucGoc(), s.getThoiHanSo(), s.getThoiHanDonVi(), s.getThoiHanGoc(), s.getLinkNop(),
                s.getDiaChiNop(), s.getGioTiepNhan(), fees.getOrDefault(s.getId(), List.of()))).toList();
    }

    private List<ProcedureDetail.Agency> loadAgencies(int id, Integer localityId) {
        return db.createQuery("""
                select a, link.ghiChu from ProcedureAgency link join Agency a on a.id = link.coQuanId
                where link.thuTucId = :id and (:locality is null or a.diaPhuongId = :locality)
                order by a.ten, a.id
                """, Object[].class).setParameter("id", id).setParameter("locality", localityId)
                .getResultList().stream().map(pair -> {
                    Agency a = (Agency) pair[0];
                    return new ProcedureDetail.Agency(a.getId(), a.getMa(), a.getTen(), a.getCap(),
                            a.getDiaPhuongId(), a.getDiaChi(), a.getViDo(), a.getKinhDo(), a.getSoDienThoai(),
                            a.getEmail(), a.getWebsite(), a.getGioLamViec(), a.getGioPhatSo(),
                            a.getNguonDiaChi(), a.getDaKiemChung(), a.getKiemChungLuc(), (String) pair[1]);
                }).toList();
    }

    private List<ProcedureDetail.LegalBasis> loadLegalBases(int id) {
        return db.createQuery("""
                select link, v from ProcedureLegalBasis link join LegalDocument v on v.id = link.vanBanId
                where link.thuTucId = :id order by link.thuTu, link.id
                """, Object[].class).setParameter("id", id).getResultList().stream().map(pair -> {
                    var link = (ProcedureLegalBasis) pair[0];
                    var v = (LegalDocument) pair[1];
                    return new ProcedureDetail.LegalBasis(link.getId(), v.getId(), v.getSoHieu(), v.getTen(),
                            v.getLoai(), v.getCoQuanBanHanh(), v.getNgayBanHanh(), v.getNgayHieuLuc(),
                            v.getNgayHetHieuLuc(), v.getTrangThaiHieuLuc(), v.getXacMinhLuc(),
                            v.getNguonXacMinh(), v.getUrl(), link.getDieuKhoan());
                }).toList();
    }

    private PageResponse<ProcedureSummary> summaries(Page<Procedure> page, String userId) {
        var ids = page.getContent().stream().map(Procedure::getId).toList();
        var fields = fields(ids);
        var favorites = favorites(userId, ids);
        return PageResponse.from(page.map(row -> summary(row, fields, favorites)));
    }

    private ProcedureSummary summary(Procedure row, Map<Integer, List<ProcedureSummary.Field>> fields,
                                     Set<Integer> favorites) {
        return ProcedureSummary.from(row, fields.getOrDefault(row.getId(), List.of()), favorites.contains(row.getId()));
    }

    private Map<Integer, List<ProcedureSummary.Field>> fields(List<Integer> ids) {
        if (ids.isEmpty()) {
            return Map.of();
        }
        var grouped = new HashMap<Integer, List<ProcedureSummary.Field>>();
        db.createQuery("""
                select l.thuTucId, f from ProcedureFieldLink l join ProcedureField f on f.id = l.linhVucId
                where l.thuTucId in :ids order by l.thuTu, f.id
                """, Object[].class).setParameter("ids", ids).getResultList().forEach(pair -> {
                    var f = (ProcedureField) pair[1];
                    grouped.computeIfAbsent((Integer) pair[0], ignored -> new ArrayList<>())
                            .add(new ProcedureSummary.Field(f.getId(), f.getMa(), f.getTen()));
                });
        return grouped;
    }

    private Set<Integer> favorites(String userId, List<Integer> ids) {
        if (userId == null || ids.isEmpty()) {
            return Set.of();
        }
        return new HashSet<>(db.createQuery("""
                select f.thuTucId from FavoriteProcedure f where f.nguoiDungId = :user and f.thuTucId in :ids
                """, Integer.class).setParameter("user", userId).setParameter("ids", ids).getResultList());
    }

    private <T> List<T> rows(Class<T> type, int procedureId, String ordering) {
        return db.createQuery("select r from " + type.getSimpleName() + " r where r.thuTucId = :id order by " + ordering,
                type).setParameter("id", procedureId).getResultList();
    }

    private String namePattern(String keyword) {
        return VietnameseText.containsPattern(VietnameseText.forSearch(keyword));
    }

    private String codePattern(String keyword) {
        return VietnameseText.containsPattern(keyword.strip().toLowerCase(Locale.ROOT));
    }
}
