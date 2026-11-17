package com.dvcguide.server.admin.entity;

import com.dvcguide.server.common.model.ChangeAction;
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
@Table(name = "nhat_ky_thay_doi")
@Getter
@Setter
public class ChangeLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Long id;

    @Column(name = "quan_tri_id")
    private Integer quanTriId;

    @Column(name = "bang", nullable = false, length = 64)
    private String bang;

    @Column(name = "ban_ghi_id", nullable = false, length = 64)
    private String banGhiId;

    @Enumerated(EnumType.STRING)
    @Column(name = "hanh_dong", nullable = false)
    private ChangeAction hanhDong;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "du_lieu_truoc")
    private JsonNode duLieuTruoc;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "du_lieu_sau")
    private JsonNode duLieuSau;

    @CreationTimestamp
    @Column(name = "tao_luc", updatable = false)
    private Instant taoLuc;
}
