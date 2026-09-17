-- ============================================================================
-- PostgreSQL — Daily Health Check (generic, no real data)
-- ============================================================================
-- Tujuan    : Ringkasan kesehatan instance untuk SOP 1 (docs/09-RUNBOOKS-SOP.md),
--             setara dengan versi SQL Server / Oracle di folder ini.
-- Cara pakai : jalankan sebagai role dengan akses pg_stat_* / pg_current_*.
--              Read-only — tidak mengubah konfigurasi apa pun.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. INSTANCE & VERSI
-- ----------------------------------------------------------------------------
SELECT version();

SELECT name, setting, unit
FROM   pg_settings
WHERE  name IN ('max_connections','shared_buffers','work_mem','wal_level',
                'max_wal_senders','archive_mode','log_min_duration_statement');

-- ----------------------------------------------------------------------------
-- 2. KONEKSI — total vs max, idle/active
-- ----------------------------------------------------------------------------
SELECT count(*)                         AS total_conn,
       sum(CASE WHEN state='idle' THEN 1 ELSE 0 END) AS idle_conn,
       current_setting('max_connections') AS max_conn
FROM   pg_stat_activity;

-- Long-running query (> 5 menit) — calon blocker/monster query
SELECT pid, now() - xact_start AS age, state, wait_event_type, wait_event,
       left(query, 120) AS query_snippet
FROM   pg_stat_activity
WHERE  xact_start IS NOT NULL
  AND  now() - xact_start > interval '5 minutes'
ORDER  BY xact_start;

-- ----------------------------------------------------------------------------
-- 3. DISK / SIZE — per-database & cache hit ratio
-- ----------------------------------------------------------------------------
SELECT datname,
       pg_size_pretty(pg_database_size(datname)) AS db_size
FROM   pg_database
ORDER  BY pg_database_size(datname) DESC;

-- Cache hit ratio (semakin tinggi semakin sedikit reads dari disk)
SELECT sum(heap_blks_read)  AS heap_read,
       sum(heap_blks_hit)   AS heap_hit,
       round(sum(heap_blks_hit) * 100.0
             / NULLIF(sum(heap_blks_hit) + sum(heap_blks_read), 0), 2) AS hit_pct
FROM   pg_statio_user_tables;

-- ----------------------------------------------------------------------------
-- 4. REPLIKASI (jika streaming replication aktif)
-- ----------------------------------------------------------------------------
SELECT client_addr, state, sync_state, sent_lsn, replay_lsn,
       round(extract(epoch FROM now() - pg_last_xact_replay_timestamp())) AS lag_sec
FROM   pg_stat_replication;
-- lag_sec besar = standby tertinggal -> kebutuhan investigasi.

-- ----------------------------------------------------------------------------
-- 5. BACKUP STATUS — recent WAL archive (arsip sukses/gagal)
-- ----------------------------------------------------------------------------
SELECT archived_count, failed_count,
       (SELECT max(archived_time) FROM pg_stat_archiver) AS last_archived
FROM   pg_stat_archiver;

-- ----------------------------------------------------------------------------
-- 6. INDEX USAGE — index yang tidak terpakai (kandidat review, docs/07 §2b)
-- ----------------------------------------------------------------------------
SELECT schemaname, relname AS table_name,
       coalesce((SELECT count(*) FROM pg_index i WHERE i.indrelid = c.oid AND NOT i.indisprimary AND NOT i.indisunique),0) AS index_count,
       seq_scan, idx_scan
FROM   pg_stat_user_tables t
JOIN   pg_class c ON c.oid = t.relid
ORDER  BY seq_scan DESC
LIMIT  20;

-- ----------------------------------------------------------------------------
-- 7. FRAGMENTASI / BLOAT — perlu vacuum (maintenance terjadwal)
-- ----------------------------------------------------------------------------
SELECT schemaname, relname,
       n_live_tup, n_dead_tup,
       round(n_dead_tup * 100.0 / NULLIF(n_live_tup + n_dead_tup, 0), 2) AS dead_pct,
       last_vacuum, last_autovacuum
FROM   pg_stat_user_tables
WHERE  n_dead_tup > 1000
ORDER  BY n_dead_tup DESC
LIMIT  20;