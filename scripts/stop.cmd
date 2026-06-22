@echo off
rem stop.cmd — Gracefully stops the database-migration-platform application.
rem
rem Usage:
rem   scripts\stop.cmd
rem
rem Environment variables:
rem   DMP_PID_FILE    — optional; PID file path (default: build\dmp.pid)
rem   DMP_STOP_WAIT   — optional; seconds to wait for graceful shutdown (default: 30)

setlocal enabledelayedexpansion

rem ─── Paths ──────────────────────────────────────────────────────────────────
set "SCRIPT_DIR=%~dp0"
pushd "%SCRIPT_DIR%.."
set "PROJECT_DIR=%CD%"
popd

if defined DMP_PID_FILE (
    set "PID_FILE=%DMP_PID_FILE%"
) else (
    set "PID_FILE=%PROJECT_DIR%\build\dmp.pid"
)

if defined DMP_STOP_WAIT (
    set /a "STOP_WAIT=%DMP_STOP_WAIT%"
) else (
    set /a "STOP_WAIT=30"
)

rem ─── No PID file ──────────────────────────────────────────────────────────
if not exist "%PID_FILE%" (
    echo [%DATE% %TIME%] PID file not found at %PID_FILE%. Application is not running ^(or was not started via start.cmd^).
    exit /b 0
)

set /p PID=<"%PID_FILE%"

rem ─── Already stopped ──────────────────────────────────────────────────────
tasklist /FI "PID eq %PID%" 2>nul | findstr /i "%PID%" >nul 2>&1
if %errorlevel% neq 0 (
    echo [%DATE% %TIME%] Process %PID% is not running. Removing stale PID file.
    del /f "%PID_FILE%" 2>nul
    exit /b 0
)

rem ─── Graceful shutdown (SIGTERM equivalent via taskkill) ────────────────────
echo [%DATE% %TIME%] Sending graceful shutdown to process %PID%...
taskkill /PID %PID% >nul 2>&1

set /a ELAPSED=0

:wait_loop
if !ELAPSED! geq !STOP_WAIT! goto force_kill

tasklist /FI "PID eq %PID%" 2>nul | findstr /i "%PID%" >nul 2>&1
if !errorlevel! neq 0 (
    echo [%DATE% %TIME%] Process %PID% stopped cleanly.
    del /f "%PID_FILE%" 2>nul
    goto stop_clickhouse
)

timeout /t 1 /nobreak >nul
set /a ELAPSED+=1
goto wait_loop

:force_kill
rem ─── Forceful shutdown ─────────────────────────────────────────────────────
echo [%DATE% %TIME%] Process %PID% did not stop within %STOP_WAIT%s. Force killing...
taskkill /F /PID %PID% >nul 2>&1

timeout /t 2 /nobreak >nul

tasklist /FI "PID eq %PID%" 2>nul | findstr /i "%PID%" >nul 2>&1
if !errorlevel! equ 0 (
    echo [%DATE% %TIME%] ERROR: Process %PID% could not be terminated. Manual intervention required. >&2
    exit /b 1
)

echo [%DATE% %TIME%] Process %PID% forcefully terminated.
del /f "%PID_FILE%" 2>nul

:stop_clickhouse
rem ─── ClickHouse: stop via Docker Compose ───────────────────────────────────
echo [%DATE% %TIME%] Stopping ClickHouse...
pushd "%PROJECT_DIR%"
docker compose down
popd
echo [%DATE% %TIME%] ClickHouse stopped.

exit /b 0
