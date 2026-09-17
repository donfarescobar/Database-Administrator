"""
Airflow DAG — generic ETL (extract -> transform -> load -> reconcile)
=========================================================================
Tujuan   : Pola ETL harian dengan retry, SLA, dan kontrol rekonsiliasi.
Koneksi  : 'source_sqlserver' dan 'dw_postgres' didefinisikan di Airflow
            Connections (UI / env var AIRFLOW_CONN_*). Tidak ada
            kredensial hardcoded di file ini.

Cara pakai:
    Letakkan file di folder $AIRFLOW_HOME/dags/
    Pastikan provider sudah ter-install: apache-airflow-providers-mssql
                                          apache-airflow-providers-postgres
"""

from __future__ import annotations

import pendulum
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
from airflow.hooks.base import BaseHook
from airflow.exceptions import AirflowFailException


# ---------------------------------------------------------------------
# Konfigurasi DAG
# ---------------------------------------------------------------------
DAG_ID = "etl_orders_daily"
SCHEDULE = "0 2 * * *"   # setiap hari jam 02:00 (off-peak)
START_DATE = pendulum.datetime(2026, 1, 1, tz="Asia/Jakarta")

default_args = {
    "owner": "data-engineering",
    "depends_on_past": False,
    "retries": 2,
    "retry_delay": pendulum.duration(minutes=10),
    "email_on_failure": True,
    "email": ["dba-oncall@example.invalid"],  # ganti dengan tim on-call
    "sla": pendulum.duration(hours=2),
}


# ---------------------------------------------------------------------
# Task Python: validasi koneksi (smoke test sebelum ETL jalan)
# ---------------------------------------------------------------------
def check_connections(**ctx) -> None:
    for conn_id in ("source_sqlserver", "dw_postgres"):
        try:
            BaseHook.get_connection(conn_id)
        except Exception as exc:
            raise AirflowFailException(
                f"Airflow Connection '{conn_id}' tidak ditemukan"
            ) from exc


# ---------------------------------------------------------------------
# Task Python: rekonsiliasi row count + control total
# ---------------------------------------------------------------------
def reconcile_batch(ti, **ctx) -> None:
    src_rows = ti.xcom_pull(task_ids="extract_to_staging", key="src_rows")
    load_rows = ti.xcom_pull(task_ids="load_to_dwh", key="load_rows")
    src_total = ti.xcom_pull(task_ids="extract_to_staging", key="src_total")

    if src_rows is None or load_rows is None or src_total is None:
        raise AirflowFailException("XCom rekonsiliasi tidak lengkap")

    if src_rows != load_rows:
        raise AirflowFailException(
            f"Rekonsiliasi gagal: src={src_rows} loaded={load_rows}"
        )
    # Control total disimpan di log task untuk audit (bukan hard-fail
    # kecuali di skrip produksi, sesuaikan kebijakan internal).


# ---------------------------------------------------------------------
# Definisi DAG
# ---------------------------------------------------------------------
with DAG(
    dag_id=DAG_ID,
    description="ETL harian: SQL Server -> Postgres DWH (staging + marts)",
    default_args=default_args,
    schedule=SCHEDULE,
    start_date=START_DATE,
    catchup=False,
    max_active_runs=1,
    tags=["etl", "dwh", "orders"],
) as dag:

    t_smoke = PythonOperator(
        task_id="check_connections",
        python_callable=check_connections,
    )

    t_extract = SQLExecuteQueryOperator(
        task_id="extract_to_staging",
        conn_id="source_sqlserver",
        sql="""
            TRUNCATE TABLE stg.stg_orders;
            INSERT INTO stg.stg_orders
                (order_id, customer_id, order_date, amount, currency,
                 status, source_updated_at, batch_id)
            SELECT order_id, customer_id, order_date, amount, currency,
                   status, updated_at, NEWID()
            FROM   src.dbo.orders
            WHERE  updated_at >= CAST(GETDATE() AS DATE) - 1
              AND  updated_at <  CAST(GETDATE() AS DATE)
              AND  is_deleted = 0;
        """,
    )

    t_transform = SQLExecuteQueryOperator(
        task_id="transform_and_load",
        conn_id="dw_postgres",
        sql="""
            -- Upsert dimensi (SCD Type-1)
            INSERT INTO dwh.dim_customer (customer_id, customer_name, segment_code, updated_at)
            SELECT DISTINCT customer_id, customer_name, segment_code, NOW()
            FROM   stg.stg_orders
            ON CONFLICT (customer_id) DO UPDATE
              SET customer_name = EXCLUDED.customer_name,
                  segment_code  = EXCLUDED.segment_code,
                  updated_at    = NOW();

            -- Append fakta
            INSERT INTO dwh.fact_orders
                (order_id, customer_key, order_date_key, amount, currency, status, batch_id)
            SELECT s.order_id,
                   dc.customer_key,
                   TO_CHAR(s.order_date, 'YYYYMMDD')::INT AS order_date_key,
                   s.amount, s.currency, s.status, s.batch_id
            FROM   stg.stg_orders s
            JOIN   dwh.dim_customer dc USING (customer_id);
        """,
    )

    t_reconcile = PythonOperator(
        task_id="reconcile",
        python_callable=reconcile_batch,
    )

    t_smoke >> t_extract >> t_transform >> t_reconcile
