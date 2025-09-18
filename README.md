# Windows 11 Silent Hardware Bypass & Auto-Upgrade Script

This repository contains a PowerShell script that performs a silent Windows 11 upgrade while bypassing hardware requirements (TPM, CPU, RAM, Secure Boot checks).

## Files

- `Windows11-Silent-Upgrade.ps1` - Main PowerShell script
- `Run-Windows11-Upgrade.bat` - Batch file wrapper for easy execution

## Features

- **Silent Operation**: No user prompts or interaction required
- **Hardware Bypass**: Bypasses TPM 2.0, CPU, RAM, and Secure Boot requirements
- **Multiple Methods**: Uses Windows 11 Installation Assistant, Windows Update automation, and DISM
- **Automatic Restart**: Configures system for automatic restart after upgrade
- **Registry Modifications**: Sets appropriate registry entries for bypass

## Usage

### Method 1: Using Batch File (Recommended)
1. Right-click `Run-Windows11-Upgrade.bat`
2. Select "Run as administrator"
3. Follow the prompts

### Method 2: Direct PowerShell Execution
1. Open PowerShell as Administrator
2. Navigate to the script directory
3. Run: `Set-ExecutionPolicy Bypass -Scope Process`
4. Run: `.\Windows11-Silent-Upgrade.ps1`

### Method 3: One-Line GitHub Execution (Recommended for Remote Use)

**Copy and paste this single command into PowerShell (Run as Administrator):**

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; iex (iwr -useb "https://raw.githubusercontent.com/meltonjoshua/Windows-upgrade-2.0/main/Windows11-Silent-Upgrade.ps1").Content
```

**Alternative with comprehensive error handling:**

```powershell
try { Set-ExecutionPolicy Bypass -Scope Process -Force; iex (iwr -useb "https://raw.githubusercontent.com/meltonjoshua/Windows-upgrade-2.0/main/Windows11-Silent-Upgrade.ps1").Content } catch { Write-Error "Failed to download or execute script: $_" }
```

This will:

- Set execution policy to Bypass for the current session
- Download the script directly from GitHub
- Execute it immediately without saving to disk
- Start the silent Windows 11 upgrade process
- No local files needed

## Requirements

- Windows 10 (any version)
- Administrator privileges
- Internet connection for downloading Windows 11 Installation Assistant

## What the Script Does

### Phase 1: Hardware Bypass Setup

- Creates registry keys: `HKLM:\System\Setup\LabConfig` and `HKLM:\System\Setup\MoSetup`
- Sets bypass flags:
  - `BypassRAMCheck = 1` - Skips minimum 4GB RAM requirement
  - `BypassTPMCheck = 1` - Bypasses TPM 2.0 requirement
  - `BypassCPUCheck = 1` - Ignores unsupported CPU models
  - `BypassSecureBootCheck = 1` - Skips Secure Boot requirement
  - `BypassStorageCheck = 1` - Bypasses storage requirements
  - `AllowUpgradesWithUnsupportedTPMOrCPU = 1` - Forces upgrade permission

### Phase 2: Windows 11 Installation Assistant

- Downloads official Microsoft Windows 11 Installation Assistant (105MB)
- Launches with parameters: `/quietinstall /skipeula /auto /norestart`
- Runs completely hidden in background
- No user prompts or EULA acceptance required

### Phase 3: Windows Update Automation

- Modifies `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate`
- Sets automatic update configuration:
  - `AUOptions = 4` - Download and install automatically
  - `ScheduledInstallTime = 3` - Install at 3 AM
  - `NoAutoUpdate = 0` - Enable automatic updates
- Programmatically searches for Windows 11 feature updates
- Downloads and installs found updates silently

### Phase 4: Update Triggers

- Executes `usoclient.exe ScanInstallWait` - Forces immediate update scan
- Runs `wuauclt.exe /detectnow` - Triggers update detection
- Runs `wuauclt.exe /updatenow` - Forces immediate update installation

### Phase 5: Restart Scheduling

- Prompts user to choose restart timing:
  - Immediate automatic restart when ready
  - Delayed restart (1, 2, or 4 hours)
  - Scheduled restart (tonight at 2 AM)
  - Manual restart (user controls timing)
- Creates scheduled tasks for delayed restarts
- Configures system based on user preference

## Expected System Behavior

**During Execution:**

- Script completes in 2-5 minutes
- Downloads begin immediately in background
- No visible windows or prompts appear
- System continues normal operation

**After Script Completion:**

- Windows 11 Installation Assistant runs silently
- System may become slightly slower during download/preparation
- Upgrade process continues even if you close PowerShell window
- System will restart according to your chosen schedule

**After Restart:**

- Windows 11 upgrade installation begins automatically
- May take 30-90 minutes depending on system speed
- Multiple automatic restarts may occur
- System will boot into Windows 11 when complete

## What You'll See

✅ **Success Indicators:**

- "Hardware bypass registry entries set successfully!"
- "Windows 11 Installation Assistant running silently"
- "Silent installation completed"
- "Triggering automatic Windows Update scan..."
- Restart scheduling confirmation message
- No error messages or prompts

⚠️ **Normal Behavior:**

- High disk activity after script runs
- Slower system performance during download
- Restart prompt for scheduling timing
- Scheduled restart notifications (if delayed restart chosen)
- Windows Update showing "Feature update to Windows 11"

❌ **Potential Issues:**

- Internet connection errors during download
- Insufficient disk space (requires ~10GB free)
- Antivirus software blocking registry changes
- Windows Update service disabled

## Important Notes

- ⚠️ **Administrator Rights Required**: Script must be run as Administrator
- ⚠️ **System Modification**: This script modifies Windows registry entries
- ⚠️ **Automatic Restart**: System will restart automatically when upgrade is ready
- ⚠️ **Use at Your Own Risk**: Test in a non-production environment first

## Registry Modifications

The script modifies these registry paths:

- `HKLM:\System\Setup\LabConfig`
- `HKLM:\System\Setup\MoSetup`
- `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate`

## Compatibility

This script is based on the Ventoy Windows11Bypass implementation and should work on most Windows 10 systems that don't meet Windows 11 hardware requirements.

## License

Use at your own risk. This script is provided as-is without warranty.
