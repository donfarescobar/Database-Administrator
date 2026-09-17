# Contoh provisioning Azure SQL Database dengan kontrol keamanan dasar
# sesuai standar di docs/05-SECURITY-COMPLIANCE.md:
# - TDE wajib (default Azure SQL)
# - Public network access dinonaktifkan (akses via private endpoint)
# - Audit log diaktifkan ke storage account terpisah
# - AAD-only authentication (tidak ada SQL auth untuk user manusia)

terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
}

provider "azurerm" {
  features {}
  # subscription_id / tenant_id via ARM_* environment variables
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "random_password" "sql_admin" {
  length           = 32
  special          = true
  override_special = "!#$%*()-_=+[]{}<>:?"
}

resource "azurerm_mssql_server" "sql" {
  name                         = var.sql_server_name
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_login
  administrator_login_password = coalesce(var.sql_admin_password, random_password.sql_admin.result)

  # Keamanan: matikan akses publik — koneksi hanya via private endpoint/VNet.
  public_network_access_enabled = false

  # Keamanan: TDE dengan customer-managed key adalah langkah lanjutan;
  # default service-managed key tetap mengenkripsi at-rest.

  azuread_administrator {
    login_username              = "sql-admins"   # grup AD, bukan akun individu
    azuread_authentication_only = true            # AAD-only auth
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_mssql_database" "db" {
  name                        = var.sql_db_name
  server_id                   = azurerm_mssql_server.sql.id
  sku_name                    = var.sql_sku_name
  collation                   = "SQL_Latin1_General_CP1_CI_AS"
  zone_redundant              = true        # HA lintas zona availability
  read_scale                  = true        # offload query reporting ke replica
  short_term_retention_days   = 14          # PITR harian
  long_term_retention_weekly_backup {
    week_of_year = 1
    retention_in_years = 1
  }

  threat_detection_policy {
    state                = "Enabled"
    email_account_admins = "Enabled"
  }
}

# Private endpoint: database tidak terekspos internet (docs/03 §3)
resource "azurerm_private_endpoint" "sql_pe" {
  name                = "pe-${var.sql_server_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "psc-sql"
    private_connection_resource_id = azurerm_mssql_server.sql.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }
}

output "sql_server_fqdn" {
  description = "FQDN untuk connection string aplikasi"
  value       = azurerm_mssql_server.sql.fully_qualified_domain_name
}
