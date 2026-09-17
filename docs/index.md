# Portofolio — Senior Database Engineer / Administrator
## Banking & Enterprise Environment

> Dokumen ini adalah kumpulan portofolio teknis yang menggambarkan kompetensi, standar kerja, arsitektur, dan praktik operasional seorang **Senior Database Engineer/Administrator** yang bekerja di lingkungan **perbankan dan enterprise** (high-availability, high-compliance, high-security).

---

## 📁 Struktur Dokumen

| No | Dokumen | Deskripsi |
|----|---------|-----------|
| 1 | [`01-PROFESSIONAL-SUMMARY.md`](./01-PROFESSIONAL-SUMMARY.md) | Ringkasan profil profesional, area keahlian, dan filosofi kerja |
| 2 | [`02-SKILLS-MATRIX.md`](./02-SKILLS-MATRIX.md) | Matriks keahlian teknis (database engine, cloud, tools, scripting) |
| 3 | [`03-ARCHITECTURE.md`](./03-ARCHITECTURE.md) | Arsitektur referensi database & infrastruktur untuk bank/enterprise |
| 4 | [`04-STANDARDS-GOVERNANCE.md`](./04-STANDARDS-GOVERNANCE.md) | Standar teknis, naming convention, change management, data governance |
| 5 | [`05-SECURITY-COMPLIANCE.md`](./05-SECURITY-COMPLIANCE.md) | Security hardening, enkripsi, audit, kepatuhan regulasi (OJK, BI, PCI-DSS) |
| 6 | [`06-OPERATIONS-DR-BACKUP.md`](./06-OPERATIONS-DR-BACKUP.md) | Backup, disaster recovery, HA/failover, monitoring & observability |
| 7 | [`07-PERFORMANCE-TUNING.md`](./07-PERFORMANCE-TUNING.md) | Metodologi tuning performa, query optimization, capacity planning |
| 8 | [`08-PROJECTS-PORTFOLIO.md`](./08-PROJECTS-PORTFOLIO.md) | Contoh studi kasus proyek (format STAR: Situation-Task-Action-Result) |
| 9 | [`09-RUNBOOKS-SOP.md`](./09-RUNBOOKS-SOP.md) | Runbook operasional / SOP siap pakai (incident response, patching, dsb.) |

---

## 🔧 Artefak Teknis (examples/)

Folder `examples/` di repo berisi artefak generik (tanpa kredensial/data sensitif) yang **membuktikan kompetensi** per domain kerja DBA — disusun per domain, bukan per tool:

| Domain | Isi Singkat |
|---|---|
| `backup-recovery/` | RMAN (Oracle), full/diff/log + verify & restore drill (SQL Server), `pg_dump`/systemd + PITR (PostgreSQL) |
| `high-availability-dr/` | Data Guard (broker & switchover), Always On (AG + failover test), streaming replication (PostgreSQL) |
| `security-hardening/` | Audit, TDE, masking, RBAC/least privilege (SQL Server, Oracle, PostgreSQL) + hardening host Linux |
| `performance-monitoring/` | Daily health check, wait stats, index maintenance (SQL Server, Oracle, PostgreSQL) |
| `data-warehouse-etl/` | ETL/ELT (SSIS-style, PL/SQL, Airflow, dbt) + DDL dimensional model & log ETL |
| `scheduling/` | Orkestrasi terjadwal (cron, systemd, SQL Agent, Oracle Scheduler) |
| `automation-iac/` | Bootstrap, Docker Compose dev, Terraform (Azure SQL) |
| `cloud-kubernetes/` | Manifest PostgreSQL stateful di Kubernetes |
| `migration-versioning/` | Database change management (Flyway, Liquibase) + checklist review RFC |

Setiap domain memiliki `README.md` yang memetakan artefaknya ke dokumen terkait di tabel di atas; lihat `examples/README.md` sebagai titik masuk.

---

## 🎯 Cara Menggunakan Portofolio Ini

- **Untuk melamar kerja / interview**: gunakan `01`, `02`, `08` sebagai bahan CV/portfolio presentasi.
- **Untuk dokumentasi internal tim**: gunakan `03–07, 09` sebagai baseline dokumentasi standar tim DBA di perusahaan.
- **Untuk audit/compliance**: `05` dan `04` bisa dijadikan referensi kontrol (control matrix) saat audit internal/eksternal (OJK, BI, ISO 27001, PCI-DSS).
- Semua isi bersifat **template/referensi profesional umum industri** — sesuaikan nama sistem, versi engine, dan detail spesifik dengan kondisi nyata di organisasi Anda sebelum digunakan sebagai dokumen resmi/legal.

---

## 🏦 Konteks Lingkungan yang Diasumsikan

Portofolio ini disusun dengan asumsi lingkungan kerja tipikal bank/enterprise di Indonesia:

- **Core Banking System (CBS)**: Oracle / DB2 / SQL Server sebagai OLTP inti (rekening, transaksi, GL)
- **ERP/Middleware**: Microsoft Dynamics NAV/BC, SAP, atau in-house system
- **Data Platform**: Data Warehouse (Oracle Exadata / SQL Server / Teradata / Snowflake), Data Lake (Hadoop/S3/ADLS)
- **Regulasi**: POJK (Peraturan OJK), SEOJK, ketentuan BI (RTGS/SKNBI), UU PDP (Perlindungan Data Pribadi), PCI-DSS (jika terkait kartu pembayaran)
- **High Availability requirement**: RPO ≤ 15 menit, RTO ≤ 4 jam untuk sistem kritikal (tier-1), sesuai praktik umum BCP/DRP perbankan

---
*Dokumen ini dibuat sebagai kerangka portofolio profesional — silakan disesuaikan dengan pengalaman, tools, dan kebijakan aktual di tempat kerja Anda.*
