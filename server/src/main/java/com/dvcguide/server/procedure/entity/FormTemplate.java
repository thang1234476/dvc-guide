package com.dvcguide.server.procedure.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

@Entity
@Table(name = "bieu_mau")
@Getter
@Setter
public class FormTemplate {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Integer id;

    @Column(name = "ma_bieu_mau", length = 50)
    private String maBieuMau;

    @Column(name = "ten", nullable = false, length = 500)
    private String ten;

    @Column(name = "phien_ban", length = 100)
    private String phienBan;

    @Column(name = "ngay_hieu_luc")
    private LocalDate ngayHieuLuc;

    @Column(name = "file_docx_url", length = 1000)
    private String fileDocxUrl;

    @Column(name = "file_pdf_url", length = 1000)
    private String filePdfUrl;

    @Column(name = "anh_mau_url", length = 1000)
    private String anhMauUrl;

    @Column(name = "van_ban_id")
    private Integer vanBanId;
}
