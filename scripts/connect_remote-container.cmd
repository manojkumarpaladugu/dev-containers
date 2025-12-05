
@echo off
REM ==========================================================
REM Script: Connect to Remote Docker Container via SSH
REM Description: Opens editor connected to a Docker container on a remote host
REM ==========================================================

setlocal enabledelayedexpansion

REM Configuration
set REMOTE_HOST=pun-mapaladugu-arc
set CONTAINER_WORK_DIR=/opt/workspace
set CONTAINER_NAME=arcadia-ubuntu

REM Check if SSH is available
where ssh >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: SSH command not found. Please ensure OpenSSH is installed.
    pause
    exit /b 1
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

REM Test SSH connection
echo Testing SSH connection...
ssh -o ConnectTimeout=5 -o BatchMode=yes %REMOTE_HOST% "echo Connection successful" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo WARNING: Could not establish SSH connection. Proceeding anyway...
    echo You may need to authenticate or check your SSH configuration.
    echo.
)

REM Generate hex-encoded URI from container name
echo Generating docker container URI...
set URI=
for /f "delims=" %%i in ('ssh %REMOTE_HOST% "echo -n %CONTAINER_NAME% | od -An -t x1 | tr -d ' \n'"') do set URI=%%i
if "!URI!"=="" (
    echo ERROR: Failed to generate container URI
    echo Please check that the remote host has 'od' and 'tr' commands available.
    pause
    exit /b 1
)

echo.

REM Construct and display the full VS Code remote URI
set FULL_URI=vscode-remote://attached-container+!URI!%@ssh-remote+%REMOTE_HOST%%CONTAINER_WORK_DIR%
echo Full Remote URI:
echo !FULL_URI!
echo.
echo.
echo Connecting to Remote Docker Container...
echo.
echo Program: %PROGRAM%
echo Remote Host: %REMOTE_HOST%
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