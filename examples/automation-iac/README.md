# Automation & Infrastructure as Code — Contoh Artefak

Bukti kompetensi **automation & IaC**: provisioning database yang dapat diulang (reproducible) dan aman — melengkapi [docs/04 §4](../../docs/04-STANDARDS-GOVERNANCE.md) (standar script diaudit) dan area *Scripting & Automation* di [Skills Matrix](../../docs/02-SKILLS-MATRIX.md).

| Path | Tool | Isi |
|---|---|---|
| [`bootstrap/bootstrap_postgres.sh`](./bootstrap/bootstrap_postgres.sh) | Bash | Install + tuning `postgresql.conf` + `pg_hba.conf` (scram-sha-256), idempotent |
| [`docker-local/docker-compose.yml`](./docker-local/docker-compose.yml) | Docker Compose | Stack dev (Postgres + pgAdmin) — port dibatasi `127.0.0.1`, **bukan** production |
| [`terraform/`](./terraform/) | Terraform | Azure SQL Database: private endpoint, AAD-only auth, audit, retensi backup (LTR) |

## Prinsip yang Diterapkan

1. **Tidak ada kredensial di kode** — env var / secret manager / state terenkripsi.
2. **Idempotent** — script aman dijalankan ulang (cek direktori, `Resource` Terraform).
3. **Default-deny** — `listen_addresses` dibatasi subnet internal; public access dimatikan di cloud.
4. **Hardening baseline** — TLS, scram-sha-256, audit logging, SSH no-root/password.

> Referensi hardening host (Ansible): [`../security-hardening/linux/`](../security-hardening/linux/). Deploy database di K8s: [`../cloud-kubernetes/`](../cloud-kubernetes/).