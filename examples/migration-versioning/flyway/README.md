# Flyway — Contoh Migrasi Database

Flyway menjaga skema database tetap sinkron dengan skema yang didefinisikan di repo. Konsep inti:

- File migrasi diberi nama `V<nomor>__<deskripsi>.sql` (underscore ganda).
- Versi dieksekusi berurutan; checksum file dicatat — jika file yang sudah dijalankan berubah, Flyway akan menolak (mejaga integritas).
- `flyway_schema_history` (tabel internal) adalah bukti audit perubahan skema yang boleh ditunjukkan ke auditor.

## Cara Pakai (ringkas)

```bash
# Prasyarat: Flyway CLI / plugin build (Maven/Gradle), koneksi ke DB target
flyway -url=jdbc:postgresql://localhost:5432/appdb \
       -user=app_svc \
       migrate                # apply V1, V2, ... yang belum dijalankan

flyway -url=... info          # lihat status migrasi
flyway -url=... repair        # perbaiki checksum mismatch (perlu dibahas tim)
```

## Aturan yang Dianut di Contoh Ini

1. **Forward-only secara default** — begitu migrasi dijalankan di production, jangan ubah isi file; buat migrasi baru.
2. **Rollback via migrasi tambahan**, bukan edit history (pattern umum: `V3__fix_xxx.sql`).
3. Penamaan objek mengikuti naming convention di [docs/04 §1](../../../docs/04-STANDARDS-GOVERNANCE.md).

## File

- `V1__baseline_core_schema.sql` — skema awal (create schema, tabel inti).
- `V2__add_transaction_index.sql` — perubahan tambahan dari feedback performance review.
- `V3__...` dan seterusnya: setiap perubahan skema berikutnya adalah file baru, bukan edit V1/V2.