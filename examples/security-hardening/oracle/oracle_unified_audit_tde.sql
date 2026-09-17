-- ============================================================================
-- Oracle — Unified Auditing & TDE (generic, no real data)
-- ============================================================================
-- Tujuan    : Aktivasi Unified Auditing + TDE tablespace sesuai
--             docs/05-SECURITY-COMPLIANCE.md (audit trail & encryption at-rest).
-- Cara pakai : jalankan sebagai user dengan privilege AUDIT_ADMIN / ALTER SYSTEM
--              (umumnya SYS). Contoh objek fiktif (CUST_ACCOUNT).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Unified Auditing — audity aktivitas kritikal
-- ----------------------------------------------------------------------------
-- Audit DDL & DML pada tabel finansial + eksekusi procedure
CREATE AUDIT POLICY dba_financial_mgmt
    ACTIONS CREATE ANY TABLE, DROP ANY TABLE, ALTER ANY TABLE,
           UPDATE ANY TABLE, DELETE ANY TABLE,
           EXECUTE ANY PROCEDURE
    ROLES DBA, RESOURCE;   -- audit saat sesi memakai role DBA/RESOURCE

-- Audit logon (mendukung deteksi brute force / failed login)
CREATE AUDIT POLICY dba_logon_fail
    ACTIONS LOGON;

AUDIT POLICY dba_financial_mgmt;
AUDIT POLICY dba_logon_fail;

-- Bukti audit trail (query setelah 24 jam): unified_audit_trail

-- ----------------------------------------------------------------------------
-- 2. Enkripsi At-Rest — TDE tablespace untuk data nasabah
-- ----------------------------------------------------------------------------
-- Prasyarat: master encryption key (wallet/OKV) dikonfigurasi oleh tim security
--   (contoh: ADMINISTER KEY MANAGEMENT CREATE KEYSTORE ...). Lihat kebijakan KMS org.

CREATE TABLESPACE tbs_cust_secret
    DATAFILE '/u01/app/oracle/oradata/DEMO/tbs_cust_secret01.dbf'
    SIZE 512M AUTOEXTEND ON NEXT 128M MAXSIZE 8G;
ALTER TABLESPACE tbs_cust_secret ENCRYPTION ONLINE USING 'AES256';

-- Pindahkan tabel sensitif ke tablespace terenkripsi
ALTER TABLE CUST_ACCOUNT MOVE TABLESPACE tbs_cust_secret;

-- Verifikasi status enkripsi
SELECT tablespace_name, encrypted
FROM   dba_tablespaces
WHERE  tablespace_name = 'TBS_CUST_SECRET';

-- ----------------------------------------------------------------------------
-- 3. Kontrol akses dasar — lock akun nonaktif & default
-- ----------------------------------------------------------------------------
ALTER USER SCOTT ACCOUNT LOCK;
ALTER USER HR    ACCOUNT LOCK;
SELECT username, account_status FROM dba_users ORDER BY username;

-- ----------------------------------------------------------------------------
-- 4. Data Redaction — mask kolom sensitif untuk role non-privileged
--    Referensi lengkap RBAC / Database Vault: oracle_rbac_redaction.sql
-- ----------------------------------------------------------------------------
BEGIN
    DBMS_REDACT.ADD_POLICY(
        object_schema  => 'APP',
        object_name    => 'CUST_ACCOUNT',
        policy_name    => 'redact_account_no',
        column_name    => 'ACCOUNT_NUMBER',
        function_type  => DBMS_REDACT.FULL
    );
END;
/
-- Efek: user tanpa privilege redaction melihat kolom ACCOUNT_NUMBER diblokir
-- (CHAR/VARCHAR -> menjadi NULL/spasi; NUMBER -> 0).