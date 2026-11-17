package com.dvcguide.server.procedure.entity;

import com.dvcguide.server.common.model.StepChannel;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "buoc_thuc_hien", uniqueConstraints =
        @UniqueConstraint(name = "uq_buoc", columnNames = {"thu_tuc_id", "hinh_thuc", "thu_tu"}))
@Getter
@Setter
public class ProcedureStep {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Integer id;

    @Column(name = "thu_tuc_id", nullable = false)
    private Integer thuTucId;

    @Enumerated(EnumType.STRING)
    @Column(name = "hinh_thuc", nullable = false)
    private StepChannel hinhThuc = StepChannel.chung;

    @Column(name = "thu_tu", nullable = false)
    private Short thuTu;

    @Column(name = "tieu_de", length = 500)
    private String tieuDe;

    @Column(name = "mo_ta", columnDefinition = "TEXT")
    private String moTa;

    @Column(name = "anh_huong_dan_url", length = 1000)
    private String anhHuongDanUrl;
}
