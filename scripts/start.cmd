@echo off
rem start.cmd — Starts ClickHouse (via Docker Compose) and the database-migration-platform application.
rem
rem Prerequisites:
rem   - Java 17+ on PATH
rem   - Docker on PATH with the Docker daemon running (for ClickHouse)
rem   - PostgreSQL already running and accessible
rem   - Required environment variables are set (see database-migration-platform.yml)
rem
rem Usage:
rem   scripts\start.cmd
rem   scripts\start.cmd --spring.profiles.active=prod
rem
rem Environment variables:
rem   LEXTR_POSTGRES_PASSWORD     — required; PostgreSQL password (or empty string)
rem   LEXTR_CLICKHOUSE_PASSWORD   — required; ClickHouse password (or empty string)
rem   DMP_CONFIG_LOCATION         — optional; override the config file path
rem   DMP_LOG_DIR                 — optional; directory for log output (default: build\logs)
rem   DMP_PID_FILE                — optional; PID file path (default: build\dmp.pid)

setlocal enabledelayedexpansion

rem ─── Paths ──────────────────────────────────────────────────────────────────
set "SCRIPT_DIR=%~dp0"
pushd "%SCRIPT_DIR%.."
set "PROJECT_DIR=%CD%"
popd

set "JAR_PATH=%PROJECT_DIR%\target\database-migration-platform-0.0.1-SNAPSHOT.jar"

if defined DMP_LOG_DIR (
    set "LOG_DIR=%DMP_LOG_DIR%"
) else (
    set "LOG_DIR=%PROJECT_DIR%\build\logs"
)

if defined DMP_PID_FILE (
    set "PID_FILE=%DMP_PID_FILE%"
) else (
    set "PID_FILE=%PROJECT_DIR%\build\dmp.pid"
)

set "LOG_FILE=%LOG_DIR%\database-migration-platform.log"

rem ─── Guard: already running ────────────────────────────────────────────────
if exist "%PID_FILE%" (
    set /p EXISTING_PID=<"%PID_FILE%"
    tasklist /FI "PID eq !EXISTING_PID!" 2>nul | findstr /i "!EXISTING_PID!" >nul 2>&1
    if !errorlevel! equ 0 (
        echo [%DATE% %TIME%] Application is already running ^(PID !EXISTING_PID!^). Skipping start.
        exit /b 0
    ) else (
        echo [%DATE% %TIME%] Stale PID file found ^(PID !EXISTING_PID! is not running^). Removing and continuing.
        del /f "%PID_FILE%" 2>nul
    )
)

rem ─── Configuration validation ──────────────────────────────────────────────
echo [%DATE% %TIME%] Validating startup configuration...

rem Java
where java >nul 2>&1
if %errorlevel% neq 0 (
    echo [%DATE% %TIME%] ERROR: java not found on PATH. Install Java 17+ and ensure it is on your PATH. >&2
    exit /b 1
)

rem Default password env vars
if not defined LEXTR_POSTGRES_PASSWORD set "LEXTR_POSTGRES_PASSWORD=Mygooru1028$"
if not defined LEXTR_CLICKHOUSE_PASSWORD set "LEXTR_CLICKHOUSE_PASSWORD="

rem ─── ClickHouse: ensure running via Docker Compose ─────────────────────────
where docker >nul 2>&1
if %errorlevel% neq 0 (
    echo [%DATE% %TIME%] ERROR: docker not found on PATH. Install Docker Desktop and ensure it is running. >&2
    exit /b 1
)

echo [%DATE% %TIME%] Ensuring ClickHouse is running...
pushd "%PROJECT_DIR%"
docker compose up -d clickhouse
popd
echo [%DATE% %TIME%] ClickHouse is up.

rem ─── Build artifact check ──────────────────────────────────────────────────
if not exist "%JAR_PATH%" (
    echo [%DATE% %TIME%] JAR not found at %JAR_PATH%. Building with Maven...
    pushd "%PROJECT_DIR%"
    call mvnw.cmd -q -DskipTests package
    popd
    if not exist "%JAR_PATH%" (
        echo [%DATE% %TIME%] ERROR: Build succeeded but JAR not found at %JAR_PATH%. Check build output. >&2
        exit /b 1
    )
    echo [%DATE% %TIME%] Build complete.
)

rem ─── Assemble arguments ────────────────────────────────────────────────────
set "JVM_ARGS="
if defined DMP_CONFIG_LOCATION (
    set "JVM_ARGS=--migration.platform.config-location=%DMP_CONFIG_LOCATION%"
)

rem ─── Create log directory ──────────────────────────────────────────────────
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

rem ─── Launch ────────────────────────────────────────────────────────────────
echo [%DATE% %TIME%] Starting database-migration-platform...
echo [%DATE% %TIME%]   JAR:      %JAR_PATH%
echo [%DATE% %TIME%]   Log file: %LOG_FILE%
echo [%DATE% %TIME%]   PID file: %PID_FILE%

rem Start the application in the background using PowerShell
for /f "tokens=*" %%P in ('powershell -NoProfile -Command "Start-Process -FilePath 'java' -ArgumentList '-jar', '%JAR_PATH%', '%JVM_ARGS%', '%*' -NoNewWindow -PassThru -RedirectStandardOutput '%LOG_FILE%' -RedirectStandardError '%LOG_DIR%\error.log' | Select-Object -ExpandProperty Id"') do (
    set "APP_PID=%%P"
)

echo !APP_PID!>"%PID_FILE%"

rem ─── Wait for startup ─────────────────────────────────────────────────────
echo [%DATE% %TIME%] Waiting for application to become ready ^(PID !APP_PID!^)...

if defined SERVER_PORT (
    set "PORT=%SERVER_PORT%"
) else (
    set "PORT=8049"
)

set /a MAX_WAIT=60
set /a ELAPSED=0

:wait_loop
if !ELAPSED! geq !MAX_WAIT! goto wait_timeout

rem Check if process is still alive
tasklist /FI "PID eq !APP_PID!" 2>nul | findstr /i "!APP_PID!" >nul 2>&1
if !errorlevel! neq 0 (
    echo [%DATE% %TIME%] ERROR: Application process ^(PID !APP_PID!^) exited unexpectedly during startup. >&2
    echo [%DATE% %TIME%] Check the log for details: %LOG_FILE% >&2
    exit /b 1
)

rem Check if health endpoint is available
curl -sf "http://localhost:!PORT!/health" >nul 2>&1
if !errorlevel! equ 0 (
    echo [%DATE% %TIME%] Application is ready on port !PORT! ^(PID !APP_PID!^).
    echo [%DATE% %TIME%] Log file: %LOG_FILE%
    exit /b 0
)

timeout /t 2 /nobreak >nul
set /a ELAPSED+=2
goto wait_loop

:wait_timeout
echo [%DATE% %TIME%] ERROR: Application did not become ready within %MAX_WAIT% seconds. >&2
echo [%DATE% %TIME%] Check the log for details: %LOG_FILE% >&2
exit /b 1
