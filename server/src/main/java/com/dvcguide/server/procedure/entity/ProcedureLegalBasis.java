package com.dvcguide.server.procedure.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "thu_tuc_van_ban", uniqueConstraints =
        @UniqueConstraint(name = "uq_tt_vb", columnNames = {"thu_tuc_id", "van_ban_id", "dieu_khoan"}))
@Getter
@Setter
public class ProcedureLegalBasis {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Integer id;

    @Column(name = "thu_tuc_id", nullable = false)
    private Integer thuTucId;

    @Column(name = "van_ban_id", nullable = false)
    private Integer vanBanId;

    @Column(name = "dieu_khoan", nullable = false, length = 255)
    private String dieuKhoan = "";

    @Column(name = "thu_tu", nullable = false)
    private Short thuTu = (short) 1;
}
