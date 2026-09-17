# Data Warehouse & ETL — Contoh Artefak

Bukti kompetensi **data platform**: ETL/ELT dengan idempotency, reconciliation, dan audit trail; model dimensional; plus orchestration — melengkapi [docs/11-DATA-WAREHOUSE-BI.md](../../docs/11-DATA-WAREHOUSE-BI.md) dan [docs/03 §5](../../docs/03-ARCHITECTURE.md).

| Path | Pendekatan | Isi |
|---|---|---|
| [`sqlserver/etl_ssis_style.sql`](./sqlserver/etl_ssis_style.sql) | SQL Server (stored proc) | Extract incremental via watermark, MERGE dimensi, rekonsiliasi row count + control total |
| [`oracle/etl_orders_pkg.sql`](./oracle/etl_orders_pkg.sql) | Oracle (PL/SQL) | BULK COLLECT, MERGE, logging `etl_log` + `etl_batch_log`, exception handling |
| [`airflow/etl_orders_daily_dag.py`](./airflow/etl_orders_daily_dag.py) | Airflow | DAG dengan retry/SLA, smoke test koneksi, rekonsiliasi via XCom |
| [`dbt/`](./dbt/) | dbt | `dbt_sources.yml` (freshness + tests) + `dbt_staging_orders.sql` (incremental + quarantine) |
| [`schemas/dwh_dimensional_model_ddl.sql`](./schemas/dwh_dimensional_model_ddl.sql) | DDL umum | Star schema: `dim_*` (SCD2) + `fact_orders` sesuai docs/11 §3 |
| [`schemas/etl_log_schema.sql`](./schemas/etl_log_schema.sql) | DDL umum | `etl_batch_log`, `etl_log_detail`, `etl_quarantine` — dipakai semua contoh |

## Prinsip yang Konsisten (docs/11 §4)

1. **Tidak ada kredensial di kode** — Airflow Connections, env var, secret manager.
2. **Idempotent** — incremental watermark atau upsert, aman di-rerun.
3. **Reconciliation wajib** — row count + control total source vs target sebelum commit.
4. **Audit trail** — setiap batch tercatat (untuk kebutuhan audit/regulator).
5. **Quarantine** — baris invalid ditandai, bukan dibuang diam-diam (docs/11 §7).

> Jadwal eksekusi batch: [`../scheduling/`](../scheduling/). Model data → [`../migration-versioning/`](../migration-versioning/).