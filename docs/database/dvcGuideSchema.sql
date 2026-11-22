-- =====================================================================
-- Trợ lý số hướng dẫn thủ tục hành chính & dịch vụ công  (BẢN SỬA v3 - khớp đặc tả ứng dụng Flutter)
-- CSDL: MySQL 8.0.13+ hoặc MariaDB 10.4+ (XAMPP) - InnoDB, utf8mb4
-- Đã chạy thử trên MariaDB 10.11 (tạo mới CSDL trống). Vector embedding KHÔNG lưu trong MySQL.
--
-- NGUYÊN TẮC CỦA BẢN SỬA
--  1. Cái gì dữ liệu gốc (clean.json) chưa biết thì để NULL, KHÔNG gán mặc định
--     (đơn vị thời hạn, số bản, hiệu lực văn bản). Mặc định sẽ biến "chưa rõ" thành "đã rõ".
--  2. Dữ liệu có thể lặp, có nhiều giá trị (lĩnh vực, lệ phí, kết quả) thì tách bảng.
--  3. Admin sửa/xóa không bị khóa ngoại chặn: dùng xóa mềm (trang_thai) và CASCADE đúng chỗ.
--  4. Mỗi lần nội dung thủ tục đổi thì tăng thu_tuc.phien_ban để đồng bộ chỉ mục RAG.
--
-- THAY ĐỔI SO VỚI v2 (để khớp đặc tả ứng dụng)
--  - co_quan: thêm nguon_dia_chi, da_kiem_chung, kiem_chung_luc  -> nhãn "Địa chỉ tham khảo do AI cung cấp".
--  - thu_tuc: thêm ten_khong_dau                                  -> ô tìm theo tên trên Trang chủ.
--  - nguoi_dung: thêm bat_nhac_lich (công tắc Nhắc lịch trong Cài đặt) và mat_khau_hash (đăng ký/đăng nhập).
--  - ho_so_cua_toi: thêm ten_ho_so, trang_thai (5 bước), ma_ho_so, ghi_chu, cap_nhat_luc;
--                   tách nơi nộp thành co_quan_du_dinh_id / co_quan_thuc_te_id; han_tra_kq đổi thành ngay_hen.
--  - ho_so_checklist: da_chuan_bi (đúng/sai) đổi thành trang_thai 3 giá trị Đã có / Chưa có / Chưa rõ.
--  - hoi_thoai: thêm thu_tuc_id (nút "Hỏi về thủ tục này"), cap_nhat_luc (sắp xếp lịch sử trò chuyện).
--  - phan_hoi: mỗi tin nhắn chỉ có một đánh giá (Hữu ích / Chưa đúng).
--  - Bảng mới: thu_tuc_yeu_thich, phien_dang_nhap, gop_y.
-- =====================================================================

CREATE DATABASE IF NOT EXISTS dvc_guide
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
-- Lưu ý collation: không phân biệt hoa/thường và dấu thanh/mũ ("ha noi" = "Hà Nội"),
-- NHƯNG chữ "đ" vẫn khác "d" ("dang ky" không khớp "đăng ký"). Đừng dựa vào cột này để tìm kiếm;
-- tìm kiếm do bộ RAG (bge-m3 + BM25) đảm nhiệm.

USE dvc_guide;

-- =====================================================================
-- A. DANH MỤC DÙNG CHUNG
-- =====================================================================

CREATE TABLE dia_phuong (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    ma         VARCHAR(10) UNIQUE,
    ten        VARCHAR(255) NOT NULL,
    cap        ENUM('trung_uong','tinh','huyen','xa') NOT NULL,
    parent_id  INT NULL,
    FOREIGN KEY (parent_id) REFERENCES dia_phuong(id)
);

CREATE TABLE co_quan (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    ma            VARCHAR(30) UNIQUE,
    ten           VARCHAR(500) NOT NULL,
    cap           ENUM('trung_uong','tinh','huyen','xa') NOT NULL,
    dia_phuong_id INT NULL,
    dia_chi       TEXT,
    vi_do         DOUBLE,
    kinh_do       DOUBLE,
    so_dien_thoai VARCHAR(30),
    email         VARCHAR(255),
    website       VARCHAR(500),
    gio_lam_viec  VARCHAR(255),
    gio_phat_so   VARCHAR(255),
    -- Địa chỉ do AI (Gemini) gợi ý mà chưa ai kiểm chứng thì app phải hiện nhãn
    -- "Địa chỉ tham khảo do AI cung cấp, cần xác nhận trước khi đến" (nguon_dia_chi = 'ai' và da_kiem_chung = FALSE).
    nguon_dia_chi  ENUM('du_lieu_goc','ai','quan_tri') NOT NULL DEFAULT 'du_lieu_goc',
    da_kiem_chung  BOOLEAN NOT NULL DEFAULT FALSE,
    kiem_chung_luc DATE NULL,
    KEY idx_cq_dia_phuong (dia_phuong_id),
    FOREIGN KEY (dia_phuong_id) REFERENCES dia_phuong(id)
);

CREATE TABLE linh_vuc (
    id   INT AUTO_INCREMENT PRIMARY KEY,
    ma   VARCHAR(30) UNIQUE,
    ten  VARCHAR(255) NOT NULL
);

-- =====================================================================
-- B. THỦ TỤC HÀNH CHÍNH
-- =====================================================================

CREATE TABLE van_ban_phap_ly (
    id                  INT AUTO_INCREMENT PRIMARY KEY,
    so_hieu             VARCHAR(100) NOT NULL UNIQUE,      -- "104/2022/NĐ-CP"
    ten                 TEXT NOT NULL,
    loai                ENUM('luat','nghi_dinh','thong_tu','quyet_dinh','nghi_quyet','khac') NOT NULL DEFAULT 'khac',
    co_quan_ban_hanh    VARCHAR(255),
    ngay_ban_hanh       DATE,
    ngay_hieu_luc       DATE,
    ngay_het_hieu_luc   DATE NULL,
    -- NULL ở ngay_het_hieu_luc KHÔNG có nghĩa là "còn hiệu lực". Trạng thái thật ghi ở đây:
    trang_thai_hieu_luc ENUM('chua_xac_minh','con_hieu_luc','het_hieu_luc') NOT NULL DEFAULT 'chua_xac_minh',
    xac_minh_luc        DATE NULL,                         -- ngày người có thẩm quyền xác minh
    nguon_xac_minh      VARCHAR(1000),
    url                 VARCHAR(1000)
);

CREATE TABLE thu_tuc (
    id                      INT AUTO_INCREMENT PRIMARY KEY,
    ma_thu_tuc              VARCHAR(50) NOT NULL UNIQUE,   -- mã trên Cổng DVCQG
    ten                     VARCHAR(1000) NOT NULL,
    ten_khong_dau           VARCHAR(1000) NULL,            -- tên đã bỏ dấu, viết thường, do ứng dụng điền; dùng cho ô tìm kiếm trên Trang chủ
    cap_thuc_hien           ENUM('trung_uong','tinh','huyen','xa') NULL,
    co_quan_thuc_hien_goc   TEXT,                          -- nguyên văn (clean.json: co_quan.thuc_hien)
    doi_tuong               TEXT,
    dieu_kien               TEXT,                          -- clean.json: yeu_cau_dieu_kien
    link_dvc                VARCHAR(1000),
    nguon_du_lieu           VARCHAR(500),
    trang_thai              ENUM('nhap','dang_dung','ngung') NOT NULL DEFAULT 'nhap',
                                                           -- chỉ 'dang_dung' được đưa vào chỉ mục RAG; xóa = chuyển 'ngung'
    phien_ban               INT NOT NULL DEFAULT 1,        -- ứng dụng tăng 1 mỗi khi sửa thủ tục hoặc bảng con
    tao_luc                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    cap_nhat_luc            TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_tt_trang_thai (trang_thai)
    -- Bỏ FULLTEXT: InnoDB không tách từ tiếng Việt và bỏ từ ngắn dưới 3 ký tự; RAG đã có BM25 riêng.
);

-- Một thủ tục có thể thuộc nhiều lĩnh vực (clean.json: linh_vuc là danh sách); thu_tu = 1 là lĩnh vực chính
CREATE TABLE thu_tuc_linh_vuc (
    thu_tuc_id   INT NOT NULL,
    linh_vuc_id  INT NOT NULL,
    thu_tu       SMALLINT NOT NULL DEFAULT 1,
    PRIMARY KEY (thu_tuc_id, linh_vuc_id),
    FOREIGN KEY (thu_tuc_id)  REFERENCES thu_tuc(id)  ON DELETE CASCADE,
    FOREIGN KEY (linh_vuc_id) REFERENCES linh_vuc(id) ON DELETE CASCADE
);

CREATE TABLE thu_tuc_ket_qua (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    thu_tuc_id  INT NOT NULL,
    ten         VARCHAR(1000) NOT NULL,
    thu_tu      SMALLINT NOT NULL DEFAULT 1,
    FOREIGN KEY (thu_tuc_id) REFERENCES thu_tuc(id) ON DELETE CASCADE
);

CREATE TABLE thu_tuc_co_quan (
    thu_tuc_id INT NOT NULL,
    co_quan_id INT NOT NULL,
    ghi_chu    VARCHAR(500),
    PRIMARY KEY (thu_tuc_id, co_quan_id),
    FOREIGN KEY (thu_tuc_id) REFERENCES thu_tuc(id) ON DELETE CASCADE,
    FOREIGN KEY (co_quan_id) REFERENCES co_quan(id) ON DELETE CASCADE
);

-- Khóa chính là id riêng để một thủ tục có thể dẫn nhiều điều khoản của cùng một văn bản
CREATE TABLE thu_tuc_van_ban (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    thu_tuc_id  INT NOT NULL,
    van_ban_id  INT NOT NULL,
    dieu_khoan  VARCHAR(255) NOT NULL DEFAULT '',         -- "Điều 5, khoản 2"
    thu_tu      SMALLINT NOT NULL DEFAULT 1,
    UNIQUE KEY uq_tt_vb (thu_tuc_id, van_ban_id, dieu_khoan),
    FOREIGN KEY (thu_tuc_id) REFERENCES thu_tuc(id) ON DELETE CASCADE,
    FOREIGN KEY (van_ban_id) REFERENCES van_ban_phap_ly(id)
);

CREATE TABLE truong_hop (
    id                 INT AUTO_INCREMENT PRIMARY KEY,
    thu_tuc_id         INT NOT NULL,
    ten                VARCHAR(500) NOT NULL,
    dieu_kien          TEXT,
    cau_hoi_phan_loai  TEXT,
    thu_tu             INT DEFAULT 0,
    FOREIGN KEY (thu_tuc_id) REFERENCES thu_tuc(id) ON DELETE CASCADE
);

CREATE TABLE bieu_mau (
    id             INT AUTO_INCREMENT PRIMARY KEY,
    ma_bieu_mau    VARCHAR(50),
    ten            VARCHAR(500) NOT NULL,
    phien_ban      VARCHAR(100),
    ngay_hieu_luc  DATE,
    file_docx_url  VARCHAR(1000),
    file_pdf_url   VARCHAR(1000),
    anh_mau_url    VARCHAR(1000),
    van_ban_id     INT NULL,
    FOREIGN KEY (van_ban_id) REFERENCES van_ban_phap_ly(id)
);

CREATE TABLE bieu_mau_truong (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    bieu_mau_id     INT NOT NULL,
    ten_o           VARCHAR(500) NOT NULL,
    huong_dan       TEXT,
    vi_du           TEXT,
    loi_thuong_gap  TEXT,
    toa_do          JSON NULL,                            -- {"page":1,"x":..,"y":..,"w":..,"h":..}
    thu_tu          INT DEFAULT 0,
    FOREIGN KEY (bieu_mau_id) REFERENCES bieu_mau(id) ON DELETE CASCADE
);

-- Khớp clean.json: ho_so = [{nhom, ten, truong_hop}]
-- truong_hop_id NULL = áp dụng cho mọi trường hợp. Số bản NULL = dữ liệu gốc không ghi.
CREATE TABLE thanh_phan_ho_so (
    id                  INT AUTO_INCREMENT PRIMARY KEY,
    thu_tuc_id          INT NOT NULL,
    truong_hop_id       INT NULL,
    nhom                VARCHAR(255),
    ten_giay_to         VARCHAR(1000) NOT NULL,
    truong_hop_goc      TEXT,                              -- nguyên văn trường truong_hop của clean.json
    so_luong_ban_chinh  SMALLINT NULL,
    so_luong_ban_sao    SMALLINT NULL,
    bat_buoc            BOOLEAN NULL,
    bieu_mau_id         INT NULL,
    ghi_chu             TEXT,
    thu_tu              INT DEFAULT 0,
    FOREIGN KEY (thu_tuc_id)    REFERENCES thu_tuc(id)    ON DELETE CASCADE,
    FOREIGN KEY (truong_hop_id) REFERENCES truong_hop(id) ON DELETE SET NULL,
    FOREIGN KEY (bieu_mau_id)   REFERENCES bieu_mau(id)   ON DELETE SET NULL
);

-- Trình tự thực hiện (clean.json: trinh_tu). 'chung' = bước áp dụng cho mọi hình thức nộp.
CREATE TABLE buoc_thuc_hien (
    id                 INT AUTO_INCREMENT PRIMARY KEY,
    thu_tuc_id         INT NOT NULL,
    hinh_thuc          ENUM('chung','truc_tuyen','truc_tiep','buu_chinh','khac') NOT NULL DEFAULT 'chung',
    thu_tu             SMALLINT NOT NULL,                  -- số bước, không giới hạn 4
    tieu_de            VARCHAR(500) NULL,
    mo_ta              TEXT,
    anh_huong_dan_url  VARCHAR(1000),
    UNIQUE KEY uq_buoc (thu_tuc_id, hinh_thuc, thu_tu),
    FOREIGN KEY (thu_tuc_id) REFERENCES thu_tuc(id) ON DELETE CASCADE
);

-- Cách thức nộp (clean.json: cach_thuc). Thời hạn và lệ phí khác nhau theo từng hình thức.
CREATE TABLE hinh_thuc_nop_chi_tiet (
    id               INT AUTO_INCREMENT PRIMARY KEY,
    thu_tuc_id       INT NOT NULL,
    hinh_thuc        ENUM('truc_tuyen','truc_tiep','buu_chinh','khac') NOT NULL,
    hinh_thuc_goc    VARCHAR(255),                         -- nguyên văn, vd "Trực tiếp"
    thoi_han_so      DECIMAL(6,1) NULL,
    thoi_han_don_vi  VARCHAR(50) NULL,                     -- "ngày làm việc", "ngày", "giờ"... NULL = dữ liệu gốc chưa ghi đơn vị, KHÔNG tự đoán
    thoi_han_goc     TEXT,                                 -- nguyên văn
    link_nop         VARCHAR(1000),
    dia_chi_nop      TEXT,
    gio_tiep_nhan    VARCHAR(500),
    FOREIGN KEY (thu_tuc_id) REFERENCES thu_tuc(id) ON DELETE CASCADE
);

-- Một cách thức có thể có nhiều khoản lệ phí, nhiều loại tiền (VND, USD...)
-- mien_phi = 0 và so_tien NULL nghĩa là "không rõ"
CREATE TABLE le_phi (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    cach_thuc_id  INT NOT NULL,
    mien_phi      BOOLEAN NOT NULL DEFAULT FALSE,
    so_tien       DECIMAL(15,2) NULL,
    tien_te       VARCHAR(10) NULL,
    ghi_chu       TEXT,
    thu_tu        SMALLINT NOT NULL DEFAULT 1,
    FOREIGN KEY (cach_thuc_id) REFERENCES hinh_thuc_nop_chi_tiet(id) ON DELETE CASCADE
);

-- =====================================================================
-- C. KHO TRI THỨC CHO RAG  (dữ liệu SINH RA, có thể xóa và dựng lại bất cứ lúc nào)
-- =====================================================================
-- Văn bản đoạn phải do cùng một hàm chia đoạn với bộ RAG tạo ra (chia theo trường, có dòng "Thủ tục: <tên>").
-- phien_ban khác thu_tuc.phien_ban nghĩa là đoạn đã cũ, cần dựng lại.

CREATE TABLE rag_chunk (
    id            BIGINT AUTO_INCREMENT PRIMARY KEY,
    nguon         ENUM('thu_tuc','thanh_phan_ho_so','buoc_thuc_hien','van_ban','bieu_mau') NOT NULL,
    thu_tuc_id    INT NULL,
    van_ban_id    INT NULL,
    bieu_mau_id   INT NULL,
    truong        VARCHAR(100) NULL,                       -- tên trường nguồn, vd "Thành phần hồ sơ"
    stt_doan      SMALLINT NOT NULL DEFAULT 0,
    noi_dung      MEDIUMTEXT NOT NULL,
    noi_dung_md5  CHAR(32) NOT NULL,                       -- khóa cache vector theo từng đoạn
    phien_ban     INT NOT NULL DEFAULT 1,
    tieu_de       VARCHAR(500),
    trich_dan     VARCHAR(500),
    url_nguon     VARCHAR(1000),
    metadata      JSON NULL,
    KEY idx_chunk_tt (thu_tuc_id, phien_ban),
    KEY idx_chunk_md5 (noi_dung_md5),
    FOREIGN KEY (thu_tuc_id)  REFERENCES thu_tuc(id) ON DELETE CASCADE,
    FOREIGN KEY (van_ban_id)  REFERENCES van_ban_phap_ly(id) ON DELETE CASCADE,
    FOREIGN KEY (bieu_mau_id) REFERENCES bieu_mau(id) ON DELETE CASCADE
);

-- =====================================================================
-- D. DỮ LIỆU ỨNG DỤNG
-- =====================================================================
-- Nếu DEFAULT (UUID()) báo lỗi trên máy bạn, bỏ phần DEFAULT và sinh UUID trong ứng dụng.

CREATE TABLE nguoi_dung (
    id             CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    email          VARCHAR(255) UNIQUE,
    mat_khau_hash  VARCHAR(255) NULL,                      -- đăng ký/đăng nhập bằng email: băm bcrypt/argon2 ở máy chủ; NULL nếu đăng nhập qua dịch vụ ngoài
    ten_hien_thi   VARCHAR(255),
    dia_phuong_id  INT NULL,
    bat_nhac_lich  BOOLEAN NOT NULL DEFAULT TRUE,          -- Cài đặt: bật/tắt nhắc lịch (ngày hẹn của hồ sơ)
    tao_luc        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (dia_phuong_id) REFERENCES dia_phuong(id)
);
-- "Xóa tài khoản" = DELETE FROM nguoi_dung: hồ sơ, yêu thích, phiên đăng nhập, hội thoại bị xóa theo (CASCADE).

-- Phiên đăng nhập để "Đăng xuất" thu hồi được phiên trên máy chủ. Chỉ lưu băm của token.
CREATE TABLE phien_dang_nhap (
    id              CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    nguoi_dung_id   CHAR(36) NOT NULL,
    token_hash      CHAR(64) NOT NULL UNIQUE,
    thiet_bi        VARCHAR(255) NULL,
    tao_luc         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    het_han_luc     DATETIME NOT NULL,
    dang_xuat_luc   DATETIME NULL,                         -- NULL = phiên còn dùng được (nếu chưa hết hạn)
    KEY idx_pdn_nd (nguoi_dung_id),
    FOREIGN KEY (nguoi_dung_id) REFERENCES nguoi_dung(id) ON DELETE CASCADE
);

-- Trang chủ: lưu thủ tục yêu thích để xem lại (bộ lọc "Đã lưu")
CREATE TABLE thu_tuc_yeu_thich (
    nguoi_dung_id  CHAR(36) NOT NULL,
    thu_tuc_id     INT NOT NULL,
    tao_luc        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (nguoi_dung_id, thu_tuc_id),
    FOREIGN KEY (nguoi_dung_id) REFERENCES nguoi_dung(id) ON DELETE CASCADE,
    FOREIGN KEY (thu_tuc_id)    REFERENCES thu_tuc(id)    ON DELETE CASCADE
);

-- Hồ sơ của tôi: mỗi hồ sơ gắn với một thủ tục (người dùng có thể có nhiều hồ sơ cho cùng một thủ tục)
CREATE TABLE ho_so_cua_toi (
    id                  CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    nguoi_dung_id       CHAR(36) NOT NULL,
    ten_ho_so           VARCHAR(255) NOT NULL,             -- tên do người dùng đặt
    thu_tuc_id          INT NOT NULL,
    truong_hop_id       INT NULL,
    -- Người dùng tự cập nhật, không đồng bộ từ hệ thống cơ quan nhà nước
    trang_thai          ENUM('dang_chuan_bi','da_nop','dang_xu_ly','can_bo_sung','da_nhan_ket_qua')
                        NOT NULL DEFAULT 'dang_chuan_bi',
    co_quan_du_dinh_id  INT NULL,                          -- nơi dự định nộp
    co_quan_thuc_te_id  INT NULL,                          -- nơi thực tế đã nộp
    ngay_nop            DATE NULL,
    ma_ho_so            VARCHAR(100) NULL,                 -- mã hồ sơ do cơ quan cấp (nếu có)
    ngay_hen            DATE NULL,                         -- ngày hẹn trả kết quả (nếu có); dùng cho nhắc lịch
    ghi_chu             TEXT,
    tao_luc             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    cap_nhat_luc        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_hs_nd (nguoi_dung_id, trang_thai),
    KEY idx_hs_hen (ngay_hen),
    FOREIGN KEY (nguoi_dung_id)       REFERENCES nguoi_dung(id) ON DELETE CASCADE,
    FOREIGN KEY (thu_tuc_id)          REFERENCES thu_tuc(id),     -- thủ tục bị ngừng dùng thì chuyển trang_thai, không xóa cứng
    FOREIGN KEY (truong_hop_id)       REFERENCES truong_hop(id) ON DELETE SET NULL,
    FOREIGN KEY (co_quan_du_dinh_id)  REFERENCES co_quan(id)    ON DELETE SET NULL,
    FOREIGN KEY (co_quan_thuc_te_id)  REFERENCES co_quan(id)    ON DELETE SET NULL
);

-- Kiểm tra giấy tờ cần chuẩn bị: Đã có / Chưa có / Chưa rõ.
-- Chưa có dòng nào cho một giấy tờ nghĩa là "chưa rõ". Mức độ chuẩn bị chỉ tính theo những gì người dùng tự đánh dấu.
CREATE TABLE ho_so_checklist (
    ho_so_id       CHAR(36) NOT NULL,
    thanh_phan_id  INT NOT NULL,
    trang_thai     ENUM('da_co','chua_co','chua_ro') NOT NULL DEFAULT 'chua_ro',
    cap_nhat_luc   TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (ho_so_id, thanh_phan_id),
    FOREIGN KEY (ho_so_id)      REFERENCES ho_so_cua_toi(id) ON DELETE CASCADE,
    FOREIGN KEY (thanh_phan_id) REFERENCES thanh_phan_ho_so(id) ON DELETE CASCADE
);

CREATE TABLE hoi_thoai (
    id             CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    nguoi_dung_id  CHAR(36) NULL,
    thu_tuc_id     INT NULL,                               -- cuộc trò chuyện mở từ nút "Hỏi về thủ tục này"
    tieu_de        VARCHAR(500),
    tao_luc        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    cap_nhat_luc   TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,  -- ứng dụng cập nhật mỗi khi có tin nhắn mới
    KEY idx_ht_nd (nguoi_dung_id, cap_nhat_luc),
    FOREIGN KEY (nguoi_dung_id) REFERENCES nguoi_dung(id) ON DELETE CASCADE,
    FOREIGN KEY (thu_tuc_id)    REFERENCES thu_tuc(id)    ON DELETE SET NULL
);

CREATE TABLE tin_nhan (
    id                   BIGINT AUTO_INCREMENT PRIMARY KEY,
    hoi_thoai_id         CHAR(36) NOT NULL,
    vai_tro              ENUM('user','assistant','tool') NOT NULL,
    noi_dung             MEDIUMTEXT,
    y_dinh               VARCHAR(100),
    tham_so              JSON NULL,                        -- vd trường hợp người dùng đã chọn, giấy tờ đang hỏi giải thích
    tool_calls           JSON NULL,
    nguon_trich_dan      JSON NULL,                        -- mảng ma_thu_tuc đã đưa vào ngữ cảnh, vd ["1.001234","2.000567"]; bấm nguồn / "Xem đầy đủ" mở trang chi tiết
    -- Theo dõi chất lượng trả lời (khớp trường how, top_score, latency_ms của AI service)
    trang_thai_tra_loi   ENUM('answered','gate','model','guard') NULL,
    diem_top1            DOUBLE NULL,
    do_tre_ms            INT NULL,
    model_phien_ban      VARCHAR(50) NULL,
    tao_luc              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    KEY idx_tn_ht (hoi_thoai_id, tao_luc),
    KEY idx_tn_trang_thai (trang_thai_tra_loi),
    FOREIGN KEY (hoi_thoai_id) REFERENCES hoi_thoai(id) ON DELETE CASCADE
);

-- Đánh giá câu trả lời: Hữu ích (TRUE) / Chưa đúng (FALSE). Mỗi tin nhắn một đánh giá, người dùng đổi ý thì ghi đè.
CREATE TABLE phan_hoi (
    id           BIGINT AUTO_INCREMENT PRIMARY KEY,
    tin_nhan_id  BIGINT NOT NULL,
    huu_ich      BOOLEAN NOT NULL,
    ghi_chu      TEXT,
    tao_luc      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_ph_tin_nhan (tin_nhan_id),
    FOREIGN KEY (tin_nhan_id) REFERENCES tin_nhan(id) ON DELETE CASCADE
);

-- Cài đặt: "Gửi góp ý, báo lỗi"; Tìm nơi tiếp nhận: "Báo thông tin địa chỉ không đúng" (loai = 'sai_dia_chi', kèm co_quan_id).
-- Người dùng xóa tài khoản thì nguoi_dung_id về NULL (ẩn danh hóa), báo cáo vẫn giữ lại để quản trị viên xử lý.
CREATE TABLE gop_y (
    id             BIGINT AUTO_INCREMENT PRIMARY KEY,
    nguoi_dung_id  CHAR(36) NULL,
    loai           ENUM('gop_y','bao_loi','sai_dia_chi') NOT NULL,
    co_quan_id     INT NULL,
    thu_tuc_id     INT NULL,
    noi_dung       TEXT NOT NULL,
    trang_thai     ENUM('moi','dang_xu_ly','da_xu_ly') NOT NULL DEFAULT 'moi',
    tao_luc        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    KEY idx_gy_loai (loai, trang_thai),
    FOREIGN KEY (nguoi_dung_id) REFERENCES nguoi_dung(id) ON DELETE SET NULL,
    FOREIGN KEY (co_quan_id)    REFERENCES co_quan(id)    ON DELETE SET NULL,
    FOREIGN KEY (thu_tuc_id)    REFERENCES thu_tuc(id)    ON DELETE SET NULL
);

-- =====================================================================
-- E. QUẢN TRỊ DỮ LIỆU
-- =====================================================================

CREATE TABLE quan_tri_vien (
    id             INT AUTO_INCREMENT PRIMARY KEY,
    email          VARCHAR(255) NOT NULL UNIQUE,
    ten_hien_thi   VARCHAR(255),
    mat_khau_hash  VARCHAR(255) NOT NULL,                  -- băm bằng bcrypt/argon2 ở ứng dụng, không lưu mật khẩu thô
    vai_tro        ENUM('admin','bien_tap') NOT NULL DEFAULT 'bien_tap',
    hoat_dong      BOOLEAN NOT NULL DEFAULT TRUE,
    tao_luc        TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Mọi thao tác thêm/sửa/xóa dữ liệu thủ tục đều ghi một dòng, có bản trước và sau để hoàn tác
CREATE TABLE nhat_ky_thay_doi (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    quan_tri_id     INT NULL,
    bang            VARCHAR(64) NOT NULL,
    ban_ghi_id      VARCHAR(64) NOT NULL,
    hanh_dong       ENUM('tao','sua','xoa') NOT NULL,
    du_lieu_truoc   JSON NULL,
    du_lieu_sau     JSON NULL,
    tao_luc         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    KEY idx_nk_bang (bang, ban_ghi_id),
    FOREIGN KEY (quan_tri_id) REFERENCES quan_tri_vien(id) ON DELETE SET NULL
);
