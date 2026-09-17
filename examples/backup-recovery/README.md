# Backup & Recovery — Contoh Artefak

Bukti kompetensi **backup-ability**: strategi full/incremental/log, verifikasi, dan restore drill yang bisa dipulihkan dalam target RTO — melengkapi [docs/06-OPERATIONS-DR-BACKUP.md](../../docs/06-OPERATIONS-DR-BACKUP.md) dan [docs/09 SOP 2](../../docs/09-RUNBOOKS-SOP.md).

| Path | Engine | Isi |
|---|---|---|
| [`oracle/rman_backup_strategy.sql`](./oracle/rman_backup_strategy.sql) | Oracle RMAN | Level 0/1 incremental + archivelog, retention window, spfile/controlfile |
| [`oracle/rman_validate_crosscheck.sql`](./oracle/rman_validate_crosscheck.sql) | Oracle RMAN | Crosscheck, `RESTORE VALIDATE`, restore drill, PITR |
| [`sqlserver/sqlserver_backup_strategy.sql`](./sqlserver/sqlserver_backup_strategy.sql) | SQL Server | Full/diff/log `WITH CHECKSUM, COMPRESSION` + `RESTORE VERIFYONLY` |
| [`sqlserver/sqlserver_restore_drill.sql`](./sqlserver/sqlserver_restore_drill.sql) | SQL Server | Restore `MOVE` ke env test, `DBCC CHECKDB`, spot-check, PITR |
| [`postgresql/pg_dump_backup.sh`](./postgresql/pg_dump_backup.sh) | PostgreSQL | Wrapper `pg_dump` + log terstruktur + notifikasi + retensi (3-2-1) |
| [`postgresql/pg_backup.service`](./postgresql/pg_backup.service) + [`pg_backup.timer`](./postgresql/pg_backup.timer) | PostgreSQL systemd | Alternatif cron modern: `OnCalendar`, `Persistent`, logging journald |

## Poin yang Ditonjolkan

- **Verifikasi wajib**: setiap contoh marketing-nya adalah `VERIFYONLY`/`VALIDATE` + restore drill terjadwal — bukan sekadar "backup jalan".
- **Retensi eksplisit** sesuai kebijakan (recovery window, offsite immutable).
- Prinsip **3-2-1** (docs/06 §2b) menjadi kerangka setiap strategi.

> Referensi jadwal eksekusi: [`../scheduling/`](../scheduling/).