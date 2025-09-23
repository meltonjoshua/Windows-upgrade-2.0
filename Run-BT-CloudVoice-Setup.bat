@echo off
REM BT CloudVoice Credential Manager Launcher
REM Perfect layout for storing BT CloudVoice login details

echo ==========================================
echo BT CloudVoice Credential Manager v1.0
echo Perfect Layout for Login Details Storage
echo ==========================================
echo.

REM Check for PowerShell
where powershell >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: PowerShell not found in PATH
    echo Please ensure PowerShell is installed and accessible
    pause
    exit /b 1
)

REM Check for Administrator privileges
net session >nul 2>nul
if %errorlevel% neq 0 (
    echo WARNING: Not running as Administrator
    echo Some features may be limited
    echo.
    echo Recommendation: Right-click this file and select "Run as administrator"
    echo.
    pause
)

echo Starting BT CloudVoice Credential Manager...
echo.

REM Set PowerShell execution policy for this session
powershell.exe -Command "Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force"

REM Run the setup example script
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0BT-CloudVoice-Setup-Example.ps1"

if %errorlevel% neq 0 (
    echo.
    echo ERROR: Script execution failed with error code %errorlevel%
    echo.
    echo Troubleshooting steps:
    echo 1. Ensure PowerShell execution policy allows script execution
    echo 2. Run as Administrator if permission errors occur
    echo 3. Check the log files in %%APPDATA%%\BTCloudVoice\Logs\
    echo 4. Review the documentation in BT-CloudVoice-Documentation.md
    echo.
) else (
    echo.
    echo SUCCESS: BT CloudVoice Credential Manager setup completed
    echo.
    echo Next steps:
    echo 1. Review the stored credentials
    echo 2. Test connections to your BT CloudVoice environments
    echo 3. Create regular backups of your credentials
    echo 4. Review the documentation for advanced features
    echo.
)

echo.
echo Log files location: %APPDATA%\BTCloudVoice\Logs\
echo Documentation: %~dp0BT-CloudVoice-Documentation.md
echo.
pause