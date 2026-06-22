#!/usr/bin/env bash
# start.sh — starts ClickHouse (via Docker Compose) and the database-migration-platform application.
#
# Prerequisites:
#   - Java 17+ on PATH
#   - Docker on PATH with the Docker daemon running (for ClickHouse)
#   - PostgreSQL already running and accessible
#   - Required environment variables are set (see database-migration-platform.yml)
#
# Usage:
#   ./scripts/start.sh
#   ./scripts/start.sh --spring.profiles.active=prod
#
# Environment variables:
#   LEXTR_POSTGRES_PASSWORD     — required; PostgreSQL password (or empty string)
#   LEXTR_CLICKHOUSE_PASSWORD   — required; ClickHouse password (or empty string)
#   DMP_CONFIG_LOCATION         — optional; override the config file path
#                                 e.g. file:/etc/dmp/database-migration-platform.yml
#   DMP_LOG_DIR                 — optional; directory for log output (default: build/logs)
#   DMP_PID_FILE                — optional; PID file path (default: build/dmp.pid)

set -euo pipefail

# ─── Paths ──────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
JAR_PATH="${PROJECT_DIR}/target/database-migration-platform-0.0.1-SNAPSHOT.jar"
LOG_DIR="${DMP_LOG_DIR:-${PROJECT_DIR}/build/logs}"
PID_FILE="${DMP_PID_FILE:-${PROJECT_DIR}/build/dmp.pid}"
LOG_FILE="${LOG_DIR}/database-migration-platform.log"

# ─── Helpers ────────────────────────────────────────────────────────────────
log()  { echo "[$(date '+%Y-%m-%dT%H:%M:%S')] $*"; }
fail() { echo "[$(date '+%Y-%m-%dT%H:%M:%S')] ERROR: $*" >&2; exit 1; }

# ─── Guard: already running ──────────────────────────────────────────────────
if [[ -f "${PID_FILE}" ]]; then
    existing_pid="$(cat "${PID_FILE}")"
    if kill -0 "${existing_pid}" 2>/dev/null; then
        log "Application is already running (PID ${existing_pid}). Skipping start."
        exit 0
    else
        log "Stale PID file found (PID ${existing_pid} is not running). Removing and continuing."
        rm -f "${PID_FILE}"
    fi
fi

# Guard: port already in use (e.g. another instance started outside this script)
port="${SERVER_PORT:-8049}"
if lsof -iTCP:"${port}" -sTCP:LISTEN -t >/dev/null 2>&1; then
    occupant=$(lsof -iTCP:"${port}" -sTCP:LISTEN -t 2>/dev/null | head -1)
    fail "Port ${port} is already in use by PID ${occupant}.
  Stop that process first, or set SERVER_PORT to use a different port."
fi

# ─── Configuration validation ───────────────────────────────────────────────
log "Validating startup configuration..."

# Java
if ! command -v java &>/dev/null; then
    fail "java not found on PATH. Install Java 21+ and ensure it is on your PATH."
fi

java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
if [[ "${java_version}" -lt 17 ]]; then
    fail "Java 17+ is required. Found version ${java_version}. Update your Java installation."
fi

export LEXTR_POSTGRES_PASSWORD="${LEXTR_POSTGRES_PASSWORD:-Mygooru1028$}"
export LEXTR_CLICKHOUSE_PASSWORD="${LEXTR_CLICKHOUSE_PASSWORD:-}"

# Environment variables for secrets
if [[ -z "${LEXTR_POSTGRES_PASSWORD+x}" ]]; then
    fail "LEXTR_POSTGRES_PASSWORD is not set.
  Set it before running: export LEXTR_POSTGRES_PASSWORD=<your-password>
  If PostgreSQL uses no password, set it to an empty string: export LEXTR_POSTGRES_PASSWORD=''"
fi

if [[ -z "${LEXTR_CLICKHOUSE_PASSWORD+x}" ]]; then
    fail "LEXTR_CLICKHOUSE_PASSWORD is not set.
  Set it before running: export LEXTR_CLICKHOUSE_PASSWORD=<your-password>
  If ClickHouse uses no password, set it to an empty string: export LEXTR_CLICKHOUSE_PASSWORD=''"
fi

# ─── ClickHouse: ensure running via Docker Compose ───────────────────────────
if ! command -v docker &>/dev/null; then
    fail "docker not found on PATH. Install Docker Desktop and ensure it is running."
fi

log "Ensuring ClickHouse is running..."
(cd "${PROJECT_DIR}" && docker compose up -d clickhouse)
log "ClickHouse is up."

# ─── Build artifact check ────────────────────────────────────────────────────
if [[ ! -f "${JAR_PATH}" ]]; then
    log "JAR not found at ${JAR_PATH}. Building with Maven..."
    (cd "${PROJECT_DIR}" && ./mvnw -q -DskipTests package)
    if [[ ! -f "${JAR_PATH}" ]]; then
        fail "Build succeeded but JAR not found at ${JAR_PATH}. Check build output."
    fi
    log "Build complete."
fi

# ─── Assemble JVM arguments ──────────────────────────────────────────────────
jvm_args=()

if [[ -n "${DMP_CONFIG_LOCATION:-}" ]]; then
    jvm_args+=("--migration.platform.config-location=${DMP_CONFIG_LOCATION}")
fi

# Pass through any extra arguments supplied to this script
extra_args=("$@")

# ─── Create log directory ────────────────────────────────────────────────────
mkdir -p "${LOG_DIR}"
mkdir -p "$(dirname "${PID_FILE}")"

# ─── Launch ─────────────────────────────────────────────────────────────────
log "Starting database-migration-platform..."
log "  JAR:      ${JAR_PATH}"
log "  Log file: ${LOG_FILE}"
log "  PID file: ${PID_FILE}"

nohup java -jar "${JAR_PATH}" ${jvm_args[@]+"${jvm_args[@]}"} ${extra_args[@]+"${extra_args[@]}"} \
    >> "${LOG_FILE}" 2>&1 &

app_pid=$!
echo "${app_pid}" > "${PID_FILE}"

# ─── Wait for startup ────────────────────────────────────────────────────────
log "Waiting for application to become ready (PID ${app_pid})..."

max_wait=60
elapsed=0
port="${SERVER_PORT:-8049}"

while [[ ${elapsed} -lt ${max_wait} ]]; do
    if ! kill -0 "${app_pid}" 2>/dev/null; then
        fail "Application process (PID ${app_pid}) exited unexpectedly during startup.
  Check the log for details: ${LOG_FILE}"
    fi
    if curl -sf "http://localhost:${port}/health" >/dev/null 2>&1; then
        log "Application is ready on port ${port} (PID ${app_pid})."
        log "Log file: ${LOG_FILE}"
        exit 0
    fi
    sleep 2
    elapsed=$((elapsed + 2))
done

fail "Application did not become ready within ${max_wait} seconds.
  Check the log for details: ${LOG_FILE}
  The process (PID ${app_pid}) may still be starting — check with: kill -0 ${app_pid}"
