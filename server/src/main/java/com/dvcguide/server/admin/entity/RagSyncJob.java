package com.dvcguide.server.admin.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

@Entity
@Table(name = "hang_doi_dong_bo_rag")
@Getter @Setter
public class RagSyncJob {
    public enum Status { PENDING, PROCESSING, SYNCED, FAILED }
    @Id @Column(name = "thu_tuc_id") private Integer procedureId;
    @Column(name = "phien_ban_can_dong_bo", nullable = false) private Integer desiredVersion;
    @Column(name = "phien_ban_da_dong_bo") private Integer indexedVersion;
    @Enumerated(EnumType.STRING) @Column(name = "trang_thai", nullable = false, length = 20) private Status status = Status.PENDING;
    @Column(name = "so_lan_thu", nullable = false) private Integer attempts = 0;
    @Column(name = "so_doan", nullable = false) private Integer chunkCount = 0;
    @Column(name = "thu_lai_luc", nullable = false) private Instant nextAttemptAt = Instant.now();
    @Column(name = "giu_den_luc") private Instant leaseUntil;
    @Column(name = "loi_gan_nhat", length = 500) private String lastError;
    @Column(name = "dong_bo_luc") private Instant indexedAt;
}
