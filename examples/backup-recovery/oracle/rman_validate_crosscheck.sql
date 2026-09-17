-- ============================================================================
-- Oracle RMAN — Validate & Crosscheck + Restore Drill (generic, no real data)
-- ============================================================================
-- Tujuan    : Verifikasi backup bisa dipulihkan (SOP 2 — Backup Restore
--             Verification, docs/09-RUNBOOKS-SOP.md) dan pengecekan catalog.
-- Cara pakai:
--   Restore drill penuh: jalankan di environment terisolasi (bukan prod).
--   Backup feedback loop: DBA harus bisa membuktikan restore dalam target RTO.
-- Produksi   : jalankan `RESTORE VALIDATE` terjamin tanpa mengubah data.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. CROSSCHECK — sinkronkan catalog RMAN dengan kondisi fisik di disk/tape
-- ----------------------------------------------------------------------------
CROSSCHECK BACKUP;
CROSSCHECK ARCHIVELOG ALL;
DELETE NOPROMPT EXPIRED BACKUP;   -- hapus entri yang filenya sudah tidak ada
DELETE NOPROMPT EXPIRED ARCHIVELOG ALL;

-- ----------------------------------------------------------------------------
-- 2. RESTORE VALIDATE — baca seluruh backup tanpa benar-benar restore
--    (bukti integritas file backup). Aman di production.
-- ----------------------------------------------------------------------------
RESTORE DATABASE VALIDATE CHECK LOGICAL;

-- Validasi piece paling baru untuk kecepatan
VALIDATE BACKUPSET MAXSIZE 10G;

-- ----------------------------------------------------------------------------
-- 3. RESTORE DRILL — restore penuh ke instance terisolasi
--    (manual, terjadwal bulanan untuk Tier-1 — docs/06 §2c)
-- ----------------------------------------------------------------------------
-- KEI LOG: restore dengan path sesuai instance drill.
RUN {
  SET DBID 1859994088;   -- ganti dengan DBID database target
  ALLOCATE CHANNEL c1 DEVICE TYPE DISK FORMAT '/restore_drill/%U';
  RESTORE DATABASE;
  RECOVER DATABASE;
  RELEASE CHANNEL c1;
}

-- Setelah recovery, verifikasi di SQL*Plus:
--   ALTER DATABASE OPEN;
--   SELECT FILE#, STATUS, ERROR FROM V$RECOVER_FILE;       -- harap kosong
--   SELECT COUNT(*) FROM <tabel_kontrol>;                   -- spot-check row count
-- Documentasikan durasi total restore pada log restore test (audit).

-- ----------------------------------------------------------------------------
-- 4. Point-in-Time Recovery (skenario data logical corruption / human error)
-- ----------------------------------------------------------------------------
-- RESTORE DATABASE UNTIL TIME "TO_DATE('2026-08-31 14:00:00','YYYY-MM-DD HH24:MI:SS')";
-- RECOVER DATABASE UNTIL TIME "TO_DATE('2026-08-31 14:00:00','YYYY-MM-DD HH24:MI:SS')";
-- ALTER DATABASE OPEN RESETLOGS;