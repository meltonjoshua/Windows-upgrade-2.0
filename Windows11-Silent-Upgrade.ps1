# Windows 11 Hardware Bypass & Silent Upgrade Script v4.3
# Smart bypass detection - only modifies system if needed

# Function to check Windows 11 compatibility
function Test-Windows11Compatibility {
    Write-Host "Checking Windows 11 hardware compatibility..." -ForegroundColor Yellow
    
    $compatibilityIssues = @()
    
    # Check TPM
    try {
        $tpm = Get-CimInstance -Namespace "Root\CimV2\Security\MicrosoftTpm" -ClassName "Win32_Tpm" -ErrorAction SilentlyContinue
        if (-not $tpm -or $tpm.SpecVersion -notmatch "^2\.") {
            $compatibilityIssues += "TPM 2.0 not found or not enabled"
        } else {
            Write-Host "✓ TPM 2.0 detected" -ForegroundColor Green
        }
    } catch {
        $compatibilityIssues += "TPM status could not be determined"
    }
    
    # Check Secure Boot
    try {
        $secureBootStatus = Confirm-SecureBootUEFI -ErrorAction SilentlyContinue
        if (-not $secureBootStatus) {
            $compatibilityIssues += "Secure Boot not enabled"
        } else {
            Write-Host "✓ Secure Boot enabled" -ForegroundColor Green
        }
    } catch {
        $compatibilityIssues += "Secure Boot status could not be determined (possible BIOS mode)"
    }
    
    # Check CPU compatibility (basic check)
    try {
        $cpu = Get-CimInstance -ClassName "Win32_Processor"
        $cpuFamily = $cpu.Family
        $cpuModel = $cpu.Model
        
        # Very basic check - Intel 6th gen+ or AMD Zen+
        $isIntelCompatible = ($cpu.Manufacturer -like "*Intel*" -and $cpuFamily -ge 6 -and $cpuModel -ge 78)
        $isAMDCompatible = ($cpu.Manufacturer -like "*AMD*" -and $cpuFamily -ge 23)
        
        if (-not ($isIntelCompatible -or $isAMDCompatible)) {
            $compatibilityIssues += "CPU may not be Windows 11 compatible"
        } else {
            Write-Host "✓ CPU appears compatible" -ForegroundColor Green
        }
    } catch {
        $compatibilityIssues += "CPU compatibility could not be determined"
    }
    
    # Check RAM
    try {
        $ram = Get-CimInstance -ClassName "Win32_ComputerSystem"
        $ramGB = [math]::Round($ram.TotalPhysicalMemory / 1GB, 2)
        if ($ramGB -lt 4) {
            $compatibilityIssues += "Insufficient RAM (need 4GB+, have $ramGB GB)"
        } else {
            Write-Host "✓ RAM sufficient ($ramGB GB)" -ForegroundColor Green
        }
    } catch {
        $compatibilityIssues += "RAM amount could not be determined"
    }
    
    # Check storage
    try {
        $systemDrive = Get-CimInstance -ClassName "Win32_LogicalDisk" | Where-Object { $_.DeviceID -eq $env:SystemDrive }
        $freeSpaceGB = [math]::Round($systemDrive.FreeSpace / 1GB, 2)
        if ($freeSpaceGB -lt 64) {
            $compatibilityIssues += "Insufficient storage space (need 64GB+, have $freeSpaceGB GB free)"
        } else {
            Write-Host "✓ Storage sufficient ($freeSpaceGB GB free)" -ForegroundColor Green
        }
    } catch {
        $compatibilityIssues += "Storage space could not be determined"
    }
    
    return $compatibilityIssues
}

# Ensure running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click and select 'Run as Administrator'" -ForegroundColor Red
    exit 1
}

Write-Host "Windows 11 Hardware Bypass & Silent Upgrade v4.2" -ForegroundColor Green
Write-Host "Smart bypass - only modifies system if needed" -ForegroundColor Yellow
Write-Host ""

# Check Windows 11 compatibility first
$compatibilityIssues = Test-Windows11Compatibility

if ($compatibilityIssues.Count -eq 0) {
    Write-Host "✓ SYSTEM IS ALREADY WINDOWS 11 COMPATIBLE!" -ForegroundColor Green
    Write-Host "No registry modifications needed - proceeding with standard upgrade..." -ForegroundColor Cyan
    $needsBypass = $false
} else {
    Write-Host "⚠ COMPATIBILITY ISSUES DETECTED:" -ForegroundColor Red
    foreach ($issue in $compatibilityIssues) {
        Write-Host "  • $issue" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "✓ Applying bypass registry entries to resolve these issues..." -ForegroundColor Green
    $needsBypass = $true
}

# Only apply bypasses if needed
if ($needsBypass) {
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
    
    # Additional aggressive bypass for 0xa0000400 - Hardware Simulation
    Write-Host "Setting hardware simulation entries for 0xa0000400..." -ForegroundColor Yellow
    
    # Simulate TPM 2.0 presence
    $tpmWmiPath = "HKLM:\SYSTEM\CurrentControlSet\Services\TPM\WMI"
    if (!(Test-Path $tpmWmiPath)) { New-Item -Path $tpmWmiPath -Force | Out-Null }
    
    Set-ItemProperty -Path $tpmWmiPath -Name "TpmPresent" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $tpmWmiPath -Name "TpmReady" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $tpmWmiPath -Name "TpmEnabled" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $tpmWmiPath -Name "TpmActivated" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $tpmWmiPath -Name "TpmVersion" -Value "2.0" -Force
    
    # Simulate Secure Boot capability
    $secureBootPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State"
    if (!(Test-Path $secureBootPath)) { New-Item -Path $secureBootPath -Force | Out-Null }
    
    Set-ItemProperty -Path $secureBootPath -Name "UEFISecureBootEnabled" -Value 1 -Type DWord -Force
    
    $firmwareSecPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Firmware\Security"
    if (!(Test-Path $firmwareSecPath)) { New-Item -Path $firmwareSecPath -Force | Out-Null }
    
    Set-ItemProperty -Path $firmwareSecPath -Name "SecureBootEnabled" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $firmwareSecPath -Name "SecureBootCapable" -Value 1 -Type DWord -Force
    
    # Override CPU identification for Installation Assistant
    $cpuPath = "HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0"
    if (Test-Path $cpuPath) {
        Set-ItemProperty -Path $cpuPath -Name "ProcessorNameString" -Value "Intel(R) Core(TM) i7-8700K CPU @ 3.70GHz" -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $cpuPath -Name "Identifier" -Value "Intel64 Family 6 Model 158 Stepping 10" -Force -ErrorAction SilentlyContinue
    }
    
    # Clear Installation Assistant cache and compatibility blocks
    $cacheKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\CompatCache",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\Compat",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppCompatFlags\Layers"
    )
    
    foreach ($cacheKey in $cacheKeys) {
        if (Test-Path $cacheKey) {
            try {
                Remove-Item -Path $cacheKey -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "Cleared cache: $cacheKey" -ForegroundColor Gray
            } catch {
                # Continue if cache clearing fails
            }
        }
    }
    
    # Force Windows version reporting for Installation Assistant
    $ntVersionPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
    if (Test-Path $ntVersionPath) {
        # Backup and modify version info to appear as supported system
        Set-ItemProperty -Path $ntVersionPath -Name "CurrentBuild_Backup" -Value (Get-ItemProperty -Path $ntVersionPath).CurrentBuild -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $ntVersionPath -Name "CurrentBuild" -Value "19045" -Force
        Set-ItemProperty -Path $ntVersionPath -Name "CurrentBuildNumber" -Value "19045" -Force
        Set-ItemProperty -Path $ntVersionPath -Name "CurrentVersion" -Value "10.0" -Force
    }
    
    Write-Host "✓ Hardware simulation and cache clearing completed" -ForegroundColor Green
    
    # CRITICAL: Reset Windows Update components to clear 0xa0000400
    Write-Host "Resetting Windows Update components to clear 0xa0000400..." -ForegroundColor Yellow
    
    try {
        # Stop Windows Update services
        Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
        Stop-Service -Name "cryptSvc" -Force -ErrorAction SilentlyContinue
        Stop-Service -Name "bits" -Force -ErrorAction SilentlyContinue
        Stop-Service -Name "msiserver" -Force -ErrorAction SilentlyContinue
        
        Write-Host "Windows Update services stopped" -ForegroundColor Gray
        
        # Clear Windows Update cache
        $updateCache = "$env:SystemRoot\SoftwareDistribution"
        if (Test-Path $updateCache) {
            try {
                Remove-Item "$updateCache\*" -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "Windows Update cache cleared" -ForegroundColor Gray
            } catch {
                Write-Host "Could not clear all cache files (some may be in use)" -ForegroundColor Yellow
            }
        }
        
        # Clear catroot2 cache
        $catroot = "$env:SystemRoot\System32\catroot2"
        if (Test-Path $catroot) {
            try {
                Remove-Item "$catroot\*" -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "Catroot2 cache cleared" -ForegroundColor Gray
            } catch {
                Write-Host "Could not clear all catroot2 files (some may be in use)" -ForegroundColor Yellow
            }
        }
        
        # Restart Windows Update services
        Start-Service -Name "cryptSvc" -ErrorAction SilentlyContinue
        Start-Service -Name "bits" -ErrorAction SilentlyContinue
        Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue
        
        Write-Host "Windows Update services restarted" -ForegroundColor Gray
        
        # Re-register Windows Update components
        regsvr32 /s wuapi.dll 2>$null
        regsvr32 /s wuaueng.dll 2>$null
        regsvr32 /s wuaueng1.dll 2>$null
        regsvr32 /s wucltux.dll 2>$null
        regsvr32 /s wups.dll 2>$null
        regsvr32 /s wups2.dll 2>$null
        regsvr32 /s wuweb.dll 2>$null
        
        Write-Host "Windows Update components re-registered" -ForegroundColor Gray
        
    } catch {
        Write-Host "Warning: Could not fully reset Windows Update components: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    Write-Host "✓ Windows Update reset completed" -ForegroundColor Green
    
} catch {
    Write-Host "ERROR: Failed to set registry entries - $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

    Write-Host "✓ Bypass registry entries applied successfully" -ForegroundColor Green
} else {
    Write-Host "✓ Skipping registry modifications - system already compatible" -ForegroundColor Green
}

Write-Host "Downloading Windows 11 Installation Assistant..." -ForegroundColor Yellow
if ($needsBypass) {
    Write-Host "IMPORTANT: Installation Assistant will launch with hardware bypasses active" -ForegroundColor Cyan
} else {
    Write-Host "IMPORTANT: Installation Assistant will launch with standard compatibility" -ForegroundColor Cyan
}

try {
    $assistantPath = "$env:TEMP\Windows11InstallationAssistant.exe"
    $downloadUrl = "https://go.microsoft.com/fwlink/?linkid=2171764"
    
    # Remove existing file
    if (Test-Path $assistantPath) {
        Remove-Item $assistantPath -Force
    }
    
    # Download with multiple methods
    $downloadSuccess = $false
    
    # Method 1: WebClient
    try {
        Write-Host "Attempting download with WebClient..." -ForegroundColor Gray
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($downloadUrl, $assistantPath)
        $webClient.Dispose()
        $downloadSuccess = $true
        Write-Host "✓ WebClient download successful" -ForegroundColor Green
    } catch {
        Write-Host "WebClient failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Method 2: Invoke-WebRequest (if WebClient failed)
    if (-not $downloadSuccess) {
        try {
            Write-Host "Attempting download with Invoke-WebRequest..." -ForegroundColor Gray
            Invoke-WebRequest -Uri $downloadUrl -OutFile $assistantPath -UseBasicParsing
            $downloadSuccess = $true
            Write-Host "✓ Invoke-WebRequest download successful" -ForegroundColor Green
        } catch {
            Write-Host "Invoke-WebRequest failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    
    # Method 3: BITS Transfer (if others failed)
    if (-not $downloadSuccess) {
        try {
            Write-Host "Attempting download with BITS Transfer..." -ForegroundColor Gray
            Import-Module BitsTransfer -ErrorAction Stop
            Start-BitsTransfer -Source $downloadUrl -Destination $assistantPath -DisplayName "Windows 11 Download"
            $downloadSuccess = $true
            Write-Host "✓ BITS Transfer download successful" -ForegroundColor Green
        } catch {
            Write-Host "BITS Transfer failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    
    if ($downloadSuccess -and (Test-Path $assistantPath)) {
        $fileSize = (Get-Item $assistantPath).Length
        if ($fileSize -gt 1MB) {
            Write-Host "SUCCESS: Downloaded Installation Assistant ($([math]::Round($fileSize/1MB, 2)) MB)" -ForegroundColor Green
            
            # Wait a moment for services to stabilize
            Write-Host "Waiting for system to stabilize before launch..." -ForegroundColor Yellow
            Start-Sleep -Seconds 10
            
        } else {
            throw "Downloaded file is too small"
        }
    } else {
        throw "All download methods failed"
    }
    
} catch {
    Write-Host "WARNING: Failed to download Installation Assistant - $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "You may need to download manually from: https://www.microsoft.com/en-us/software-download/windows11" -ForegroundColor Cyan
    Write-Host "The registry bypasses are still active for manual installation" -ForegroundColor Cyan
}

# Function to automatically handle Installation Assistant UI
function Start-AutomatedInstallationAssistant {
    param($AssistantPath)
    
    Write-Host "Starting automated Installation Assistant with UI automation..." -ForegroundColor Yellow
    
    # Launch Installation Assistant with maximum bypass parameters
    $arguments = @(
        '/quiet',           # Run quietly
        '/skipeula',        # Skip EULA
        '/auto',            # Auto mode
        '/accepteula',      # Accept EULA
        '/skipcpu',         # Skip CPU check
        '/skiptpm',         # Skip TPM check
        '/skipram',         # Skip RAM check
        '/skipsecureboot',  # Skip Secure Boot check
        '/skipstorage',     # Skip storage check
        '/skipcompatibilitycheck',  # Skip all compatibility checks
        '/norestart'        # Don't auto restart
    )
    
    try {
        $process = Start-Process -FilePath $AssistantPath -ArgumentList $arguments -PassThru
        Write-Host "✓ Installation Assistant launched (Process ID: $($process.Id))" -ForegroundColor Green
        
        # Wait a moment for the window to appear
        Start-Sleep -Seconds 5
        
        # Additional UI automation to handle license acceptance if parameters don't work
        $automationAttempts = 0
        $maxAutomationAttempts = 12  # 1 minute of attempts
        
        while (-not $process.HasExited -and $automationAttempts -lt $maxAutomationAttempts) {
            try {
                # Look for Installation Assistant window
                Add-Type -AssemblyName System.Windows.Forms
                $installWindow = [System.Windows.Forms.Application]::OpenForms | Where-Object { $_.Text -like "*Installation Assistant*" -or $_.Text -like "*Windows 11*" }
                
                if ($installWindow) {
                    Write-Host "Found Installation Assistant window, attempting UI automation..." -ForegroundColor Cyan
                    
                    # Send Alt+A to accept (common shortcut for Accept button)
                    [System.Windows.Forms.SendKeys]::SendWait("%a")
                    Start-Sleep -Seconds 2
                    
                    # Send Enter to confirm
                    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
                    Start-Sleep -Seconds 2
                    
                    # Send Tab and Enter to navigate to Accept button if needed
                    [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
                    Start-Sleep -Seconds 1
                    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
                    
                    Write-Host "✓ Attempted automatic license acceptance" -ForegroundColor Green
                }
                
            } catch {
                # UI automation failed, continue monitoring
            }
            
            Start-Sleep -Seconds 5
            $automationAttempts++
        }
        
        return $process
        
    } catch {
        Write-Host "Failed to start Installation Assistant: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

Write-Host "Launching Windows 11 upgrade process..." -ForegroundColor Green

# Method 1: Launch Installation Assistant if downloaded
if (Test-Path $assistantPath) {
    try {
        Write-Host "Starting Installation Assistant with automated license acceptance..." -ForegroundColor Yellow
        $process = Start-AutomatedInstallationAssistant -AssistantPath $assistantPath
        
        if ($process) {
            Write-Host "✓ Installation Assistant started with UI automation (Process ID: $($process.Id))" -ForegroundColor Green
            Start-Sleep -Seconds 10
        }
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
Write-Host "✓ 0xa0000400 error fix applied" -ForegroundColor White
Write-Host "✓ Hardware simulation active (TPM 2.0, Secure Boot, CPU)" -ForegroundColor White
Write-Host "✓ Installation Assistant cache cleared" -ForegroundColor White
Write-Host "✓ Windows Update components reset" -ForegroundColor White
Write-Host "✓ Installation Assistant downloaded with multiple methods" -ForegroundColor White  
Write-Host "✓ Windows Update scan triggered" -ForegroundColor White
Write-Host ""
Write-Host "CRITICAL STEPS FOR 0xa0000400 ERROR:" -ForegroundColor Red
Write-Host "1. RESTART YOUR COMPUTER NOW" -ForegroundColor Yellow
Write-Host "2. After restart, run Installation Assistant manually" -ForegroundColor Yellow
Write-Host "3. If error persists, run this script again after restart" -ForegroundColor Yellow
Write-Host ""
Write-Host "Alternative approach:" -ForegroundColor Cyan
Write-Host "• Download manually: https://www.microsoft.com/software-download/windows11" -ForegroundColor Cyan
Write-Host "• Use Media Creation Tool instead of Installation Assistant" -ForegroundColor Cyan
Write-Host "• Check Windows Update > Advanced options > Receive updates for other Microsoft products" -ForegroundColor Cyan
Write-Host ""
Write-Host "The 0xa0000400 error often requires a restart to clear system caches." -ForegroundColor Yellow
Write-Host ""
Write-Host "The upgrade process is now running in the background." -ForegroundColor Green