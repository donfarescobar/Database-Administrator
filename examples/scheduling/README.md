# Scheduling & Orchestration — Contoh Artefak

Bukti kompetensi **operational automation**: menjadwalkan backup, health check, dan maintenance lintas platform dengan disiplin (offset waktu, disabled-by-default, logging) — melengkapi [docs/06-OPERATIONS-DR-BACKUP.md §5–6](../../docs/06-OPERATIONS-DR-BACKUP.md) dan [docs/09 SOP 1–4](../../docs/09-RUNBOOKS-SOP.md).

| Path | Platform | Isi |
|---|---|---|
| [`linux/crontab.txt`](./linux/crontab.txt) | Linux cron | Jadwal backup/healthcheck/maintenance + env var, offset anti thundering herd |
| [`oracle/oracle_dbms_scheduler.sql`](./oracle/oracle_dbms_scheduler.sql) | Oracle | `DBMS_SCHEDULER`: program + schedule + job (health check, window, RMAN wrapper) |
| [`sqlserver/sql_agent_jobs.sql`](./sqlserver/sql_agent_jobs.sql) | SQL Server Agent | Job health check, full/log backup, index maintenance (msdb) |

> Alternatif systemd timer untuk Postgres disimpan di folder terkait: [`../backup-recovery/postgresql/pg_backup.timer`](../backup-recovery/postgresql/pg_backup.timer).

## Prinsip yang Diterapkan

1. **Offset waktu** — `:07`, `:30` (bukan `:00`) menghindari thundering herd.
2. **Disabled by default** — job dibuat non-aktif, diaktifkan setelah review (tanpa deploy otomatis menjalankan job yang belum dites).
3. **Logging terstruktur** — tiap eksekusi mencetak timestamp + level untuk audit & RCA.
4. **Notifikasi gagal** — webhook/email dipicu saat exit code non-zero / job fail.
5. **Tidak ada secret di file** — credential via env var, Ansible Vault, DBMS_CREDENTIAL.