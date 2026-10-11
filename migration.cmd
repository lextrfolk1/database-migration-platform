@echo off
rem migration.cmd — Windows equivalent of the ./migration bash script.
rem
rem Two modes:
rem   local    (pom.xml next to this script): compiles changed sources and runs from target\classes,
rem            so the latest code, config and SQL are always used. No jar is built.
rem   deployed (no pom.xml): runs the bundled jar with externalized config and SQL locations.
rem
rem Overrides (both modes):
rem   DMP_CONFIG_LOCATION   platform config, e.g. file:C:/dmp/config/database-migration-platform.yml
rem   DMP_MIGRATIONS_ROOT   root folder for relative migration locations
rem   DMP_AUDIT_DIR         audit output folder
rem Relative override paths are resolved against the directory the script is run from.
rem
rem Usage:
rem   migration.cmd run --service semantic-service --target postgres-main-dev
rem   migration.cmd inventory
rem   migration.cmd plan --all-services --all-targets --env dev

setlocal enabledelayedexpansion

rem Make relative override paths absolute before changing directory.
if defined DMP_CONFIG_LOCATION if /i "%DMP_CONFIG_LOCATION:~0,5%"=="file:" for %%I in ("%DMP_CONFIG_LOCATION:~5%") do set "DMP_CONFIG_LOCATION=file:%%~fI"
if defined DMP_MIGRATIONS_ROOT for %%I in ("%DMP_MIGRATIONS_ROOT%") do set "DMP_MIGRATIONS_ROOT=%%~fI"
if defined DMP_AUDIT_DIR for %%I in ("%DMP_AUDIT_DIR%") do set "DMP_AUDIT_DIR=%%~fI"

set "DMP_HOME=%~dp0"
if "%DMP_HOME:~-1%"=="\" set "DMP_HOME=%DMP_HOME:~0,-1%"
cd /d "%DMP_HOME%"

set "MAIN_CLASS=com.lextr.migrationplatform.MigrationPlatformApplication"

if "%LEXTR_POSTGRES_PASSWORD%"=="" set "LEXTR_POSTGRES_PASSWORD=Mygooru1028$"

set "JAVA_OPTS="
if not defined LEXTR_CLICKHOUSE_PASSWORD set "JAVA_OPTS=-DLEXTR_CLICKHOUSE_PASSWORD="

if exist "pom.xml" goto local

rem ─── Deployed mode ─────────────────────────────────────────────────────────
set "JAR_PATH=%DMP_HOME%\database-migration-platform.jar"
if not exist "%JAR_PATH%" (
    echo ERROR: %JAR_PATH% not found. >&2
    exit /b 1
)
if not defined DMP_CONFIG_LOCATION set "DMP_CONFIG_LOCATION=file:%DMP_HOME%\config\database-migration-platform.yml"
if not defined DMP_MIGRATIONS_ROOT set "DMP_MIGRATIONS_ROOT=%DMP_HOME%\migrations"
if not defined DMP_AUDIT_DIR set "DMP_AUDIT_DIR=%DMP_HOME%\audit"
java %JAVA_OPTS% "-Dmigration.platform.config-location=%DMP_CONFIG_LOCATION%" "-Dmigration.platform.migrations-root=%DMP_MIGRATIONS_ROOT%" "-Dmigration.platform.audit-directory=%DMP_AUDIT_DIR%" -jar "%JAR_PATH%" %*
exit /b %errorlevel%

rem ─── Local mode ────────────────────────────────────────────────────────────
:local
set "CLASSPATH_FILE=target\classpath.txt"
rem The dependency classpath is too long for a cmd variable, so it goes to java via an @argfile.
set "CP_ARGFILE=target\java-cp.args"
set "BUILD_STAMP=target\.dmp-compiled"

rem SQL migrations are read from the source tree, so only code/config changes need a compile.
powershell -NoProfile -Command "$s = Get-Item '%BUILD_STAMP%' -ErrorAction SilentlyContinue; if (-not $s) { exit 1 }; $n = Get-ChildItem pom.xml, src\main -Recurse -File | Where-Object { $_.FullName -notlike '*\src\main\resources\migrations\*' -and $_.LastWriteTime -gt $s.LastWriteTime } | Select-Object -First 1; if ($n) { exit 1 }"
if errorlevel 1 (
    echo Compiling sources... >&2
    call mvnw.cmd -q -DskipTests compile
    if errorlevel 1 exit /b 1
    type nul > "%BUILD_STAMP%"
)

rem Regenerate when the dependencies or this script (which defines the classpath command) change.
powershell -NoProfile -Command "$c = Get-Item '%CP_ARGFILE%' -ErrorAction SilentlyContinue; if (-not $c -or (Get-Item pom.xml).LastWriteTime -gt $c.LastWriteTime -or (Get-Item '%~f0').LastWriteTime -gt $c.LastWriteTime) { exit 1 }"
if errorlevel 1 (
    echo Resolving dependency classpath... >&2
    call mvnw.cmd -q dependency:build-classpath -DincludeScope=runtime "-Dmdep.outputFile=%CLASSPATH_FILE%" "-Dmdep.fileSeparator=/"
    if errorlevel 1 exit /b 1
    powershell -NoProfile -Command "$d = (Get-Content '%CLASSPATH_FILE%' -Raw).Trim(); Set-Content -Encoding Default '%CP_ARGFILE%' ('-cp', ([char]34 + 'target/classes;' + $d + [char]34))"
    if errorlevel 1 exit /b 1
)

if defined DMP_CONFIG_LOCATION set "JAVA_OPTS=!JAVA_OPTS! "-Dmigration.platform.config-location=%DMP_CONFIG_LOCATION%""
if defined DMP_MIGRATIONS_ROOT set "JAVA_OPTS=!JAVA_OPTS! "-Dmigration.platform.migrations-root=%DMP_MIGRATIONS_ROOT%""
if defined DMP_AUDIT_DIR set "JAVA_OPTS=!JAVA_OPTS! "-Dmigration.platform.audit-directory=%DMP_AUDIT_DIR%""

java !JAVA_OPTS! @%CP_ARGFILE% %MAIN_CLASS% %*
exit /b %errorlevel%
