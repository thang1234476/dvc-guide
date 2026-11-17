package com.dvcguide.server.chat.entity;

import com.dvcguide.server.common.model.AnswerStatus;
import com.dvcguide.server.common.model.MessageRole;
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
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;

@Entity
@Table(name = "tin_nhan")
@Getter
@Setter
public class Message {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Long id;

    @JdbcTypeCode(SqlTypes.CHAR)
    @Column(name = "hoi_thoai_id", nullable = false, length = 36)
    private String hoiThoaiId;

    @Enumerated(EnumType.STRING)
    @Column(name = "vai_tro", nullable = false)
    private MessageRole vaiTro;

    @Column(name = "noi_dung", columnDefinition = "MEDIUMTEXT")
    private String noiDung;

    @Column(name = "y_dinh", length = 100)
    private String yDinh;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "tham_so")
    private JsonNode thamSo;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "tool_calls")
    private JsonNode toolCalls;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "nguon_trich_dan")
    private JsonNode nguonTrichDan;

    @Enumerated(EnumType.STRING)
    @Column(name = "trang_thai_tra_loi")
    private AnswerStatus trangThaiTraLoi;

    @Column(name = "diem_top1")
    private Double diemTop1;

    @Column(name = "do_tre_ms")
    private Integer doTreMs;

    @Column(name = "model_phien_ban", length = 50)
    private String modelPhienBan;

    @CreationTimestamp
    @Column(name = "tao_luc", updatable = false)
    private Instant taoLuc;
}
