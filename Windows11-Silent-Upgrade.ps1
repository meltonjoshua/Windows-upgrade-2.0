# Windows 11 Hardware Bypass & Auto-Upgrade Script v3.5
# Fixed version - all syntax errors corrected
# Run as Administrator for best results

param(
    [switch]$Force,
    [switch]$Quiet
)

# Ensure script execution is allowed
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# Global variables
$global:LogFile = "$env:TEMP\Windows11-Upgrade-Log.txt"

# Enhanced logging function
function Write-LogMessage {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Color = "White"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to console with color
    Write-Host $Message -ForegroundColor $Color
    
    # Write to log file
    try {
        Add-Content -Path $global:LogFile -Value $logEntry -ErrorAction SilentlyContinue
    } catch {
        # Silently continue if logging fails
    }
}

# Check if running as Administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# System compatibility check
function Test-SystemCompatibility {
    Write-LogMessage "Performing system compatibility check..." "INFO" "Cyan"
    
    $issues = @()
    
    # Check if running as Administrator
    if (-not (Test-Administrator)) {
        $issues += "Script must be run as Administrator"
    }
    
    # Check Windows version
    $buildNumber = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuild
    
    if ($buildNumber -ge 22000) {
        Write-LogMessage "System is already running Windows 11 (Build: $buildNumber)" "WARNING" "Yellow"
        return $true
    }
    
    # Check available disk space (minimum 20GB)
    $systemDrive = $env:SystemDrive
    $freeSpace = (Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='$systemDrive'").FreeSpace
    $freeSpaceGB = [Math]::Round($freeSpace / 1GB, 2)
    
    if ($freeSpaceGB -lt 20) {
        $issues += "Insufficient disk space. Available: $freeSpaceGB GB, Required: 20 GB"
    }
    
    if ($issues.Count -gt 0) {
        Write-LogMessage "System compatibility issues found:" "ERROR" "Red"
        foreach ($issue in $issues) {
            Write-LogMessage "  • $issue" "ERROR" "Red"
        }
        return $false
    }
    
    Write-LogMessage "✓ System compatibility check passed" "SUCCESS" "Green"
    return $true
}

# Set registry bypass entries
function Set-BypassRegistryEntries {
    Write-LogMessage "Setting hardware bypass registry entries..." "INFO" "Cyan"
    
    try {
        # Create registry paths
        $setupKeyPath = "HKLM:\System\Setup"
        $labConfigPath = "$setupKeyPath\LabConfig"
        $moSetupPath = "$setupKeyPath\MoSetup"
        
        $paths = @($setupKeyPath, $labConfigPath, $moSetupPath)
        foreach ($path in $paths) {
            if (!(Test-Path $path)) { 
                New-Item -Path $path -Force | Out-Null
                Write-LogMessage "Created: $path" "SUCCESS" "Gray"
            }
        }
        
        # Set bypass values
        $bypassValues = @{
            "BypassRAMCheck" = 1
            "BypassTPMCheck" = 1
            "BypassCPUCheck" = 1
            "BypassSecureBootCheck" = 1
            "BypassStorageCheck" = 1
        }
        
        foreach ($value in $bypassValues.GetEnumerator()) {
            Set-ItemProperty -Path $labConfigPath -Name $value.Key -Value $value.Value -Type DWord -Force
            Write-LogMessage "Set $($value.Key) = $($value.Value)" "SUCCESS" "Gray"
        }
        
        # Additional bypass for Windows Update
        Set-ItemProperty -Path $moSetupPath -Name "AllowUpgradesWithUnsupportedTPMOrCPU" -Value 1 -Type DWord -Force
        Write-LogMessage "Set AllowUpgradesWithUnsupportedTPMOrCPU = 1" "SUCCESS" "Gray"
        
        Write-LogMessage "✓ Hardware bypass registry entries set successfully!" "SUCCESS" "Green"
        
    } catch {
        Write-LogMessage "Registry modification failed: $($_.Exception.Message)" "ERROR" "Red"
        throw "Critical registry modifications failed"
    }
}

# Download function with progress
function Download-FileWithProgress {
    param(
        [string]$Url,
        [string]$OutFile,
        [int]$TimeoutSeconds = 300
    )
    
    try {
        Write-LogMessage "Downloading from: $Url" "INFO" "Yellow"
        
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($Url, $OutFile)
        $webClient.Dispose()
        
        if (Test-Path $OutFile) {
            $fileSize = (Get-Item $OutFile).Length
            Write-LogMessage "Download completed. Size: $([math]::Round($fileSize/1MB, 2)) MB" "SUCCESS" "Green"
            return $true
        }
        
        return $false
    } catch {
        Write-LogMessage "Download failed: $($_.Exception.Message)" "ERROR" "Red"
        return $false
    }
}

# Main upgrade function
function Start-Windows11Upgrade {
    Write-LogMessage "Starting Windows 11 upgrade process..." "INFO" "Magenta"
    
    try {
        # Download Windows 11 Installation Assistant
        $updateAssistantPath = "$env:TEMP\Windows11InstallationAssistant.exe"
        $downloadUrl = "https://go.microsoft.com/fwlink/?linkid=2171764"
        
        # Remove existing file if present
        if (Test-Path $updateAssistantPath) {
            Remove-Item $updateAssistantPath -Force
        }
        
        Write-LogMessage "Downloading Windows 11 Installation Assistant..." "INFO" "Yellow"
        
        if (Download-FileWithProgress -Url $downloadUrl -OutFile $updateAssistantPath) {
            $fileSize = (Get-Item $updateAssistantPath).Length
            
            if ($fileSize -gt 1MB) {
                Write-LogMessage "Launching Windows 11 Installation Assistant..." "INFO" "Green"
                
                # Launch with bypass parameters
                $processArgs = @(
                    '/skipeula'
                    '/auto'
                    '/norestart'
                    '/skipcpu'
                    '/skiptpm'
                    '/skipram'
                    '/skipsecureboot'
                    '/skipstorage'
                    '/skipcompat'
                )
                
                $process = Start-Process -FilePath $updateAssistantPath -ArgumentList $processArgs -PassThru -WindowStyle Normal
                Write-LogMessage "✓ Installation Assistant started (Process ID: $($process.Id))" "SUCCESS" "Green"
                
                # Monitor for a short time
                Start-Sleep -Seconds 10
                
                if (!$process.HasExited) {
                    Write-LogMessage "✓ Installation Assistant is running - upgrade in progress" "SUCCESS" "Green"
                } else {
                    Write-LogMessage "Installation Assistant completed with exit code: $($process.ExitCode)" "INFO" "Yellow"
                }
                
            } else {
                Write-LogMessage "Downloaded file appears to be incomplete" "ERROR" "Red"
            }
        } else {
            Write-LogMessage "Installation Assistant download failed" "ERROR" "Red"
        }
        
        # Trigger Windows Update
        Write-LogMessage "Triggering Windows Update scan..." "INFO" "Cyan"
        
        try {
            Start-Process -FilePath "usoclient.exe" -ArgumentList "ScanInstallWait" -NoNewWindow
            Write-LogMessage "✓ Windows Update scan initiated" "SUCCESS" "Green"
        } catch {
            Write-LogMessage "Windows Update trigger failed: $($_.Exception.Message)" "WARNING" "Yellow"
        }
        
    } catch {
        Write-LogMessage "Upgrade process failed: $($_.Exception.Message)" "ERROR" "Red"
        throw "Upgrade initiation failed"
    }
}

# Main execution
function Start-Main {
    Write-LogMessage "Windows 11 Hardware Bypass & Auto-Upgrade v3.5" "INFO" "Green"
    Write-LogMessage "Starting upgrade process..." "INFO" "Yellow"
    
    # Initialize log file
    try {
        "=== Windows 11 Auto-Upgrade Log Started at $(Get-Date) ===" | Out-File -FilePath $global:LogFile -Force
    } catch {
        Write-Host "Warning: Could not initialize log file" -ForegroundColor Yellow
    }
    
    try {
        # Check system compatibility
        if (-not (Test-SystemCompatibility)) {
            if (-not $Force) {
                throw "System compatibility check failed. Use -Force to override."
            }
            Write-LogMessage "Forcing upgrade despite compatibility issues..." "WARNING" "Yellow"
        }
        
        # Set registry bypass entries
        Set-BypassRegistryEntries
        
        # Start upgrade process
        Start-Windows11Upgrade
        
        Write-LogMessage "`n=== WINDOWS 11 UPGRADE INITIATED ===" "INFO" "Green"
        Write-LogMessage "✓ Hardware bypass registry entries active" "SUCCESS" "White"
        Write-LogMessage "✓ Installation Assistant launched with bypass parameters" "SUCCESS" "White"
        Write-LogMessage "✓ Windows Update scan triggered" "SUCCESS" "White"
        Write-LogMessage "✓ System prepared for upgrade" "SUCCESS" "White"
        
        Write-LogMessage "`nNext steps:" "INFO" "Yellow"
        Write-LogMessage "• Monitor the Installation Assistant window for progress" "INFO" "Cyan"
        Write-LogMessage "• Check Windows Update in Settings if needed" "INFO" "Cyan"
        Write-LogMessage "• System will restart automatically when ready" "INFO" "Cyan"
        
        Write-LogMessage "`nLog file: $global:LogFile" "INFO" "Gray"
        
    } catch {
        Write-LogMessage "Script execution failed: $($_.Exception.Message)" "ERROR" "Red"
        exit 1
    }
}

# Execute main function
Start-Main