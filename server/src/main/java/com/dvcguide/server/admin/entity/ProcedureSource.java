package com.dvcguide.server.admin.entity;

import com.fasterxml.jackson.databind.JsonNode;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "thu_tuc_du_lieu_goc")
@Getter @Setter
public class ProcedureSource {
    @Id @Column(name = "thu_tuc_id") private Integer procedureId;
    @JdbcTypeCode(SqlTypes.JSON) @Column(name = "du_lieu_goc", nullable = false, columnDefinition = "JSON")
    private JsonNode payload;
}
