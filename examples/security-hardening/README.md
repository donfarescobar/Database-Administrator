# Security Hardening & Compliance — Contoh Artefak

Bukti kompetensi **keamanan database**: audit trail, enkripsi at-rest/in-transit, masking, RBAC/least privilege, dan hardening host — selaras [docs/05-SECURITY-COMPLIANCE.md](../../docs/05-SECURITY-COMPLIANCE.md) & [docs/04 §5](../../docs/04-STANDARDS-GOVERNANCE.md).

| Path | Engine | Isi |
|---|---|---|
| [`sqlserver/sqlserver_audit_tde_masking.sql`](./sqlserver/sqlserver_audit_tde_masking.sql) | SQL Server | Server/Database Audit, TDE (AES-256), Dynamic Data Masking |
| [`sqlserver/sqlserver_rbac_least_privilege.sql`](./sqlserver/sqlserver_rbac_least_privilege.sql) | SQL Server | DB roles minimal, verifikasi hak, access review pack |
| [`oracle/oracle_unified_audit_tde.sql`](./oracle/oracle_unified_audit_tde.sql) | Oracle | Unified Auditing policy, TDE tablespace, lock akun default, Data Redaction |
| [`oracle/oracle_rbac_redaction.sql`](./oracle/oracle_rbac_redaction.sql) | Oracle | Role aplikasi minimal, privilege analysis, Database Vault |
| [`postgresql/postgresql_rbac_encryption.sql`](./postgresql/postgresql_rbac_encryption.sql) | PostgreSQL | Role minimal + default privileges, RLS, pgcrypto, SSL, pgaudit |
| [`postgresql/pg_hba_hardening.conf`](./postgresql/pg_hba_hardening.conf) | PostgreSQL | pg_hba pattern: scram-sha-256, TLS-only, default-deny |
| [`linux/ansible_server_hardening.yml`](./linux/ansible_server_hardening.yml) | Linux/Ansible | Baseline hardening host (patch, sysctl, firewall, sshd, auditd) |

## Poin yang Ditonjolkan

- **Least privilege = default**; tidak pernah ada `sysadmin`/`db_owner` untuk aplikasi.
- **Audit trail immutable** dikirim ke SIEM (tidak sekadar log lokal) — docs/05 §2e.
- Klasifikasi data (docs/04 §3a) menentukan kontrol mana yang wajib (TDE vs masking vs keduanya).
- Script generik: **tanpa kredensial** — semua mekanisme autentikasi dipasok env var/vault.

> Host hardening dilengkapi contoh bootstrap infra di [`../automation-iac/bootstrap/`](../automation-iac/bootstrap/).