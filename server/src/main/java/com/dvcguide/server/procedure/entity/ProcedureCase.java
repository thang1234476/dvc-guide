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
@Table(name = "truong_hop")
@Getter
@Setter
public class ProcedureCase {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Integer id;

    @Column(name = "thu_tuc_id", nullable = false)
    private Integer thuTucId;

    @Column(name = "ten", nullable = false, length = 500)
    private String ten;

    @Column(name = "dieu_kien", columnDefinition = "TEXT")
    private String dieuKien;

    @Column(name = "cau_hoi_phan_loai", columnDefinition = "TEXT")
    private String cauHoiPhanLoai;

    @Column(name = "thu_tu")
    private Integer thuTu = 0;
}
