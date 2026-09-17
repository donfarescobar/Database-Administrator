-- ============================================================================
-- PostgreSQL — RBAC, Least Privilege & Encryption (generic, no real data)
-- ============================================================================
-- Tujuan    : Pola hak akses minimal (role-based) + enkripsi at-rest (pgcrypto)
--             & in-transit (SSL), sesuai docs/05 §2 dan docs/04 §5.
-- Catatan   : Contoh skema & objek fiktif. Jalankan sebagai superuser (postgres).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Role aplikasi — minimal privilege (bukan superuser)
-- ----------------------------------------------------------------------------
CREATE ROLE app_reader NOLOGIN;
CREATE ROLE app_writer NOLOGIN;

GRANT CONNECT                       ON DATABASE appdb   TO app_reader, app_writer;
GRANT USAGE                         ON SCHEMA sales     TO app_reader, app_writer;
GRANT SELECT                        ON ALL TABLES IN SCHEMA sales TO app_reader;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA sales TO app_writer;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA sales TO app_writer;

-- Default privileges untuk objek tabel baru ke depan (developer-friendly)
ALTER DEFAULT PRIVILEGES IN SCHEMA sales
    GRANT SELECT ON TABLES TO app_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA sales
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_writer;

-- Service account login (password dari vault / berkala dirotate)
CREATE ROLE app_svc LOGIN PASSWORD '<vault-credential>' IN ROLE app_writer;
REVOKE SUPERUSER, CREATEROLE, CREATEDB FROM app_svc;

-- ----------------------------------------------------------------------------
-- 2. Row-Level Security (RLS) — isolasi data per cabang/divisi
-- ----------------------------------------------------------------------------
ALTER TABLE sales.orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY branch_isolation ON sales.orders
    USING   (branch_code = current_setting('app.branch_code'))
    WITH CHECK (branch_code = current_setting('app.branch_code'));

-- Aplikasi memanggil SET app.branch_code (via pooled connection).
-- Superuser/penjamin di-service oleh role dengan BYPASSRLS (hanya DBA).

-- ----------------------------------------------------------------------------
-- 3. Enkripsi At-Rest — column-level untuk data super sensitif (pgcrypto)
-- ----------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS pgcrypto;

ALTER TABLE sales.orders ADD COLUMN cif_encrypted BYTEA;
UPDATE sales.orders SET cif_encrypted = pgp_sym_encrypt(cif, '${PGPASS}', 'compress-algo=1');
-- Akses hanya via view/app layer — kolom plaintext tidak disimpan.
-- Key passed pada session startup (app layer), bukan di DB.

-- ----------------------------------------------------------------------------
-- 4. Enkripsi In-Transit — wajib SSL (referensi pg_hba_hardening.conf)
-- ----------------------------------------------------------------------------
-- Verifikasi SSL aktif:
SELECT name, setting FROM pg_settings WHERE name IN ('ssl', 'ssl_min_protocol_version');

-- Cek koneksi yang menggunakan SSL sekarang:
SELECT usename, client_addr, ssl, version FROM pg_stat_ssl s JOIN pg_stat_activity a
      ON a.pid = s.pid WHERE a.state = 'active';

-- ----------------------------------------------------------------------------
-- 5. Audit — log koneksi & statement lambat (postgresql.conf)
-- ----------------------------------------------------------------------------
--   log_connections = on
--   log_disconnections = on
--   log_min_duration_statement = 1000
--   log_line_prefix = '%m [%p] %q%u@%d from %h '
--   (lengkapi dengan pgaudit untuk audit DDL/DML — contoh di bawah)
-- ============================================================================
-- Contoh pgaudit (extension): 
--   CREATE EXTENSION IF NOT EXISTS pgaudit;
--   ALTER SYSTEM SET pgaudit.log = 'write, ddl';
--   ALTER SYSTEM SET pgaudit.log_relation = 'on';