package com.dvcguide.server.dossier.entity;

import com.dvcguide.server.common.model.DossierStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
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
import java.time.LocalDate;

@Entity
@Table(name = "ho_so_cua_toi")
@Getter
@Setter
public class Dossier {

    @Id
    @UuidGenerator
    @JdbcTypeCode(SqlTypes.CHAR)
    @Column(name = "id", nullable = false, length = 36)
    private String id;

    @JdbcTypeCode(SqlTypes.CHAR)
    @Column(name = "nguoi_dung_id", nullable = false, length = 36)
    private String nguoiDungId;

    @Column(name = "ten_ho_so", nullable = false, length = 255)
    private String tenHoSo;

    @Column(name = "thu_tuc_id", nullable = false)
    private Integer thuTucId;

    @Column(name = "truong_hop_id")
    private Integer truongHopId;

    @Enumerated(EnumType.STRING)
    @Column(name = "trang_thai", nullable = false)
    private DossierStatus trangThai = DossierStatus.dang_chuan_bi;

    @Column(name = "co_quan_du_dinh_id")
    private Integer coQuanDuDinhId;

    @Column(name = "co_quan_thuc_te_id")
    private Integer coQuanThucTeId;

    @Column(name = "ngay_nop")
    private LocalDate ngayNop;

    @Column(name = "ma_ho_so", length = 100)
    private String maHoSo;

    @Column(name = "ngay_hen")
    private LocalDate ngayHen;

    @Column(name = "ghi_chu", columnDefinition = "TEXT")
    private String ghiChu;

    @CreationTimestamp
    @Column(name = "tao_luc", updatable = false)
    private Instant taoLuc;

    @UpdateTimestamp
    @Column(name = "cap_nhat_luc")
    private Instant capNhatLuc;
}
