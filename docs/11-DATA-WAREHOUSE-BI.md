# Data Warehouse & BI
## Arsitektur DWH & Reporting — Banking/Enterprise

> Dokumen ini memperdalam bagian [Architecture §5 (Data Flow OLTP → DWH → Reporting)](./03-ARCHITECTURE.md) menjadi rancangan lengkap platform data warehouse dan business intelligence untuk kebutuhan bank: laporan regulator, MIS manajemen, dan analytics bisnis.

---

## 1. Tujuan & Konsumen Data

| Konsumen | Kebutuhan | Karakteristik |
|---|---|---|
| **Regulator (OJK/BI)** | Laporan periodik wajib (SLIK, laporan monetarias, dsb.) | Akurat, on-time, audit-trail penuh, format baku |
| **Manajemen / MIS** | Dashboard KPI harian/bulanan, drill-down | Cepat, konsisten antar periode |
| **Unit bisnis** | Analisis penjualan/komisi/portofolio nasabah | Fleksibel, self-service dengan kontrol akses |
| **Risk & Compliance** | AML, credit risk, stress test data | Data historis panjang, lineage jelas |

Prinsip: satu sumber kebenaran (**single source of truth**) — semua pelaporan resmi mengambil dari DWH, bukan langsung dari OLTP.

---

## 2. Arsitektur Layer

```mermaid
flowchart TB
    subgraph Sources["Source Systems"]
        CBS["Core Banking DB"]
        ERP["ERP DB"]
        CH["Channel Systems\n(Mobile/Internet Banking)"]
        EXT["External Feed\n(biro kredit, kurs)"]
    end

    subgraph Ingest["Ingestion Layer"]
        CDC["CDC Streaming\n(transaksi real-time)"]
        BATCH["Batch ETL\n(off-peak, nightly)"]
    end

    subgraph Core["Core DWH Layers"]
        STG["Staging\n(1:1 source, volatile)"]
        DIM["Dimensional Layer\n(dim_*, fact_* — star schema)"]
        HIST["History/Archive Zone\n(SCD Type-2, retensi panjang)"]
    end

    subgraph Serving["Serving Layer"]
        MART["Data Marts per Domain\n(Finance, Risk, Sales)"]
        OLAP["Semantic/Semantic Model\n(Power BI dataset)"]
    end

    subgraph Consumption["Consumption"]
        PBI["Power BI Dashboards"]
        SSRS["Paginated Reports (SSRS)"]
        REGREP["Regulatory Submission Files\n(OJK/BI)"]
        ADHOC["Ad-hoc Query / Excel"]
    end

    CBS --> CDC --> STG
    ERP --> BATCH --> STG
    CH --> CDC --> STG
    EXT --> BATCH --> STG
    STG --> DIM
    DIM --> HIST
    DIM --> MART
    MART --> OLAP
    OLAP --> PBI
    MART --> SSRS
    MART --> REGREP
    OLAP --> ADHOC
```

**Definisi layer:**
- **Staging**: replika mentah per-source, dibersihkan tiap batch. Tidak diakses user akhir.
- **Dimensional**: model star schema (`dim_customer`, `fact_transaction`, dll.) — standar industri untuk reporting.
- **History**: SCD Type-2 menyimpan riwayat perubahan atribut (mis. perubahan segmen nasabah) — penting agar angka laporan tahun lalu bisa direproduksi persis saat audit.
- **Data mart**: subset per domain dengan access control granular.

---

## 3. Desain Dimensional Model (Contoh)

```mermaid
erDiagram
    dim_customer ||--o{ fact_transaction : "customer_key"
    dim_account ||--o{ fact_transaction : "account_key"
    dim_date ||--o{ fact_transaction : "date_key"
    dim_branch ||--o{ fact_transaction : "branch_key"
    dim_product ||--o{ fact_transaction : "product_key"

    fact_transaction {
        bigint transaction_id
        int date_key FK
        int customer_key FK
        int account_key FK
        int branch_key FK
        int product_key FK
        decimal amount
        string currency
        string channel_code
        string trx_type
    }
    dim_customer {
        int customer_key PK
        string segment
        date valid_from
        date valid_to "SCD Type-2"
        boolean is_current
    }
```

**Aturan desain:**
- Grain fakta didefinisikan eksplisit sebelum desain kolom (satu baris = satu transaksi? satu transaksi × satu status?)
- Kunci surrogate (`*_key`) dipakai di DWH — kunci bisnis dari source tetap disimpan sebagai atribut.
- SCD Type-2 untuk dimensi yang atributnya berubah dan harus dilacak; SCD Type-1 cukup untuk koreksi data.

---

## 4. Strategi Load & Orchestration

| Aspek | Pendekatan |
|---|---|
| Metode ekstraksi | CDC untuk tabel transaksi high-volume; batch incremental (watermark `last_updated`) untuk lainnya |
| Jadwal | Batch nightly setelah jam operasional; streaming untuk dashboard near-real-time |
| Idempotency | Setiap load dapat di-rerun tanpa duplikasi (delete-insert berdasarkan batch_id / merge upsert) |
| Reconciliation | Row count + control total (sum amount) source vs DWH per batch — selisih = alert |
| Late-arriving data | Window reprocessing (mis. 3 hari) untuk data yang datang terlambat |
| Dependency management | Orchestrator (SQL Agent job / Airflow / Azure Data Factory) dengan retry + alerting |

> 📌 **Reconciliation adalah kontrol wajib di banking**: laporan regulator yang angkanya tidak cocok dengan source system adalah temuan audit.

---

## 5. Performa & Skalabilitas

- **Partitioning** tabel fakta besar berdasarkan tanggal (bulanan/tahunan) — mendukung partition switching untuk load & purge cepat.
- **Columnstore index** untuk workload analytical pada tabel fakta.
- Pisahkan storage/compute bila platform mendukung (mis. Synapse dedicated pool, Snowflake warehouse size).
- Materialized/indexed view untuk agregat yang sering diminta (saldo harian, total per produk).
- Monitoring: durasi ETL vs SLA window, query report > threshold, blokir ad-hoc query berat dari menabrak window ETL (workload management/resource governor).

---

## 6. Keamanan Data di Platform BI

| Risiko | Kontrol |
|---|---|
| Akses data lintas divisi | Row-Level Security (RLS) per cabang/divisi; Object-Level Security di semantic model |
| PII terekspos di dashboard | Masking/pseudonymization di data mart; akses kolom sensitif by exception |
| Export tak terkendali | Kebijakan export Power BI (label sensitivitas, log aktivitas), pembatasan download dataset |
| Laporan regulator dimodifikasi | Snapshot report read-only + versioning; file submission disimpan immutable |
| Service account berlebihan | Akun ETL hanya akses staging/mart yang relevan; tidak ada sysadmin |

Integrasi dengan [Security & Compliance](./05-SECURITY-COMPLIANCE.md): klasifikasi data berlaku sama — kolom PII/PAN di DWH diperlakukan seperti di OLTP.

---

## 7. Data Quality Framework

Kualitas DWH ditentukan sejak ingest — bukan diperbaiki saat laporan sudah salah.

```mermaid
flowchart LR
    LOAD["Load ke Staging"] --> RULE{"Data Quality Rules"}
    RULE -- "Pass" --> PROMOTE["Promote ke Dimensional Layer"]
    RULE -- "Fail (minor)" --> QUAR["Quarantine Table + Log"]
    RULE -- "Fail (major)" --> HALT["Stop Load + Alert Tim Data"]
    QUAR --> FIX["Perbaikan Source / Transformasi"]
    FIX --> RELOAD["Reload Batch"]
```

Contoh aturan: not-null kolom kunci, referential integrity antar dimensi-fakta, range check (amount tidak negatif untuk jenis transaksi tertentu), duplikasi natural key, format NIK/rekening.

---

## 8. Retensi & Arsip Data Historis

| Zona | Retensi Tipikal (sesuaikan regulasi internal) |
|---|---|
| Staging | 7–30 hari |
| Detail fakta aktif (queryable) | 2–5 tahun |
| History/arsip (queryable lambat / arsip storage) | 5–10 tahun+ sesuai ketentuan perbankan |
| Snapshot laporan regulator | Permanen (bukti submission) |

Arsip menggunakan format terkompresi (columnar/parquet/backup native), dengan prosedur restore yang terdokumentasi dan diuji.

---

## 9. Checklist Go-Live DWH/BI

- [ ] Model dimensional direview oleh perwakilan finance/risk/business (business keys benar)
- [ ] Reconciliation control total berjalan otomatis + alert aktif
- [ ] RLS/object-level security diuji dengan akun representatif tiap role
- [ ] Durasi ETL penuh < maintenance window, dengan headroom minimal 30%
- [ ] Restore arsip diuji sekali sebelum go-live
- [ ] Dokumentasi data dictionary + lineage pipeline lengkap (lihat [Standards §6](./04-STANDARDS-GOVERNANCE.md))
- [ ] Angka laporan pilot dicocokkan manual dengan source oleh tim bisnis (UAT sign-off)
