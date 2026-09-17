# Schema Version Control & Database Migration

Folder ini mendemonstrasikan disiplin **database change management yang terkontrol** melalui version control (Git) dan tools migrasi — prinsip inti docs/04-STANDARDS-GOVERNANCE.md bagian *Change Management* dan *Standar Kode & Script Database*.

## Kenapa Folder Ini Penting untuk Senior DBA/DBE

Aplikasi modern mengubah skema ribuan kali. Tanpa versioning, dua masalah besar muncul:

1. **Skema production ≠ skema dev** — drift antar environment sulit dilacak.
2. **Perubahan tidak bisa di-rollback** — menyalahi aturan wajib: *setiap change wajib punya rollback* (docs/04 §2).

## Isi Folder

| Path | Tujuan |
|---|---|
| [`flyway/`](./flyway/) | Contoh migrasi berbasis SQL murni (Flyway): versioning `V1, V2, ...`, checksum, directive separator nomor versi |
| [`liquibase/`](./liquibase/) | Contoh changelog Liquibase (YAML + changeset SQL) dengan konsep *context* & rollback |
| [`review/migration_rfc_checklist.md`](./review/migration_rfc_checklist.md) | Checklist review RFC migrasi sebelum approve ke production |

## Pola Kerja yang Sama di Semua Contoh

- **Satu migrasi = satu unit kerja atomik** (bisa di-rollback).
- **Urutan deterministik** oleh versi/timestamp — bukan urutan eksekusi manual.
- **Statements idempotent** untuk DDL di mana memungkinkan.
- **Uji berulang di environment DEV → UAT → PROD** dengan *baseline* yang sama.
- **Secret/injectable values tidak pernah dihardcode** — dipropagasi via env/config saat runtime.
- Terintegrasi dengan CI/CD: migrasi dijalankan otomatis saat deploy (bukan ad-hoc oleh DBA).