package com.dvcguide.server.procedure.entity;

import com.dvcguide.server.common.model.SubmissionChannel;
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

import java.math.BigDecimal;

@Entity
@Table(name = "hinh_thuc_nop_chi_tiet")
@Getter
@Setter
public class SubmissionMethod {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Integer id;

    @Column(name = "thu_tuc_id", nullable = false)
    private Integer thuTucId;

    @Enumerated(EnumType.STRING)
    @Column(name = "hinh_thuc", nullable = false)
    private SubmissionChannel hinhThuc;

    @Column(name = "hinh_thuc_goc", length = 255)
    private String hinhThucGoc;

    @Column(name = "thoi_han_so", precision = 6, scale = 1)
    private BigDecimal thoiHanSo;

    @Column(name = "thoi_han_don_vi", length = 50)
    private String thoiHanDonVi;

    @Column(name = "thoi_han_goc", columnDefinition = "TEXT")
    private String thoiHanGoc;

    @Column(name = "link_nop", length = 1000)
    private String linkNop;

    @Column(name = "dia_chi_nop", columnDefinition = "TEXT")
    private String diaChiNop;

    @Column(name = "gio_tiep_nhan", length = 500)
    private String gioTiepNhan;
}
