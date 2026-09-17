-- ============================================================================
-- SQL Server Index Maintenance (Ola Hallengren-style, versi ringkas generik)
-- Tujuan   : rebuild/reorganize index sesuai fragmentasi (docs/07 §6):
--            >30% rebuild, 10-30% reorganize. Skip index kecil.
-- Penggunaan : jalankan via SQL Agent Job mingguan pada maintenance window.
-- Catatan  : versi edukasi/portofolio — untuk production gunakan skrip
--            Ola Hallengren penuh (https://ola.hallengren.com) dengan logging.
-- ============================================================================

DECLARE @min_page_count INT = 1000;      -- abaikan index < ~8 MB
DECLARE @rebuild_threshold FLOAT = 30.0;
DECLARE @reorganize_threshold FLOAT = 10.0;

DECLARE @commands TABLE (
    object_id      INT,
    index_id       INT,
    partition_number INT,
    frag_pct       FLOAT,
    page_count     BIGINT,
    action         VARCHAR(20)
);

INSERT INTO @commands (object_id, index_id, partition_number, frag_pct, page_count)
SELECT
    ps.object_id,
    ps.index_id,
    ps.partition_number,
    ps.avg_fragmentation_in_percent,
    ps.page_count
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ps
JOIN sys.indexes i ON i.object_id = ps.object_id AND i.index_id = ps.index_id
WHERE ps.alloc_unit_type_desc = 'IN_ROW_DATA'
  AND ps.index_id > 0
  AND ps.page_count >= @min_page_count
  AND ps.avg_fragmentation_in_percent >= @reorganize_threshold
  AND OBJECTPROPERTY(ps.object_id, 'IsUserTable') = 1;

-- Susun perintah per partisi
UPDATE c
SET c.action = CASE
    WHEN c.frag_pct > @rebuild_threshold THEN 'REBUILD'
    ELSE 'REORGANIZE'
END
FROM @commands c;

-- Jalankan satu per satu (serial — aman untuk window maintenance)
DECLARE @obj NVARCHAR(261), @idx SYSNAME, @act VARCHAR(20), @sql NVARCHAR(1000);
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT QUOTENAME(OBJECT_SCHEMA_NAME(c.object_id)) + N'.' + QUOTENAME(OBJECT_NAME(c.object_id)),
           i.name,
           c.action
    FROM @commands c
    JOIN sys.indexes i ON i.object_id = c.object_id AND i.index_id = c.index_id
    ORDER BY c.page_count DESC;

OPEN cur;
FETCH NEXT FROM cur INTO @obj, @idx, @act;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF @act = 'REBUILD'
        SET @sql = N'ALTER INDEX ' + QUOTENAME(@idx) + N' ON ' + @obj + N' REBUILD WITH (ONLINE = OFF);';
        -- ONLINE = ON hanya pada Enterprise/edisi tertentu — sesuaikan.
    ELSE
        SET @sql = N'ALTER INDEX ' + QUOTENAME(@idx) + N' ON ' + @obj + N' REORGANIZE;';

    RAISERROR('%s %s', 0, 1, @act, @sql) WITH NOWAIT;
    EXEC (@sql);

    FETCH NEXT FROM cur INTO @obj, @idx, @act;
END
CLOSE cur;
DEALLOCATE cur;

-- Statistik ikut diperbarui setelah maintenance index
EXEC sp_MSforeachtable N'UPDATE STATISTICS ? WITH SAMPLE 25 PERCENT;';
