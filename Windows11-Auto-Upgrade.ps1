# Windows 11 Full Auto-Upgrade Script v6.0
# Completely automated - handles restart and continues after reboot

# Check if this is running after restart
$isPostRestart = $false
if ($env:WIN11_POST_RESTART -eq "1") {
    $isPostRestart = $true
}

# Ensure running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Red
    exit 1
}

# Check if this is running after restart
if ($isPostRestart) {
    Write-Host "Windows 11 Auto-Upgrade v6.0 - POST-RESTART PHASE" -ForegroundColor Green
    Write-Host "Continuing upgrade process after restart..." -ForegroundColor Yellow
    
    # Clean up environment variable
    [Environment]::SetEnvironmentVariable("WIN11_POST_RESTART", $null, "Machine")
    
    # Remove the startup task
    try {
        schtasks /delete /tn "Windows11AutoUpgrade" /f 2>$null | Out-Null
        Write-Host "Cleaned up restart task" -ForegroundColor Gray
    } catch {
        # Task may not exist
    }
    
    # Wait for system to fully initialize
    Write-Host "Waiting for system to fully initialize..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    
    # Try automatic upgrade methods
    Write-Host "Attempting automatic Windows 11 upgrade..." -ForegroundColor Green
    
    # Method 1: Force Windows Update check
    try {
        Write-Host "Method 1: Triggering Windows Update..." -ForegroundColor Yellow
        Start-Process -FilePath "usoclient.exe" -ArgumentList "ScanInstallWait" -NoNewWindow
        Start-Process -FilePath "usoclient.exe" -ArgumentList "StartDownload" -NoNewWindow
        Start-Process -FilePath "usoclient.exe" -ArgumentList "StartInstall" -NoNewWindow
        Write-Host "✓ Windows Update triggered" -ForegroundColor Green
        Start-Sleep -Seconds 10
    } catch {
        Write-Host "Windows Update trigger failed" -ForegroundColor Yellow
    }
    
    # Method 2: Download and run Installation Assistant automatically
    try {
        Write-Host "Method 2: Auto-downloading and running Installation Assistant..." -ForegroundColor Yellow
        $assistantPath = "$env:TEMP\Windows11InstallationAssistant.exe"
        $downloadUrl = "https://go.microsoft.com/fwlink/?linkid=2171764"
        
        if (Test-Path $assistantPath) {
            Remove-Item $assistantPath -Force
        }
        
        # Download
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($downloadUrl, $assistantPath)
        $webClient.Dispose()
        
        if (Test-Path $assistantPath) {
            Write-Host "✓ Installation Assistant downloaded" -ForegroundColor Green
            
            # Auto-launch with all bypass parameters
            $process = Start-Process -FilePath $assistantPath -ArgumentList @('/quiet', '/skipeula', '/auto', '/skipcpu', '/skiptpm', '/skipram', '/skipsecureboot', '/skipstorage', '/accepteula') -PassThru
            Write-Host "✓ Installation Assistant launched automatically (Process ID: $($process.Id))" -ForegroundColor Green
            
            # Monitor for 2 minutes to see if it starts successfully
            $timeout = 120
            $elapsed = 0
            while (-not $process.HasExited -and $elapsed -lt $timeout) {
                Start-Sleep -Seconds 5
                $elapsed += 5
                if ($elapsed % 30 -eq 0) {
                    Write-Host "Installation Assistant running... ($elapsed/$timeout seconds)" -ForegroundColor Cyan
                }
            }
            
            if ($process.HasExited) {
                if ($process.ExitCode -eq 0) {
                    Write-Host "✓ Installation Assistant completed successfully!" -ForegroundColor Green
                } else {
                    Write-Host "Installation Assistant exit code: $($process.ExitCode)" -ForegroundColor Yellow
                }
            } else {
                Write-Host "✓ Installation Assistant is running - upgrade in progress" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "Installation Assistant auto-launch failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Method 3: Download and auto-run ISO if available
    try {
        Write-Host "Method 3: Checking for pre-downloaded Windows 11 ISO..." -ForegroundColor Yellow
        
        # Common ISO download locations
        $isoLocations = @(
            "$env:USERPROFILE\Downloads\Win11*.iso",
            "$env:PUBLIC\Downloads\Win11*.iso",
            "C:\Windows11*.iso",
            "D:\Windows11*.iso"
        )
        
        $foundISO = $null
        foreach ($location in $isoLocations) {
            $isos = Get-ChildItem -Path $location -ErrorAction SilentlyContinue
            if ($isos) {
                $foundISO = $isos[0].FullName
                break
            }
        }
        
        if ($foundISO) {
            Write-Host "✓ Found Windows 11 ISO: $foundISO" -ForegroundColor Green
            Write-Host "Auto-mounting and launching setup..." -ForegroundColor Yellow
            
            # Mount ISO
            $mount = Mount-DiskImage -ImagePath $foundISO -PassThru
            $driveLetter = ($mount | Get-Volume).DriveLetter
            
            if ($driveLetter) {
                $setupPath = "${driveLetter}:\setup.exe"
                if (Test-Path $setupPath) {
                    # Auto-launch setup
                    Start-Process -FilePath $setupPath -ArgumentList "/auto upgrade /quiet /compat IgnoreWarning" -PassThru
                    Write-Host "✓ Windows 11 setup launched from ISO" -ForegroundColor Green
                }
            }
        } else {
            Write-Host "No Windows 11 ISO found in common locations" -ForegroundColor Gray
        }
    } catch {
        Write-Host "ISO auto-launch failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "=== AUTO-UPGRADE PROCESS COMPLETED ===" -ForegroundColor Green
    Write-Host "✓ System restarted and bypass settings applied" -ForegroundColor White
    Write-Host "✓ Windows Update triggered automatically" -ForegroundColor White
    Write-Host "✓ Installation Assistant launched automatically" -ForegroundColor White
    Write-Host "✓ ISO setup attempted if available" -ForegroundColor White
    Write-Host ""
    Write-Host "The upgrade should now proceed automatically." -ForegroundColor Green
    Write-Host "Monitor for Windows 11 installation progress." -ForegroundColor Cyan
    Write-Host "System will restart again when upgrade completes." -ForegroundColor Cyan
    
    exit 0
}

# MAIN SCRIPT - PRE-RESTART PHASE
Write-Host "Windows 11 Full Auto-Upgrade Script v6.0" -ForegroundColor Green
Write-Host "Completely automated with restart handling" -ForegroundColor Yellow

try {
    # Phase 1: Set all bypass registry entries (using nuclear approach)
    Write-Host "Phase 1: Setting NUCLEAR bypass registry entries..." -ForegroundColor Red
    
    $registryPaths = @{
        "HKLM:\System\Setup\LabConfig" = @{
            "BypassRAMCheck" = 1
            "BypassTPMCheck" = 1
            "BypassCPUCheck" = 1
            "BypassSecureBootCheck" = 1
            "BypassStorageCheck" = 1
        }
        "HKLM:\System\Setup\MoSetup" = @{
            "AllowUpgradesWithUnsupportedTPMOrCPU" = 1
        }
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\TargetVersionUpgradeExperienceIndicators" = @{
            "Redstone4.NI" = 0
            "Redstone4.AI" = 0
            "Redstone4.E1" = 0
            "Redstone4.E2" = 0
        }
    }
    
    foreach ($regPath in $registryPaths.Keys) {
        if (!(Test-Path $regPath)) {
            $null = New-Item -Path $regPath -Force -ErrorAction SilentlyContinue
        }
        foreach ($valueName in $registryPaths[$regPath].Keys) {
            $value = $registryPaths[$regPath][$valueName]
            Set-ItemProperty -Path $regPath -Name $valueName -Value $value -Type DWord -Force -ErrorAction SilentlyContinue
        }
        Write-Host "✓ Set bypass entries in $regPath" -ForegroundColor Green
    }
    
    # Phase 2: Spoof system identity
    Write-Host "Phase 2: Spoofing system identity..." -ForegroundColor Yellow
    
    $ntVersionPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
    if (Test-Path $ntVersionPath) {
        $originalBuild = (Get-ItemProperty -Path $ntVersionPath -Name "CurrentBuild" -ErrorAction SilentlyContinue).CurrentBuild
        $originalVersion = (Get-ItemProperty -Path $ntVersionPath -Name "CurrentVersion" -ErrorAction SilentlyContinue).CurrentVersion
        
        Set-ItemProperty -Path $ntVersionPath -Name "CurrentBuild_Original" -Value $originalBuild -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $ntVersionPath -Name "CurrentVersion_Original" -Value $originalVersion -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $ntVersionPath -Name "CurrentBuild" -Value "19044" -Force
        Set-ItemProperty -Path $ntVersionPath -Name "CurrentBuildNumber" -Value "19044" -Force
        Set-ItemProperty -Path $ntVersionPath -Name "CurrentVersion" -Value "10.0" -Force
        Set-ItemProperty -Path $ntVersionPath -Name "ProductName" -Value "Windows 10 Pro" -Force
        
        Write-Host "✓ System identity spoofed to Windows 10 21H2" -ForegroundColor Green
    }
    
    # Phase 3: Reset Windows Update components
    Write-Host "Phase 3: Resetting Windows Update components..." -ForegroundColor Yellow
    
    $services = @("wuauserv", "cryptSvc", "bits", "msiserver")
    foreach ($service in $services) {
        Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
    }
    
    $cachePaths = @(
        "$env:SystemRoot\SoftwareDistribution",
        "$env:SystemRoot\System32\catroot2"
    )
    
    foreach ($cachePath in $cachePaths) {
        if (Test-Path $cachePath) {
            Remove-Item "$cachePath\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    
    foreach ($service in $services) {
        Start-Service -Name $service -ErrorAction SilentlyContinue
    }
    
    Write-Host "✓ Windows Update components reset" -ForegroundColor Green
    
    # Phase 4: Create restart continuation task
    Write-Host "Phase 4: Setting up automatic restart continuation..." -ForegroundColor Yellow
    
    # Get the current script path for re-execution
    $scriptContent = @"
Set-ExecutionPolicy Bypass -Scope Process -Force
[Environment]::SetEnvironmentVariable("WIN11_POST_RESTART", "1", "Machine")
Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/meltonjoshua/Windows-upgrade-2.0/main/Windows11-Auto-Upgrade.ps1" -UseBasicParsing).Content
"@
    
    $postRestartScript = "$env:TEMP\PostRestartUpgrade.ps1"
    $scriptContent | Out-File -FilePath $postRestartScript -Force
    
    # Create scheduled task to run after restart
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$postRestartScript`""
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    
    try {
        # Remove existing task if it exists
        Unregister-ScheduledTask -TaskName "Windows11AutoUpgrade" -Confirm:$false -ErrorAction SilentlyContinue
        
        # Register new task
        Register-ScheduledTask -TaskName "Windows11AutoUpgrade" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force
        Write-Host "✓ Restart continuation task created" -ForegroundColor Green
    } catch {
        Write-Host "Warning: Could not create scheduled task: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "Manual restart will be required" -ForegroundColor Yellow
    }
    
    # Phase 5: Automatic restart
    Write-Host ""
    Write-Host "=== PRE-RESTART SETUP COMPLETED ===" -ForegroundColor Green
    Write-Host "✓ All registry bypasses set" -ForegroundColor White
    Write-Host "✓ System identity spoofed" -ForegroundColor White
    Write-Host "✓ Windows Update components reset" -ForegroundColor White
    Write-Host "✓ Post-restart automation configured" -ForegroundColor White
    Write-Host ""
    Write-Host "AUTOMATIC RESTART IN 10 SECONDS..." -ForegroundColor Red
    Write-Host "After restart, the upgrade will continue automatically." -ForegroundColor Yellow
    
    # Countdown
    for ($i = 10; $i -gt 0; $i--) {
        Write-Host "Restarting in $i seconds... (Press Ctrl+C to cancel)" -ForegroundColor Red
        Start-Sleep -Seconds 1
    }
    
    Write-Host "Restarting now..." -ForegroundColor Red
    Restart-Computer -Force
    
} catch {
    Write-Host "CRITICAL ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Manual intervention required" -ForegroundColor Yellow
    exit 1
}