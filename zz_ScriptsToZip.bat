@echo off
setlocal enabledelayedexpansion

REM --- Config ---
set "sourceDir=scripts"
set "zipFile=scripts.zip"

REM --- Basic checks ---
if not exist "%sourceDir%\" (
	echo [ERROR] Folder "%sourceDir%" not found in: %cd%
	echo.
	pause
	exit /b 1
)

REM --- Remove old zip if it exists ---
if exist "%zipFile%" (
	del /f /q "%zipFile%" >nul 2>&1
)

REM --- Zip using PowerShell ---
powershell -NoLogo -NoProfile -Command ^
	"Compress-Archive -Path '%sourceDir%\*' -DestinationPath '%zipFile%' -Force" >nul 2>&1

REM --- Verify result ---
if exist "%zipFile%" (
	echo [OK] Created "%zipFile%" from "%sourceDir%" in: %cd%
) else (
	echo [ERROR] Failed to create "%zipFile%".
	echo        (PowerShell Compress-Archive may be unavailable or blocked.)
)

echo.
pause
endlocal
