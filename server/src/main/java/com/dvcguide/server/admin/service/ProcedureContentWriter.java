package com.dvcguide.server.admin.service;

import com.dvcguide.server.admin.dto.CleanProcedureData;
import com.dvcguide.server.admin.dto.ProcedureImportModels.Issue;
import com.dvcguide.server.catalog.entity.ProcedureField;
import com.dvcguide.server.common.model.*;
import com.dvcguide.server.procedure.entity.*;
import com.fasterxml.jackson.databind.*;
import jakarta.persistence.EntityManager;
import jakarta.validation.Validator;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.*;

@Service
@RequiredArgsConstructor
public class ProcedureContentWriter {
    private final EntityManager db;
    private final ObjectMapper json;
    private final Validator validator;

    public void replace(int id, CleanProcedureData clean) {
        replaceFields(id, clean);
        replaceContent(id, clean);
    }

    public void replaceContent(int id, CleanProcedureData clean) {
        replaceSteps(id, clean);
        replaceDocuments(id, clean);
        replaceSubmissions(id, clean);
        replaceResults(id, clean);
        replaceLegalBases(id, clean);
    }

    public void update(int id, CleanProcedureData clean, JsonNode before, JsonNode after) {
        if (!Objects.equals(before.get("trinh_tu"), after.get("trinh_tu"))) replaceSteps(id, clean);
        if (!Objects.equals(before.get("ho_so"), after.get("ho_so"))) replaceDocuments(id, clean);
        if (!Objects.equals(before.get("cach_thuc"), after.get("cach_thuc"))) replaceSubmissions(id, clean);
        if (!Objects.equals(before.get("ket_qua"), after.get("ket_qua"))) replaceResults(id, clean);
        if (!Objects.equals(before.get("can_cu"), after.get("can_cu"))) replaceLegalBases(id, clean);
    }

    private void replaceFields(int id, CleanProcedureData clean) {
        deleteRows("ProcedureFieldLink", id);
        int order = 1;
        var fieldIds = new HashSet<Integer>();
        for (var f : list(clean.fields())) {
            var field = field(f);
            if (!fieldIds.add(field.getId())) continue;
            var link = new ProcedureFieldLink(); link.setThuTucId(id); link.setLinhVucId(field.getId()); link.setThuTu((short) order++); db.persist(link);
        }
    }

    private void replaceSteps(int id, CleanProcedureData clean) {
        deleteRows("ProcedureStep", id);
        int order = 1;
        for (String description : list(clean.steps())) {
            var step = new ProcedureStep(); step.setThuTucId(id); step.setHinhThuc(StepChannel.chung);
            step.setThuTu((short) order++); step.setMoTa(description); db.persist(step);
        }
    }

    private void replaceDocuments(int id, CleanProcedureData clean) {
        db.createQuery("delete from DocumentForm f where f.documentId in (select d.id from RequiredDocument d where d.thuTucId = :id)").setParameter("id", id).executeUpdate();
        deleteRows("RequiredDocument", id);
        int order = 1;
        for (var d : list(clean.documents())) {
            var document = new RequiredDocument(); document.setThuTucId(id); document.setNhom(d.group()); document.setTenGiayTo(d.name());
            document.setTruongHopGoc(d.originalCase()); document.setSoLuongBanChinh(shortOrNull(d.originals())); document.setSoLuongBanSao(shortOrNull(d.copies())); document.setThuTu(order++);
            var forms = list(d.forms()).stream().map(this::form).toList();
            if (!forms.isEmpty()) document.setBieuMauId(forms.get(0).getId());
            db.persist(document); db.flush();
            int formOrder = 1;
            for (var f : new LinkedHashSet<>(forms)) {
                var link = new DocumentForm(); link.setDocumentId(document.getId()); link.setFormId(f.getId()); link.setSortOrder(formOrder++); db.persist(link);
            }
        }
    }

    private void replaceSubmissions(int id, CleanProcedureData clean) {
        db.createQuery("delete from Fee f where f.cachThucId in (select s.id from SubmissionMethod s where s.thuTucId = :id)").setParameter("id", id).executeUpdate();
        deleteRows("SubmissionMethod", id);
        for (var s : list(clean.submissions())) {
            var submission = new SubmissionMethod(); submission.setThuTucId(id); submission.setHinhThuc(channel(s.channel()));
            submission.setHinhThucGoc(s.originalChannel() == null ? s.channel() : s.originalChannel());
            if (s.duration() != null) { submission.setThoiHanSo(s.duration().amount()); submission.setThoiHanDonVi(s.duration().unit()); submission.setThoiHanGoc(s.duration().original()); }
            db.persist(submission); db.flush();
            short feeOrder = 1;
            for (var f : list(s.fees())) {
                var fee = new Fee(); fee.setCachThucId(submission.getId()); fee.setMienPhi(Boolean.TRUE.equals(f.free()));
                fee.setSoTien(f.amount()); fee.setTienTe(f.currency()); fee.setGhiChu(f.notes()); fee.setThuTu(feeOrder++); db.persist(fee);
            }
        }
    }

    private void replaceResults(int id, CleanProcedureData clean) {
        deleteRows("ProcedureResult", id);
        int order = 1;
        for (var r : list(clean.results())) { var result = new ProcedureResult(); result.setThuTucId(id); result.setTen(r.name()); result.setThuTu((short) order++); db.persist(result); }
    }

    private void replaceLegalBases(int id, CleanProcedureData clean) {
        deleteRows("ProcedureLegalBasis", id);
        int order = 1;
        var legalIds = new HashSet<Integer>();
        for (var l : list(clean.legalBases())) {
            var law = legal(l);
            if (!legalIds.add(law.getId())) continue;
            var link = new ProcedureLegalBasis(); link.setThuTucId(id); link.setVanBanId(law.getId()); link.setThuTu((short) order++); db.persist(link);
        }
    }

    private void deleteRows(String type, int id) {
        db.createQuery("delete from " + type + " p where p.thuTucId = :id").setParameter("id", id).executeUpdate();
    }

    private ProcedureField field(CleanProcedureData.Field f) {
        String code = f.sourceId() == null || f.sourceId().isBlank() ? null : f.sourceId().length() <= 30 ? f.sourceId() : key(f.sourceId(), 28);
        var found = db.createQuery("select f from ProcedureField f where (:code is not null and f.ma = :code) or f.ten = :name order by f.id", ProcedureField.class)
                .setParameter("code", code).setParameter("name", f.name()).setMaxResults(1).getResultList();
        if (!found.isEmpty() && found.get(0).getTen().equals(f.name())) return found.get(0);
        if (!found.isEmpty()) {
            code = key(String.valueOf(f.sourceId()) + "|" + f.name(), 28);
            var renamed = db.createQuery("select f from ProcedureField f where f.ma = :code", ProcedureField.class)
                    .setParameter("code", code).setMaxResults(1).getResultList();
            if (!renamed.isEmpty()) return renamed.get(0);
        }
        var field = new ProcedureField(); field.setMa(code); field.setTen(f.name()); db.persist(field); db.flush(); return field;
    }

    private FormTemplate form(CleanProcedureData.Form f) {
        String code = f.sourceId() == null || f.sourceId().isBlank() ? key(f.name() + "|" + f.url(), 45) : f.sourceId();
        String url = blankToNull(f.url());
        boolean pdf = f.name().toLowerCase(Locale.ROOT).endsWith(".pdf") || url != null && url.toLowerCase(Locale.ROOT).contains(".pdf");
        var existing = db.createQuery("select f from FormTemplate f where f.maBieuMau = :code", FormTemplate.class)
                .setParameter("code", code).getResultList().stream().filter(template -> Objects.equals(template.getTen(), f.name())
                        && Objects.equals(pdf ? template.getFilePdfUrl() : template.getFileDocxUrl(), url)).findFirst();
        if (existing.isPresent()) return existing.get();
        var form = new FormTemplate();
        form.setMaBieuMau(code); form.setTen(f.name());
        if (pdf) form.setFilePdfUrl(url);
        else form.setFileDocxUrl(blankToNull(f.url()));
        db.persist(form);
        db.flush(); return form;
    }

    private LegalDocument legal(CleanProcedureData.LegalBasis l) {
        String code = l.reference() == null || l.reference().isBlank() ? key(l.name(), 45) : l.reference();
        var found = db.createQuery("select v from LegalDocument v where v.soHieu = :code", LegalDocument.class)
                .setParameter("code", code).setMaxResults(1).getResultList();
        if (!found.isEmpty()) return found.get(0);
        var law = new LegalDocument(); law.setSoHieu(code); law.setTen(l.name()); db.persist(law); db.flush(); return law;
    }

    public List<Issue> validate(JsonNode raw, int number, String code) {
        var issues = new ArrayList<Issue>();
        try {
            if (!raw.isObject()) throw new IllegalArgumentException();
            var clean = json.treeToValue(raw, CleanProcedureData.class);
            max(clean.sourceId(), 128);
            max(clean.originalLevel(), 255);
            max(clean.procedureType(), 255);
            max(clean.decisionNumber(), 1000);
            max(clean.audience(), 16000);
            max(clean.conditions(), 16000);
            for (String step : list(clean.steps())) max(step, 16000);
            for (String keyword : list(clean.keywords())) max(keyword, 1000);
            if (clean.agencies() != null) {
                max(clean.agencies().implementing(), 16000); max(clean.agencies().competent(), 16000);
                max(clean.agencies().receivingAddress(), 16000); max(clean.agencies().authorized(), 16000); max(clean.agencies().coordinating(), 16000);
            }
            validator.validate(clean).forEach(v -> issues.add(new Issue(number, code, v.getPropertyPath().toString(), v.getMessage())));
            for (var f : list(clean.fields())) requireText(f.name(), 255);
            for (var d : list(clean.documents())) { requireText(d.name(), 16000); max(d.group(), 255); max(d.originalCase(), 16000); shortOrNull(d.originals()); shortOrNull(d.copies()); for (var f : list(d.forms())) { requireText(f.name(), 500); max(f.sourceId(), 50); max(f.url(), 1000); } }
            for (var l : list(clean.legalBases())) { requireText(l.name(), 1000); max(l.reference(), 100); }
            for (var r : list(clean.results())) requireText(r.name(), 1000);
            for (var s : list(clean.submissions())) {
                max(s.originalChannel(), 255);
                max(s.description(), 16000);
                if (s.duration() != null) {
                    max(s.duration().unit(), 50);
                    max(s.duration().original(), 16000);
                    if (s.duration().amount() != null && (s.duration().amount().signum() < 0 || s.duration().amount().scale() > 1 || s.duration().amount().abs().compareTo(new java.math.BigDecimal("99999.9")) > 0)) throw new IllegalArgumentException();
                }
                for (var f : list(s.fees())) {
                    max(f.currency(), 50);
                    max(f.notes(), 16000);
                    if (f.amount() != null && (f.amount().signum() < 0 || f.amount().scale() > 2 || f.amount().abs().compareTo(new java.math.BigDecimal("9999999999999.99")) > 0)) throw new IllegalArgumentException();
                }
            }
        } catch (Exception error) {
            String detail = error instanceof com.fasterxml.jackson.databind.JsonMappingException mapping
                    ? "Sai kiểu dữ liệu tại " + mapping.getPathReference()
                    : error.getMessage() == null ? "Dữ liệu thiếu tên, sai cấu trúc hoặc vượt giới hạn lưu trữ." : error.getMessage();
            issues.add(new Issue(number, code, "structure", detail.substring(0, Math.min(detail.length(), 250))));
        }
        return issues;
    }

    private static <T> List<T> list(List<T> list) { return list == null ? List.of() : list; }
    private static Short shortOrNull(Integer n) { if (n == null) return null; if (n < 0 || n > Short.MAX_VALUE) throw new IllegalArgumentException(); return n.shortValue(); }
    private static void requireText(String s, int length) { if (s == null || s.isBlank()) throw new IllegalArgumentException(); max(s, length); }
    private static void max(String s, int length) { if (s != null && s.length() > length) throw new IllegalArgumentException(); }
    private static String blankToNull(String s) { return s == null || s.isBlank() ? null : s; }
    public static AdministrativeLevel level(String s) { try { return AdministrativeLevel.valueOf(s); } catch (Exception ignored) { return null; } }
    private static SubmissionChannel channel(String s) { try { return SubmissionChannel.valueOf(s); } catch (Exception ignored) { return SubmissionChannel.khac; } }
    public static String key(String text, int length) {
        try { return "src-" + HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(text.getBytes(StandardCharsets.UTF_8))).substring(0, length - 4); }
        catch (Exception error) { throw new IllegalStateException(error); }
    }
}
