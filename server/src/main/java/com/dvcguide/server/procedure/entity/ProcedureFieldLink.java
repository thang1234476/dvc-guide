package com.dvcguide.server.procedure.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "thu_tuc_linh_vuc")
@IdClass(ProcedureFieldLink.Key.class)
@Getter
@Setter
public class ProcedureFieldLink {

    @Id
    @Column(name = "thu_tuc_id", nullable = false)
    private Integer thuTucId;

    @Id
    @Column(name = "linh_vuc_id", nullable = false)
    private Integer linhVucId;

    @Column(name = "thu_tu", nullable = false)
    private Short thuTu = (short) 1;

    public record Key(Integer thuTucId, Integer linhVucId) implements java.io.Serializable {}
}
