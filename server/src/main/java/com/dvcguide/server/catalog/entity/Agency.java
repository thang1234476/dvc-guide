package com.dvcguide.server.catalog.entity;

import com.dvcguide.server.common.model.AddressSource;
import com.dvcguide.server.common.model.AdministrativeLevel;
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

import java.time.LocalDate;

@Entity
@Table(name = "co_quan")
@Getter
@Setter
public class Agency {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Integer id;

    @Column(name = "ma", unique = true, length = 30)
    private String ma;

    @Column(name = "ten", nullable = false, length = 500)
    private String ten;

    @Enumerated(EnumType.STRING)
    @Column(name = "cap", nullable = false)
    private AdministrativeLevel cap;

    @Column(name = "dia_phuong_id")
    private Integer diaPhuongId;

    @Column(name = "dia_chi", columnDefinition = "TEXT")
    private String diaChi;

    @Column(name = "vi_do")
    private Double viDo;

    @Column(name = "kinh_do")
    private Double kinhDo;

    @Column(name = "so_dien_thoai", length = 30)
    private String soDienThoai;

    @Column(name = "email", length = 255)
    private String email;

    @Column(name = "website", length = 500)
    private String website;

    @Column(name = "gio_lam_viec", length = 255)
    private String gioLamViec;

    @Column(name = "gio_phat_so", length = 255)
    private String gioPhatSo;

    @Enumerated(EnumType.STRING)
    @Column(name = "nguon_dia_chi", nullable = false)
    private AddressSource nguonDiaChi = AddressSource.du_lieu_goc;

    @Column(name = "da_kiem_chung", nullable = false)
    private Boolean daKiemChung = false;

    @Column(name = "kiem_chung_luc")
    private LocalDate kiemChungLuc;
}
