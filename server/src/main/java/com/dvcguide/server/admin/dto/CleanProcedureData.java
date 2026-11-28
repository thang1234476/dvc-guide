package com.dvcguide.server.admin.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.JsonNode;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.util.List;

/**
 * Import representation of clean.json. Source IDs and nullable values are preserved.
 * Database IDs are assigned separately when the import is persisted.
 */
public record CleanProcedureData(
        @JsonProperty("schema_version") String schemaVersion,
        @JsonProperty("id") String sourceId,
        @JsonProperty("ma_thu_tuc") @NotBlank @Size(max = 50) String code,
        @JsonProperty("ten") @NotBlank @Size(max = 1000) String name,
        @JsonProperty("linh_vuc") @Valid List<Field> fields,
        @JsonProperty("cap_thuc_hien") String originalLevel,
        @JsonProperty("loai_thu_tuc") String procedureType,
        @JsonProperty("doi_tuong") String audience,
        @JsonProperty("so_quyet_dinh") String decisionNumber,
        @JsonProperty("co_quan") @Valid Agency agencies,
        @JsonProperty("trinh_tu") List<String> steps,
        @JsonProperty("cach_thuc") @Valid List<Submission> submissions,
        @JsonProperty("ho_so") @Valid List<Document> documents,
        @JsonProperty("can_cu") @Valid List<LegalBasis> legalBases,
        @JsonProperty("yeu_cau_dieu_kien") String conditions,
        @JsonProperty("ket_qua") @Valid List<Result> results,
        @JsonProperty("tu_khoa") List<String> keywords,
        @JsonProperty("phan_loai_goc") JsonNode originalClassification,
        @JsonProperty("dan_xuat") JsonNode derivedData,
        @JsonProperty("nguon") JsonNode source,
        @JsonProperty("chat_luong") JsonNode quality) {

    public record Field(@JsonProperty("id") String sourceId, @JsonProperty("ten") String name) {}

    public record Agency(
            @JsonProperty("thuc_hien") String implementing,
            @JsonProperty("tham_quyen") String competent,
            @JsonProperty("dia_chi_tiep_nhan") String receivingAddress,
            @JsonProperty("uy_quyen") String authorized,
            @JsonProperty("phoi_hop") String coordinating) {}

    public record Document(
            @JsonProperty("nhom") String group,
            @JsonProperty("truong_hop") String originalCase,
            @JsonProperty("ten") String name,
            @JsonProperty("so_ban_chinh") @PositiveOrZero Integer originals,
            @JsonProperty("so_ban_sao") @PositiveOrZero Integer copies,
            @JsonProperty("mau_don") @Valid List<Form> forms) {}

    public record Form(@JsonProperty("ten") String name, @JsonProperty("file_id") String sourceId,
                       String url, @JsonProperty("loi_tai") String downloadError) {}

    public record Submission(
            @JsonProperty("hinh_thuc") String channel,
            @JsonProperty("hinh_thuc_goc") String originalChannel,
            @JsonProperty("thoi_han") @Valid Duration duration,
            @JsonProperty("le_phi") @Valid List<Fee> fees,
            @JsonProperty("mo_ta") String description) {}

    public record Duration(@JsonProperty("so") BigDecimal amount, @JsonProperty("don_vi") String unit,
                           @JsonProperty("goc") String original) {}

    public record Fee(
            @JsonProperty("so_tien") BigDecimal amount,
            @JsonProperty("tien_te") String currency,
            @JsonProperty("mien_phi") Boolean free,
            @JsonProperty("ghi_chu") String notes) {}

    public record LegalBasis(@JsonProperty("ma") String reference, @JsonProperty("ten") String name) {}

    public record Result(@JsonProperty("ten") String name, @JsonProperty("ma") String code) {}
}
