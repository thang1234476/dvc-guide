-- Run once against the existing dvc_guide database before restarting Spring Boot.
-- CREATE TABLE IF NOT EXISTS preserves existing procedure and account data.
CREATE TABLE IF NOT EXISTS procedure_source (
    procedure_id INT NOT NULL PRIMARY KEY,
    payload JSON NOT NULL,
    CONSTRAINT fk_source_procedure FOREIGN KEY (procedure_id) REFERENCES thu_tuc(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS rag_sync_job (
    procedure_id INT NOT NULL PRIMARY KEY,
    desired_version INT NOT NULL,
    indexed_version INT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    attempts INT NOT NULL DEFAULT 0,
    chunk_count INT NOT NULL DEFAULT 0,
    next_attempt_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    lease_until TIMESTAMP(6) NULL,
    last_error VARCHAR(500) NULL,
    indexed_at TIMESTAMP(6) NULL,
    KEY idx_rag_sync_due (status, next_attempt_at)
);

CREATE TABLE IF NOT EXISTS document_form (
    document_id INT NOT NULL,
    form_id INT NOT NULL,
    sort_order INT NOT NULL,
    PRIMARY KEY (document_id, form_id),
    CONSTRAINT fk_document_form_document FOREIGN KEY (document_id) REFERENCES thanh_phan_ho_so(id) ON DELETE CASCADE,
    CONSTRAINT fk_document_form_form FOREIGN KEY (form_id) REFERENCES bieu_mau(id)
);
ALTER TABLE thanh_phan_ho_so MODIFY COLUMN ten_giay_to TEXT NOT NULL;
ALTER TABLE le_phi MODIFY COLUMN tien_te VARCHAR(50) NULL;
