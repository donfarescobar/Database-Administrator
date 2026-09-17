# Runbooks & Standard Operating Procedures (SOP)
## Siap Pakai untuk Operasional Database Banking/Enterprise

---

## SOP 1 — Daily Health Check Database

**Tujuan**: Memastikan seluruh instance database dalam kondisi sehat sebelum jam operasional bisnis dimulai.

**Frekuensi**: Setiap hari kerja, sebelum jam 07:00

**Langkah-langkah**:
1. Verifikasi status service database (up/running) di semua node (primary & secondary/standby)
2. Periksa status replikasi/Always On/Data Guard — pastikan tidak ada lag abnormal
3. Periksa hasil job backup semalam — pastikan status **Success**, catat jika ada kegagalan
4. Periksa free disk space (data, log, backup, tempdb) — pastikan di atas threshold minimum (mis. 20%)
5. Periksa error log database untuk anomali (deadlock, corruption warning, failed login berlebihan)
6. Periksa job/scheduled task lain (ETL, maintenance plan) — pastikan berjalan sesuai jadwal
7. Catat hasil pada checklist harian; eskalasi ke Lead DBA jika ditemukan anomali

---

## SOP 2 — Prosedur Backup & Restore Verification

**Tujuan**: Memastikan backup dapat digunakan untuk pemulihan saat dibutuhkan.

**Frekuensi**: Verifikasi checksum harian (otomatis); restore test bulanan (Tier-1) / kuartalan (Tier-2/3)

**Langkah-langkah**:
1. Konfirmasi job backup terjadwal berjalan sesuai kebijakan retensi (full/differential/log)
2. Jalankan verifikasi integritas backup (mis. `RESTORE VERIFYONLY` / `RMAN VALIDATE`)
3. Untuk restore test terjadwal: restore backup ke environment terisolasi (bukan production)
4. Validasi data hasil restore (row count, spot-check data kritikal, konsistensi skema)
5. Dokumentasikan waktu tempuh restore, status, dan temuan pada log restore test
6. Jika ditemukan kegagalan, eskalasi segera dan investigasi root cause backup

---

## SOP 3 — Prosedur Failover (Planned/Unplanned)

**Tujuan**: Memindahkan layanan database dari node primary ke secondary dengan gangguan minimal.

**Trigger**: Kegagalan node primary (unplanned) atau kebutuhan maintenance (planned)

**Langkah-langkah**:
1. **Unplanned**: konfirmasi node primary benar-benar down/tidak responsif (cek dari multiple monitoring point untuk hindari false positive)
2. **Planned**: informasikan stakeholder H-1, jadwalkan di maintenance window
3. Verifikasi node secondary dalam kondisi sinkron (tidak ada data loss signifikan)
4. Jalankan failover (otomatis via cluster manager, atau manual sesuai runbook engine spesifik)
5. Validasi aplikasi dapat terhubung ke node baru (connection string/listener/VIP sudah mengarah dengan benar)
6. Lakukan validasi fungsional (transaksi test) sebelum mengumumkan layanan pulih sepenuhnya
7. Investigasi root cause node yang gagal (untuk unplanned failover) dan buat laporan insiden
8. Jadwalkan failback ke node original setelah dipastikan sehat dan sesuai kebijakan (tidak selalu wajib failback segera)

---

## SOP 4 — Prosedur Patching Database

**Tujuan**: Menerapkan patch keamanan/bugfix dengan risiko downtime minimal.

**Frekuensi**: Sesuai siklus vendor (mis. bulanan untuk critical security patch, kuartalan untuk cumulative update)

**Langkah-langkah**:
1. Review release notes patch — identifikasi apakah ada breaking change
2. Uji patch di environment DEV/UAT terlebih dahulu, termasuk regresi fungsional aplikasi terkait
3. Ajukan RFC ke CAB dengan detail: tujuan, risiko, rollback plan, jadwal
4. Backup penuh sebelum patching (termasuk konfigurasi instance)
5. Terapkan strategi rolling patch (secondary dulu, baru primary — lihat dokumen Operations)
6. Validasi service normal pasca-patch (health check menyeluruh)
7. Dokumentasikan versi patch baru di inventory sistem

---

## SOP 5 — Prosedur Penanganan Insiden P1 (Critical Outage)

**Tujuan**: Memulihkan layanan kritikal secepat mungkin dan meminimalkan dampak bisnis.

**Langkah-langkah**:
1. **0–5 menit**: Konfirmasi insiden, buka ticket P1, aktifkan war room/bridge call
2. **5–15 menit**: Diagnosis awal — cek monitoring, error log, status HA/replication
3. **15–30 menit**: Terapkan mitigasi tercepat (failover, restart service, rollback perubahan terakhir jika penyebabnya jelas)
4. Update stakeholder setiap 15–30 menit selama insiden berlangsung (status, ETA)
5. Setelah layanan pulih: validasi fungsional penuh sebelum menutup status "resolved"
6. Susun **Root Cause Analysis (RCA)** dalam 2x24 jam
7. Lakukan **Post-Incident Review** dengan seluruh tim terkait, hasilkan action item pencegahan
8. Update runbook/SOP jika ditemukan gap prosedur

---

## SOP 6 — Prosedur Permintaan Akses Database Baru

**Tujuan**: Memastikan pemberian akses sesuai prinsip least privilege dan tercatat untuk audit.

**Langkah-langkah**:
1. Requester mengajukan form permintaan akses (nama, sistem, level akses, justifikasi bisnis)
2. Approval dari atasan requester + data owner sistem terkait
3. DBA memverifikasi kesesuaian level akses dengan role yang sudah terdefinisi (RBAC) — hindari membuat permission ad-hoc
4. Akses diberikan dengan waktu berlaku jelas (permanen dengan review berkala, atau temporary dengan expiry otomatis)
5. Dokumentasikan pemberian akses pada log akses untuk kebutuhan audit
6. Lakukan **access recertification** berkala (6/12 bulan) — cabut akses yang tidak lagi relevan

---

## SOP 7 — Prosedur Onboarding Sistem Database Baru ke Production

**Tujuan**: Memastikan sistem baru memenuhi standar sebelum go-live.

**Checklist Go-Live**:
- [ ] Arsitektur HA/DR sudah diimplementasikan sesuai tier kekritisan
- [ ] Backup strategy sudah dikonfigurasi dan diuji
- [ ] Monitoring & alerting sudah terpasang
- [ ] Security hardening checklist sudah dijalankan (lihat dokumen Security)
- [ ] Kredensial/akses sudah sesuai RBAC (tidak ada default password)
- [ ] Load testing sudah dilakukan dengan hasil memenuhi target performa
- [ ] Dokumentasi (data dictionary, runbook, diagram arsitektur) sudah lengkap
- [ ] DR drill awal sudah dilakukan sebelum go-live (untuk Tier-1)
- [ ] Sign-off dari tim Security, Risk, dan Business Owner
