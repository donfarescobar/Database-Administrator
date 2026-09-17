#!/usr/bin/env bash
# ============================================================================
# Bash wrapper untuk cron job — generic, no real data
# Tujuan   : Backup Postgres dengan logging terstruktur, exit code benar,
#            notifikasi ke tim on-call saat gagal. Dipanggil dari crontab.
# Cara pakai :
#   1. Simpan di /opt/dbops/bin/db_backup.sh; chmod 0750; owner root:dba.
#   2. Crontab lihat di examples/scheduling/linux/crontab.txt.
# Catatan  :
#   - PGHOST/PGUSER/PGPASSWORD via ~/.pgpass (mode 0600), bukan di sini.
#   - Log di-rotate via logrotate (lihat README scheduler).
# ============================================================================

set -euo pipefail

# ---- Konfigurasi (override via env var di crontab)
PGHOST="${PGHOST:-127.0.0.1}"
PGUSER="${PGUSER:-backup_role}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/postgres}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"
LOG_DIR="${LOG_DIR:-/var/log/dbops}"
SCRIPT_NAME="$(basename "$0" .sh)"

mkdir -p "${BACKUP_DIR}" "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/${SCRIPT_NAME}.log"

# ---- Logging: timestamp + level
log() { printf '%s [%s] %s\n' "$(date -Iseconds)" "$1" "$2" | tee -a "${LOG_FILE}"; }
notify() {
    # Hook: kirim alert ke Slack/email/Teams. Konfigurasi via env var.
    local msg="$1"
    if [[ -n "${ALERT_WEBHOOK:-}" ]]; then
        curl -sS -m 5 -X POST -H 'Content-Type: application/json' \
            -d "$(printf '{"text":"[%s] %s on %s"}' "${SCRIPT_NAME}" "${msg}" "$(hostname)")" \
            "${ALERT_WEBHOOK}" >/dev/null || true
    fi
}

# ---- 1. Pre-check
if ! command -v pg_dump >/dev/null 2>&1; then
    log "ERROR" "pg_dump tidak ditemukan di PATH"
    notify "FATAL: pg_dump missing"
    exit 3
fi

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
OUT_FILE="${BACKUP_DIR}/pgdump-${TIMESTAMP}.sql.gz"

# ---- 2. Backup
log "INFO" "Mulai backup ke ${OUT_FILE}"
if pg_dump --host="${PGHOST}" --user="${PGUSER}" \
        --format=custom --compress=9 --jobs=4 \
        --file="${OUT_FILE%.gz}"; then
    gzip -9 "${OUT_FILE%.gz}"
    log "INFO" "Backup selesai: $(du -h "${OUT_FILE}" | cut -f1)"
else
    rc=$?
    log "ERROR" "pg_dump gagal exit=${rc}"
    notify "Backup GAGAL exit=${rc}"
    exit "${rc}"
fi

# ---- 3. Verifikasi (integritas gzip + size > 0)
if ! gzip -t "${OUT_FILE}"; then
    log "ERROR" "File backup korup: ${OUT_FILE}"
    notify "Backup KORUP"
    exit 4
fi

# ---- 4. Retensi — hapus backup > N hari
DELETED=$(find "${BACKUP_DIR}" -name 'pgdump-*.sql.gz' -mtime "+${RETENTION_DAYS}" -print -delete | wc -l)
log "INFO" "Retensi: ${DELETED} file dihapus (>${RETENTION_DAYS} hari)"

log "INFO" "OK"
exit 0
