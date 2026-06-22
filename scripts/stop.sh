#!/usr/bin/env bash
# stop.sh — gracefully stops the database-migration-platform application.
#
# Usage:
#   ./scripts/stop.sh
#
# Environment variables:
#   DMP_PID_FILE    — optional; PID file path (default: build/dmp.pid)
#   DMP_STOP_WAIT   — optional; seconds to wait for graceful shutdown (default: 30)

set -euo pipefail

# ─── Paths ──────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PID_FILE="${DMP_PID_FILE:-${PROJECT_DIR}/build/dmp.pid}"
STOP_WAIT="${DMP_STOP_WAIT:-30}"

# ─── Helpers ────────────────────────────────────────────────────────────────
log()  { echo "[$(date '+%Y-%m-%dT%H:%M:%S')] $*"; }
fail() { echo "[$(date '+%Y-%m-%dT%H:%M:%S')] ERROR: $*" >&2; exit 1; }

# ─── No PID file ────────────────────────────────────────────────────────────
if [[ ! -f "${PID_FILE}" ]]; then
    log "PID file not found at ${PID_FILE}. Application is not running (or was not started via start.sh)."
    exit 0
fi

pid="$(cat "${PID_FILE}")"

# ─── Already stopped ────────────────────────────────────────────────────────
if ! kill -0 "${pid}" 2>/dev/null; then
    log "Process ${pid} is not running. Removing stale PID file."
    rm -f "${PID_FILE}"
    exit 0
fi

# ─── Graceful shutdown (SIGTERM) ─────────────────────────────────────────────
log "Sending SIGTERM to process ${pid}..."
kill -TERM "${pid}"

elapsed=0
while [[ ${elapsed} -lt ${STOP_WAIT} ]]; do
    if ! kill -0 "${pid}" 2>/dev/null; then
        log "Process ${pid} stopped cleanly."
        rm -f "${PID_FILE}"
        # ─── ClickHouse: stop via Docker Compose ─────────────────────────────
        log "Stopping ClickHouse..."
        (cd "${PROJECT_DIR}" && docker compose down)
        log "ClickHouse stopped."
        exit 0
    fi
    sleep 1
    elapsed=$((elapsed + 1))
done

# ─── Forceful shutdown (SIGKILL) ─────────────────────────────────────────────
log "Process ${pid} did not stop within ${STOP_WAIT}s. Sending SIGKILL..."
kill -KILL "${pid}" 2>/dev/null || true

# Wait briefly for the kernel to clean up
sleep 2

if kill -0 "${pid}" 2>/dev/null; then
    fail "Process ${pid} could not be terminated. Manual intervention required."
fi

log "Process ${pid} forcefully terminated."
rm -f "${PID_FILE}"

# ─── ClickHouse: stop via Docker Compose ─────────────────────────────────────
log "Stopping ClickHouse..."
(cd "${PROJECT_DIR}" && docker compose down)
log "ClickHouse stopped."

exit 0
