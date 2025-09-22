# Windows 11 Auto-Upgrade Launcher
# Handles the PostRestart parameter for the auto-upgrade script

# Check if PostRestart parameter was passed via URL or environment
$isPostRestart = $false

# Check environment variable (set by scheduled task)
if ($env:WIN11_POST_RESTART -eq "1") {
    $isPostRestart = $true
}

# Check if running from scheduled task
$currentProcess = Get-WmiObject Win32_Process -Filter "ProcessId = $PID"
if ($currentProcess.CommandLine -like "*PostRestart*") {
    $isPostRestart = $true
}

# Download and execute the main script with appropriate parameter
if ($isPostRestart) {
    Write-Host "Launching POST-RESTART phase..." -ForegroundColor Green
    $env:WIN11_POST_RESTART = "1"
    Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/meltonjoshua/Windows-upgrade-2.0/main/Windows11-Auto-Upgrade.ps1" -UseBasicParsing).Content
} else {
    Write-Host "Launching PRE-RESTART phase..." -ForegroundColor Yellow
    $env:WIN11_POST_RESTART = "0"
    Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/meltonjoshua/Windows-upgrade-2.0/main/Windows11-Auto-Upgrade.ps1" -UseBasicParsing).Content
}