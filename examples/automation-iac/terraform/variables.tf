# Contoh provisioning Azure SQL Database (generik, tanpa kredensial)
# Kredensial/admin password diambil dari environment variable TF_VAR_* atau
# secret manager — JANGAN pernah ditulis di file .tf.

variable "resource_group_name" {
  description = "Nama resource group tujuan"
  type        = string
}

variable "location" {
  description = "Region Azure"
  type        = string
  default     = "southeastasia" # data residency Indonesia/terdekat
}

variable "sql_server_name" {
  description = "Nama logical SQL server (harus unik global)"
  type        = string
}

variable "sql_db_name" {
  description = "Nama database"
  type        = string
  default     = "sqldb-app-prod-01"
}

variable "sql_admin_login" {
  description = "Admin login (password via env var TF_VAR_sql_admin_password)"
  type        = string
}

variable "sql_admin_password" {
  description = "Password admin — diisi via environment variable, bukan file"
  type        = string
  sensitive   = true
}

variable "sql_sku_name" {
  description = "SKU database (mis. GP_Gen5_4 untuk General Purpose)"
  type        = string
  default     = "GP_Gen5_4"
}

variable "allow_azure_services" {
  description = "Izinkan akses dari layanan Azure (firewall rule) — batasi di production"
  type        = bool
  default     = false
}

variable "subnet_id" {
  description = "ID subnet dedicated untuk private endpoint (data zone)"
  type        = string
}
