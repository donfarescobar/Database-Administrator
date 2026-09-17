-- ============================================================================
-- SQL Server Daily Health Check (generik, tanpa data sensitif)
-- Tujuan   : ringkasan kesehatan instance untuk SOP harian (docs/09-RUNBOOKS-SOP.md)
-- Penggunaan : jalankan pada instance target; review output manual / via job
--              terjadwal yang mengirim hasil ke tim DBA.
-- Catatan  : read-only. Tidak mengubah konfigurasi apa pun.
-- ============================================================================

SET NOCOUNT ON;

PRINT '=== INSTANCE INFO ===';
SELECT
    SERVERPROPERTY('ServerName')            AS server_name,
    SERVERPROPERTY('ProductVersion')        AS product_version,
    SERVERPROPERTY('ProductLevel')          AS patch_level,
    SERVERPROPERTY('Edition')               AS edition,
    sqlserver_start_time AS last_restart
FROM sys.dm_os_sys_info;

PRINT '=== DATABASE STATUS ===';
SELECT
    name,
    state_desc,
    recovery_model_desc,
    log_reuse_wait_desc,
    compatibility_level
FROM sys.databases
ORDER BY name;

-- Backup terakhir per database (full/diff/log) — sesuai SOP 2
PRINT '=== LAST BACKUP PER DATABASE ===';
SELECT
    d.name AS database_name,
    MAX(CASE WHEN b.type = 'D' THEN b.backup_finish_date END) AS last_full_backup,
    MAX(CASE WHEN b.type = 'I' THEN b.backup_finish_date END) AS last_diff_backup,
    MAX(CASE WHEN b.type = 'L' THEN b.backup_finish_date END) AS last_log_backup
FROM sys.databases d
LEFT JOIN msdb.dbo.backupset b
       ON b.database_name = d.name
      AND b.is_copy_only = 0
WHERE d.database_id <> 2            -- kecualikan tempdb
GROUP BY d.name
ORDER BY d.name;

PRINT '=== ALWAYS ON AVAILABILITY GROUP HEALTH (jika terpasang) ===';
IF EXISTS (SELECT 1 FROM sys.dm_hadr_availability_replica_states)
BEGIN
    SELECT
        ag.name                    AS ag_name,
        ars.role_desc,
        ars.synchronization_health_desc,
        DB_NAME(drs.database_id)   AS database_name,
        drs.log_send_queue_size    AS log_send_queue_kb,
        drs.redo_queue_size        AS redo_queue_kb
    FROM sys.dm_hadr_availability_replica_states ars
    JOIN sys.availability_groups ag ON ag.group_id = ars.group_id
    LEFT JOIN sys.dm_hadr_database_replica_states drs ON drs.replica_id = ars.replica_id;
END
ELSE
    PRINT 'Always On tidak aktif di instance ini.';

PRINT '=== WAIT STATS SEJAK RESTART (TOP 10) ===';
SELECT TOP 10
    wait_type,
    waiting_tasks_count,
    wait_time_ms / 1000.0        AS wait_time_sec,
    max_wait_time_ms
FROM sys.dm_os_wait_stats
WHERE wait_type NOT IN (
    N'BROKER_EVENTHANDLER', N'BROKER_RECEIVE_WAITFOR', N'BROKER_TASK_STOP',
    N'DIRTY_PAGE_POLL', N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
    N'LAZYWRITER_SLEEP', N'LOGMGR_QUEUE', N'XE_TIMER_EVENT',
    N'SLEEP_TASK', N'SLEEP_SYSTEMTASK', N'WAITFOR')
  AND wait_time_ms > 0
ORDER BY wait_time_ms DESC;

PRINT '=== TOP RESOURCE QUERY (dari Query Store, jika aktif) ===';
SELECT TOP 10
    qt.query_sql_text,
    rs.avg_duration / 1000.0 AS avg_duration_ms,
    rs.count_executions
FROM sys.query_store_query_text qt
JOIN sys.query_store_query q  ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_plan p   ON p.query_id = q.query_id
JOIN sys.query_store_runtime_stats rs ON rs.plan_id = p.plan_id
CROSS APPLY (SELECT TOP 1 1) dummy
WHERE 1 = 0;   -- template: ganti dengan filter database & window waktu spesifik saat dipakai

PRINT '=== DISK SPACE DATA/LOG DRIVE ===';
SELECT DISTINCT
    vs.volume_mount_point AS drive,
    CAST(vs.available_bytes / 1024.0 / 1024 / 1024 AS DECIMAL(10,2)) AS free_gb,
    CAST(vs.total_bytes     / 1024.0 / 1024 / 1024 AS DECIMAL(10,2)) AS total_gb
FROM sys.master_files f
CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.file_id) vs;

PRINT '=== FAILED LOGIN 24 JAM TERAKHIR (ringkasan, butuh audit aktif) ===';
-- Sesuaikan nama audit/spec dengan standar hardening internal.
-- Contoh membaca file audit:
-- SELECT event_time, action_id, session_server_principal_name, client_ip
-- FROM sys.fn_get_audit_file('<audit_file_path>*', DEFAULT, DEFAULT)
-- WHERE action_id = 'LGIF' AND event_time > DATEADD(HOUR, -24, SYSUTCDATETIME());
PRINT 'Lihat dokumen Security & Compliance untuk konfigurasi audit.';
