package com.dvcguide.server.procedure.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

@Entity
@Table(name = "le_phi")
@Getter
@Setter
public class Fee {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Integer id;

    @Column(name = "cach_thuc_id", nullable = false)
    private Integer cachThucId;

    @Column(name = "mien_phi", nullable = false)
    private Boolean mienPhi = false;

    @Column(name = "so_tien", precision = 15, scale = 2)
    private BigDecimal soTien;

    @Column(name = "tien_te", length = 50)
    private String tienTe;

    @Column(name = "ghi_chu", columnDefinition = "TEXT")
    private String ghiChu;

    @Column(name = "thu_tu", nullable = false)
    private Short thuTu = (short) 1;
}
