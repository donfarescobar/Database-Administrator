-- ============================================================================
-- Flyway V2 — Add transaction index (generic, no real data)
-- ============================================================================
-- Tujuan : Perbaikan performa dari review (docs/07 §2b): index untuk pola
--          query yang paling sering dijalankan (status + created_at).
-- Aturan : Jangan edit V1; perubahan baru = file migrasi baru.
-- ============================================================================

CREATE INDEX idx_trx_status_created     ON app.transaction (status, created_at);
CREATE INDEX idx_trx_customer_created   ON app.transaction (customer_id, created_at);

-- Statistik optimizer diperbarui (contoh PostgreSQL)
ANALYZE app.transaction;