package com.dvcguide.server.dossier.entity;

import com.dvcguide.server.common.model.ChecklistStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.type.SqlTypes;

import java.time.Instant;

@Entity
@Table(name = "ho_so_checklist")
@IdClass(ChecklistItem.Key.class)
@Getter
@Setter
public class ChecklistItem {

    @Id
    @JdbcTypeCode(SqlTypes.CHAR)
    @Column(name = "ho_so_id", nullable = false, length = 36)
    private String hoSoId;

    @Id
    @Column(name = "thanh_phan_id", nullable = false)
    private Integer thanhPhanId;

    @Enumerated(EnumType.STRING)
    @Column(name = "trang_thai", nullable = false)
    private ChecklistStatus trangThai = ChecklistStatus.chua_ro;

    @UpdateTimestamp
    @Column(name = "cap_nhat_luc")
    private Instant capNhatLuc;

    public record Key(String hoSoId, Integer thanhPhanId) implements java.io.Serializable {}
}
