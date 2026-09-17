-- ============================================================================
-- SSIS-style ETL (T-SQL stored procedures) — generic, no real data
-- Tujuan   : Pola extract-transform-load dengan kontrol ETL sederhana yang
--            bisa dijalankan via SQL Agent (lihat examples/scheduling/sqlserver/sql_agent_jobs.sql).
--            Skema: source di [src_db], staging & marts di [dw_db].


-- Variabel eksekusi (sesuaikan dengan environment)
DECLARE @batch_id UNIQUEIDENTIFIER = NEWID();
DECLARE @batch_start DATETIME2 = SYSUTCDATETIME();
DECLARE @source_row_count INT = 0;
DECLARE @staging_row_count INT = 0;
DECLARE @control_total NUMERIC(18,2) = 0;

PRINT 'Batch ETL dimulai. batch_id = ' + CAST(@batch_id AS VARCHAR(36));

BEGIN TRY
    BEGIN TRANSACTION;

    ------------------------------------------------------------------
    -- 1) EXTRACT — tarik incremental dari source ke staging
    --    Tabel source: [src_db].[dbo].[orders]
    ------------------------------------------------------------------
    TRUNCATE TABLE [dw_db].[stg].[stg_orders];

    INSERT INTO [dw_db].[stg].[stg_orders]
        (order_id, customer_id, order_date, amount, currency, status,
         source_updated_at, batch_id)
    SELECT
        o.order_id,
        o.customer_id,
        o.order_date,
        o.amount,
        o.currency,
        o.status,
        o.updated_at,
        @batch_id
    FROM [src_db].[dbo].[orders] AS o
    WHERE o.updated_at > DATEADD(DAY, -1, CAST(@batch_start AS DATE))
      AND o.updated_at <= @batch_start
      AND o.is_deleted = 0;

    SET @source_row_count = @@ROWCOUNT;

    ------------------------------------------------------------------
    -- 2) TRANSFORM — normalisasi, lookup dimensi, validasi
    --    Hasil muat ke tabel dimensi/fakta (star schema, docs/11).
    ------------------------------------------------------------------
    -- Upsert dimensi customer (SCD Type-1: timpa atribut non-historis)
    MERGE [dw_db].[dbo].[dim_customer] AS tgt
    USING (
        SELECT DISTINCT
            s.customer_id,
            LTRIM(RTRIM(s.customer_name)) AS customer_name,
            s.segment_code
        FROM [dw_db].[stg].[stg_orders] s
    ) AS src
      ON tgt.customer_id = src.customer_id
    WHEN MATCHED THEN
        UPDATE SET customer_name = src.customer_name,
                   segment_code   = src.segment_code,
                   updated_at     = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN
        INSERT (customer_id, customer_name, segment_code, created_at, updated_at)
        VALUES (src.customer_id, src.customer_name, src.segment_code,
                SYSUTCDATETIME(), SYSUTCDATETIME());

    -- Insert fakta orders (append-only)
    INSERT INTO [dw_db].[dbo].[fact_orders]
        (order_id, customer_key, order_date_key, amount, currency, status, batch_id)
    SELECT
        s.order_id,
        dc.customer_key,
        CONVERT(INT, CONVERT(VARCHAR(8), s.order_date, 112)) AS order_date_key,
        s.amount,
        s.currency,
        s.status,
        @batch_id
    FROM [dw_db].[stg].[stg_orders] s
    JOIN [dw_db].[dbo].[dim_customer] dc
      ON dc.customer_id = s.customer_id;

    SET @staging_row_count = @@ROWCOUNT;

    ------------------------------------------------------------------
    -- 3) RECONCILIATION — kontrol wajib sebelum commit
    --    Bandingkan row count & control total source vs staging
    ------------------------------------------------------------------
    SELECT @control_total = SUM(amount)
    FROM [dw_db].[stg].[stg_orders];

    IF @source_row_count <> @staging_row_count
    BEGIN
        THROW 50001, 'Rekonsiliasi gagal: row count source != staging', 1;
    END

    -- Catat hasil batch (audit trail ETL)
    INSERT INTO [dw_db].[dbo].[etl_batch_log]
        (batch_id, started_at, finished_at, source_rows, loaded_rows,
         control_total, status)
    VALUES
        (@batch_id, @batch_start, SYSUTCDATETIME(),
         @source_row_count, @staging_row_count, @control_total, 'SUCCESS');

    COMMIT TRANSACTION;
    PRINT 'Batch ETL selesai. rows=' + CAST(@staging_row_count AS VARCHAR(20));
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    INSERT INTO [dw_db].[dbo].[etl_batch_log]
        (batch_id, started_at, finished_at, status, error_message)
    VALUES
        (@batch_id, @batch_start, SYSUTCDATETIME(), 'FAILED', ERROR_MESSAGE());

    THROW;
END CATCH;
