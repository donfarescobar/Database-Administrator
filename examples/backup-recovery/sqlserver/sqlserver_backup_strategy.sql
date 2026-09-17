-- ============================================================================
-- SQL Server — Backup Strategy (Full / Differential / Log) + Verify
-- ============================================================================
-- Tujuan    : Pola backup untuk database dalam FULL recovery model dengan
--             CHECKSUM, COMPRESSION, dan verifikasi otomatis (docs/06 §2,
--             docs/09 SOP 2). Jalankan via SQL Agent (lihat
--             examples/scheduling/sqlserver/sql_agent_jobs.sql).
-- Catatan   : Parameter @backup_dir @db_name sesuaikan dengan standar internal.
-- ============================================================================

SET NOCOUNT ON;

DECLARE @db_name    SYSNAME  = N'AppDB';              -- ganti sesuai database
DECLARE @backup_dir NVARCHAR(500) = N'E:\Backup\';    -- ganti sesuai path internal
DECLARE @stamp      NVARCHAR(40) = REPLACE(REPLACE(CONVERT(VARCHAR(27), SYSUTCDATETIME(), 121), ' ', '_'), ':', '');
DECLARE @full_file  NVARCHAR(1000) = @backup_dir + @db_name + N'_FULL_' + @stamp + N'.bak';
DECLARE @diff_file  NVARCHAR(1000) = @backup_dir + @db_name + N'_DIFF_' + @stamp + N'.bak';
DECLARE @log_file   NVARCHAR(1000) = @backup_dir + @db_name + N'_LOG_' + @stamp + N'.trn';

-- ----------------------------------------------------------------------------
-- 1. FULL BACKUP (harian, off-peak) — WITH CHECKSUM + COMPRESSION
-- ----------------------------------------------------------------------------
BACKUP DATABASE  @db_name TO DISK = @full_file
WITH CHECKSUM, COMPRESSION, INIT, MAXTRANSFERSIZE = 1048576, STATS = 10;

-- ----------------------------------------------------------------------------
-- 2. DIFFERENTIAL BACKUP (setiap 4–6 jam) — perubahaan sejak full terakhir
-- ----------------------------------------------------------------------------
-- BACKUP DATABASE @db_name TO DISK = @diff_file
-- WITH CHECKSUM, COMPRESSION, DIFFERENTIAL, INIT, STATS = 10;

-- ----------------------------------------------------------------------------
-- 3. LOG BACKUP (setiap 15 menit) — mendukung Point-in-Time Recovery
-- ----------------------------------------------------------------------------
-- BACKUP LOG @db_name TO DISK = @log_file
-- WITH CHECKSUM, COMPRESSION, INIT, STATS = 10;

-- ----------------------------------------------------------------------------
-- 4. VERIFIKASI backup (langkah wajib setiap kali backup, docs/09 SOP 2)
--    - RESTORE VERIFYONLY : memvalidasi header + integritas backup
--    - WITH CHECKSUM      : validasi checksum (harus backup dibuat dgn CHECKSUM)
-- ----------------------------------------------------------------------------
RESTORE VERIFYONLY FROM DISK = @full_file WITH CHECKSUM;
PRINT N'Verify OK: ' + @full_file;

-- ----------------------------------------------------------------------------
-- 5. Logging ke tabel audit backup internal (untuk dashboard & RCA)
-- ----------------------------------------------------------------------------
INSERT INTO DBA.dbo.backup_audit_log (database_name, backup_type, file_path, finished_at, duration_sec)
VALUES (@db_name, N'FULL', @full_file, SYSUTCDATETIME(),
        DATEDIFF(SECOND, SYSUTCDATETIME(), SYSUTCDATETIME()));  -- ganti dengan durasi aktual dari msdb