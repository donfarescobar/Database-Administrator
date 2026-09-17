-- ============================================================================
-- SQL Server — Always On: Failover Test & Health Monitoring
-- ============================================================================
-- Tujuan    : Uji failover terjadwal (docs/06 §4a) + pemeriksaan kesehatan AG
--             sebagai bagian DR drill (docs/09 SOP 3).
-- Skenario  : (1) health check AG/DB replica   (2) planned failover
--             (3) validasi pasca-failover       (4) failback
-- Catatan   : Jalankan dari SQLCMD/SSMS dengan hak ALTER AVAILABILITY GROUP.
-- ============================================================================
SET NOCOUNT ON;

-- ----------------------------------------------------------------------------
-- 1. HEALTH CHECK — status replika & database (read-only, aman)
-- ----------------------------------------------------------------------------
SELECT
    ag.name                                    AS ag_name,
    ar.replica_server_name,
    ars.role_desc                              AS role,
    ar.availability_mode_desc                  AS sync_mode,
    ar.failover_mode_desc                      AS failover_mode,
    ars.connected_state_desc,
    ars.synchronization_health_desc
FROM sys.availability_groups ag
JOIN sys.availability_replicas ar ON ar.group_id = ag.group_id
JOIN sys.dm_hadr_availability_replica_states ars
     ON ars.replica_id = ar.replica_id;

SELECT
    DB_NAME(drs.database_id) AS database_name,
    drs.synchronization_state_desc,
    drs.synchronization_health_desc,
    drs.log_send_queue_size         AS log_send_queue_kb,
    drs.redo_queue_size             AS redo_queue_kb,
    drs.last_commit_time
FROM sys.dm_hadr_database_replica_states drs
ORDER BY database_name, drs.last_commit_time DESC;

-- Interpretasi: redone_queue + log_send_queue mendekati 0 = replikasi sehat.
-- last_commit_time antar replica dekat = latency bagus.

-- ----------------------------------------------------------------------------
-- 2. PLANNED FAILOVER (ujian kuartalan di luar jam sibuk, docs/06 §4a)
--    Catatan: hanya replicas dengan FAILOVER_MODE = AUTOMATIC dapat
--    menerima FAILOVER tanpa data loss (SYNCHRONOUS_COMMIT).
-- ----------------------------------------------------------------------------
ALTER AVAILABILITY GROUP [AG-AppDB] FAILOVER;
-- (Tanpa target -> failover ke replica sinkron otomatis terbaik)

-- Sasaran eksplisit (bila perlu):
-- ALTER AVAILABILITY GROUP [AG-AppDB] FAILOVER TO N'SQLNODE2';

-- ----------------------------------------------------------------------------
-- 3. VALIDASI setelah failover (docs/09 SOP 3 langkah 5–6)
-- ----------------------------------------------------------------------------
-- Cek role primary saat ini & konektivitas listener:
SELECT role_desc, replica_server_name
FROM sys.dm_hadr_availability_replica_states ars
JOIN sys.availability_replicas ar ON ar.replica_id = ars.replica_id
WHERE ars.role_desc = 'PRIMARY';

-- Uji koneksi & transaksi test dari aplikasi yang sama (bukan hanya SELECT)

-- ----------------------------------------------------------------------------
-- 4. FAILBACK (kembalikan peran ke node sediakala bila kebijakan meminta)
-- ----------------------------------------------------------------------------
-- ALTER AVAILABILITY GROUP [AG-AppDB] FAILOVER TO N'SQLNODE1';

-- ----------------------------------------------------------------------------
-- 5. Dokumentasi hasil failover test (audit DR drill)
-- ----------------------------------------------------------------------------
INSERT INTO DBA.dbo.failover_test_log
    (ag_name, executed_at, tested_by, primary_before, primary_after,
     rto_reached_sec, result)
VALUES
    (N'AG-AppDB', SYSUTCDATETIME(), SUSER_SNAME(), N'SQLNODE1', N'SQLNODE2',
     <durasi_detik>, N'PASS');