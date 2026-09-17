-- ============================================================================
-- SQL Server — Server Audit, TDE & Dynamic Data Masking (generic, no real data)
-- ============================================================================
-- Tujuan    : Menerapkan tiga kontrol inti docs/05 §2: audit trail, enkripsi
--             at-rest (TDE), dan masking untuk role non-privileged.
-- Cara pakai : jalankan sebagai user dengan ALTER ANY SERVER AUDIT / CONTROL.
--              Contoh objek fiktif: AppDB.Customer (kolom CardNumber).
-- ============================================================================
SET NOCOUNT ON;

-- ----------------------------------------------------------------------------
-- 1. SERVER AUDIT (ke file, bisa juga ke Security Log / Azure Blob)
-- ----------------------------------------------------------------------------
CREATE SERVER AUDIT [DBA_ServerAudit]
   TO FILE
   (
      FILEPATH      = N'D:\SQLAudit\',
      MAX_FILES     = 20,
      MAX_FILE_SIZE = 256 MB,
      RESERVE_DISK_SPACE = OFF
   )
   WITH
   (
      QUEUE_DELAY        = 1000,      -- 1 detik delay sebelum tulis
      ON_FAILURE         = CONTINUE,  -- jangan blok transaksi bila audit gagal
      AUDIT_GUID         = NULL
   );
ALTER SERVER AUDIT [DBA_ServerAudit] WITH (STATE = ON);

-- Database Audit Specification — tangkap DDL dan akses data sensitif
CREATE DATABASE AUDIT SPECIFICATION [DBA_DbAudit]
   FOR SERVER AUDIT [DBA_ServerAudit]
   ADD (SCHEMA_OBJECT_CHANGE_GROUP),
   ADD (SELECT ON OBJECT::AppDB.dbo.Customer BY public),
   ADD (UPDATE ON OBJECT::AppDB.dbo.Customer BY public);
ALTER DATABASE AUDIT SPECIFICATION [DBA_DbAudit] WITH (STATE = ON);

-- Verifikasi hasil audit:
-- SELECT * FROM sys.fn_get_audit_file('D:\SQLAudit\*.sqlaudit', DEFAULT, DEFAULT);

-- ----------------------------------------------------------------------------
-- 2. TDE — enkripsi at-rest untuk database berisi data nasabah
-- ----------------------------------------------------------------------------
USE master;
CREATE MASTER KEY ENCRYPTION BY PASSWORD = '<from-vault>';   -- master key instance
CREATE CERTIFICATE TDE_Cert WITH SUBJECT = 'TDE Certificate for AppDB';
GO

USE AppDB;
CREATE DATABASE ENCRYPTION KEY
   WITH ALGORITHM = AES_256
   ENCRYPTION BY SERVER CERTIFICATE TDE_Cert;
GO
-- Backup sertifikat + private key wajib di simpan di tempat aman
--   BACKUP CERTIFICATE TDE_Cert TO FILE = 'D:\certs\TDE_Cert.cer'
--      WITH PRIVATE KEY (FILE='D:\certs\TDE_Cert_key.pvk', ENCRYPTION BY PASSWORD='...');

ALTER DATABASE AppDB SET ENCRYPTION ON;
GO
-- Monitor: SELECT db_name(database_id) db, encryption_state FROM sys.dm_database_encryption_keys;
-- (encryption_state = 3 -> encrypted)

-- ----------------------------------------------------------------------------
-- 3. DYNAMIC DATA MASKING — tipe kolom sensitif untuk role support
-- ----------------------------------------------------------------------------
USE AppDB;
ALTER TABLE dbo.Customer
   ALTER COLUMN CardNumber ADD MASKED WITH (FUNCTION = 'partial(0,"XXXX-XXXX-XXXX-",4)');
ALTER TABLE dbo.Customer
   ALTER COLUMN Email       ADD MASKED WITH (FUNCTION = 'email()');

-- Aplikasikan untuk user tertentu
GRANT UNMASK TO [DOMAIN\dba_privileged];   -- role yang berhak melihat data asli
-- User yang TIDAK memiliki UNMASK otomatis melihat nilai ter-mask saat SELECT.

-- ============================================================================
-- Referensi RBAC & least privilege lebih lengkap: sqlserver_rbac_least_privilege.sql