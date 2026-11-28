-- Chay tren database dvc_guide sau khi dung backend.
-- Ho tro ca database chua co bang RAG va database da tao ba bang ten tieng Anh.
-- Doi ten bang/cot tai cho, giu nguyen ban ghi, khoa chinh va quan he khoa ngoai.
-- Neu ca ten cu va ten moi cung ton tai, RENAME TABLE se bao loi; khong ghi de du lieu.
-- Khong can tao stored procedure. Co the dan toan bo file vao tab SQL cua phpMyAdmin.
USE dvc_guide;

SET @rag_group_concat_truoc = @@SESSION.group_concat_max_len;
SET SESSION group_concat_max_len = 16384;

-- Doi tat ca bang ten cu trong cung mot lenh.
SELECT GROUP_CONCAT(CONCAT('`', doi.ten_cu, '` TO `', doi.ten_moi, '`') ORDER BY doi.ten_cu SEPARATOR ', ')
INTO @rag_danh_sach_bang
FROM (
    SELECT 'procedure_source' AS ten_cu, 'thu_tuc_du_lieu_goc' AS ten_moi
    UNION ALL SELECT 'rag_sync_job', 'hang_doi_dong_bo_rag'
    UNION ALL SELECT 'document_form', 'thanh_phan_ho_so_bieu_mau'
) AS doi
JOIN information_schema.TABLES AS bang
  ON bang.TABLE_SCHEMA = DATABASE() AND bang.TABLE_NAME = doi.ten_cu AND bang.TABLE_TYPE = 'BASE TABLE';
SET @rag_lenh = IF(@rag_danh_sach_bang IS NULL, 'DO 0', CONCAT('RENAME TABLE ', @rag_danh_sach_bang));
PREPARE rag_doi_ten FROM @rag_lenh;
EXECUTE rag_doi_ten;
DEALLOCATE PREPARE rag_doi_ten;


-- MariaDB 10.4: tach cot khoa ngoai khoi cot JSON de doi ten bang INPLACE.
SET @rag_lenh = IF(EXISTS (
    SELECT 1 FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'thu_tuc_du_lieu_goc' AND COLUMN_NAME = 'procedure_id'
), 'ALTER TABLE thu_tuc_du_lieu_goc ALGORITHM=INPLACE, CHANGE COLUMN procedure_id thu_tuc_id INT NOT NULL', 'DO 0');
PREPARE rag_doi_cot FROM @rag_lenh;
EXECUTE rag_doi_cot;
DEALLOCATE PREPARE rag_doi_cot;

SET @rag_lenh = IF(EXISTS (
    SELECT 1 FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'thu_tuc_du_lieu_goc' AND COLUMN_NAME = 'payload'
), 'ALTER TABLE thu_tuc_du_lieu_goc CHANGE COLUMN payload du_lieu_goc JSON NOT NULL', 'DO 0');
PREPARE rag_doi_cot FROM @rag_lenh;
EXECUTE rag_doi_cot;
DEALLOCATE PREPARE rag_doi_cot;


-- Chi doi cac cot ten cu con ton tai trong hang_doi_dong_bo_rag.
SELECT GROUP_CONCAT(CONCAT('CHANGE COLUMN `', doi.ten_cu, '` `', doi.ten_moi, '` ', doi.dinh_nghia)
                    ORDER BY doi.thu_tu SEPARATOR ', ')
INTO @rag_danh_sach_cot
FROM (
    SELECT 'procedure_id' AS ten_cu, 'thu_tuc_id' AS ten_moi, 'INT NOT NULL' AS dinh_nghia, 0 AS thu_tu
    UNION ALL SELECT 'desired_version' AS ten_cu, 'phien_ban_can_dong_bo' AS ten_moi, 'INT NOT NULL' AS dinh_nghia, 1 AS thu_tu
    UNION ALL SELECT 'indexed_version' AS ten_cu, 'phien_ban_da_dong_bo' AS ten_moi, 'INT NULL' AS dinh_nghia, 2 AS thu_tu
    UNION ALL SELECT 'status' AS ten_cu, 'trang_thai' AS ten_moi, 'VARCHAR(20) NOT NULL DEFAULT ''PENDING''' AS dinh_nghia, 3 AS thu_tu
    UNION ALL SELECT 'attempts' AS ten_cu, 'so_lan_thu' AS ten_moi, 'INT NOT NULL DEFAULT 0' AS dinh_nghia, 4 AS thu_tu
    UNION ALL SELECT 'chunk_count' AS ten_cu, 'so_doan' AS ten_moi, 'INT NOT NULL DEFAULT 0' AS dinh_nghia, 5 AS thu_tu
    UNION ALL SELECT 'next_attempt_at' AS ten_cu, 'thu_lai_luc' AS ten_moi, 'TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)' AS dinh_nghia, 6 AS thu_tu
    UNION ALL SELECT 'lease_until' AS ten_cu, 'giu_den_luc' AS ten_moi, 'TIMESTAMP(6) NULL' AS dinh_nghia, 7 AS thu_tu
    UNION ALL SELECT 'last_error' AS ten_cu, 'loi_gan_nhat' AS ten_moi, 'VARCHAR(500) NULL' AS dinh_nghia, 8 AS thu_tu
    UNION ALL SELECT 'indexed_at' AS ten_cu, 'dong_bo_luc' AS ten_moi, 'TIMESTAMP(6) NULL' AS dinh_nghia, 9 AS thu_tu
) AS doi
JOIN information_schema.COLUMNS AS cot
  ON cot.TABLE_SCHEMA = DATABASE() AND cot.TABLE_NAME = 'hang_doi_dong_bo_rag' AND cot.COLUMN_NAME = doi.ten_cu;
SET @rag_lenh = IF(@rag_danh_sach_cot IS NULL, 'DO 0',
                  CONCAT('ALTER TABLE `hang_doi_dong_bo_rag` ', @rag_danh_sach_cot));
PREPARE rag_doi_cot FROM @rag_lenh;
EXECUTE rag_doi_cot;
DEALLOCATE PREPARE rag_doi_cot;


-- Chi doi cac cot ten cu con ton tai trong thanh_phan_ho_so_bieu_mau.
SELECT GROUP_CONCAT(CONCAT('CHANGE COLUMN `', doi.ten_cu, '` `', doi.ten_moi, '` ', doi.dinh_nghia)
                    ORDER BY doi.thu_tu SEPARATOR ', ')
INTO @rag_danh_sach_cot
FROM (
    SELECT 'document_id' AS ten_cu, 'thanh_phan_id' AS ten_moi, 'INT NOT NULL' AS dinh_nghia, 0 AS thu_tu
    UNION ALL SELECT 'form_id' AS ten_cu, 'bieu_mau_id' AS ten_moi, 'INT NOT NULL' AS dinh_nghia, 1 AS thu_tu
    UNION ALL SELECT 'sort_order' AS ten_cu, 'thu_tu' AS ten_moi, 'INT NOT NULL' AS dinh_nghia, 2 AS thu_tu
) AS doi
JOIN information_schema.COLUMNS AS cot
  ON cot.TABLE_SCHEMA = DATABASE() AND cot.TABLE_NAME = 'thanh_phan_ho_so_bieu_mau' AND cot.COLUMN_NAME = doi.ten_cu;
SET @rag_lenh = IF(@rag_danh_sach_cot IS NULL, 'DO 0',
                  CONCAT('ALTER TABLE `thanh_phan_ho_so_bieu_mau` ALGORITHM=INPLACE, ', @rag_danh_sach_cot));
PREPARE rag_doi_cot FROM @rag_lenh;
EXECUTE rag_doi_cot;
DEALLOCATE PREPARE rag_doi_cot;


-- Tao cac bang chua co, su dung ten tieng Viet khong dau.
CREATE TABLE IF NOT EXISTS thu_tuc_du_lieu_goc (
    thu_tuc_id INT NOT NULL PRIMARY KEY,
    du_lieu_goc JSON NOT NULL,
    CONSTRAINT fk_du_lieu_goc_thu_tuc FOREIGN KEY (thu_tuc_id) REFERENCES thu_tuc(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS hang_doi_dong_bo_rag (
    thu_tuc_id INT NOT NULL PRIMARY KEY,
    phien_ban_can_dong_bo INT NOT NULL,
    phien_ban_da_dong_bo INT NULL,
    trang_thai VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    so_lan_thu INT NOT NULL DEFAULT 0,
    so_doan INT NOT NULL DEFAULT 0,
    thu_lai_luc TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    giu_den_luc TIMESTAMP(6) NULL,
    loi_gan_nhat VARCHAR(500) NULL,
    dong_bo_luc TIMESTAMP(6) NULL,
    KEY idx_hang_doi_rag_thu_lai (trang_thai, thu_lai_luc)
);

CREATE TABLE IF NOT EXISTS thanh_phan_ho_so_bieu_mau (
    thanh_phan_id INT NOT NULL,
    bieu_mau_id INT NOT NULL,
    thu_tu INT NOT NULL,
    PRIMARY KEY (thanh_phan_id, bieu_mau_id),
    CONSTRAINT fk_ho_so_bieu_mau_thanh_phan FOREIGN KEY (thanh_phan_id) REFERENCES thanh_phan_ho_so(id) ON DELETE CASCADE,
    CONSTRAINT fk_ho_so_bieu_mau_bieu_mau FOREIGN KEY (bieu_mau_id) REFERENCES bieu_mau(id)
);

-- Mo rong cot de giu day du du lieu clean.json.
ALTER TABLE thanh_phan_ho_so MODIFY COLUMN ten_giay_to TEXT NOT NULL;
ALTER TABLE le_phi MODIFY COLUMN tien_te VARCHAR(50) NULL;

SET SESSION group_concat_max_len = @rag_group_concat_truoc;
