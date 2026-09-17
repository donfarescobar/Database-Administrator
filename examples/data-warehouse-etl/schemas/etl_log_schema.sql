-- ============================================================================
-- DWH — ETL Audit/Log Tables (generic, no real data)
-- ============================================================================
-- Tujuan    : Tabel log batch & log detail yang dipakai oleh contoh ETL
--             (SQL Server SSIS-style, Oracle PL/SQL, Airflow) di folder ini —
--             memenuhi prinsip audit trail & reconciliation (docs/11 §4).
-- Catatan   : PostgreSQL. Bentuk kolom dibuat kompatibel lintas engine.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. ETL_BATCH_LOG — satu baris per batch eksekusi (kontrol & rekonsiliasi)
-- ----------------------------------------------------------------------------
CREATE TABLE dwh.etl_batch_log (
    batch_id        UUID         PRIMARY KEY,
    pipeline_name   VARCHAR(100) NOT NULL,                  -- nama DAG/program
    started_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    finished_at     TIMESTAMP,
    source_rows     BIGINT,
    loaded_rows     BIGINT,
    control_total   NUMERIC(19,2),                          -- sum(amount) dsb.
    status          VARCHAR(15)  NOT NULL DEFAULT 'RUNNING',-- RUNNING/SUCCESS/FAILED
    error_message   TEXT,
    created_by      VARCHAR(100)                            -- scheduler/system
);

-- ----------------------------------------------------------------------------
-- 2. ETL_LOG_DETAIL — log langkah/level di dalam satu batch
-- ----------------------------------------------------------------------------
CREATE TABLE dwh.etl_log_detail (
    log_id      BIGSERIAL    PRIMARY KEY,
    batch_id    UUID         NOT NULL REFERENCES dwh.etl_batch_log (batch_id),
    log_level   VARCHAR(10)  NOT NULL,                      -- INFO/WARN/ERROR
    log_message TEXT         NOT NULL,
    logged_at   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX ix_etl_log_batch ON dwh.etl_log_detail (batch_id, logged_at);

-- ----------------------------------------------------------------------------
-- 3. Quarantine — baris gagal validasi (docs/11 §7, Data Quality Framework)
-- ----------------------------------------------------------------------------
CREATE TABLE dwh.etl_quarantine (
    quarantine_id   BIGSERIAL    PRIMARY KEY,
    batch_id        UUID         NOT NULL,
    source_table    VARCHAR(100) NOT NULL,
    reject_reason   VARCHAR(500) NOT NULL,
    reject_at       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    raw_payload     JSONB                                -- snapshot baris sumber
);
CREATE INDEX ix_etl_quarantine_batch ON dwh.etl_quarantine (batch_id);

-- ----------------------------------------------------------------------------
-- 4. Contoh rekonsiliasi (kontrol wajib — docs/11 §4)
--   SELECT b.source_rows, b.loaded_rows, b.control_total, b.status
--   FROM dwh.etl_batch_log b ORDER BY b.started_at DESC LIMIT 20;
-- ============================================================================