package com.dvcguide.server.chat.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.annotations.UuidGenerator;
import org.hibernate.type.SqlTypes;

import java.time.Instant;

@Entity
@Table(name = "hoi_thoai")
@Getter
@Setter
public class Conversation {

    @Id
    @UuidGenerator
    @JdbcTypeCode(SqlTypes.CHAR)
    @Column(name = "id", nullable = false, length = 36)
    private String id;

    @JdbcTypeCode(SqlTypes.CHAR)
    @Column(name = "nguoi_dung_id", length = 36)
    private String nguoiDungId;

    @Column(name = "thu_tuc_id")
    private Integer thuTucId;

    @Column(name = "tieu_de", length = 500)
    private String tieuDe;

    @CreationTimestamp
    @Column(name = "tao_luc", updatable = false)
    private Instant taoLuc;

    @UpdateTimestamp
    @Column(name = "cap_nhat_luc")
    private Instant capNhatLuc;
}
