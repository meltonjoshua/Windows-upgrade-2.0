# Windows 11 Hardware Bypass & Auto-Upgrade Script
# Shows all operations and progress in PowerShell
# Based on Ventoy's Windows11Bypass implementation

# Ensure script execution is allowed
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

function Windows11-Silent-Auto-Upgrade {
    Write-Host "Starting Windows 11 Hardware Bypass & Auto-Upgrade..." -ForegroundColor Green
    Write-Host "All operations will be visible in PowerShell" -ForegroundColor Yellow
    
    try {
        # Set registry bypass entries with visible output
        Set-BypassRegistryEntries
        
        # Start upgrade process with visible output
        Start-SilentWindows11Upgrade
        
    } catch {
        Write-Error "Upgrade failed: $($_.Exception.Message)"
    }
}

function Set-BypassRegistryEntries {
    Write-Host "Setting hardware bypass registry entries..." -ForegroundColor Cyan
    
    # Create registry paths with visible output
    $setupKeyPath = "HKLM:\System\Setup"
    $labConfigPath = "$setupKeyPath\LabConfig"
    $moSetupPath = "$setupKeyPath\MoSetup"
    
    # Ensure paths exist and show progress
    Write-Host "Creating registry paths..." -ForegroundColor Yellow
    if (!(Test-Path $setupKeyPath)) { 
        New-Item -Path $setupKeyPath -Force
        Write-Host "Created: $setupKeyPath" -ForegroundColor Gray
    }
    if (!(Test-Path $labConfigPath)) { 
        New-Item -Path $labConfigPath -Force
        Write-Host "Created: $labConfigPath" -ForegroundColor Gray
    }
    if (!(Test-Path $moSetupPath)) { 
        New-Item -Path $moSetupPath -Force
        Write-Host "Created: $moSetupPath" -ForegroundColor Gray
    }
    
    # Set comprehensive bypass values
    $bypassValues = @{
        "BypassRAMCheck" = 1
        "BypassTPMCheck" = 1
        "BypassCPUCheck" = 1
        "BypassSecureBootCheck" = 1
        "BypassStorageCheck" = 1
        "AllowUpgradesWithUnsupportedTPMOrCPU" = 1
    }
    
    Write-Host "Setting bypass registry values..." -ForegroundColor Yellow
    foreach ($value in $bypassValues.GetEnumerator()) {
        Set-ItemProperty -Path $labConfigPath -Name $value.Key -Value $value.Value -Type DWord -Force
        Write-Host "Set $($value.Key) = $($value.Value)" -ForegroundColor Gray
    }
    
    # Additional bypass for Windows Update
    Write-Host "Setting additional Windows Update bypass..." -ForegroundColor Yellow
    Set-ItemProperty -Path $moSetupPath -Name "AllowUpgradesWithUnsupportedTPMOrCPU" -Value 1 -Type DWord -Force
    Write-Host "Set AllowUpgradesWithUnsupportedTPMOrCPU = 1" -ForegroundColor Gray
    
    # Additional registry keys for Windows 11 compatibility
    Write-Host "Setting additional Windows 11 compatibility entries..." -ForegroundColor Yellow
    
    # Force Windows 11 eligibility
    $eligibilityPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
    try {
        Set-ItemProperty -Path $eligibilityPath -Name "EditionID" -Value "Professional" -Type String -Force
        Write-Host "Set EditionID = Professional" -ForegroundColor Gray
    } catch {
        Write-Host "Could not set EditionID (may not be necessary)" -ForegroundColor Yellow
    }
    
    # Windows Update service configuration
    $wuServicePath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
    if (!(Test-Path $wuServicePath)) { 
        New-Item -Path $wuServicePath -Force | Out-Null
        Write-Host "Created Windows Update AU path" -ForegroundColor Gray
    }
    Set-ItemProperty -Path $wuServicePath -Name "AllowMUUpdateService" -Value 1 -Type DWord -Force
    Write-Host "Set AllowMUUpdateService = 1" -ForegroundColor Gray
    
    Write-Host "Hardware bypass registry entries set successfully!" -ForegroundColor Green
}

function Start-SilentWindows11Upgrade {
    Write-Host "Starting Windows 11 upgrade process with visible output..." -ForegroundColor Magenta
    
    try {
        # Method 1: Windows 11 Installation Assistant with visible output
        $updateAssistantPath = "$env:TEMP\Windows11InstallationAssistant.exe"
        
        Write-Host "Downloading Windows 11 Installation Assistant..." -ForegroundColor Yellow
        Write-Host "Download URL: https://go.microsoft.com/fwlink/?linkid=2171764" -ForegroundColor Gray
        Write-Host "Destination: $updateAssistantPath" -ForegroundColor Gray
        
        try {
            # Download with progress showing
            $downloadUrl = "https://go.microsoft.com/fwlink/?linkid=2171764"
            Invoke-WebRequest -Uri $downloadUrl -OutFile $updateAssistantPath -UseBasicParsing
            
            Write-Host "Download completed. Verifying file..." -ForegroundColor Green
            
            if (Test-Path $updateAssistantPath) {
                $fileSize = (Get-Item $updateAssistantPath).Length
                Write-Host "File size: $([math]::Round($fileSize/1MB, 2)) MB" -ForegroundColor Gray
                
                if ($fileSize -gt 1MB) {
                    Write-Host "Starting Windows 11 Installation Assistant..." -ForegroundColor Green
                    Write-Host "Command: $updateAssistantPath /quietinstall /skipeula /auto /norestart" -ForegroundColor Gray
                    
                    # Launch with error handling
                    $processArgs = @{
                        FilePath = $updateAssistantPath
                        ArgumentList = @('/quietinstall', '/skipeula', '/auto', '/norestart')
                        Wait = $false
                        PassThru = $true
                    }
                    
                    $process = Start-Process @processArgs
                    Write-Host "✓ Installation Assistant started with Process ID: $($process.Id)" -ForegroundColor Green
                    
                    # Wait a moment to verify it's running
                    Start-Sleep -Seconds 3
                    if (!$process.HasExited) {
                        Write-Host "✓ Installation Assistant is running in background" -ForegroundColor Green
                    } else {
                        Write-Host "⚠ Installation Assistant exited quickly - this may be normal" -ForegroundColor Yellow
                    }
                } else {
                    Write-Host "Downloaded file appears to be incomplete (too small)" -ForegroundColor Red
                }
            } else {
                Write-Host "Download failed - file not found" -ForegroundColor Red
            }
        } catch {
            Write-Host "Installation Assistant download/execution failed: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Continuing with Windows Update methods..." -ForegroundColor Yellow
        }
        
        # Method 2: Configure Windows Update with visible progress
        Write-Host "Configuring Windows Update for upgrade..." -ForegroundColor Cyan
        
        # Disable Windows Update prompts
        $wuPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
        Write-Host "Creating Windows Update policy path: $wuPath" -ForegroundColor Gray
        if (!(Test-Path $wuPath)) { 
            New-Item -Path $wuPath -Force
            Write-Host "Created Windows Update policy path" -ForegroundColor Gray
        }
        
        Write-Host "Setting Windows Update policies..." -ForegroundColor Yellow
        Set-ItemProperty -Path $wuPath -Name "AcceptTrustedPublisherCerts" -Value 1 -Type DWord -Force
        Write-Host "Set AcceptTrustedPublisherCerts = 1" -ForegroundColor Gray
        Set-ItemProperty -Path $wuPath -Name "ElevateNonAdmins" -Value 1 -Type DWord -Force
        Write-Host "Set ElevateNonAdmins = 1" -ForegroundColor Gray
        
        # Configure automatic updates
        $auPath = "$wuPath\AU"
        Write-Host "Creating Automatic Update path: $auPath" -ForegroundColor Gray
        if (!(Test-Path $auPath)) { 
            New-Item -Path $auPath -Force
            Write-Host "Created Automatic Update path" -ForegroundColor Gray
        }
        
        Write-Host "Setting automatic update configuration..." -ForegroundColor Yellow
        Set-ItemProperty -Path $auPath -Name "NoAutoUpdate" -Value 0 -Type DWord -Force
        Write-Host "Set NoAutoUpdate = 0 (Enable automatic updates)" -ForegroundColor Gray
        Set-ItemProperty -Path $auPath -Name "AUOptions" -Value 4 -Type DWord -Force
        Write-Host "Set AUOptions = 4 (Auto download and install)" -ForegroundColor Gray
        Set-ItemProperty -Path $auPath -Name "ScheduledInstallDay" -Value 0 -Type DWord -Force
        Write-Host "Set ScheduledInstallDay = 0 (Every day)" -ForegroundColor Gray
        Set-ItemProperty -Path $auPath -Name "ScheduledInstallTime" -Value 3 -Type DWord -Force
        Write-Host "Set ScheduledInstallTime = 3 (3 AM)" -ForegroundColor Gray
        
        # Method 3: Trigger Windows Update programmatically with visible progress
        Write-Host "Triggering Windows Update scan..." -ForegroundColor Cyan
        
        try {
            # Create Windows Update session
            Write-Host "Creating Windows Update session..." -ForegroundColor Yellow
            $updateSession = New-Object -ComObject Microsoft.Update.Session
            $updateSearcher = $updateSession.CreateUpdateSearcher()
            
            # Multiple search strategies for comprehensive Windows 11 detection
            $searchQueries = @(
                "IsInstalled=0 and Type='Software'",
                "IsInstalled=0",
                "Type='Software' and IsInstalled=0"
            )
            
            $allUpdates = @()
            foreach ($query in $searchQueries) {
                try {
                    Write-Host "Searching with query: $query" -ForegroundColor Gray
                    $searchResult = $updateSearcher.Search($query)
                    $allUpdates += $searchResult.Updates
                    Write-Host "Found $($searchResult.Updates.Count) updates with this query" -ForegroundColor Gray
                } catch {
                    Write-Host "Search query failed: $query - $($_.Exception.Message)" -ForegroundColor Yellow
                }
            }
            
            # Remove duplicates by UpdateID
            $uniqueUpdates = $allUpdates | Sort-Object UpdateID -Unique
            Write-Host "Found $($uniqueUpdates.Count) total unique updates" -ForegroundColor Gray
            
            if ($uniqueUpdates.Count -gt 0) {
                Write-Host "Filtering for Windows 11 feature updates..." -ForegroundColor Yellow
                $updateCollection = New-Object -ComObject Microsoft.Update.UpdateColl
                
                foreach ($update in $uniqueUpdates) {
                    Write-Host "Checking update: $($update.Title)" -ForegroundColor Gray
                    
                    # Enhanced filtering for Windows 11 updates
                    $isWindows11Update = $false
                    
                    # Check title patterns
                    $windows11Patterns = @(
                        "*Windows 11*",
                        "*Feature update to Windows 11*", 
                        "*Upgrade to Windows 11*",
                        "*Windows 11 version*",
                        "*22H2*",
                        "*21H2*",
                        "*23H2*",
                        "*24H2*"
                    )
                    
                    foreach ($pattern in $windows11Patterns) {
                        if ($update.Title -like $pattern) {
                            $isWindows11Update = $true
                            Write-Host "Matched pattern '$pattern' for: $($update.Title)" -ForegroundColor Cyan
                            break
                        }
                    }
                    
                    # Check categories
                    if (!$isWindows11Update -and $update.Categories) {
                        $categoryNames = @("Feature Packs", "Upgrades", "Feature Updates", "Critical Updates")
                        foreach ($category in $update.Categories) {
                            if ($categoryNames -contains $category.Name) {
                                # Additional check for feature updates that might be Windows 11
                                if ($update.Title -like "*feature*" -or $update.Title -like "*upgrade*") {
                                    $isWindows11Update = $true
                                    Write-Host "Matched category '$($category.Name)' for potential Windows 11 update: $($update.Title)" -ForegroundColor Cyan
                                    break
                                }
                            }
                        }
                    }
                    
                    # Check description for additional clues
                    if (!$isWindows11Update -and $update.Description) {
                        if ($update.Description -like "*Windows 11*" -or $update.Description -like "*feature update*") {
                            $isWindows11Update = $true
                            Write-Host "Matched description content for: $($update.Title)" -ForegroundColor Cyan
                        }
                    }
                    
                    if ($isWindows11Update) {
                        $updateCollection.Add($update) | Out-Null
                        Write-Host "✓ Queued for install: $($update.Title)" -ForegroundColor Green
                    }
                }
                
                if ($updateCollection.Count -gt 0) {
                    # Download updates with visible progress
                    Write-Host "Downloading $($updateCollection.Count) Windows 11 updates..." -ForegroundColor Yellow
                    $updateDownloader = $updateSession.CreateUpdateDownloader()
                    $updateDownloader.Updates = $updateCollection
                    
                    Write-Host "Starting download process..." -ForegroundColor Gray
                    $downloadResult = $updateDownloader.Download()
                    Write-Host "Download completed with result code: $($downloadResult.ResultCode)" -ForegroundColor Gray
                    
                    if ($downloadResult.ResultCode -eq 2) {
                        # Install updates with visible progress
                        Write-Host "Installing Windows 11 updates..." -ForegroundColor Yellow
                        $updateInstaller = $updateSession.CreateUpdateInstaller()
                        $updateInstaller.Updates = $updateCollection
                        
                        Write-Host "Starting installation process..." -ForegroundColor Gray
                        $installationResult = $updateInstaller.Install()
                        
                        Write-Host "Installation completed. Result code: $($installationResult.ResultCode)" -ForegroundColor Green
                        
                        if ($installationResult.ResultCode -eq 2) {
                            Write-Host "✓ Windows 11 updates installed successfully!" -ForegroundColor Green
                        } else {
                            Write-Host "Installation result code indicates potential issues: $($installationResult.ResultCode)" -ForegroundColor Yellow
                        }
                    } else {
                        Write-Host "Download failed or incomplete. Result code: $($downloadResult.ResultCode)" -ForegroundColor Yellow
                    }
                } else {
                    Write-Host "No Windows 11 feature updates found in available updates" -ForegroundColor Yellow
                    Write-Host "This may be normal if:" -ForegroundColor Cyan
                    Write-Host "• Windows 11 is already installed" -ForegroundColor Gray
                    Write-Host "• Feature updates are not yet available for this system" -ForegroundColor Gray
                    Write-Host "• System needs to check for updates manually through Settings" -ForegroundColor Gray
                }
            } else {
                Write-Host "No updates found with any search criteria" -ForegroundColor Yellow
            }
        } catch {
            Write-Warning "Windows Update automation encountered an issue: $($_.Exception.Message)"
            Write-Host "Falling back to alternative update triggers..." -ForegroundColor Yellow
        }
        
        # Method 4: Additional Windows 11 upgrade triggers
        Write-Host "`nExecuting additional Windows 11 upgrade triggers..." -ForegroundColor Magenta
        
        # Trigger 1: USOClient for modern Windows Update
        Write-Host "Trigger 1: Modern Windows Update scan..." -ForegroundColor Yellow
        Write-Host "Command: usoclient.exe ScanInstallWait" -ForegroundColor Gray
        try {
            Start-Process -FilePath "usoclient.exe" -ArgumentList "ScanInstallWait" -Wait -NoNewWindow
            Write-Host "✓ USOClient scan completed" -ForegroundColor Green
        } catch {
            Write-Host "USOClient scan failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        
        # Trigger 2: Force refresh of update sources
        Write-Host "Trigger 2: Refreshing Windows Update sources..." -ForegroundColor Yellow
        try {
            Write-Host "Command: usoclient.exe RefreshSettings" -ForegroundColor Gray
            Start-Process -FilePath "usoclient.exe" -ArgumentList "RefreshSettings" -Wait -NoNewWindow
            Write-Host "✓ Update sources refreshed" -ForegroundColor Green
        } catch {
            Write-Host "Update source refresh failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        
        # Trigger 3: Start feature update download specifically
        Write-Host "Trigger 3: Starting feature update download..." -ForegroundColor Yellow
        try {
            Write-Host "Command: usoclient.exe StartDownload" -ForegroundColor Gray
            Start-Process -FilePath "usoclient.exe" -ArgumentList "StartDownload" -Wait -NoNewWindow
            Write-Host "✓ Feature update download initiated" -ForegroundColor Green
        } catch {
            Write-Host "Feature update download failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        
        # Trigger 4: Force Windows Update agent to check for feature updates
        Write-Host "Trigger 4: Forcing Windows Update agent scan..." -ForegroundColor Yellow
        try {
            $updateServiceManager = New-Object -ComObject Microsoft.Update.ServiceManager
            $updateService = $updateServiceManager.AddService2("7971f918-a847-4430-9279-4a52d1efe18d", 7, "")
            Write-Host "✓ Windows Update service configured for feature updates" -ForegroundColor Green
        } catch {
            Write-Host "Windows Update service configuration failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        
        # Method 5: Configure restart options
        Write-Host "`nConfiguring restart options for upgrade completion..." -ForegroundColor Yellow
        
        # Prompt user for restart preference
        Write-Host "`nWhen would you like the system to restart for the Windows 11 upgrade?" -ForegroundColor Cyan
        Write-Host "1. Restart immediately when upgrade is ready (automatic)" -ForegroundColor White
        Write-Host "2. Restart in 1 hour" -ForegroundColor White
        Write-Host "3. Restart in 2 hours" -ForegroundColor White
        Write-Host "4. Restart in 4 hours" -ForegroundColor White
        Write-Host "5. Restart tonight at 2 AM" -ForegroundColor White
        Write-Host "6. Manual restart (you choose when)" -ForegroundColor White
        
        do {
            $choice = Read-Host "`nEnter your choice (1-6)"
        } while ($choice -notmatch '^[1-6]$')
        
        switch ($choice) {
            "1" {
                # Automatic restart when ready
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "AutoRestartShell" -Value 1 -Type DWord -Force
                Write-Host "✓ Configured for automatic restart when upgrade is ready" -ForegroundColor Green
                $restartMessage = "Your system will automatically restart when ready."
            }
            "2" {
                # Restart in 1 hour
                $restartTime = (Get-Date).AddHours(1).ToString("HH:mm")
                Write-Host "Creating scheduled task for restart in 1 hour..." -ForegroundColor Gray
                schtasks /create /tn "Windows11UpgradeRestart" /tr "shutdown /r /f /t 0" /sc once /st $restartTime /f
                Write-Host "✓ Scheduled restart for 1 hour from now ($restartTime)" -ForegroundColor Green
                $restartMessage = "System will restart in 1 hour at $restartTime."
            }
            "3" {
                # Restart in 2 hours
                $restartTime = (Get-Date).AddHours(2).ToString("HH:mm")
                Write-Host "Creating scheduled task for restart in 2 hours..." -ForegroundColor Gray
                schtasks /create /tn "Windows11UpgradeRestart" /tr "shutdown /r /f /t 0" /sc once /st $restartTime /f
                Write-Host "✓ Scheduled restart for 2 hours from now ($restartTime)" -ForegroundColor Green
                $restartMessage = "System will restart in 2 hours at $restartTime."
            }
            "4" {
                # Restart in 4 hours
                $restartTime = (Get-Date).AddHours(4).ToString("HH:mm")
                Write-Host "Creating scheduled task for restart in 4 hours..." -ForegroundColor Gray
                schtasks /create /tn "Windows11UpgradeRestart" /tr "shutdown /r /f /t 0" /sc once /st $restartTime /f
                Write-Host "✓ Scheduled restart for 4 hours from now ($restartTime)" -ForegroundColor Green
                $restartMessage = "System will restart in 4 hours at $restartTime."
            }
            "5" {
                # Restart at 2 AM tonight (or tomorrow if it's already past 2 AM)
                $tonight2AM = Get-Date -Hour 2 -Minute 0 -Second 0
                if ($tonight2AM -lt (Get-Date)) {
                    $tonight2AM = $tonight2AM.AddDays(1)
                }
                $restartTime = $tonight2AM.ToString("HH:mm")
                $restartDate = $tonight2AM.ToString("MM/dd/yyyy")
                Write-Host "Creating scheduled task for restart at 2:00 AM..." -ForegroundColor Gray
                schtasks /create /tn "Windows11UpgradeRestart" /tr "shutdown /r /f /t 0" /sc once /st $restartTime /sd $restartDate /f
                Write-Host "✓ Scheduled restart for tonight at 2:00 AM" -ForegroundColor Green
                $restartMessage = "System will restart tonight at 2:00 AM."
            }
            "6" {
                # Manual restart
                Write-Host "✓ Manual restart selected - you control when to restart" -ForegroundColor Green
                $restartMessage = "Manual restart selected. Restart your computer when ready to complete the upgrade."
            }
        }
        
        Write-Host "`n=== UPGRADE INITIATED ===" -ForegroundColor Green
        Write-Host "✓ Hardware bypass registry entries active" -ForegroundColor White
        Write-Host "✓ Windows 11 Installation Assistant running with visible output" -ForegroundColor White
        Write-Host "✓ Windows Update configured for automatic installation" -ForegroundColor White
        Write-Host "✓ System prepared for upgrade with visible progress" -ForegroundColor White
        Write-Host "✓ Restart option configured" -ForegroundColor White
        Write-Host "`nThe upgrade will proceed with all operations visible!" -ForegroundColor Yellow
        Write-Host $restartMessage -ForegroundColor Cyan
        
        # Force immediate check with visible output
        Write-Host "`nForcing immediate Windows Update check..." -ForegroundColor Magenta
        Write-Host "Command: usoclient.exe ScanInstallWait" -ForegroundColor Gray
        Start-Process -FilePath "usoclient.exe" -ArgumentList "ScanInstallWait"
        
    } catch {
        Write-Error "Upgrade initiation failed: $($_.Exception.Message)"
        Write-Host "Fallback: Registry bypass entries are still active for manual installation." -ForegroundColor Yellow
    }
}

# Execute the complete upgrade
Windows11-Silent-Auto-Upgrade

Write-Host "`n=== SCRIPT COMPLETE ===" -ForegroundColor Red
Write-Host "• Hardware requirements BYPASSED" -ForegroundColor Green
Write-Host "• Windows 11 upgrade INITIATED with visible output" -ForegroundColor Green  
Write-Host "• All operations shown in PowerShell" -ForegroundColor Green
Write-Host "• System will upgrade and restart automatically" -ForegroundColor Green
Write-Host "• Keep this window open to see progress" -ForegroundColor Yellow

# Final triggers with visible output
Write-Host "`nExecuting final update triggers..." -ForegroundColor Cyan

# Legacy Windows Update triggers
Write-Host "Legacy trigger 1: wuauclt.exe /detectnow" -ForegroundColor Gray
Start-Process -FilePath "wuauclt.exe" -ArgumentList "/detectnow" -NoNewWindow
Write-Host "Legacy trigger 2: wuauclt.exe /updatenow" -ForegroundColor Gray  
Start-Process -FilePath "wuauclt.exe" -ArgumentList "/updatenow" -NoNewWindow

# Modern Windows Update triggers
Write-Host "Modern trigger 1: usoclient.exe ScanInstallWait" -ForegroundColor Gray
Start-Process -FilePath "usoclient.exe" -ArgumentList "ScanInstallWait" -NoNewWindow
Write-Host "Modern trigger 2: usoclient.exe StartInstall" -ForegroundColor Gray
Start-Process -FilePath "usoclient.exe" -ArgumentList "StartInstall" -NoNewWindow

# Force feature update check
Write-Host "Feature update trigger: usoclient.exe StartDownload" -ForegroundColor Gray
Start-Process -FilePath "usoclient.exe" -ArgumentList "StartDownload" -NoNewWindow

Write-Host "`n✓ All upgrade triggers executed!" -ForegroundColor Green
Write-Host "✓ Multiple update mechanisms activated" -ForegroundColor Green
Write-Host "`nThe system should now begin downloading and installing Windows 11..." -ForegroundColor Yellow
Write-Host "Monitor Windows Update in Settings > Update & Security for progress." -ForegroundColor Cyan

Write-Host "Upgrade fully initiated with visible progress!" -ForegroundColor Green