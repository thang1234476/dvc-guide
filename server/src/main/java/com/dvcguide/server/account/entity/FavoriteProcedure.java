package com.dvcguide.server.account.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;

@Entity
@Table(name = "thu_tuc_yeu_thich")
@IdClass(FavoriteProcedure.Key.class)
@Getter
@Setter
public class FavoriteProcedure {

    @Id
    @JdbcTypeCode(SqlTypes.CHAR)
    @Column(name = "nguoi_dung_id", nullable = false, length = 36)
    private String nguoiDungId;

    @Id
    @Column(name = "thu_tuc_id", nullable = false)
    private Integer thuTucId;

    @CreationTimestamp
    @Column(name = "tao_luc", updatable = false)
    private Instant taoLuc;

    public record Key(String nguoiDungId, Integer thuTucId) implements java.io.Serializable {}
}
