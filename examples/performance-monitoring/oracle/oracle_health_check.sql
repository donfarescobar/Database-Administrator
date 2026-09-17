-- ============================================================================
-- Oracle Daily Health Check (generik, tanpa data sensitif)
-- Tujuan   : ringkasan kesehatan instance untuk SOP harian (docs/09-RUNBOOKS-SOP.md)
-- Penggunaan : jalankan sebagai user dengan akses view v$*/dba* (read-only).
--              Untuk analisis mendalam gunakan AWR/ASH (docs/07 §3).
-- Catatan  : read-only. Tidak mengubah konfigurasi apa pun.
-- ============================================================================

PROMPT === INSTANCE INFO ===
SELECT instance_name, host_name, version, status, startup_time
FROM   v$instance;

PROMPT === DATABASE STATUS ===
SELECT name, open_mode, log_mode, flashback_on
FROM   v$database;

PROMPT === TABLESPACE USAGE (>80% = perhatian) ===
SELECT df.tablespace_name,
       ROUND(df.total_mb)                                   AS total_mb,
       ROUND(NVL(du.used_mb, 0))                            AS used_mb,
       ROUND((NVL(du.used_mb, 0) / df.total_mb) * 100, 1)   AS used_pct
FROM   (SELECT tablespace_name, SUM(bytes)/1024/1024 AS total_mb
        FROM dba_data_files GROUP BY tablespace_name) df
LEFT JOIN
       (SELECT tablespace_name, SUM(bytes)/1024/1024 AS used_mb
        FROM dba_segments GROUP BY tablespace_name) du
  ON   du.tablespace_name = df.tablespace_name
WHERE  (NVL(du.used_mb, 0) / df.total_mb) * 100 > 80
ORDER BY used_pct DESC;

PROMPT === ARCHIVELOG SPACE & SWITCH FREQUENCY ===
SELECT TRUNC(first_time) AS day, COUNT(*) AS log_switches
FROM   v$archived_log
WHERE  first_time > SYSDATE - 7
GROUP BY TRUNC(first_time)
ORDER BY day;

PROMPT === DATA GUARD STATUS (jika terpasang) ===
SELECT database_role, open_mode, db_unique_name, switchover_status
FROM   v$database;
SELECT process, status, thread#, sequence#, block#
FROM   v$managed_standby
WHERE  process IN ('MRP0', 'RFS');

PROMPT === TOP SQL BY ELAPSED TIME (buffer cache hit via v$sqlstats) ===
SELECT *
FROM (
    SELECT sql_id,
           executions,
           ROUND(elapsed_time / 1e6, 2) AS elapsed_sec,
           ROUND(elapsed_time / NULLIF(executions, 0) / 1e3, 2) AS ms_per_exec,
           SUBSTR(sql_text, 1, 120) AS sql_text_snippet
    FROM   v$sqlstats
    ORDER BY elapsed_time DESC
)
WHERE ROWNUM <= 10;

PROMPT === INVALID OBJECTS (harusnya tidak ada di production sehat) ===
SELECT owner, object_name, object_type
FROM   dba_objects
WHERE  status = 'INVALID'
ORDER BY owner, object_type;

PROMPT === FAILED LOGIN ATTEMPTS TERAKHIR (butuh unified auditing aktif) ===
-- SELECT event_timestamp, username, return_code
-- FROM   unified_audit_trail
-- WHERE  action_name = 'LOGON' AND return_code <> 0
--   AND  event_timestamp > SYSDATE - 1
-- ORDER BY event_timestamp DESC;
PROMPT Lihat dokumen Security & Compliance untuk konfigurasi unified auditing.

PROMPT === RMAN BACKUP STATUS (24 jam terakhir) ===
SELECT input_type, status, TO_CHAR(start_time, 'YYYY-MM-DD HH24:MI') AS started,
       TO_CHAR(end_time,   'YYYY-MM-DD HH24:MI') AS finished
FROM   v$rman_backup_job_details
WHERE  start_time > SYSDATE - 1
ORDER BY start_time DESC;

EXIT
