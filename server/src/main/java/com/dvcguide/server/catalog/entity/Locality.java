package com.dvcguide.server.catalog.entity;

import com.dvcguide.server.common.model.AdministrativeLevel;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "dia_phuong")
@Getter
@Setter
public class Locality {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Integer id;

    @Column(name = "ma", unique = true, length = 10)
    private String ma;

    @Column(name = "ten", nullable = false, length = 255)
    private String ten;

    @Enumerated(EnumType.STRING)
    @Column(name = "cap", nullable = false)
    private AdministrativeLevel cap;

    @Column(name = "parent_id")
    private Integer parentId;
}
