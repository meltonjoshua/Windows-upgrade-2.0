@echo off
echo Starting Windows 11 Silent Hardware Bypass & Auto-Upgrade...
echo.
echo IMPORTANT: This script must be run as Administrator!
echo.
pause

REM Run PowerShell script with execution policy bypass
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Windows11-Silent-Upgrade.ps1"

echo.
echo Script execution completed.
pause