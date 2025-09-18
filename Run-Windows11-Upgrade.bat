@echo off
echo ====================================================
echo   Windows 11 Hardware Bypass ^& Auto-Upgrade v3.0
echo ====================================================
echo.
echo IMPORTANT: This script must be run as Administrator!
echo.
echo New in v3.0:
echo  * Automated with visible progress monitoring
echo  * Enhanced error handling and retry mechanisms
echo  * Comprehensive logging and system validation
echo  * Automatic restart configuration
echo.
echo The script will:
echo  1. Check system compatibility automatically
echo  2. Bypass hardware requirements
echo  3. Download and install Windows 11 with visible progress
echo  4. Restart system automatically when ready
echo.
echo Log file will be created at: %TEMP%\Windows11-Upgrade-Log.txt
echo.
pause

REM Run PowerShell script with execution policy bypass
echo Starting Windows 11 upgrade with visible progress monitoring...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Windows11-Silent-Upgrade.ps1"

echo.
echo Script execution completed.
echo Check the log file for detailed operation status.
pause