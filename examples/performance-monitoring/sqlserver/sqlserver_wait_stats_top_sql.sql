-- ============================================================================
-- SQL Server — Wait Stats & Top Query (generic, no real data)
-- ============================================================================
-- Tujuan    : Analisis bottleneck & query termahal untuk docs/07-PERFORMANCE-TUNING.md
--             (metodologi wait-based tuning). Read-only, aman di production.
-- ============================================================================
SET NOCOUNT ON;

-- ----------------------------------------------------------------------------
-- 1. WAIT STATS TOP 15 SEJAK RESTART — indikator sumber bottleneck
-- ----------------------------------------------------------------------------
SELECT TOP 15
    wait_type,
    wait_time_ms / 1000.0                                AS wait_sec,
    waiting_tasks_count,
    wait_time_ms / NULLIF(waiting_tasks_count,0) / 1000.0 AS avg_wait_ms
FROM sys.dm_os_wait_stats
WHERE wait_type NOT IN (
    N'BROKER_EVENTHANDLER', N'BROKER_RECEIVE_WAITFOR', N'BROKER_TASK_STOP',
    N'DIRTY_PAGE_POLL', N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
    N'LAZYWRITER_SLEEP', N'LOGMGR_QUEUE', N'XE_TIMER_EVENT',
    N'SLEEP_TASK', N'SLEEP_SYSTEMTASK', N'WAITFOR')
  AND wait_time_ms > 0
ORDER BY wait_time_ms DESC;

-- Interpretasi umum:
--   PAGEIOLATCH_XX   -> storage I/O (data tidak di cache)
--   WRITELOG         -> log I/O / transaction log ketat
--   LCK_M_XX         -> blocking/lock
--   CXPACKET / CXCONSUMER -> parallelism (sering miring ke query)
--   RESOURCE_SEMAPHORE    -> memori query grant terbatas

-- ----------------------------------------------------------------------------
-- 2. TOP QUERY VIA DMV (runtime pool) — CPU/duration terbesar
-- ----------------------------------------------------------------------------
SELECT TOP 20
    qs.execution_count,
    qs.total_worker_time / 1000000.0 AS total_cpu_sec,
    qs.total_elapsed_time / 1000000.0 AS total_duration_sec,
    qs.total_logical_reads,
    SUBSTRING(st.text, (qs.statement_start_offset/2)+1,
        ((CASE qs.statement_end_offset WHEN -1
              THEN DATALENGTH(st.text)
              ELSE qs.statement_end_offset END
          - qs.statement_start_offset)/2)+1) AS statement_text,
    DB_NAME(st.dbid) AS db
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
ORDER BY qs.total_worker_time DESC;

-- ----------------------------------------------------------------------------
-- 3. QUERY STORE (jika aktif) — regresi durasi antar periode (SOP berkala)
-- ----------------------------------------------------------------------------
SELECT TOP 10
    qt.query_sql_text,
    MIN(rs.avg_duration)/1000.0   AS min_avg_ms,
    MAX(rs.avg_duration)/1000.0   AS max_avg_ms,
    MAX(rs.avg_duration) > MIN(rs.avg_duration) * 2 AS regressed_flag
FROM sys.query_store_query_text qt
JOIN sys.query_store_query q  ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_plan p   ON p.query_id       = q.query_id
JOIN sys.query_store_runtime_stats rs ON rs.plan_id = p.plan_id
GROUP BY qt.query_sql_text
ORDER BY regressed_flag DESC;   -- query yang degradasinya paling mencurigakan

-- ----------------------------------------------------------------------------
-- 4. MISSING INDEX CANDIDATES (rekomendasi, review sebelum implementasi)
-- ----------------------------------------------------------------------------
SELECT TOP 10
    d.statement AS table_name,
    d.equality_columns,
    d.inequality_columns,
    d.included_columns,
    s.user_seeks, s.user_scans, s.avg_user_impact
FROM sys.dm_db_missing_index_details d
JOIN sys.dm_db_missing_index_groups g ON d.index_handle = g.index_handle
JOIN sys.dm_db_missing_index_group_stats s ON g.group_handle = s.group_handle
WHERE d.database_id = DB_ID()
ORDER BY (s.user_seeks + s.user_scans) * s.avg_user_impact DESC;

-- ----------------------------------------------------------------------------
-- 5. BLOCKING — chain aktif (docs/07 §2d)
-- ----------------------------------------------------------------------------
SELECT blocking.session_id AS blocking_spid,
       blocked.session_id  AS blocked_spid,
       blocked.wait_type, blocked.wait_time,
       LEFT(blocked.text, 200) AS blocked_text
FROM sys.dm_exec_requests blocked
JOIN sys.dm_exec_requests blocking ON blocking.session_id = blocked.blocking_session_id
CROSS APPLY sys.dm_exec_sql_text(blocked.sql_handle) blocked_text
WHERE blocked.blocking_session_id <> 0;