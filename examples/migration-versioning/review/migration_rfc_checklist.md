# Checklist Review RFC — Migrasi / Perubahan Skema Database

Checklist ini digunakan saat **code review** perubahan skema sebelum disetujui ke production (docs/04 §2 — Change Management). Untuk setiap perubahan, reviewer (bukan penulis) mengisi: `[ ]` (lulus) atau `[x]` (blokir + catatan).

## 1. Fungsional & Skema

- [ ] DDL sudah mengikuti **naming convention** (docs/04 §1) — tabel, index, constraint.
- [ ] **Business key** & tipe data sudah sesuai kamus data yang disetujui.
- [ ] Index dibuat **hanya** untuk pola query nyata (check docs/07) — bukan spekulasi.
- [ ] Tidak ada `SELECT *` / dynamic SQL tak terparameter di dalam migrasi.
- [ ] Perubahan tidak menambahkan kolom tabel **tanpa default/nilai** yang bisa mengganggu transaksi berjalan.
- [ ] Partisi/skema besar diputuskan sebelum implementasi (bukan sesudah tabel penuh).

## 2. Data

- [ ] Migrasi data (backfill) **idempotent** — dapat dijalankan ulang tanpa duplikasi.
- [ ] Data sensitif **tidak pernah** disertakan dalam skrip migrasi (hanya di env yang di-mask).
- [ ] Ada **pre-post check** delta row count untuk backfill besar.
- [ ] Arah data & linage dicatat sesuai data dictionary (docs/04 §3c).

## 3. Performa & Risiko

- [ ] Estimasi durasi eksekusi vs **maintenance window** — termasuk headroom 30%.
- [ ] **Lock impact**: eksklusif lock pada tabel besar → pertimbangkan `ONLINE` (SQL Server) / pakai approach low-lock.
- [ ] Migrasi diuji di **UAT dengan volume data mendekati production** (docs/07 §4).
- [ ] Tidak ada statement yang tanpa sadar membuat full table rewrite (mis. `ALTER COLUMN` di PostgreSQL bila tak perlu).

## 4. Rollback & Recovery

- [ ] **Rollback** terdokumentasi (pakai mekanisme tool: `flyway ... ` reverse / `rollback` liquibase).
- [ ] **Backup pre-change** terjadwal & terverifikasi (docs/09 SOP 4).
- [ ] Jalur pemulihan bila migrasi gagal di tengah (restore PITR) jelas.

## 5. Governance

- [ ] RFC/approval CAB tercatat (docs/04 §2) & disetujui oleh *second reviewer* (four-eyes).
- [ ] Milestone & jadwal deploy sinkron dengan release window aplikasi.
- [ ] Dokumentasi (data dictionary, runbook) telah diperbarui seiring perubahan.

## Hasil

- **Approve** / **Blokir**
- Nama reviewer: `___________`   Tanggal: `___________`

---

> Referensi: [docs/04-Standards & Governance](../../../docs/04-STANDARDS-GOVERNANCE.md), [docs/07-Performance Tuning](../../../docs/07-PERFORMANCE-TUNING.md), [docs/09-Runbooks & SOP](../../../docs/09-RUNBOOKS-SOP.md)