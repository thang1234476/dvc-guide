package com.dvcguide.server.chat.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;

@Entity
@Table(name = "phan_hoi", uniqueConstraints =
        @UniqueConstraint(name = "uq_ph_tin_nhan", columnNames = {"tin_nhan_id"}))
@Getter
@Setter
public class MessageRating {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Long id;

    @Column(name = "tin_nhan_id", nullable = false)
    private Long tinNhanId;

    @Column(name = "huu_ich", nullable = false)
    private Boolean huuIch;

    @Column(name = "ghi_chu", columnDefinition = "TEXT")
    private String ghiChu;

    @CreationTimestamp
    @Column(name = "tao_luc", updatable = false)
    private Instant taoLuc;
}
