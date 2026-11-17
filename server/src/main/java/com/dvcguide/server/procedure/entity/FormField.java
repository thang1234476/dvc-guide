package com.dvcguide.server.procedure.entity;

import com.fasterxml.jackson.databind.JsonNode;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "bieu_mau_truong")
@Getter
@Setter
public class FormField {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Integer id;

    @Column(name = "bieu_mau_id", nullable = false)
    private Integer bieuMauId;

    @Column(name = "ten_o", nullable = false, length = 500)
    private String tenO;

    @Column(name = "huong_dan", columnDefinition = "TEXT")
    private String huongDan;

    @Column(name = "vi_du", columnDefinition = "TEXT")
    private String viDu;

    @Column(name = "loi_thuong_gap", columnDefinition = "TEXT")
    private String loiThuongGap;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "toa_do")
    private JsonNode toaDo;

    @Column(name = "thu_tu")
    private Integer thuTu = 0;
}
