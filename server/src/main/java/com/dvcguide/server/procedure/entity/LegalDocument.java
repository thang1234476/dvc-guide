package com.dvcguide.server.procedure.entity;

import com.dvcguide.server.common.model.LegalDocumentType;
import com.dvcguide.server.common.model.LegalValidity;
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
@Table(name = "van_ban_phap_ly")
@Getter
@Setter
public class LegalDocument {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Integer id;

    @Column(name = "so_hieu", nullable = false, unique = true, length = 100)
    private String soHieu;

    @Column(name = "ten", nullable = false, columnDefinition = "TEXT")
    private String ten;

    @Enumerated(EnumType.STRING)
    @Column(name = "loai", nullable = false)
    private LegalDocumentType loai = LegalDocumentType.khac;

    @Column(name = "co_quan_ban_hanh", length = 255)
    private String coQuanBanHanh;

    @Column(name = "ngay_ban_hanh")
    private LocalDate ngayBanHanh;

    @Column(name = "ngay_hieu_luc")
    private LocalDate ngayHieuLuc;

    @Column(name = "ngay_het_hieu_luc")
    private LocalDate ngayHetHieuLuc;

    @Enumerated(EnumType.STRING)
    @Column(name = "trang_thai_hieu_luc", nullable = false)
    private LegalValidity trangThaiHieuLuc = LegalValidity.chua_xac_minh;

    @Column(name = "xac_minh_luc")
    private LocalDate xacMinhLuc;

    @Column(name = "nguon_xac_minh", length = 1000)
    private String nguonXacMinh;

    @Column(name = "url", length = 1000)
    private String url;
}
