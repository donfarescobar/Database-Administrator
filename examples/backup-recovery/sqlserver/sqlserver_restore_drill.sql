-- ============================================================================
-- SQL Server — Restore Drill & Verify (generic, no real data)
-- ============================================================================
-- Tujuan    : Prosedur restore test terjadwal ke environment terisolasi untuk
--             membuktikan backup dapat dipulihkan (docs/06 §2c, docs/09 SOP 2).
-- Skenario  : a) Restore penuh + DBCC CHECKDB   b) Point-in-Time recovery
-- Catatan   : Jalankan di instance RESTORE (test) — JANGAN di production.
--             Ukur durasi restore & catat hasilnya pada log restore test.
-- ============================================================================

SET NOCOUNT ON;
DECLARE @src_file   NVARCHAR(1000) = N'E:\Backup\AppDB_FULL_20260831_020000.bak';  -- ganti
DECLARE @target_db  SYSNAME = N'AppDB_Verify';

---- ---------------------------------------------------------------------------
---- 1. Dapatkan lokasi file logis di dalam backup (untuk MOVE)
---- ---------------------------------------------------------------------------
-- RESTORE FILELISTONLY FROM DISK = @src_file;   -- hasil: LogicalName & PhysicalName

---- ---------------------------------------------------------------------------
---- 2. RESTORE penuh ke database baru dengan MOVE (proteksi production)
---- ---------------------------------------------------------------------------
IF DB_ID(@target_db) IS NOT NULL
BEGIN
    ALTER DATABASE [@target_db] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [@target_db];
END
GO
RESTORE DATABASE [AppDB_Verify]
FROM DISK = N'E:\Backup\AppDB_FULL_20260831_020000.bak'
WITH
    MOVE N'AppDB_Data'  TO N'F:\RestoreDrill\AppDB_Verify.mdf',
    MOVE N'AppDB_Log'   TO N'F:\RestoreDrill\AppDB_Verify_Log.ldf',
    REPLACE,
    RECOVERY,                -- database siap dibuka
    STATS = 10;

---- ---------------------------------------------------------------------------
---- 3. Validasi integritas fisik & logis setelah restore
---- ---------------------------------------------------------------------------
DBCC CHECKDB (AppDB_Verify) WITH NO_INFOMSGS, ALL_ERRORMSGS;

-- Spot-check data kritikal (ganti dengan query tabel kontrol internal)
SELECT COUNT(*) AS order_count FROM AppDB_Verify.dbo.orders;
SELECT MAX(updated_at) AS latest_update FROM AppDB_Verify.dbo.orders;

---- ---------------------------------------------------------------------------
---- 4. Point-in-Time Recovery (contoh restore log + STOPAT)
---- ---------------------------------------------------------------------------
-- Urutan: restore full WITH NORECOVERY -> restore terakhir log diff/lot ->
-- restore log target WITH STOPAT.
-- RESTORE DATABASE [AppDB_Verify]
--     FROM DISK = N'E:\Backup\AppDB_FULL_...bak'  WITH NORECOVERY, REPLACE;
-- RESTORE LOG [AppDB_Verify]
--     FROM DISK = N'E:\Backup\AppDB_LOG_...trn'
--     WITH STOPAT = N'2026-08-31T13:45:00', RECOVERY;
---- Penjelasan: file LOG terakhir yang memuat momen STOPAT. Jalankan
---- RECOVERY = DEFERRED (-->parameter ARO) jika STOPAT bukan ujung terakhir log.

---- ---------------------------------------------------------------------------
---- 5. Dokumentasi hasil restore test (wajib untuk audit / kualitas backup)
---- ---------------------------------------------------------------------------
-- INSERT INTO DBA.dbo.restore_test_log
--     (database_name, source_backup, started_at, finished_at, duration_sec,
--      checkdb_status, spot_check_status)
-- VALUES
--     (N'AppDB_Verify', @src_file, <start>, SYSUTCDATETIME(),
--      DATEDIFF(SECOND, <start>, SYSUTCDATETIME()),
--      N'PASS', N'PASS');