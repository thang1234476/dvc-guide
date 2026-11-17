package com.dvcguide.server.procedure.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "thanh_phan_ho_so")
@Getter
@Setter
public class RequiredDocument {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Integer id;

    @Column(name = "thu_tuc_id", nullable = false)
    private Integer thuTucId;

    @Column(name = "truong_hop_id")
    private Integer truongHopId;

    @Column(name = "nhom", length = 255)
    private String nhom;

    @Column(name = "ten_giay_to", nullable = false, length = 1000)
    private String tenGiayTo;

    @Column(name = "truong_hop_goc", columnDefinition = "TEXT")
    private String truongHopGoc;

    @Column(name = "so_luong_ban_chinh")
    private Short soLuongBanChinh;

    @Column(name = "so_luong_ban_sao")
    private Short soLuongBanSao;

    @Column(name = "bat_buoc")
    private Boolean batBuoc;

    @Column(name = "bieu_mau_id")
    private Integer bieuMauId;

    @Column(name = "ghi_chu", columnDefinition = "TEXT")
    private String ghiChu;

    @Column(name = "thu_tu")
    private Integer thuTu = 0;
}
