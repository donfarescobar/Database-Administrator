# Skills Matrix
## Senior Database Engineer / Administrator

Level: `★☆☆☆☆` Basic → `★★★★★` Expert (sesuaikan bintang dengan level penguasaan Anda yang sebenarnya)

---

## 1. Database Engines (RDBMS)

| Teknologi | Level | Catatan Penggunaan Umum |
|---|---|---|
| Oracle Database (11g–19c/21c) | ★★★★☆ | Core banking, RAC, Data Guard, RMAN |
| Microsoft SQL Server (2016–2022) | ★★★★★ | ERP (Dynamics NAV/BC), reporting, Always On AG |
| PostgreSQL | ★★★★☆ | Aplikasi internal, microservices backend |
| MySQL / MariaDB | ★★★☆☆ | Aplikasi web, sistem pendukung |
| IBM Db2 | ★★★☆☆ | Legacy core banking (mainframe/AS400 environment) |

## 2. NoSQL & Big Data

| Teknologi | Level | Catatan |
|---|---|---|
| MongoDB | ★★★☆☆ | Log & semi-structured data |
| Redis | ★★★☆☆ | Caching layer, session store |
| Apache Kafka | ★★★☆☆ | Event streaming antar sistem (transaksi real-time) |
| Hadoop/HDFS, Hive | ★★☆☆☆ | Data lake, historical data archiving |
| Elasticsearch | ★★★☆☆ | Log analytics, audit trail search |

## 3. Cloud Platforms

| Platform | Level | Layanan Relevan |
|---|---|---|
| Microsoft Azure | ★★★★☆ | Azure SQL MI, Azure VM, Azure Backup, Azure Monitor |
| AWS | ★★★☆☆ | RDS, EC2, S3, CloudWatch, IAM |
| Google Cloud Platform | ★★☆☆☆ | Cloud SQL, BigQuery |
| Hybrid/On-Prem (VMware) | ★★★★★ | Umum di bank karena regulasi data residency |

## 4. High Availability & Disaster Recovery

- Oracle Data Guard / RAC — ★★★★☆
- SQL Server Always On Availability Groups / Failover Cluster Instance — ★★★★★
- Log Shipping & Replication (transactional, merge) — ★★★★☆
- Storage-level replication (SAN-to-SAN, SRM/VMware) — ★★★☆☆
- DR drill & BCP testing — ★★★★☆

## 5. Backup & Recovery Tools

- RMAN (Oracle) — ★★★★☆
- Native SQL Server Backup, Ola Hallengren scripts — ★★★★★
- Veeam / Commvault / NetBackup (enterprise backup) — ★★★☆☆
- Point-in-Time Recovery (PITR) design — ★★★★☆

## 6. Security & Compliance Tools

- Transparent Data Encryption (TDE) — ★★★★☆
- Database Activity Monitoring (DAM) / audit log — ★★★★☆
- Data Masking / Dynamic Data Masking — ★★★☆☆
- Vulnerability Assessment (native DB tools, Nessus) — ★★★☆☆
- IAM/Active Directory integration untuk DB auth — ★★★★☆

## 7. Scripting & Automation

| Bahasa/Tools | Level | Kegunaan |
|---|---|---|
| T-SQL / PL-SQL | ★★★★★ | Stored procedure, tuning, automasi maintenance |
| PowerShell | ★★★★☆ | Automasi administrasi Windows/SQL Server |
| Python | ★★★★☆ | ETL scripting, automasi laporan, integrasi API |
| Bash | ★★★☆☆ | Automasi di Linux-based database server |
| VBA (Excel) | ★★★★★ | Automasi laporan bisnis terintegrasi ERP (mis. Dynamics NAV) |

## 8. Infrastructure as Code & DevOps

- Terraform — ★★★☆☆ (provisioning DB infra)
- Ansible — ★★★☆☆ (konfigurasi & patching otomatis)
- Git/GitHub/GitLab — ★★★★☆ (version control untuk script & schema)
- Flyway / Liquibase — ★★★☆☆ (database migration terkontrol)
- CI/CD (Azure DevOps, Jenkins, GitHub Actions) — ★★★☆☆

## 9. Monitoring & Observability

- SQL Server native DMVs, Extended Events — ★★★★☆
- Oracle AWR/ASH/Statspack — ★★★☆☆
- Prometheus + Grafana — ★★★☆☆
- Zabbix / Nagios — ★★★☆☆
- SolarWinds DPA / Redgate SQL Monitor — ★★★☆☆

## 10. Data Integration & Reporting

- SSIS (SQL Server Integration Services) — ★★★★☆
- ETL/ELT design (batch & near-real-time) — ★★★★☆
- Power BI / SSRS untuk pelaporan bisnis — ★★★★☆
- Integrasi dengan ERP (Microsoft Dynamics NAV/BC) — ★★★★★

## 11. Governance & Framework

- ITIL v4 (Incident, Change, Problem Management) — ★★★★☆
- COBIT (IT Governance) — ★★★☆☆
- ISO 27001 (Information Security Management) — ★★★☆☆
- Basis regulasi perbankan Indonesia (POJK, SEOJK terkait IT & data) — ★★★☆☆
