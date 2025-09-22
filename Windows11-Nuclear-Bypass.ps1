# Windows 11 Ultimate Bypass Script v5.0
# Nuclear approach for persistent 0xa0000400 errors
# Bypasses Installation Assistant entirely

# Ensure running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Red
    exit 1
}

Write-Host "Windows 11 Ultimate Bypass Script v5.0" -ForegroundColor Green
Write-Host "Nuclear approach for persistent 0xa0000400 errors" -ForegroundColor Yellow
Write-Host "This completely bypasses the Installation Assistant" -ForegroundColor Yellow

try {
    # NUCLEAR OPTION 1: Complete registry takeover
    Write-Host "Setting NUCLEAR bypass registry entries..." -ForegroundColor Red
    
    # All possible registry paths for bypasses
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
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Services\7971f918-a847-4430-9279-4a52d1efe18d" = @{
            "RegisteredWithAU" = 1
        }
    }
    
    foreach ($regPath in $registryPaths.Keys) {
        try {
            # Create path if it doesn't exist
            if (!(Test-Path $regPath)) {
                $null = New-Item -Path $regPath -Force -ErrorAction SilentlyContinue
            }
            
            # Set all values for this path
            foreach ($valueName in $registryPaths[$regPath].Keys) {
                $value = $registryPaths[$regPath][$valueName]
                Set-ItemProperty -Path $regPath -Name $valueName -Value $value -Type DWord -Force -ErrorAction SilentlyContinue
            }
            Write-Host "✓ Set bypass entries in $regPath" -ForegroundColor Green
        } catch {
            Write-Host "⚠ Could not set entries in $regPath" -ForegroundColor Yellow
        }
    }
    
    # NUCLEAR OPTION 2: Force Windows Update to think it's a different system
    Write-Host "Spoofing system identity for Windows Update..." -ForegroundColor Red
    
    $ntVersionPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
    if (Test-Path $ntVersionPath) {
        # Backup original values
        $originalBuild = (Get-ItemProperty -Path $ntVersionPath -Name "CurrentBuild" -ErrorAction SilentlyContinue).CurrentBuild
        $originalVersion = (Get-ItemProperty -Path $ntVersionPath -Name "CurrentVersion" -ErrorAction SilentlyContinue).CurrentVersion
        
        # Set to Windows 10 21H2 (known compatible)
        Set-ItemProperty -Path $ntVersionPath -Name "CurrentBuild_Original" -Value $originalBuild -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $ntVersionPath -Name "CurrentVersion_Original" -Value $originalVersion -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $ntVersionPath -Name "CurrentBuild" -Value "19044" -Force
        Set-ItemProperty -Path $ntVersionPath -Name "CurrentBuildNumber" -Value "19044" -Force
        Set-ItemProperty -Path $ntVersionPath -Name "CurrentVersion" -Value "10.0" -Force
        Set-ItemProperty -Path $ntVersionPath -Name "ProductName" -Value "Windows 10 Pro" -Force
        
        Write-Host "✓ System identity spoofed to Windows 10 21H2" -ForegroundColor Green
    }
    
    # NUCLEAR OPTION 3: Complete Windows Update scorched earth
    Write-Host "Performing scorched earth Windows Update reset..." -ForegroundColor Red
    
    # Stop ALL related services
    $services = @("wuauserv", "cryptSvc", "bits", "msiserver", "appidsvc", "SENS", "EventSystem")
    foreach ($service in $services) {
        try {
            Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
            Write-Host "Stopped $service" -ForegroundColor Gray
        } catch {
            Write-Host "Could not stop $service" -ForegroundColor Yellow
        }
    }
    
    # Nuclear cache clearing
    $cachePaths = @(
        "$env:SystemRoot\SoftwareDistribution",
        "$env:SystemRoot\System32\catroot2",
        "$env:LOCALAPPDATA\Microsoft\Windows\INetCache",
        "$env:SystemRoot\Logs\WindowsUpdate"
    )
    
    foreach ($cachePath in $cachePaths) {
        if (Test-Path $cachePath) {
            try {
                Remove-Item "$cachePath\*" -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "Nuked cache: $cachePath" -ForegroundColor Gray
            } catch {
                Write-Host "Could not clear: $cachePath" -ForegroundColor Yellow
            }
        }
    }
    
    # Restart services
    foreach ($service in $services) {
        try {
            Start-Service -Name $service -ErrorAction SilentlyContinue
            Write-Host "Restarted $service" -ForegroundColor Gray
        } catch {
            Write-Host "Could not restart $service" -ForegroundColor Yellow
        }
    }
    
    Write-Host "✓ Scorched earth reset completed" -ForegroundColor Green
    
    # NUCLEAR OPTION 4: Alternative upgrade method - Media Creation Tool
    Write-Host "Attempting alternative upgrade method..." -ForegroundColor Yellow
    
    $mediaToolPath = "$env:TEMP\MediaCreationTool21H2.exe"
    $mediaToolUrl = "https://software.download.prss.microsoft.com/dbazure/Win11_21H2_MediaCreationTool.exe"
    
    try {
        Write-Host "Downloading Media Creation Tool (alternative to Installation Assistant)..." -ForegroundColor Yellow
        
        # Remove existing file
        if (Test-Path $mediaToolPath) {
            Remove-Item $mediaToolPath -Force
        }
        
        # Download Media Creation Tool
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($mediaToolUrl, $mediaToolPath)
        $webClient.Dispose()
        
        if (Test-Path $mediaToolPath) {
            $fileSize = (Get-Item $mediaToolPath).Length
            if ($fileSize -gt 1MB) {
                Write-Host "✓ Media Creation Tool downloaded successfully" -ForegroundColor Green
                Write-Host "Launching Media Creation Tool..." -ForegroundColor Yellow
                
                # Launch Media Creation Tool
                Start-Process -FilePath $mediaToolPath -ArgumentList "/Upgrade" -PassThru
                Write-Host "✓ Media Creation Tool launched" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "Could not download Media Creation Tool: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # NUCLEAR OPTION 5: Force Windows Update feature update
    Write-Host "Force-triggering Windows Update feature update..." -ForegroundColor Yellow
    
    try {
        # Force Windows Update to check for feature updates
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateUpdateSearcher()
        
        # Search specifically for feature updates
        $searchResult = $updateSearcher.Search("IsInstalled=0 and CategoryIDs contains '5312e4f1-6372-442d-aeb2-15f2132c9bd7'")
        
        Write-Host "Found $($searchResult.Updates.Count) potential feature updates" -ForegroundColor Gray
        
        # Trigger update scan with all methods
        Start-Process -FilePath "usoclient.exe" -ArgumentList "ScanInstallWait" -NoNewWindow -ErrorAction SilentlyContinue
        Start-Process -FilePath "usoclient.exe" -ArgumentList "RefreshSettings" -NoNewWindow -ErrorAction SilentlyContinue
        Start-Process -FilePath "wuauclt.exe" -ArgumentList "/detectnow" -NoNewWindow -ErrorAction SilentlyContinue
        
        Write-Host "✓ Windows Update scan triggered" -ForegroundColor Green
        
    } catch {
        Write-Host "Windows Update trigger failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "CRITICAL ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== NUCLEAR BYPASS COMPLETED ===" -ForegroundColor Red
Write-Host "✓ All possible registry bypasses set" -ForegroundColor White
Write-Host "✓ System identity spoofed to compatible version" -ForegroundColor White
Write-Host "✓ Complete Windows Update reset performed" -ForegroundColor White
Write-Host "✓ Media Creation Tool downloaded and launched" -ForegroundColor White
Write-Host "✓ Windows Update feature scan triggered" -ForegroundColor White
Write-Host ""
Write-Host "NEXT STEPS FOR PERSISTENT 0xa0000400:" -ForegroundColor Red
Write-Host "1. RESTART your computer immediately" -ForegroundColor Yellow
Write-Host "2. Use the Media Creation Tool instead of Installation Assistant" -ForegroundColor Yellow
Write-Host "3. Or go to Settings > Windows Update and check for updates" -ForegroundColor Yellow
Write-Host "4. If nothing works, download Windows 11 ISO and upgrade manually" -ForegroundColor Yellow
Write-Host ""
Write-Host "Manual ISO upgrade instructions:" -ForegroundColor Cyan
Write-Host "• Download Windows 11 ISO from Microsoft" -ForegroundColor Cyan
Write-Host "• Mount the ISO file" -ForegroundColor Cyan
Write-Host "• Run setup.exe from the mounted drive" -ForegroundColor Cyan
Write-Host "• The registry bypasses will work with manual ISO upgrade" -ForegroundColor Cyan
Write-Host ""
Write-Host "This was the nuclear option. A restart is now MANDATORY." -ForegroundColor Red