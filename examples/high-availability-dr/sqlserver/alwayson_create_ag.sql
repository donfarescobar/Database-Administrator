-- ============================================================================
-- SQL Server — Create Availability Group (Always On) (generic, no real data)
-- ============================================================================
-- Tujuan    : Membuat Availability Group AG-AppDB dengan:
--             - Replika sinkron (automatic failover) di DC1 (Node1 & Node2)
--             - Replika asinkron (manual failover) di DC2/DR   (Node3)
--             - Listener untuk koneksi transparan aplikasi
-- Melengkapi : docs/03-ARCHITECTURE.md §4 dan docs/06-OPERATIONS-DR-BACKUP.md §3.
-- Prasyarat : WSFC cluster aktif, semua node tergabung, endpoint 5022 terbuka,
--             database dalam FULL recovery model + sudah pernah full backup.
-- Catatan   : Jalankan script #1 di PRIMARY. Backup→restore ke replica
--             sebelum menambahkan database ke AG (langkah 5–7).
-- ============================================================================
SET NOCOUNT ON;

-- ----------------------------------------------------------------------------
-- 1. Endpoint HADR wajib eksis di SEMUA node sebelum AG dibuat.
--    (biasanya di-setup saat konfigurasi WSFC; verifikasi dulu)
-- ----------------------------------------------------------------------------
IF SERVERPROPERTY('IsHadrEnabled') = 0
    RAISERROR('Always On belum diaktifkan di instance ini.', 16, 1);

SELECT name, type_desc FROM sys.tcp_endpoints WHERE type = 4;   -- type 4 = HADR

-- ----------------------------------------------------------------------------
-- 2. Buat Availability Group (jalankan di NODE PRIMER)
-- ----------------------------------------------------------------------------
CREATE AVAILABILITY GROUP [AG-AppDB]
WITH
(
    AUTOMATED_BACKUP_PREFERENCE = SECONDARY,
    FAILURE_CONDITION_LEVEL     = 3,      -- seimbang: deteksi cepat tanpa alarm false
    HEALTH_CHECK_TIMEOUT        = 30000
)
FOR DATABASE [AppDB]
REPLICA ON
    N'SQLNODE1' WITH
    (
        ENDPOINT_URL      = N'TCP://sqlnode1.corp.internal:5022',
        AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,     -- HA lokal DC1
        FAILOVER_MODE     = AUTOMATIC,
        BACKUP_PRIORITY   = 50,
        SECONDARY_ROLE    (ALLOW_CONNECTIONS = NO)
    ),
    N'SQLNODE2' WITH
    (
        ENDPOINT_URL      = N'TCP://sqlnode2.corp.internal:5022',
        AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,     -- HA lokal DC1
        FAILOVER_MODE     = AUTOMATIC,
        BACKUP_PRIORITY   = 50,
        SECONDARY_ROLE    (ALLOW_CONNECTIONS = NO)
    ),
    N'SQLNODE3' WITH
    (
        ENDPOINT_URL      = N'TCP://sqlnode3.corp.internal:5022',
        AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,    -- DR jauh DC2
        FAILOVER_MODE     = MANUAL,
        BACKUP_PRIORITY   = 0,                       -- jangan backup di DR
        SECONDARY_ROLE    (ALLOW_CONNECTIONS = NO)
    );

-- ----------------------------------------------------------------------------
-- 3. Listener (virtual IP + DNS digunakan aplikasi saat koneksi)
-- ----------------------------------------------------------------------------
ALTER AVAILABILITY GROUP [AG-AppDB]
ADD LISTENER N'AG-AppDB-Listener'
(
    WITH IP
    (
        (N'10.10.1.50', N'255.255.255.0'),   -- IP DC1 — sesuaikan subnet
        (N'10.20.1.50', N'255.255.255.0')    -- IP DC2 — multi-subnet listener
    ),
    PORT = 1433
);
GO

-- ----------------------------------------------------------------------------
-- 4. Backup & restore seed ke replica (sekali saja, sebelum add database)
--    Backup FULL dengan NORECOVERY pada Node2 & Node3 terlebih dahulu.
-- ----------------------------------------------------------------------------
BACKUP DATABASE [AppDB] TO DISK = N'E:\Backup\AppDB_seed.bak'
WITH CHECKSUM, COMPRESSION, INIT;
BACKUP LOG [AppDB] TO DISK = N'E:\Backup\AppDB_seed.trn'
WITH CHECKSUM, COMPRESSION, INIT;
GO
-- Jalankan di Node2 & Node3:
--   RESTORE DATABASE [AppDB] FROM DISK = N'\\share\AppDB_seed.bak'
--       WITH NORECOVERY, MOVE <logical files>;
--   RESTORE LOG [AppDB] FROM DISK = N'\\share\AppDB_seed.trn'
--       WITH NORECOVERY;

-- ----------------------------------------------------------------------------
-- 5. Join replica ke AG (jalankan di Node2 & Node3 setelah restore seeds)
-- ----------------------------------------------------------------------------
-- ALTER AVAILABILITY GROUP [AG-AppDB] JOIN WITH (CLUSTER_TYPE = WSFC);
-- ALTER AVAILABILITY GROUP [AG-AppDB] GRANT CREATE ANY DATABASE;

-- ----------------------------------------------------------------------------
-- 6. (Opsional) Preferensi backup = SECONDARY agar HA replica menangani backup
--    Lihat setup backup di examples/backup-recovery/sqlserver/.
-- ----------------------------------------------------------------------------
ALTER AVAILABILITY GROUP [AG-AppDB]
SET (AUTOMATED_BACKUP_PREFERENCE = SECONDARY,
     BACKUP_PRIORITY = 50 ON (SQLNODE1),
     BACKUP_PRIORITY = 50 ON (SQLNODE2),
     BACKUP_PRIORITY = 0  ON (SQLNODE3));