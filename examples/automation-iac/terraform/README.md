# Contoh Terraform — Provisioning Database

Contoh IaC generik (tanpa kredensial) untuk provisioning database dengan kontrol keamanan dasar sesuai [docs/05-SECURITY-COMPLIANCE.md](../../../docs/05-SECURITY-COMPLIANCE.md).

| File | Isi |
|---|---|
| [`variables.tf`](./variables.tf) | Input variables — password via env var `TF_VAR_sql_admin_password`, tidak pernah di file |
| [`main.tf`](./main.tf) | Azure SQL Database: public access off, AAD-only auth, private endpoint, audit & threat detection, retensi backup |

## Prinsip yang Diterapkan

1. **Tidak ada kredensial di kode** — semua secret lewat environment variable / secret manager / backend state terenkripsi.
2. **Database tidak terekspos publik** — akses hanya via private endpoint dari VNet data zone.
3. **AAD-only authentication** — tidak ada akun SQL lokal untuk user manusia.
4. **Backup retention** dikonfigurasi eksplisit (PITR 14 hari + LTR mingguan), selaras strategi backup di [docs/06](../../../docs/06-OPERATIONS-DR-BACKUP.md).
5. State file disimpan di remote backend terenkripsi (lihat komentar di `main.tf`) — state berisi atribut sensitif.

## Cara Pakai (contoh)

```bash
export TF_VAR_sql_admin_password='...'   # atau gunakan secret manager
terraform init
terraform plan  -var-file=env/prod.tfvars
terraform apply -var-file=env/prod.tfvars
```
