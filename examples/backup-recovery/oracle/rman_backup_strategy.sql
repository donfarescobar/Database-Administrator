-- ============================================================================
-- Oracle RMAN — Backup Strategy (generic, no real data)
-- ============================================================================
-- Tujuan    : Pola strategi backup incremental (Level 0/1) + archivelog
--             dengan retention window, sesuai docs/06-OPERATIONS-DR-BACKUP.md §2.
-- Cara pakai:
--   rman target / cmdfile=rman_backup_strategy.sql
--   atau jadwalkan via DBMS_SCHEDULER (lihat examples/scheduling/oracle/).
-- Skema     :
--   - Minggu pertama & tengah bulan : Level 0 (baseline)
--   - Hari lainnya                 : Level 1 (differential) harian
--   - Archivelog di-backup setiap 2 jam, dihapus setelah masuk backup
--   - Retention policy: recovery window 14 hari + arsip bulanan offsite
-- Catatan   : Semua contoh path/format generik — sesuaikan TARGET di server.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 0. Konfigurasi permanen (sekali saja per database)
-- ----------------------------------------------------------------------------
CONFIGURE CONTROLFILE AUTOBACKUP ON;
CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '/backup/rman/cf_%F';
CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 14 DAYS;
CONFIGURE DEVICE TYPE DISK PARALLELISM 2;
CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '/backup/rman/%U';

-- ----------------------------------------------------------------------------
-- 1. BACKUP LEVEL 0 (baseline) — jalankan bertahap sesuai jadwal
-- ----------------------------------------------------------------------------
RUN {
  ALLOCATE CHANNEL c1 DEVICE TYPE DISK;
  BACKUP INCREMENTAL LEVEL 0
    DATABASE
    TAG 'DB_LVL0_MONTHLY'
    PLUS ARCHIVELOG DELETE INPUT;
  RELEASE CHANNEL c1;
  CROSSCHECK BACKUP;
  DELETE NOPROMPT OBSOLETE;
}

-- ----------------------------------------------------------------------------
-- 2. BACKUP LEVEL 1 DIFFERENTIAL (harian) + archivelog
-- ----------------------------------------------------------------------------
RUN {
  ALLOCATE CHANNEL c1 DEVICE TYPE DISK;
  ALLOCATE CHANNEL c2 DEVICE TYPE DISK;
  BACKUP INCREMENTAL LEVEL 1
    DATABASE
    TAG 'DB_LVL1_DAILY';
  BACKUP ARCHIVELOG ALL TAG 'ARCH_DAILY' DELETE INPUT;
  RELEASE CHANNEL c1;
  RELEASE CHANNEL c2;
  CROSSCHECK BACKUP;
  DELETE NOPROMPT OBSOLETE;
}

-- Alternatif cumulative (semua blok sejak Level 0 terakhir):
-- BACKUP INCREMENTAL LEVEL 1 CUMULATIVE DATABASE TAG 'DB_LVL1_CUMULATIVE';

-- ----------------------------------------------------------------------------
-- 3. BACKUP SPFILE + CONTROLFILE (daily, cheap & wajib)
-- ----------------------------------------------------------------------------
BACKUP CURRENT CONTROLFILE FORMAT '/backup/rman/ctrl_%U';
BACKUP SPFILE FORMAT '/backup/rman/spfile_%U';

-- ----------------------------------------------------------------------------
-- 4. Validasi cepat hasil backup terbaru (automatis via job)
-- ----------------------------------------------------------------------------
RESTORE DATABASE VALIDATE CHECK LOGICAL;
VALIDATE BACKUPSET MAXSIZE 1G;