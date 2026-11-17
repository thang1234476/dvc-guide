package com.dvcguide.server.knowledge.entity;

import com.dvcguide.server.common.model.ChunkSource;
import com.fasterxml.jackson.databind.JsonNode;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "rag_chunk")
@Getter
@Setter
public class RagChunk {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(name = "nguon", nullable = false)
    private ChunkSource nguon;

    @Column(name = "thu_tuc_id")
    private Integer thuTucId;

    @Column(name = "van_ban_id")
    private Integer vanBanId;

    @Column(name = "bieu_mau_id")
    private Integer bieuMauId;

    @Column(name = "truong", length = 100)
    private String truong;

    @Column(name = "stt_doan", nullable = false)
    private Short sttDoan = (short) 0;

    @Column(name = "noi_dung", nullable = false, columnDefinition = "MEDIUMTEXT")
    private String noiDung;

    @JdbcTypeCode(SqlTypes.CHAR)
    @Column(name = "noi_dung_md5", nullable = false, length = 32)
    private String noiDungMd5;

    @Column(name = "phien_ban", nullable = false)
    private Integer phienBan = 1;

    @Column(name = "tieu_de", length = 500)
    private String tieuDe;

    @Column(name = "trich_dan", length = 500)
    private String trichDan;

    @Column(name = "url_nguon", length = 1000)
    private String urlNguon;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "metadata")
    private JsonNode metadata;
}
