# Projects Portfolio
## Studi Kasus (Format STAR: Situation – Task – Action – Result)

> ⚠️ **Catatan penting**: Bagian ini adalah **template/kerangka contoh** studi kasus yang umum ditemukan pada peran Senior DBA di sektor perbankan/enterprise. Ganti detail (nama sistem, angka, timeline) dengan **pengalaman nyata Anda sendiri** sebelum digunakan sebagai portofolio resmi/CV — jangan mencantumkan pencapaian yang tidak benar-benar dikerjakan, karena ini bisa dianggap misrepresentasi saat verifikasi/referensi kerja.

---

## Studi Kasus 1 — Migrasi Database dengan Zero Downtime

**Situation**: Sistem core banking/ERP menggunakan versi database yang sudah *end-of-support*, berisiko terhadap keamanan dan tidak lagi didukung vendor.

**Task**: Migrasi ke versi/engine baru tanpa mengganggu operasional transaksi 24/7.

**Action**:
- Menyusun rencana migrasi bertahap menggunakan strategi replikasi (log shipping/replication) ke instance baru
- Melakukan uji migrasi berulang di lingkungan UAT dengan salinan data production (ter-masking)
- Menjadwalkan cutover pada jendela waktu low-traffic dengan rollback plan siap
- Berkoordinasi dengan tim aplikasi, jaringan, dan business stakeholder

**Result**: *(isi dengan hasil nyata, misal: migrasi selesai dengan downtime < X menit, tidak ada insiden pasca-migrasi, performa meningkat Y%)*

---

## Studi Kasus 2 — Implementasi High Availability & Disaster Recovery

**Situation**: Sistem kritikal belum memiliki DR site yang teruji, berisiko terhadap kepatuhan BCP/DRP regulator.

**Task**: Merancang dan mengimplementasikan arsitektur HA/DR sesuai target RPO/RTO yang ditetapkan manajemen risiko.

**Action**:
- Merancang topologi replikasi (synchronous untuk HA lokal, asynchronous untuk DR remote)
- Mengimplementasikan automated failover dan menguji skenario failover
- Menyusun runbook DR dan melatih tim operasional
- Melaksanakan DR drill terjadwal dan mendokumentasikan hasil untuk kebutuhan audit

**Result**: *(isi dengan hasil nyata, misal: RTO tercapai di bawah target, hasil DR drill terdokumentasi dan lolos audit internal)*

---

## Studi Kasus 3 — Optimasi Performa Sistem Pelaporan

**Situation**: Laporan bisnis harian (mis. laporan omzet, komisi, atau laporan regulator) membutuhkan waktu eksekusi berjam-jam, menghambat pengambilan keputusan.

**Task**: Mempercepat waktu eksekusi laporan tanpa mengubah kebutuhan bisnis.

**Action**:
- Menganalisis execution plan dan mengidentifikasi bottleneck (missing index, query tidak efisien, tabel tanpa partisi)
- Merancang ulang struktur tabel (partitioning) dan menambahkan index yang tepat
- Memisahkan beban query reporting dari OLTP (menggunakan replica/read-only copy)
- Melakukan automasi proses melalui scripting (mis. VBA terintegrasi ERP, atau stored procedure terjadwal)

**Result**: *(isi dengan hasil nyata, misal: waktu eksekusi laporan berkurang dari beberapa jam menjadi beberapa menit)*

---

## Studi Kasus 4 — Hardening Keamanan Database untuk Kepatuhan Audit

**Situation**: Temuan audit internal/eksternal menunjukkan kontrol akses database belum sesuai prinsip least privilege dan minim audit trail.

**Task**: Melakukan remediasi kontrol keamanan sesuai rekomendasi audit dan standar internal.

**Action**:
- Melakukan access review menyeluruh dan mencabut hak akses berlebihan
- Mengimplementasikan audit logging terpusat untuk aktivitas DDL/DML kritikal
- Menerapkan enkripsi (TDE) pada database yang menyimpan data nasabah
- Menyusun dokumentasi kontrol untuk kebutuhan audit berikutnya

**Result**: *(isi dengan hasil nyata, misal: seluruh temuan audit tertutup dalam waktu X bulan, tidak ada temuan berulang pada audit berikutnya)*

---

## Studi Kasus 5 — Automasi Proses Operasional Rutin

**Situation**: Proses maintenance database (backup verification, index rebuild, laporan kapasitas) masih dilakukan manual, rentan human error dan memakan waktu.

**Task**: Mengotomasi proses rutin untuk meningkatkan reliabilitas dan efisiensi waktu tim.

**Action**:
- Membuat script otomasi (PowerShell/T-SQL/Python) untuk backup verification, index maintenance, dan health check harian
- Mengintegrasikan alerting otomatis ke tim melalui email/chat jika terjadi anomali
- Mendokumentasikan seluruh script dalam version control (Git)

**Result**: *(isi dengan hasil nyata, misal: mengurangi waktu kerja manual X jam/minggu, meningkatkan konsistensi proses maintenance)*

---

## Template Kosong (untuk Diisi dengan Pengalaman Anda)

```
### [Nama Proyek/Inisiatif]

**Situation**:
**Task**:
**Action**:
**Result** (gunakan angka konkret bila memungkinkan):

**Teknologi yang digunakan**:
**Durasi**:
**Peran saya**:
```
