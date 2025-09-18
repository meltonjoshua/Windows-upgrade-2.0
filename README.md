# Windows 11 Hardware Bypass & Auto-Upgrade Script v3.0

This repository contains an enhanced PowerShell script that performs an **automated** Windows 11 upgrade with **visible progress monitoring** while bypassing hardware requirements (TPM, CPU, RAM, Secure Boot checks).

## 🆕 Version 3.0 Features

- **🔄 Automated with Visible Progress**: Minimal user interaction required - automated Windows 10 to 11 upgrade with progress monitoring
- **⚡ Enhanced Reliability**: Advanced error handling with retry mechanisms and fallback options
- **📊 Visible Download Progress**: BITS transfer with real-time progress display and automatic resume capability  
- **🛡️ System Validation**: Pre-upgrade compatibility checks (admin rights, disk space, connectivity)
- **📝 Comprehensive Logging**: Detailed logging with timestamps for troubleshooting
- **🔧 Improved Registry**: Enhanced registry modifications with better error handling
- **🔄 Auto-Restart**: Automatic restart configuration when upgrade is ready
- **🎯 Multiple Triggers**: Modern and legacy Windows Update activation methods

## Files

- `Windows11-Silent-Upgrade.ps1` - Enhanced PowerShell script with full automation (v3.0)
- `Run-Windows11-Upgrade.bat` - Batch file wrapper for easy execution

## 🚀 Enhanced Features

- **🔄 Automated with Visible Progress**: Minimal manual intervention with real-time progress monitoring
- **🛡️ Pre-Flight Validation**: Comprehensive system compatibility checks before upgrade
- **⚡ Visible Download Progress**: BITS transfer with real-time progress display and retry logic
- **📝 Enhanced Logging**: Detailed operation logs with timestamps saved to temp directory
- **🎯 Hardware Bypass**: Bypasses TPM 2.0, CPU, RAM, and Secure Boot requirements
- **🔄 Multiple Update Methods**: Uses Windows 11 Installation Assistant and Windows Update automation
- **🔄 Automatic Restart**: Configures system for automatic restart after upgrade
- **📋 Registry Modifications**: Sets appropriate registry entries for bypass with error handling
- **🔧 Modern & Legacy Triggers**: Uses both USOClient and legacy Windows Update commands

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
- Start the **fully automated** Windows 11 upgrade process
- No local files needed
- **No user interaction required** - completely automated

## Requirements

- Windows 10 (any version)
- Administrator privileges
- Internet connection for downloading Windows 11 Installation Assistant
- **Minimum 20GB free disk space** (automatically checked)

## What the Script Does

### Phase 1: System Validation & Compatibility Check

- **Pre-flight validation**: Checks admin rights, Windows version, and disk space
- **Network connectivity test**: Verifies internet connection to Microsoft servers  
- **System information**: Logs current Windows version and available disk space
- **Automatic validation**: Stops execution if critical requirements not met

### Phase 2: Enhanced Hardware Bypass Setup

- Creates registry keys: `HKLM:\System\Setup\LabConfig` and `HKLM:\System\Setup\MoSetup`
- Sets comprehensive bypass flags with error handling:
  - `BypassRAMCheck = 1` - Skips minimum 4GB RAM requirement
  - `BypassTPMCheck = 1` - Bypasses TPM 2.0 requirement
  - `BypassCPUCheck = 1` - Ignores unsupported CPU models
  - `BypassSecureBootCheck = 1` - Skips Secure Boot requirement
  - `BypassStorageCheck = 1` - Bypasses storage requirements
  - `AllowUpgradesWithUnsupportedTPMOrCPU = 1` - Forces upgrade permission

### Phase 3: Enhanced Windows 11 Installation Assistant

- **Smart Download**: Downloads official Microsoft Windows 11 Installation Assistant (105MB)
- **BITS Transfer**: Uses Background Intelligent Transfer Service with fallback to WebRequest
- **Retry Logic**: Automatic retry with exponential backoff on download failures
- **File Verification**: Validates download integrity and file size
- **Visible Execution**: Launches with parameters: `/skipeula /auto /norestart` with visible progress window
- **Process Monitoring**: Tracks execution status and exit codes

### Phase 4: Advanced Windows Update Automation

- **Enhanced Registry Configuration**: Modifies `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate`
- **Automatic Update Settings**: 
  - `AUOptions = 4` - Download and install automatically
  - `ScheduledInstallTime = 3` - Install at 3 AM
  - `NoAutoUpdate = 0` - Enable automatic updates
  - `NoAutoRebootWithLoggedOnUsers = 0` - Allow automatic restart
- **Multi-Strategy Detection**: Uses multiple search strategies to find Windows 11 updates
- **Comprehensive Filtering**: Detects various Windows 11 update patterns (21H2, 22H2, 23H2, 24H2, 25H2)
- **Category-Based Search**: Searches Feature Packs, Upgrades, Feature Updates, and Critical Updates
- **Automatic Installation**: Downloads and installs found updates with detailed progress reporting

### Phase 5: Comprehensive Update Triggers

- **Modern USOClient Commands**: Executes `ScanInstallWait`, `RefreshSettings`, `StartDownload`, `StartInstall`
- **Legacy Windows Update Commands**: Runs `wuauclt.exe /detectnow` and `/updatenow` for compatibility
- **Multiple Activation Strategies**: Uses both modern and legacy Windows Update mechanisms
- **Service Configuration**: Configures Windows Update services for feature updates
- **Error Handling**: Each trigger includes comprehensive error handling and logging
- **Immediate Activation**: Forces immediate update detection and download initiation

### Phase 6: Automatic Restart Configuration

- **Zero User Interaction**: Completely automated restart configuration
- **Primary Method**: Configures automatic restart when upgrade is ready
- **Backup Scheduling**: Creates scheduled task for restart in 4 hours as fallback
- **Registry Configuration**: Sets `AutoRestartShell = 1` for automatic shell restart
- **User Session Handling**: Allows restart even with users logged on
- **No Manual Prompts**: Eliminates all manual restart selection prompts

## Expected System Behavior

**During Execution (Enhanced v3.0):**

- Script completes initial setup in 2-3 minutes
- **System validation** checks are performed automatically
- Downloads begin immediately with **real-time progress display**
- All operations logged to `%TEMP%\Windows11-Upgrade-Log.txt`
- **Minimal user prompts** - automated operation with visible progress
- System continues normal operation

**After Script Completion:**

- Windows 11 Installation Assistant runs **with visible progress window**
- Downloads proceed with **real-time progress monitoring and automatic retry on failures**
- System may become slightly slower during download/preparation
- **Automatic restart configured** - no user interaction required
- **Backup restart scheduled** for 4 hours as failsafe

**After Automatic Restart:**

- Windows 11 upgrade installation begins **automatically**
- May take 30-90 minutes depending on system speed
- Multiple automatic restarts may occur
- System will boot into Windows 11 when complete
- **Progress visible through Installation Assistant interface**

## What You'll See

✅ **Success Indicators (v3.0 Enhanced):**

- "✓ System compatibility check passed"
- "✓ Hardware bypass registry entries set successfully!"
- "✓ Download completed using BITS transfer" or "✓ Download completed using WebRequest"
- "✓ Installation Assistant started with Process ID: [number]"
- "✓ Windows 11 updates installed successfully!"
- "✓ All upgrade triggers executed successfully"
- "✓ Automatic restart configured"
- "=== WINDOWS 11 UPGRADE FULLY INITIATED ==="
- Detailed logging messages with timestamps
- Comprehensive operation status updates

⚠️ **Normal Automated Behavior:**

- High disk activity after script runs
- Slower system performance during download
- **No restart prompts** - system configures itself automatically
- **No user interaction required** - completely silent operation
- Windows Update showing "Feature update to Windows 11"
- Log file created in %TEMP% directory for troubleshooting

❌ **Potential Issues (Now with Auto-Recovery):**

- Internet connection errors during download (**automatic retry implemented**)
- Insufficient disk space (**pre-checked and reported**)
- Antivirus software blocking registry changes or download (**detailed error logging**)
- Windows Update service disabled or corrupted (**multiple fallback methods**)
- "No Windows 11 feature updates found" (**enhanced detection patterns implemented**)
- Installation Assistant exits quickly (may be normal behavior)

**If Updates Aren't Found:**
- The system may already be on Windows 11
- Feature updates might not be available yet for your specific hardware
- Multiple detection strategies implemented in v3.0 improve success rate
- Check log file at `%TEMP%\Windows11-Upgrade-Log.txt` for detailed information

## 🔧 Troubleshooting (v3.0 Enhanced)

**Log File Location:** `%TEMP%\Windows11-Upgrade-Log.txt`

**Common Issues and Auto-Recovery:**

1. **Download Failures**: 
   - v3.0 includes automatic retry with BITS transfer
   - Falls back to WebRequest if BITS fails
   - Check log for specific download error details

2. **Registry Access Denied**:
   - Ensure running as Administrator
   - Some antivirus software may block registry changes
   - Script includes enhanced error handling for registry operations

3. **Windows Update Service Issues**:
   - Script uses multiple activation methods (USOClient + legacy wuauclt)
   - Automatic service configuration included
   - Check Windows Update service status if issues persist

4. **Insufficient Disk Space**:
   - v3.0 includes automatic disk space validation (requires 20GB minimum)
   - Script will stop execution and report issue if insufficient space

5. **Network Connectivity**:
   - Pre-flight network validation included
   - Script tests connectivity to Microsoft servers before starting
   - Automatic retry mechanisms for temporary network issues

**Manual Verification Steps:**

1. Check log file for detailed operation status
2. Verify Windows Update service is running: `Get-Service wuauserv`
3. Check for pending updates: Settings > Update & Security > Windows Update
4. Monitor download progress in Windows Update settings
5. Restart system manually if automatic restart doesn't occur after 4+ hours

## Recent Improvements (v3.0)

**🔄 Enhanced Automation with Visibility:**
- **Minimal User Interaction**: Eliminated most manual prompts while maintaining progress visibility
- **Automatic Restart Configuration**: System configures itself for automatic restart when ready
- **Visible Progress Operation**: All processes display real-time progress to the user
- **Intelligent Scheduling**: Backup restart scheduled automatically as failsafe

**🛡️ Enhanced System Validation:**
- **Pre-flight Compatibility Checks**: Validates admin rights, Windows version, and disk space
- **Network Connectivity Testing**: Verifies connection to Microsoft update servers
- **Automatic Requirement Verification**: Stops execution if critical requirements not met
- **Detailed System Information Logging**: Records current system state for troubleshooting

**⚡ Visible Download & Installation Progress:**
- **BITS Transfer with Real-time Progress**: Uses Background Intelligent Transfer Service with visible progress monitoring
- **Automatic Retry Logic**: Exponential backoff retry mechanism for failed downloads with progress updates
- **Download Verification**: File integrity and size validation with status reporting
- **Multiple Fallback Methods**: WebRequest fallback with progress display if BITS transfer fails

**📝 Comprehensive Logging System:**
- **Timestamped Operation Logs**: All operations logged with date/time stamps
- **Severity Level Tracking**: INFO, SUCCESS, WARNING, ERROR severity levels
- **File-Based Logging**: Logs saved to %TEMP%\Windows11-Upgrade-Log.txt
- **Enhanced Troubleshooting**: Detailed error messages and operation status

**🔧 Improved Error Handling:**
- **Comprehensive Try-Catch Blocks**: All critical operations wrapped in error handling
- **Graceful Failure Recovery**: Script continues with alternative methods when one fails
- **Detailed Error Reporting**: Specific error messages with suggested resolutions
- **Process Monitoring**: Tracks subprocess execution and exit codes

**🎯 Enhanced Update Detection:**
- **Multiple Search Strategies**: Comprehensive update discovery using various search patterns
- **Extended Version Support**: Covers Windows 11 versions 21H2, 22H2, 23H2, 24H2, 25H2
- **Category-Based Filtering**: Searches across Feature Packs, Upgrades, Feature Updates
- **Modern & Legacy Compatibility**: Uses both USOClient and legacy wuauclt commands

## Important Notes

- ⚠️ **Administrator Rights Required**: Script must be run as Administrator
- ⚠️ **System Modification**: This script modifies Windows registry entries
- ⚠️ **Fully Automated**: System will restart automatically when upgrade is ready - **no user interaction required**
- ⚠️ **Use at Your Own Risk**: Test in a non-production environment first
- 📝 **Enhanced Logging**: All operations logged to `%TEMP%\Windows11-Upgrade-Log.txt`
- 🔄 **Complete Automation**: Zero manual prompts - runs completely unattended

## Registry Modifications

The script modifies these registry paths with enhanced error handling:

- `HKLM:\System\Setup\LabConfig`
- `HKLM:\System\Setup\MoSetup`
- `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate`
- `HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon`

## Compatibility

This enhanced script (v3.0) is based on the Ventoy Windows11Bypass implementation and includes significant improvements for reliability and automation. It should work on most Windows 10 systems that don't meet Windows 11 hardware requirements.

**New in v3.0:**
- Enhanced compatibility checks before execution
- Improved error handling for various system configurations  
- Better support for different Windows 10 editions and builds
- Automatic fallback methods for challenging network environments

## License

Use at your own risk. This script is provided as-is without warranty.
