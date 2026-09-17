# Database Engineering Portfolio

## Banking and Enterprise Environments

This repository presents a practical approach to database engineering and administration in environments where availability, security, recoverability, and operational discipline matter. It brings together architecture notes, standards, runbooks, and representative technical examples for systems that support business-critical workloads.

The material is intentionally vendor-aware rather than vendor-dependent. It covers OLTP databases, data warehouses, integration workloads, hybrid cloud platforms, and the day-to-day practices required to keep database services reliable.

## Areas of Practice

| Area | Scope |
|---|---|
| Database engineering | Data modeling, partitioning, indexing, migration planning, and capacity management |
| Reliability | High availability, disaster recovery, backup, restore, failover, and DR exercises |
| Security | Hardening, RBAC, least privilege, encryption, masking, auditing, and SIEM integration |
| Operations | Monitoring, incident response, patching, change management, and operational runbooks |
| Performance | Execution plans, query tuning, locking, concurrency, and workload isolation |
| Data platforms | Data warehousing, dimensional modeling, ETL/ELT, data quality, lineage, and regulatory reporting |
| Automation | T-SQL, PL/SQL, PowerShell, Python, Bash, Terraform, Ansible, and CI/CD |

## Documentation

| Document | Coverage |
|---|---|
| [Professional Summary](docs/01-PROFESSIONAL-SUMMARY.md) | Professional focus and database engineering principles |
| [Skills Matrix](docs/02-SKILLS-MATRIX.md) | Database engines, cloud, HA/DR, automation, and observability |
| [Architecture](docs/03-ARCHITECTURE.md) | Network zoning, HA, DR, backup, security layers, and data flows |
| [Standards and Governance](docs/04-STANDARDS-GOVERNANCE.md) | Naming conventions, RFCs, CAB, data governance, and segregation of duties |
| [Security and Compliance](docs/05-SECURITY-COMPLIANCE.md) | Database security controls and the Indonesian regulatory context |
| [Operations, Backup and DR](docs/06-OPERATIONS-DR-BACKUP.md) | Service metrics, backup, failover, DR, monitoring, and incident management |
| [Performance Tuning](docs/07-PERFORMANCE-TUNING.md) | Tuning methodology, bottleneck analysis, and capacity management |
| [Projects Portfolio](docs/08-PROJECTS-PORTFOLIO.md) | Case study structures for migration, HA/DR, performance, security, and automation |
| [Runbooks and SOP](docs/09-RUNBOOKS-SOP.md) | Health checks, restore verification, failover, patching, P1 response, and go-live |
| [Cloud and Kubernetes](docs/10-CLOUD-KUBERNETES.md) | Stateful databases on Kubernetes and hybrid cloud patterns |
| [Data Warehouse and BI](docs/11-DATA-WAREHOUSE-BI.md) | Data warehousing, dimensional modeling, orchestration, reconciliation, and BI security |
| [Certifications](docs/CERTIFICATIONS.md) | Certification record format and professional development roadmap |

Architecture diagrams are maintained in Mermaid so that design decisions remain reviewable alongside the documentation.

## Technical Examples

The [`examples/`](examples/) directory contains anonymized, vendor-specific examples organized by operational domain. Each area includes scripts, configuration, or reference implementations that show how the documented practices can be applied. See [`examples/README.md`](examples/README.md) for the full map.

- [`examples/backup-recovery/`](examples/backup-recovery/): RMAN, SQL Server full/differential/log backups, restore drills, `pg_dump`, systemd, and PostgreSQL PITR.
- [`examples/high-availability-dr/`](examples/high-availability-dr/): Data Guard, Always On availability groups, failover testing, and PostgreSQL streaming replication.
- [`examples/security-hardening/`](examples/security-hardening/): Auditing, TDE, masking, RBAC, and host hardening with Ansible.
- [`examples/performance-monitoring/`](examples/performance-monitoring/): Health checks, wait statistics, query analysis, and index maintenance.
- [`examples/data-warehouse-etl/`](examples/data-warehouse-etl/): ETL/ELT patterns using SQL Server, PL/SQL, Airflow, and dbt, with dimensional models and process logging.
- [`examples/scheduling/`](examples/scheduling/): Scheduled operations using cron, systemd, SQL Server Agent, and Oracle Scheduler.
- [`examples/automation-iac/`](examples/automation-iac/): Environment bootstrap, Docker Compose, and Terraform for Azure SQL.
- [`examples/cloud-kubernetes/`](examples/cloud-kubernetes/): PostgreSQL StatefulSet configuration for Kubernetes.
- [`examples/migration-versioning/`](examples/migration-versioning/): Database change management with Flyway, Liquibase, and RFC review checklists.

The examples are generic by design. They contain no production credentials, internal hostnames, customer information, or other sensitive operational data.

## Running the Documentation

Requirements: Python and `pip`.

```bash
git clone https://github.com/USERNAME/REPO_NAME.git
cd REPO_NAME
pip install -r requirements.txt
mkdocs serve
```

The local preview is available at `http://127.0.0.1:8000`. Before publishing, run:

```bash
mkdocs build --strict
```

Pushes to the `main` branch trigger the GitHub Actions workflow in [`.github/workflows/deploy-docs.yml`](.github/workflows/deploy-docs.yml), which builds and publishes the documentation to GitHub Pages. Update `site_url`, `repo_url`, badges, and the clone URL before publishing this repository.

## Use and Disclaimer

This repository is a professional reference and a starting point for technical documentation. Review organizational policies, applicable regulations, vendor guidance, and the target environment before applying any example to a production system.
