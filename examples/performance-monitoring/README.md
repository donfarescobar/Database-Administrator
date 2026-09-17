# Performance Tuning & Monitoring — Contoh Artefak

Bukti kompetensi **performance engineering**: health check harian, analisis wait stats, index maintenance, dan deteksi query bermasalah — melengkapi [docs/07-PERFORMANCE-TUNING.md](../../docs/07-PERFORMANCE-TUNING.md) dan [docs/09 SOP 1](../../docs/09-RUNBOOKS-SOP.md).

| Path | Engine | Isi |
|---|---|---|
| [`sqlserver/sqlserver_health_check.sql`](./sqlserver/sqlserver_health_check.sql) | SQL Server | Instance, database status, backup terakhir, AG health, wait stats, disk |
| [`sqlserver/sqlserver_index_maintenance.sql`](./sqlserver/sqlserver_index_maintenance.sql) | SQL Server | Rebuild/reorganize berdasarkan fragmentasi (threshold docs/07 §6) |
| [`sqlserver/sqlserver_wait_stats_top_sql.sql`](./sqlserver/sqlserver_wait_stats_top_sql.sql) | SQL Server | Wait stats top-15, top query via DMV/Query Store, missing index, blocking |
| [`oracle/oracle_health_check.sql`](./oracle/oracle_health_check.sql) | Oracle | Instance, tablespace, archivelog, Data Guard, top SQL (v$sqlstats), invalid objects |
| [`postgresql/postgresql_health_check.sql`](./postgresql/postgresql_health_check.sql) | PostgreSQL | Koneksi & long-running, ukuran DB, cache hit, replikasi lag, bloat/index |

## Poin yang Ditonjolkan

- Semua read-only → aman dijalankan terhadap **production** saat SOP harian.
- Diawali **metodologi top-down** (docs/07 §1): gejala → baseline → bottleneck → perbaikan → verifikasi.
- Wait-based analysis (bukan asal "tune index") menunjukkan pendekatan senior.

> Jadwal eksekusi otomatis: [`../scheduling/`](../scheduling/).