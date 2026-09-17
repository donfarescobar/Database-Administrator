#!/usr/bin/env bash
# ============================================================================
# Bash bootstrap — Postgres server (generic, no real data)
# Tujuan : Instalasi awal + tuning postgresql.conf + pg_hba.conf sesuai
#          baseline hardening (docs/05). Untuk server on-premise / VM.
# Cara pakai :
#   sudo PG_VERSION=16 PGDATA=/var/lib/pgsql/16/data ./bootstrap_postgres.sh
# Catatan :
#   - Idempotent: aman dijalankan ulang (cek direktori, skip jika sudah ada).
#   - Tidak ada password di file ini — generate setelah instalasi.
# ============================================================================

set -euo pipefail

PG_VERSION="${PG_VERSION:-16}"
PGDATA="${PGDATA:-/var/lib/pgsql/${PG_VERSION}/data}"
PG_CONF="${PGDATA}/postgresql.conf"
PG_HBA="${PGDATA}/pg_hba.conf"

# ---- 1. Instalasi paket (RHEL family; sesuaikan untuk Debian)
if command -v dnf >/dev/null 2>&1; then
    dnf install -y "postgresql${PG_VERSION}-server" "postgresql${PG_VERSION}-contrib"
elif command -v apt-get >/dev/null 2>&1; then
    apt-get update
    apt-get install -y "postgresql-${PG_VERSION}"
else
    echo "Distro tidak dikenali. Install Postgres secara manual." >&2
    exit 1
fi

# ---- 2. Init cluster (skip jika sudah ada)
if [[ ! -s "${PGDATA}/PG_VERSION" ]]; then
    echo "Inisialisasi cluster di ${PGDATA} ..."
    PGSETUP_INITDB_OPTIONS="--encoding=UTF8 --locale=C" \
        postgresql-${PG_VERSION}-setup initdb || /usr/pgsql-${PG_VERSION}/bin/postgresql-${PG_VERSION}-setup initdb
fi

# ---- 3. Backup konfigurasi sebelum diubah
cp -n "${PG_CONF}" "${PG_CONF}.bak.$(date +%F)" 2>/dev/null || true
cp -n "${PG_HBA}"  "${PG_HBA}.bak.$(date +%F)"  2>/dev/null || true

# ---- 4. Tuning postgresql.conf (generic, conservative)
cat >> "${PG_CONF}" <<'EOF'

# ---- Custom tuning (bootstrap_postgres.sh) ----
listen_addresses = 'localhost,10.0.0.0/8'   # batasi ke subnet internal
max_connections  = 200
shared_buffers   = 256MB
work_mem         = 4MB
maintenance_work_mem = 64MB
effective_cache_size = 768MB
log_min_duration_statement = 1000
log_connections = on
log_disconnections = on
log_line_prefix = '%m [%p] %q%u@%d from %h '
ssl = on
EOF

# ---- 5. pg_hba.conf — default scram-sha-256 untuk user lokal
cat > "${PG_HBA}" <<'EOF'
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             postgres                                peer
local   all             all                                     scram-sha-256
host    all             all             127.0.0.1/32            scram-sha-256
host    all             all             ::1/128                 scram-sha-256
hostssl all             app_user        10.0.0.0/8              scram-sha-256
EOF
chown postgres:postgres "${PG_HBA}" "${PG_CONF}"

# ---- 6. Enable & start service
if command -v systemctl >/dev/null 2>&1; then
    systemctl enable --now "postgresql-${PG_VERSION}"
    systemctl is-active --quiet "postgresql-${PG_VERSION}" \
        || { echo "Service gagal start" >&2; exit 1; }
fi

# ---- 7. Setup password untuk user postgres (interaktif)
echo "Membuat password untuk role 'postgres' ..."
sudo -u postgres psql -c "\password postgres" || true

echo "Bootstrap selesai. Verifikasi: psql -h localhost -U postgres -c 'SELECT version();'"
