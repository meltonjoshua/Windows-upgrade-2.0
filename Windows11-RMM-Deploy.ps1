#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Silently sets registry keys, downloads, and runs the Windows 11 Installation Assistant.
 
.DESCRIPTION
  Designed for deployment through an RMM.
  Must be executed with administrative rights.
  
.NOTES
  Author: Joshua Melton
  Version: 1.0
  For RMM deployment only
#>
 
# ----- CONFIG -----
$TempDir     = "C:\Temp"
$Installer   = Join-Path $TempDir "Windows11InstallationAssistant.exe"
$LogFile     = Join-Path $TempDir "upgrade.log"
$DownloadUrl = "https://go.microsoft.com/fwlink/?linkid=2171764"
 
# Create temp directory if needed
if (-not (Test-Path $TempDir)) {
    New-Item -Path $TempDir -ItemType Directory -Force | Out-Null
}
 
# ----- SET REGISTRY KEYS -----
$regItems = @(
    @{Path="HKCU:\SOFTWARE\Microsoft\PCHC"; Name="UpgradeEligibility"},
    @{Path="HKLM:\SOFTWARE\Microsoft\PCHC"; Name="UpgradeEligibility"},
    @{Path="HKLM:\SYSTEM\Setup\MoSetup"; Name="AllowUpgradesWithUnsupportedTPMOrCPU"},
    @{Path="HKLM:\SYSTEM\Setup\LabConfig"; Name="BypassTPMCheck"},
    @{Path="HKLM:\SYSTEM\Setup\LabConfig"; Name="BypassCPUCheck"},
    @{Path="HKLM:\SYSTEM\Setup\LabConfig"; Name="BypassRAMCheck"},
    @{Path="HKLM:\SYSTEM\Setup\LabConfig"; Name="BypassSecureBootCheck"},
    @{Path="HKLM:\SYSTEM\Setup\LabConfig"; Name="BypassStorageCheck"}
)
 
foreach ($item in $regItems) {
    if (-not (Test-Path $item.Path)) {
        New-Item -Path $item.Path -Force | Out-Null
    }
    New-ItemProperty -Path $item.Path -Name $item.Name -Value 1 -PropertyType DWord -Force | Out-Null
}
 
# ----- DOWNLOAD INSTALLER -----
try {
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $Installer -UseBasicParsing -ErrorAction Stop
} catch {
    Write-Error "Failed to download Windows 11 Installation Assistant. $_"
    exit 1
}
 
# ----- RUN INSTALLER SILENTLY -----
$arguments = "/quietinstall /skipeula /auto upgrade /CopyLogs `"$LogFile`""
 
$process = Start-Process -FilePath $Installer -ArgumentList $arguments -PassThru -Wait
 
# Return installer exit code to RMM
exit $process.ExitCode