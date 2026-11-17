package com.dvcguide.server.feedback.entity;

import com.dvcguide.server.common.model.FeedbackStatus;
import com.dvcguide.server.common.model.FeedbackType;
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
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;

@Entity
@Table(name = "gop_y")
@Getter
@Setter
public class Feedback {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Long id;

    @JdbcTypeCode(SqlTypes.CHAR)
    @Column(name = "nguoi_dung_id", length = 36)
    private String nguoiDungId;

    @Enumerated(EnumType.STRING)
    @Column(name = "loai", nullable = false)
    private FeedbackType loai;

    @Column(name = "co_quan_id")
    private Integer coQuanId;

    @Column(name = "thu_tuc_id")
    private Integer thuTucId;

    @Column(name = "noi_dung", nullable = false, columnDefinition = "TEXT")
    private String noiDung;

    @Enumerated(EnumType.STRING)
    @Column(name = "trang_thai", nullable = false)
    private FeedbackStatus trangThai = FeedbackStatus.moi;

    @CreationTimestamp
    @Column(name = "tao_luc", updatable = false)
    private Instant taoLuc;
}
