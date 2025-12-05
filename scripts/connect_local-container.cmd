@echo off
REM ==========================================================
REM Script: Connect to Local Docker Container
REM Description: Opens editor connected to a Docker container on local host
REM ==========================================================

setlocal enabledelayedexpansion

REM Configuration
set CONTAINER_WORK_DIR=/opt/workspace
set CONTAINER_NAME=arcadia-ubuntu

REM Check if Docker is available
where docker >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Docker command not found. Please ensure Docker is installed and in your Path.
    pause
    exit /b 1
)

REM Check if container exists
docker ps -a --filter "name=^%CONTAINER_NAME%$" --format "{{.Names}}" | findstr /C:"%CONTAINER_NAME%" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo WARNING: Container '%CONTAINER_NAME%' not found. Proceeding anyway...
    echo You may need to start the container or check the container name.
    echo.
)

REM Check for Cursor first, then VS Code
REM Checking for available editors...
where cursor >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    set PROGRAM=cursor
) else (
    echo Cursor not found, checking for VS Code...
    where code >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        set PROGRAM=code
    ) else (
        echo ERROR: Neither 'cursor' nor 'code' command found.
        echo Please ensure either Cursor or VS Code is installed and in your Path.
        pause
        exit /b 1
    )
)
echo Found editor: %PROGRAM%
echo.

REM Generate hex-encoded URI from container name
echo Generating docker container URI...
REM Use PowerShell to convert container name to hex
for /f "delims=" %%i in ('powershell -Command "[System.Text.Encoding]::UTF8.GetBytes('%CONTAINER_NAME%') | ForEach-Object { $_.ToString('x2') } | Join-String -Separator ''"') do set URI=%%i
if "!URI!"=="" (
    echo ERROR: Failed to generate container URI
    echo Please check that PowerShell is available.
    pause
    exit /b 1
)
echo.

REM Construct and display the full VS Code remote URI
set FULL_URI=vscode-remote://attached-container+!URI!!CONTAINER_WORK_DIR%
echo Full Local URI:
echo !FULL_URI!
echo.
echo.
echo Connecting to Local Docker Container...
echo.
echo Program: %PROGRAM%
echo Container: %CONTAINER_NAME%
echo Work Directory: %CONTAINER_WORK_DIR%
echo.

REM Launch PROGRAM
%PROGRAM% --folder-uri "!FULL_URI!"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Failed to launch %PROGRAM% (exit code: %ERRORLEVEL%)
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo %PROGRAM% launched successfully!
endlocal
