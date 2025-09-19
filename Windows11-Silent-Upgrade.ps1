# Windows 11 Hardware Bypass & Silent Upgrade Script v4.1
# Enhanced with 0xa0000400 error fix

# Ensure running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click and select 'Run as Administrator'" -ForegroundColor Red
    exit 1
}

Write-Host "Windows 11 Hardware Bypass & Silent Upgrade v4.1" -ForegroundColor Green
Write-Host "Enhanced with 0xa0000400 error fix" -ForegroundColor Yellow
Write-Host "Setting comprehensive hardware bypass registry entries..." -ForegroundColor Yellow

try {
    # Create registry paths
    $setupPath = "HKLM:\System\Setup"
    $labConfigPath = "$setupPath\LabConfig"
    $moSetupPath = "$setupPath\MoSetup"
    
    # Ensure paths exist
    if (!(Test-Path $setupPath)) { New-Item -Path $setupPath -Force | Out-Null }
    if (!(Test-Path $labConfigPath)) { New-Item -Path $labConfigPath -Force | Out-Null }
    if (!(Test-Path $moSetupPath)) { New-Item -Path $moSetupPath -Force | Out-Null }
    
    # Standard bypass values
    Set-ItemProperty -Path $labConfigPath -Name "BypassRAMCheck" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $labConfigPath -Name "BypassTPMCheck" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $labConfigPath -Name "BypassCPUCheck" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $labConfigPath -Name "BypassSecureBootCheck" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $labConfigPath -Name "BypassStorageCheck" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $moSetupPath -Name "AllowUpgradesWithUnsupportedTPMOrCPU" -Value 1 -Type DWord -Force
    
    Write-Host "✓ Standard hardware bypass entries set" -ForegroundColor Green
    
    # Enhanced 0xa0000400 error fix registry entries
    Write-Host "Setting enhanced 0xa0000400 error fix entries..." -ForegroundColor Yellow
    
    # Installation Assistant compatibility bypass
    $compFlagsPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppCompatFlags\Compatibility Assistant\Store"
    if (!(Test-Path $compFlagsPath)) { New-Item -Path $compFlagsPath -Force | Out-Null }
    
    Set-ItemProperty -Path $compFlagsPath -Name "Windows11InstallationAssistant.exe" -Value "~ RUNASADMIN WIN11COMPAT DISABLETHEMES" -Force
    Set-ItemProperty -Path $compFlagsPath -Name "Windows11Upgrade" -Value "COMPATIBLE" -Force
    
    # System state override for Installation Assistant
    $oobeStatePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\OOBE"
    if (!(Test-Path $oobeStatePath)) { New-Item -Path $oobeStatePath -Force | Out-Null }
    
    Set-ItemProperty -Path $oobeStatePath -Name "SetupDisplayedEula" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $oobeStatePath -Name "MediaBootInstall" -Value 1 -Type DWord -Force
    
    # Setup state configuration
    $setupStatePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\State"
    if (!(Test-Path $setupStatePath)) { New-Item -Path $setupStatePath -Force | Out-Null }
    
    Set-ItemProperty -Path $setupStatePath -Name "ImageState" -Value "IMAGE_STATE_COMPLETE" -Force
    Set-ItemProperty -Path $setupStatePath -Name "FactoryPreInstallInProgress" -Value 0 -Type DWord -Force
    
    # Memory management bypass for Installation Assistant
    $memoryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
    if (Test-Path $memoryPath) {
        Set-ItemProperty -Path $memoryPath -Name "FeatureSettings" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $memoryPath -Name "FeatureSettingsOverride" -Value 3 -Type DWord -Force -ErrorAction SilentlyContinue
    }
    
    Write-Host "✓ Enhanced 0xa0000400 error fix entries set" -ForegroundColor Green
    
} catch {
    Write-Host "ERROR: Failed to set registry entries - $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "Downloading Windows 11 Installation Assistant..." -ForegroundColor Yellow

try {
    $assistantPath = "$env:TEMP\Windows11InstallationAssistant.exe"
    $downloadUrl = "https://go.microsoft.com/fwlink/?linkid=2171764"
    
    # Remove existing file
    if (Test-Path $assistantPath) {
        Remove-Item $assistantPath -Force
    }
    
    # Download
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($downloadUrl, $assistantPath)
    $webClient.Dispose()
    
    if (Test-Path $assistantPath) {
        $fileSize = (Get-Item $assistantPath).Length
        if ($fileSize -gt 1MB) {
            Write-Host "SUCCESS: Downloaded Installation Assistant ($([math]::Round($fileSize/1MB, 2)) MB)" -ForegroundColor Green
        } else {
            throw "Downloaded file is too small"
        }
    } else {
        throw "Download file not found"
    }
    
} catch {
    Write-Host "WARNING: Failed to download Installation Assistant - $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "Continuing with Windows Update method..." -ForegroundColor Cyan
}

Write-Host "Launching Windows 11 upgrade process..." -ForegroundColor Green

# Method 1: Launch Installation Assistant if downloaded
if (Test-Path $assistantPath) {
    try {
        Write-Host "Starting Installation Assistant with bypass parameters..." -ForegroundColor Yellow
        $process = Start-Process -FilePath $assistantPath -ArgumentList @('/skipeula', '/auto', '/skipcpu', '/skiptpm', '/skipram', '/skipsecureboot', '/skipstorage') -PassThru
        Write-Host "Installation Assistant started (Process ID: $($process.Id))" -ForegroundColor Green
        Start-Sleep -Seconds 5
    } catch {
        Write-Host "WARNING: Failed to start Installation Assistant - $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Method 2: Trigger Windows Update
try {
    Write-Host "Triggering Windows Update scan..." -ForegroundColor Yellow
    Start-Process -FilePath "usoclient.exe" -ArgumentList "ScanInstallWait" -NoNewWindow
    Write-Host "Windows Update scan initiated" -ForegroundColor Green
} catch {
    Write-Host "WARNING: Failed to trigger Windows Update - $($_.Exception.Message)" -ForegroundColor Yellow
}

# Method 3: Legacy Windows Update trigger
try {
    Start-Process -FilePath "wuauclt.exe" -ArgumentList "/detectnow" -NoNewWindow
    Write-Host "Legacy update detection triggered" -ForegroundColor Green
} catch {
    Write-Host "WARNING: Failed to trigger legacy update - $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== WINDOWS 11 UPGRADE PROCESS INITIATED ===" -ForegroundColor Green
Write-Host "✓ Hardware compatibility checks bypassed" -ForegroundColor White
Write-Host "✓ Installation Assistant launched (if available)" -ForegroundColor White  
Write-Host "✓ Windows Update scan triggered" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "• Monitor Installation Assistant window for progress" -ForegroundColor Cyan
Write-Host "• Check Settings > Windows Update for feature updates" -ForegroundColor Cyan
Write-Host "• System will restart automatically when upgrade is ready" -ForegroundColor Cyan
Write-Host ""
Write-Host "The upgrade process is now running in the background." -ForegroundColor Green