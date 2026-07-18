@echo off
rem migration.cmd — Windows equivalent of the ./migration bash script.
rem
rem Usage:
rem   migration.cmd run --service semantic-service --target postgres-main-dev
rem   migration.cmd inventory
rem   migration.cmd plan --all-services --all-targets --env dev

setlocal enabledelayedexpansion

set "JAR_PATH=target\database-migration-platform-0.0.1-SNAPSHOT.jar"

if "%LEXTR_POSTGRES_PASSWORD%"=="" set "LEXTR_POSTGRES_PASSWORD=Mygooru1028$"

set "JVM_ARGS="
if "%LEXTR_CLICKHOUSE_PASSWORD%"=="" (
    set "JVM_ARGS=-DLEXTR_CLICKHOUSE_PASSWORD="
)

rem ─── Check if pre-built JAR exists and is a valid Spring Boot JAR ──────────
if exist "%JAR_PATH%" (
    rem Verify it's a Spring Boot executable JAR by checking the manifest
    jar tf "%JAR_PATH%" 2>nul | findstr /c:"META-INF/MANIFEST.MF" >nul 2>&1
    if !errorlevel! equ 0 (
        java !JVM_ARGS! -jar "%JAR_PATH%" %*
        exit /b !errorlevel!
    )
)

rem ─── Fallback: run via Maven wrapper ───────────────────────────────────────
set "JOINED="
for %%A in (%*) do (
    if defined JOINED (
        set "JOINED=!JOINED! %%A"
    ) else (
        set "JOINED=%%A"
    )
)

call mvnw.cmd -q spring-boot:run "-Dspring-boot.run.arguments=!JOINED!" "-Dspring-boot.run.jvmArguments=!JVM_ARGS!"
exit /b %errorlevel%
