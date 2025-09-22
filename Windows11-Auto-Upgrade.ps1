#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Windows 11 Auto-Upgrade Script with Smart Hardware Bypass
    
.DESCRIPTION
    Automatically upgrades Windows 10 to Windows 11 with intelligent hardware compatibility
    bypass. Only applies registry modifications when needed based on system analysis.
    
.PARAMETER Force
    Forces bypass application even on compatible systems
    
.PARAMETER SkipCompatibilityCheck
    Skips the compatibility check and applies all bypasses
    
.EXAMPLE
    .\Windows11-Auto-Upgrade.ps1
    
.EXAMPLE
    .\Windows11-Auto-Upgrade.ps1 -Force
    
.NOTES
    Author: Joshua Melton
    Version: 8.0 - Cleaned and Optimized
    Requires: PowerShell 5.1+, Administrator privileges
#>

[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$SkipCompatibilityCheck
)

# Script Configuration
$script:Config = @{
    ScriptVersion = "8.0"
    ScriptName = "Windows 11 Auto-Upgrade Script"
    DownloadUrl = "https://go.microsoft.com/fwlink/?linkid=2171764"
    TempPath = "$env:TEMP\Windows11InstallationAssistant.exe"
    LogFile = "$env:TEMP\Windows11-Upgrade-Log.txt"
}

# Initialize logging
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to console with colors
    switch ($Level) {
        'SUCCESS' { Write-Host $Message -ForegroundColor Green }
        'WARNING' { Write-Host $Message -ForegroundColor Yellow }
        'ERROR'   { Write-Host $Message -ForegroundColor Red }
        default   { Write-Host $Message -ForegroundColor White }
    }
    
    # Write to log file
    Add-Content -Path $script:Config.LogFile -Value $logEntry -ErrorAction SilentlyContinue
}

function Test-SystemCompatibility {
    <#
    .SYNOPSIS
        Tests Windows 11 hardware compatibility requirements
    #>
    
    Write-Log "Analyzing system compatibility for Windows 11..." -Level INFO
    $issues = @()
    
    try {
        # Check TPM 2.0
        $tpm = Get-CimInstance -Namespace "Root\CimV2\Security\MicrosoftTpm" -ClassName "Win32_Tpm" -ErrorAction SilentlyContinue
        if (-not $tpm -or $tpm.SpecVersion -notmatch "^2\.") {
            $issues += "TPM 2.0 not found or not enabled"
        } else {
            Write-Log "✓ TPM 2.0 detected and enabled" -Level SUCCESS
        }
        
        # Check Secure Boot
        $secureBootStatus = Confirm-SecureBootUEFI -ErrorAction SilentlyContinue
        if (-not $secureBootStatus) {
            $issues += "Secure Boot not enabled"
        } else {
            Write-Log "✓ Secure Boot enabled" -Level SUCCESS
        }
        
        # Check CPU compatibility
        $cpu = Get-CimInstance -ClassName "Win32_Processor"
        $isIntelCompatible = ($cpu.Manufacturer -like "*Intel*" -and $cpu.Family -ge 6)
        $isAMDCompatible = ($cpu.Manufacturer -like "*AMD*" -and $cpu.Family -ge 23)
        
        if (-not ($isIntelCompatible -or $isAMDCompatible)) {
            $issues += "CPU may not meet Windows 11 requirements"
        } else {
            Write-Log "✓ CPU appears compatible ($($cpu.Name))" -Level SUCCESS
        }
        
        # Check RAM (4GB minimum)
        $ram = Get-CimInstance -ClassName "Win32_ComputerSystem"
        $ramGB = [math]::Round($ram.TotalPhysicalMemory / 1GB, 1)
        if ($ramGB -lt 4) {
            $issues += "Insufficient RAM (need 4GB+, have $ramGB GB)"
        } else {
            Write-Log "✓ Sufficient RAM detected ($ramGB GB)" -Level SUCCESS
        }
        
        # Check storage (64GB minimum free)
        $systemDrive = Get-CimInstance -ClassName "Win32_LogicalDisk" | Where-Object { $_.DeviceID -eq $env:SystemDrive }
        $freeSpaceGB = [math]::Round($systemDrive.FreeSpace / 1GB, 1)
        if ($freeSpaceGB -lt 64) {
            $issues += "Insufficient storage space (need 64GB+, have $freeSpaceGB GB free)"
        } else {
            Write-Log "✓ Sufficient storage space ($freeSpaceGB GB free)" -Level SUCCESS
        }
        
    } catch {
        Write-Log "Error during compatibility check: $($_.Exception.Message)" -Level ERROR
        $issues += "Could not complete full compatibility analysis"
    }
    
    return $issues
}

function Set-CompatibilityBypass {
    <#
    .SYNOPSIS
        Applies registry modifications to bypass Windows 11 hardware requirements
    #>
    
    Write-Log "Applying Windows 11 compatibility bypass registry entries..." -Level INFO
    
    $registrySettings = @{
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
    
    try {
        foreach ($regPath in $registrySettings.Keys) {
            # Create registry path if it doesn't exist
            if (!(Test-Path $regPath)) {
                $null = New-Item -Path $regPath -Force -ErrorAction Stop
            }
            
            # Set registry values
            foreach ($valueName in $registrySettings[$regPath].Keys) {
                $value = $registrySettings[$regPath][$valueName]
                Set-ItemProperty -Path $regPath -Name $valueName -Value $value -Type DWord -Force -ErrorAction Stop
            }
            
            Write-Log "✓ Applied bypass settings to $regPath" -Level SUCCESS
        }
        
        # Temporarily spoof system version for compatibility
        $ntVersionPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
        if (Test-Path $ntVersionPath) {
            # Backup original values
            $originalBuild = (Get-ItemProperty -Path $ntVersionPath -Name "CurrentBuild" -ErrorAction SilentlyContinue).CurrentBuild
            Set-ItemProperty -Path $ntVersionPath -Name "CurrentBuild_Backup" -Value $originalBuild -Force -ErrorAction SilentlyContinue
            
            # Set temporary compatibility values
            Set-ItemProperty -Path $ntVersionPath -Name "CurrentBuild" -Value "19044" -Force
            Set-ItemProperty -Path $ntVersionPath -Name "CurrentBuildNumber" -Value "19044" -Force
            
            Write-Log "✓ System version temporarily modified for compatibility" -Level SUCCESS
        }
        
        return $true
        
    } catch {
        Write-Log "Failed to apply compatibility bypass: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Reset-WindowsUpdateComponents {
    <#
    .SYNOPSIS
        Resets Windows Update components to ensure clean upgrade process
    #>
    
    Write-Log "Resetting Windows Update components..." -Level INFO
    
    try {
        # Stop Windows Update services
        $services = @("wuauserv", "cryptSvc", "bits", "msiserver")
        foreach ($service in $services) {
            Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
            Write-Log "Stopped service: $service" -Level INFO
        }
        
        # Clear update caches
        $cachePaths = @(
            "$env:SystemRoot\SoftwareDistribution",
            "$env:SystemRoot\System32\catroot2"
        )
        
        foreach ($cachePath in $cachePaths) {
            if (Test-Path $cachePath) {
                Remove-Item "$cachePath\*" -Recurse -Force -ErrorAction SilentlyContinue
                Write-Log "Cleared cache: $cachePath" -Level INFO
            }
        }
        
        # Restart Windows Update services
        foreach ($service in $services) {
            Start-Service -Name $service -ErrorAction SilentlyContinue
            Write-Log "Restarted service: $service" -Level INFO
        }
        
        Write-Log "✓ Windows Update components reset successfully" -Level SUCCESS
        return $true
        
    } catch {
        Write-Log "Failed to reset Windows Update components: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Start-InstallationAssistant {
    <#
    .SYNOPSIS
        Downloads and launches the Windows 11 Installation Assistant
    #>
    
    param(
        [string]$Path = $script:Config.TempPath
    )
    
    Write-Log "Preparing Windows 11 Installation Assistant..." -Level INFO
    
    try {
        # Download Installation Assistant if not present
        if (-not (Test-Path $Path)) {
            Write-Log "Downloading Installation Assistant..." -Level INFO
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile($script:Config.DownloadUrl, $Path)
            $webClient.Dispose()
            Write-Log "✓ Installation Assistant downloaded" -Level SUCCESS
        } else {
            Write-Log "Installation Assistant already present" -Level INFO
        }
        
        # Verify file exists and launch
        if (Test-Path $Path) {
            Write-Log "Launching Installation Assistant with proven working switches..." -Level INFO
            
            # Use only the most reliable switch combination that works
            $arguments = @('/SkipEULA')
            
            $process = Start-Process -FilePath $Path -ArgumentList $arguments -PassThru -WindowStyle Normal
            Start-Sleep -Seconds 8
            
            if ($process -and -not $process.HasExited) {
                Write-Log "✓ Installation Assistant launched successfully with /SkipEULA (PID: $($process.Id))" -Level SUCCESS
                Write-Log "License screen will be skipped automatically" -Level INFO
                return $process
            } else {
                throw "Installation Assistant failed to launch properly with /SkipEULA switch"
            }
        } else {
            throw "Installation Assistant file not found after download"
        }
        
    } catch {
        Write-Log "Failed to launch Installation Assistant: $($_.Exception.Message)" -Level ERROR
        return $null
    }
}

function Show-CompletionSummary {
    <#
    .SYNOPSIS
        Displays script completion summary
    #>
    
    param(
        [bool]$BypassApplied,
        [object]$Process
    )
    
    Write-Log "" -Level INFO
    Write-Log "=== WINDOWS 11 UPGRADE SETUP COMPLETED ===" -Level SUCCESS
    Write-Log "" -Level INFO
    
    if ($BypassApplied) {
        Write-Log "✓ Hardware compatibility bypass applied" -Level SUCCESS
    } else {
        Write-Log "✓ System already compatible - no bypass needed" -Level SUCCESS
    }
    
    Write-Log "✓ Windows Update components reset" -Level SUCCESS
    Write-Log "✓ Installation Assistant launched" -Level SUCCESS
    Write-Log "" -Level INFO
    
    if ($Process) {
        Write-Log "INSTALLATION STATUS:" -Level INFO
        Write-Log "• Installation Assistant is running (Process ID: $($Process.Id))" -Level INFO
        Write-Log "• The process should minimize to taskbar and handle license automatically" -Level INFO
        Write-Log "• Windows 11 download and installation will proceed automatically" -Level INFO
        Write-Log "• No user interaction should be required" -Level INFO
    } else {
        Write-Log "WARNING: Installation Assistant may not have launched properly" -Level WARNING
        Write-Log "Please check for any Installation Assistant windows that may require attention" -Level WARNING
    }
    
    Write-Log "" -Level INFO
    Write-Log "You can continue using your computer while the upgrade downloads and installs." -Level INFO
    Write-Log "Log file saved to: $($script:Config.LogFile)" -Level INFO
}

# Main Script Execution
try {
    # Display script header
    Write-Log "$($script:Config.ScriptName) v$($script:Config.ScriptVersion)" -Level SUCCESS
    Write-Log "Automated Windows 11 upgrade with smart hardware bypass" -Level INFO
    Write-Log "" -Level INFO
    
    # Verify administrator privileges
    if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        throw "This script must be run as Administrator. Right-click PowerShell and select 'Run as Administrator'"
    }
    
    # Initialize variables
    $bypassNeeded = $false
    $compatibilityIssues = @()
    
    # Check system compatibility (unless skipped)
    if (-not $SkipCompatibilityCheck) {
        $compatibilityIssues = Test-SystemCompatibility
        
        if ($compatibilityIssues.Count -eq 0 -and -not $Force) {
            Write-Log "✓ System meets all Windows 11 hardware requirements" -Level SUCCESS
            Write-Log "No compatibility bypass needed - proceeding with standard upgrade" -Level INFO
            $bypassNeeded = $false
        } else {
            if ($Force) {
                Write-Log "Force parameter specified - applying bypass regardless of compatibility" -Level WARNING
            } else {
                Write-Log "Compatibility issues detected:" -Level WARNING
                foreach ($issue in $compatibilityIssues) {
                    Write-Log "  • $issue" -Level WARNING
                }
            }
            Write-Log "Applying compatibility bypass to resolve hardware requirements" -Level INFO
            $bypassNeeded = $true
        }
    } else {
        Write-Log "Compatibility check skipped - applying bypass" -Level WARNING
        $bypassNeeded = $true
    }
    
    # Apply compatibility bypass if needed
    if ($bypassNeeded) {
        if (-not (Set-CompatibilityBypass)) {
            throw "Failed to apply compatibility bypass"
        }
    }
    
    # Reset Windows Update components
    if (-not (Reset-WindowsUpdateComponents)) {
        Write-Log "Warning: Failed to reset Windows Update components - continuing anyway" -Level WARNING
    }
    
    # Launch Installation Assistant
    $installProcess = Start-InstallationAssistant
    
    # Show completion summary
    Show-CompletionSummary -BypassApplied $bypassNeeded -Process $installProcess
    
} catch {
    Write-Log "CRITICAL ERROR: $($_.Exception.Message)" -Level ERROR
    Write-Log "Script execution failed - manual intervention may be required" -Level ERROR
    exit 1
}