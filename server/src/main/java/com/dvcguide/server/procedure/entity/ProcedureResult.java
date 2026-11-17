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
@Table(name = "thu_tuc_ket_qua")
@Getter
@Setter
public class ProcedureResult {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Integer id;

    @Column(name = "thu_tuc_id", nullable = false)
    private Integer thuTucId;

    @Column(name = "ten", nullable = false, length = 1000)
    private String ten;

    @Column(name = "thu_tu", nullable = false)
    private Short thuTu = (short) 1;
}
