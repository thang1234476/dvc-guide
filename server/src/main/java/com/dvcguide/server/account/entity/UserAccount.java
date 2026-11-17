package com.dvcguide.server.account.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.UuidGenerator;
import org.hibernate.type.SqlTypes;

import java.time.Instant;

@Entity
@Table(name = "nguoi_dung")
@Getter
@Setter
public class UserAccount {

    @Id
    @UuidGenerator
    @JdbcTypeCode(SqlTypes.CHAR)
    @Column(name = "id", nullable = false, length = 36)
    private String id;

    @Column(name = "email", unique = true, length = 255)
    private String email;

    @Column(name = "mat_khau_hash", length = 255)
    private String matKhauHash;

    @Column(name = "ten_hien_thi", length = 255)
    private String tenHienThi;

    @Column(name = "dia_phuong_id")
    private Integer diaPhuongId;

    @Column(name = "bat_nhac_lich", nullable = false)
    private Boolean batNhacLich = true;

    @CreationTimestamp
    @Column(name = "tao_luc", updatable = false)
    private Instant taoLuc;
}
