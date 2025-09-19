# Windows 11 Hardware Bypass Script v4.0 - Fix for Error 0xa0000400
# Run this BEFORE launching Windows 11 Installation Assistant

Write-Host "Windows 11 Hardware Bypass - Error 0xa0000400 Fix" -ForegroundColor Cyan
Write-Host "Applying registry bypasses..." -ForegroundColor Yellow

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click and select 'Run as Administrator'" -ForegroundColor Red
    exit 1
}

try {
    # Primary bypass registry keys
    $regPaths = @{
        "HKLM:\SYSTEM\Setup\MoSetup" = @{ "AllowUpgradesWithUnsupportedTPMOrCPU" = 1 }
        "HKLM:\SYSTEM\Setup\LabConfig" = @{
            "BypassTPMCheck" = 1
            "BypassSecureBootCheck" = 1  
            "BypassRAMCheck" = 1
            "BypassStorageCheck" = 1
            "BypassCPUCheck" = 1
        }
    }
    
    foreach ($path in $regPaths.Keys) {
        if (!(Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
            Write-Host "Created: $path" -ForegroundColor Green
        }
        
        foreach ($name in $regPaths[$path].Keys) {
            $value = $regPaths[$path][$name]
            Set-ItemProperty -Path $path -Name $name -Value $value -Type DWord -Force
            Write-Host "Set: $path\$name = $value" -ForegroundColor Gray
        }
    }
    
    Write-Host "SUCCESS: All registry bypasses applied!" -ForegroundColor Green
    Write-Host "You can now run Windows 11 Installation Assistant" -ForegroundColor Yellow
    Write-Host "The 0xa0000400 error should be resolved" -ForegroundColor Green
    
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
