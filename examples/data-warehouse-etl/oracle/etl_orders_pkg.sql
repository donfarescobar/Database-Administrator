-- ============================================================================
-- Oracle PL/SQL ETL Package — generic, no real data
-- Tujuan   : Pola ELT dari OLTP ke DWH menggunakan Oracle-native
--            (BULK COLLECT, MERGE, DBMS_SCHEDULER trigger).
--            Dipanggil dari job scheduler (lihat examples/scheduling/oracle/oracle_dbms_scheduler.sql).
-- Skema    : SRC (transaksional) -> STG (staging) -> DWH (dimensional).
-- ============================================================================

CREATE OR REPLACE PACKAGE etl_orders_pkg AS
    PROCEDURE run_daily_batch (p_batch_id OUT RAW(16));
    FUNCTION  reconcile_batch  (p_batch_id IN RAW(16)) RETURN VARCHAR2;
END etl_orders_pkg;
/

CREATE OR REPLACE PACKAGE BODY etl_orders_pkg AS

    -- Konstanta threshold & ukuran batch (BULK COLLECT)
    c_limit   CONSTANT PLS_INTEGER := 10000;
    c_src     CONSTANT VARCHAR2(30) := 'SRC';
    c_stg     CONSTANT VARCHAR2(30) := 'STG';
    c_dwh     CONSTANT VARCHAR2(30) := 'DWH';

    -- Logging utility (sesuaikan tabel ETL_LOG dengan standar internal)
    PROCEDURE log_msg (p_batch_id IN RAW, p_level IN VARCHAR2, p_msg IN VARCHAR2) IS
    BEGIN
        INSERT INTO etl_log (batch_id, log_level, log_msg, logged_at)
        VALUES (p_batch_id, p_level, p_msg, SYSTIMESTAMP);
        COMMIT;
    END;

    PROCEDURE run_daily_batch (p_batch_id OUT RAW(16)) IS
        l_batch_id  RAW(16);
        l_src_cnt   PLS_INTEGER := 0;
        l_stg_cnt   PLS_INTEGER := 0;
        l_total     NUMBER(18,2) := 0;

        -- BULK COLLECT dari source
        CURSOR c_src_orders IS
            SELECT order_id, customer_id, order_date, amount, currency, status,
                   updated_at
            FROM   src.orders
            WHERE  updated_at >= TRUNC(SYSDATE) - 1
              AND  updated_at <  TRUNC(SYSDATE)
              AND  is_deleted = 0;

        TYPE t_orders IS TABLE OF c_src_orders%ROWTYPE;
        l_buf t_orders;
    BEGIN
        -- Generate batch ID (SYS_GUID)
        l_batch_id := SYS_GUID();
        p_batch_id := l_batch_id;
        log_msg(l_batch_id, 'INFO', 'Batch dimulai');

        -- 1) EXTRACT + LOAD staging
        EXECUTE IMMEDIATE 'TRUNCATE TABLE stg.stg_orders';
        OPEN c_src_orders;
        LOOP
            FETCH c_src_orders BULK COLLECT INTO l_buf LIMIT c_limit;
            EXIT WHEN l_buf.COUNT = 0;

            FORALL i IN 1..l_buf.COUNT
                INSERT INTO stg.stg_orders
                    (order_id, customer_id, order_date, amount, currency,
                     status, source_updated_at, batch_id)
                VALUES
                    (l_buf(i).order_id, l_buf(i).customer_id, l_buf(i).order_date,
                     l_buf(i).amount, l_buf(i).currency, l_buf(i).status,
                     l_buf(i).updated_at, l_batch_id);

            l_src_cnt := l_src_cnt + l_buf.COUNT;
        END LOOP;
        CLOSE c_src_orders;
        COMMIT;
        log_msg(l_batch_id, 'INFO', 'Extract selesai: '||l_src_cnt||' rows');

        -- 2) TRANSFORM — upsert dimensi, append fakta
        MERGE INTO dwh.dim_customer tgt
        USING (SELECT DISTINCT customer_id, customer_name, segment_code
               FROM   stg.stg_orders) src
          ON (tgt.customer_id = src.customer_id)
        WHEN MATCHED THEN
            UPDATE SET customer_name = src.customer_name,
                       segment_code   = src.segment_code,
                       updated_at     = SYSTIMESTAMP
        WHEN NOT MATCHED THEN
            INSERT (customer_id, customer_name, segment_code, created_at, updated_at)
            VALUES (src.customer_id, src.customer_name, src.segment_code,
                    SYSTIMESTAMP, SYSTIMESTAMP);

        INSERT INTO dwh.fact_orders
            (order_id, customer_key, order_date_key, amount, currency,
             status, batch_id)
        SELECT  s.order_id,
                dc.customer_key,
                TO_NUMBER(TO_CHAR(s.order_date, 'YYYYMMDD')) AS order_date_key,
                s.amount,
                s.currency,
                s.status,
                l_batch_id
        FROM    stg.stg_orders s
        JOIN    dwh.dim_customer dc ON dc.customer_id = s.customer_id;

        l_stg_cnt := SQL%ROWCOUNT;
        SELECT NVL(SUM(amount),0) INTO l_total FROM stg.stg_orders;
        COMMIT;

        -- 3) RECONCILIATION — kontrol wajib
        IF l_src_cnt <> l_stg_cnt THEN
            RAISE_APPLICATION_ERROR(-20001,
                'Rekonsiliasi gagal: src='||l_src_cnt||' stg='||l_stg_cnt);
        END IF;

        INSERT INTO etl_batch_log
            (batch_id, started_at, finished_at, source_rows, loaded_rows,
             control_total, status)
        VALUES
            (l_batch_id, SYSTIMESTAMP, SYSTIMESTAMP, l_src_cnt, l_stg_cnt,
             l_total, 'SUCCESS');
        COMMIT;
        log_msg(l_batch_id, 'INFO', 'Batch selesai: '||l_stg_cnt||' rows');
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            INSERT INTO etl_batch_log
                (batch_id, started_at, finished_at, status, error_message)
            VALUES
                (l_batch_id, SYSTIMESTAMP, SYSTIMESTAMP, 'FAILED', SQLERRM);
            COMMIT;
            RAISE;
    END run_daily_batch;

    FUNCTION reconcile_batch (p_batch_id IN RAW(16)) RETURN VARCHAR2 IS
        l_status VARCHAR2(20);
    BEGIN
        SELECT status INTO l_status
        FROM   etl_batch_log
        WHERE  batch_id = p_batch_id
        ORDER  BY finished_at DESC
        FETCH FIRST 1 ROW ONLY;
        RETURN l_status;
    END reconcile_batch;

END etl_orders_pkg;
/
