package com.dvcguide.server.procedure.entity;

import com.dvcguide.server.common.model.AdministrativeLevel;
import com.dvcguide.server.common.model.ProcedureStatus;
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
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;

@Entity
@Table(name = "thu_tuc")
@Getter
@Setter
public class Procedure {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Integer id;

    @Column(name = "ma_thu_tuc", nullable = false, unique = true, length = 50)
    private String maThuTuc;

    @Column(name = "ten", nullable = false, length = 1000)
    private String ten;

    @Column(name = "ten_khong_dau", length = 1000)
    private String tenKhongDau;

    @Enumerated(EnumType.STRING)
    @Column(name = "cap_thuc_hien")
    private AdministrativeLevel capThucHien;

    @Column(name = "co_quan_thuc_hien_goc", columnDefinition = "TEXT")
    private String coQuanThucHienGoc;

    @Column(name = "doi_tuong", columnDefinition = "TEXT")
    private String doiTuong;

    @Column(name = "dieu_kien", columnDefinition = "TEXT")
    private String dieuKien;

    @Column(name = "link_dvc", length = 1000)
    private String linkDvc;

    @Column(name = "nguon_du_lieu", length = 500)
    private String nguonDuLieu;

    @Enumerated(EnumType.STRING)
    @Column(name = "trang_thai", nullable = false)
    private ProcedureStatus trangThai = ProcedureStatus.nhap;

    @Column(name = "phien_ban", nullable = false)
    private Integer phienBan = 1;

    @CreationTimestamp
    @Column(name = "tao_luc", updatable = false)
    private Instant taoLuc;

    @UpdateTimestamp
    @Column(name = "cap_nhat_luc")
    private Instant capNhatLuc;
}
