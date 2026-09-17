#!/usr/bin/env bash
# ============================================================================
# PostgreSQL — Streaming Replication: Primary & Standby Setup (generic)
# ============================================================================
# Tujuan    : Menyiapkan replikasi streaming asynchronous PostgreSQL 16
#             (primary -> standby) untuk HA/DR — melengkapi docs/03 §4 dan
#             docs/06 §3. Ini documentary-step script, BUKAN production registry.
# Catatan   :
#   - Tanpa kredensial/alamat real di script ini — pakai VARIABEL lingkungan.
#   - Otomasi lanjutan (failover otomatis) pakai Patroni / repmgr / etc.
# ============================================================================
set -euo pipefail

PRIMARY_HOST="${PRIMARY_HOST:?set hostname primary}"
STANDBY_HOST="${STANDBY_HOST:?set hostname standby}"
REPL_USER="${REPL_USER:-repl_user}"
PG_VERSION="${PG_VERSION:-16}"
PGDATA_PRIMARY="/var/lib/pgsql/${PG_VERSION}/data"
STANDBY_DATA="/var/lib/pgsql/${PG_VERSION}/data"     # di host standby

# -----------------------------------------------------------------------------
# 1. PRIMARY — konfigurasi minimal (postgresql.conf)
# -----------------------------------------------------------------------------
#   wal_level             = replica
#   max_wal_senders       = 10
#   wal_keep_size         = 1GB          # buffer WAL bila standby tertinggal
#   listen_addresses      = 'localhost,10.0.0.0/8'
#   ssl                   = on
#   checkpoint_timeout    = 5min

# -----------------------------------------------------------------------------
# 2. PRIMARY — pg_hba.conf: izinkan replikasi hanya dari standby yang dikenal
# -----------------------------------------------------------------------------
#   host   replication   repl_user   10.0.0.0/8    scram-sha-256
#   hostssl application   app_user    10.0.0.0/8    scram-sha-256

# -----------------------------------------------------------------------------
# 3. PRIMARY — buat role replikasi + token (tanpa password di shell history)
# -----------------------------------------------------------------------------
echo "-- jalankan di primary sebagai superuser:"
echo "CREATE ROLE ${REPL_USER} WITH REPLICATION LOGIN PASSWORD '<dari-ross-vault>';"
echo "GRANT CONNECT ON DATABASE postgres TO ${REPL_USER};"

# -----------------------------------------------------------------------------
# 4. STANDBY — basis dari streaming replication (pg_basebackup)
# -----------------------------------------------------------------------------
#   systemctl stop postgresql-${PG_VERSION}
#   rm -rf "${STANDBY_DATA}"
#   PGPASSWORD='<vault>' pg_basebackup \
#       -h "${PRIMARY_HOST}" -U "${REPL_USER}" \
#       --wal-method=stream --checkpoint=fast \
#       -D "${STANDBY_DATA}" -R -P
# Flag -R otomatis menulis standby.signal + primary_conninfo.

# -----------------------------------------------------------------------------
# 5. STANDBY — otomasi touch signal (bila memakai metode manual)
# -----------------------------------------------------------------------------
#   touch "${STANDBY_DATA}/standby.signal"
#   cat >> "${STANDBY_DATA}/postgresql.auto.conf" <<EOF
#   primary_conninfo = 'host=${PRIMARY_HOST} port=5432 user=${REPL_USER} application_name=standby01 sslmode=require'
#   primary_slot_name = 'standby01'
# EOF

# -----------------------------------------------------------------------------
# 6. PRIMARY — buat replication slot (mencegah standby kehabisan WAL saat pause)
# -----------------------------------------------------------------------------
#   SELECT pg_create_physical_replication_slot('standby01');

# -----------------------------------------------------------------------------
# 7. START + verifikasi
# -----------------------------------------------------------------------------
#   systemctl start postgresql-${PG_VERSION}
#   systemctl enable --now postgresql-${PG_VERSION}
PSQL() { psql -p 5432 -d postgres -c "$1"; }
echo "== Status replikasi (di primary) =="
PSQL "SELECT slot_name, active, restart_lsn, wal_status FROM pg_replication_slots;"
PSQL "SELECT client_addr, state, sync_state, sent_lsn, replay_lsn FROM pg_stat_replication;"
echo "== Deteksi lag standby (detik) =="
PSQL "SELECT EXTRACT(EPOCH FROM now() - COALESCE(MIN(f.pg_last_xact_replay_timestamp()), now()))::int
      FROM pg_is_in_recovery() f;"

# -----------------------------------------------------------------------------
# 8. DR note
#   - Failover: promot di standby -> pg_ctl promote (atau Patroni) + redirect
#     aplikasi. Failback: buat ulang node lama dari primary baru (published
#     runbook docs/09 SOP 3).
#   - Backup tetap wajib walau ada replica (docs/06 §2, prinsip 3-2-1) —
#     lihat examples/backup-recovery/postgresql/.
# ============================================================================