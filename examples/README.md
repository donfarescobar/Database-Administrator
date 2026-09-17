# Examples — Artefak Teknis Senior DBA/DBE

Folder `examples/` berisi artefak teknis anonim (tanpa kredensial, hostname asli, atau data production) yang **membuktikan** kompetensi yang diklaim di `docs/`. Struktur folder sengaja disusun per **domain kerja DBA**, bukan per tool, agar mudah dinavigasi saat interview maupun saat digunakan sebagai baseline dokumentasi internal.

## Peta Domain → Dokumentasi

| Domain | Isi | Kaitkan Dengan |
|---|---|---|
| [`backup-recovery/`](./backup-recovery/) | Backup Oracle RMAN, SQL Server (full/diff/log+verify), PostgreSQL PITR, restore drill | [docs/06](../docs/06-OPERATIONS-DR-BACKUP.md), [docs/09 SOP 2](../docs/09-RUNBOOKS-SOP.md) |
| [`high-availability-dr/`](./high-availability-dr/) | Oracle Data Guard (broker, switchover/switchback), SQL Server Always On (AG+listener, failover test), PostgreSQL streaming replication | [docs/03 §4](../docs/03-ARCHITECTURE.md), [docs/06 §3–4](../docs/06-OPERATIONS-DR-BACKUP.md) |
| [`security-hardening/`](./security-hardening/) | Audit, TDE, masking, RBAC/least privilege (SQL Server, Oracle, PostgreSQL), hardening host Linux | [docs/05](../docs/05-SECURITY-COMPLIANCE.md), [docs/04 §5](../docs/04-STANDARDS-GOVERNANCE.md) |
| [`performance-monitoring/`](./performance-monitoring/) | Daily health check (SQL Server, Oracle, PostgreSQL), index maintenance, wait stats, top query, missing index | [docs/07](../docs/07-PERFORMANCE-TUNING.md), [docs/09 SOP 1](../docs/09-RUNBOOKS-SOP.md) |
| [`data-warehouse-etl/`](./data-warehouse-etl/) | ETL/ELT: SSIS-style, Oracle PL/SQL, Airflow, dbt + DDL dimensional model & log ETL | [docs/11](../docs/11-DATA-WAREHOUSE-BI.md) |
| [`scheduling/`](./scheduling/) | Orchestration terjadwal: Linux cron, systemd timer, SQL Agent, Oracle DBMS_SCHEDULER | [docs/06 §5–6](../docs/06-OPERATIONS-DR-BACKUP.md) |
| [`automation-iac/`](./automation-iac/) | Bootstrap, Docker Compose (dev), Terraform (Azure SQL dengan kontrol security) | [docs/04 §4](../docs/04-STANDARDS-GOVERNANCE.md) |
| [`cloud-kubernetes/`](./cloud-kubernetes/) | Manifest PostgreSQL stateful di K8s (StatefulSet + PVC + NetworkPolicy) | [docs/10](../docs/10-CLOUD-KUBERNETES.md) |
| [`migration-versioning/`](./migration-versioning/) | Flyway & Liquibase untuk database change management terkontrol + checklist review RFC | [docs/04 §2](../docs/04-STANDARDS-GOVERNANCE.md) |

## Prinsip yang Konsisten pada Semua Artefak

1. **No secrets** — kredensial lewat env var, vault, atau DBMS_CREDENTIAL, tidak pernah di file.
2. **Idempotent** — script aman dijalankan ulang tanpa efek ganda.
3. **Audit trail** — setiap aksi penting tercatat log (batch/operational log) untuk RCA/audit regulator.
4. **Default-deny** — jaringan, firewall, dan akses minimal; prinsip *least privilege* di mana-mana.
5. **Bersifat template** — sesuaikan skema, path, dan env naming dengan standar internal organisasi.

## Cara Menggunakan Folder Ini

- **Interview / portofolio**: gunakan satu artefak dari tiap domain untuk menunjukkan kedalaman (misal: runbook + backup verifikasi + Data Guard/Always On + hardening).
- **Baseline tim DBA**: salin & adaptasi artefak sesuai standar internal; jangan langsung eksekusi di production.
- **Audit readiness**: artefak di `backup-recovery`, `high-availability-dr`, dan `security-hardening` bisa dijadikan bukti prosedur terdokumentasi.