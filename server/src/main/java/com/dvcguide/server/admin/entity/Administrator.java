package com.dvcguide.server.admin.entity;

import com.dvcguide.server.common.model.AdminRole;
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

import java.time.Instant;

@Entity
@Table(name = "quan_tri_vien")
@Getter
@Setter
public class Administrator {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Integer id;

    @Column(name = "email", nullable = false, unique = true, length = 255)
    private String email;

    @Column(name = "ten_hien_thi", length = 255)
    private String tenHienThi;

    @Column(name = "mat_khau_hash", nullable = false, length = 255)
    private String matKhauHash;

    @Enumerated(EnumType.STRING)
    @Column(name = "vai_tro", nullable = false)
    private AdminRole vaiTro = AdminRole.bien_tap;

    @Column(name = "hoat_dong", nullable = false)
    private Boolean hoatDong = true;

    @CreationTimestamp
    @Column(name = "tao_luc", updatable = false)
    private Instant taoLuc;
}
