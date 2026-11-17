package com.dvcguide.server.procedure.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "thu_tuc_co_quan")
@IdClass(ProcedureAgency.Key.class)
@Getter
@Setter
public class ProcedureAgency {

    @Id
    @Column(name = "thu_tuc_id", nullable = false)
    private Integer thuTucId;

    @Id
    @Column(name = "co_quan_id", nullable = false)
    private Integer coQuanId;

    @Column(name = "ghi_chu", length = 500)
    private String ghiChu;

    public record Key(Integer thuTucId, Integer coQuanId) implements java.io.Serializable {}
}
