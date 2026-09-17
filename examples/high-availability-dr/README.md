# High Availability & Disaster Recovery — Contoh Artefak

Bukti kompetensi **HA/DR**: replikasi, failover otomatis/manual, switchover, dan prosedur failback yang teruji — melengkapi [docs/03-ARCHITECTURE.md §4](../../docs/03-ARCHITECTURE.md) dan [docs/06 §3–4](../../docs/06-OPERATIONS-DR-BACKUP.md).

| Path | Engine | Isi |
|---|---|---|
| [`oracle/dataguard_broker_setup.dgmgrl`](./oracle/dataguard_broker_setup.dgmgrl) | Oracle Data Guard | Setup broker (primary + physical standby), protection mode, fast-start failover |
| [`oracle/dataguard_switchover.dgmgrl`](./oracle/dataguard_switchover.dgmgrl) | Oracle Data Guard | Planned switchover, failover (unplanned), reinstate/failback |
| [`sqlserver/alwayson_create_ag.sql`](./sqlserver/alwayson_create_ag.sql) | SQL Server Always On | AG multi-replica (sync/async), listener, seeding, backup preference |
| [`sqlserver/alwayson_failover_test.sql`](./sqlserver/alwayson_failover_test.sql) | SQL Server Always On | Health check DMVs, planned failover test, validasi, dokumentasi |
| [`postgresql/streaming_replication_setup.sh`](./postgresql/streaming_replication_setup.sh) | PostgreSQL | Primary+standby, pg_basebackup, replication slot, verifikasi lag |

## Poin yang Ditonjolkan

- Topologi yang sama dengan [docs/03 §4](../../docs/03-ARCHITECTURE.md): **sinkron untuk HA lokal, asinkron untuk DR lintas lokasi**.
- Setiap prosedur menyertakan **verifikasi pra & pasca eksekusi** (lag = 0, role bertukar) + **dokumentasi hasil DR drill** untuk audit.
- Failback/reinstate dieksplisitkan — membedakan planned switchover vs unplanned failover.

> Kombinasikan dengan [`../backup-recovery/`](../backup-recovery/) — HA bukan pengganti backup (prinsip 3-2-1).