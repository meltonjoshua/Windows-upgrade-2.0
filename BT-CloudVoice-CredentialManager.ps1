# BT CloudVoice Credential Manager v1.0
# Secure storage and management for BT CloudVoice login details
# Compatible with Windows 11 upgrade automation scripts

<#
.SYNOPSIS
    Secure credential management system for BT CloudVoice login details
    
.DESCRIPTION
    This module provides secure storage, retrieval, and management of BT CloudVoice 
    credentials using Windows DPAPI encryption and structured configuration files.
    
.FEATURES
    - Encrypted credential storage using Windows DPAPI
    - Multiple environment support (Production, Staging, Development)
    - Automatic credential validation and expiry management
    - Secure configuration file structure
    - Integration with existing PowerShell automation scripts
    - Audit logging for credential access
    
.AUTHOR
    Windows Upgrade Automation Team
    
.VERSION
    1.0
#>

# Global variables for credential management
$script:CredentialPath = "$env:APPDATA\BTCloudVoice\Credentials"
$script:ConfigPath = "$env:APPDATA\BTCloudVoice\Config"
$script:LogPath = "$env:APPDATA\BTCloudVoice\Logs"
$script:EncryptionScope = "CurrentUser"

# Enhanced logging function compatible with existing scripts
function Write-CredentialLog {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Color = "White"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] [CREDENTIAL-MGR] $Message"
    
    # Console output with color
    Write-Host $logEntry -ForegroundColor $Color
    
    # File logging
    try {
        if (!(Test-Path $script:LogPath)) {
            New-Item -Path $script:LogPath -ItemType Directory -Force | Out-Null
        }
        $logFile = Join-Path $script:LogPath "BT-CloudVoice-$(Get-Date -Format 'yyyy-MM-dd').log"
        Add-Content -Path $logFile -Value $logEntry -Encoding UTF8 -ErrorAction SilentlyContinue
    } catch {
        # Silent continue on log errors
    }
}

# Initialize credential storage directories
function Initialize-CredentialStorage {
    Write-CredentialLog "Initializing BT CloudVoice credential storage..." "INFO" "Cyan"
    
    try {
        # Create required directories
        $directories = @($script:CredentialPath, $script:ConfigPath, $script:LogPath)
        foreach ($dir in $directories) {
            if (!(Test-Path $dir)) {
                New-Item -Path $dir -ItemType Directory -Force | Out-Null
                Write-CredentialLog "Created directory: $dir" "SUCCESS" "Green"
            }
        }
        
        # Set secure permissions on credential directory
        $acl = Get-Acl $script:CredentialPath
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $env:USERNAME, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
        )
        $acl.SetAccessRule($accessRule)
        Set-Acl -Path $script:CredentialPath -AclObject $acl
        
        Write-CredentialLog "✓ Credential storage initialized successfully" "SUCCESS" "Green"
        return $true
    } catch {
        Write-CredentialLog "Failed to initialize credential storage: $($_.Exception.Message)" "ERROR" "Red"
        return $false
    }
}

# BT CloudVoice credential structure
class BTCloudVoiceCredential {
    [string]$Environment
    [string]$Username
    [string]$EncryptedPassword
    [string]$ApiUrl
    [string]$Domain
    [string]$Extension
    [datetime]$CreatedDate
    [datetime]$LastModified
    [datetime]$ExpiryDate
    [bool]$IsActive
    [hashtable]$AdditionalSettings
    
    BTCloudVoiceCredential() {
        $this.CreatedDate = Get-Date
        $this.LastModified = Get-Date
        $this.IsActive = $true
        $this.AdditionalSettings = @{}
    }
}

# Encrypt sensitive data using Windows DPAPI
function Protect-CredentialData {
    param(
        [string]$PlainText,
        [string]$Scope = "CurrentUser"
    )
    
    try {
        $secureString = ConvertTo-SecureString -String $PlainText -AsPlainText -Force
        $encrypted = ConvertFrom-SecureString -SecureString $secureString
        return $encrypted
    } catch {
        Write-CredentialLog "Failed to encrypt credential data: $($_.Exception.Message)" "ERROR" "Red"
        return $null
    }
}

# Decrypt sensitive data using Windows DPAPI
function Unprotect-CredentialData {
    param(
        [string]$EncryptedText
    )
    
    try {
        $secureString = ConvertTo-SecureString -String $EncryptedText
        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
        $plainText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        return $plainText
    } catch {
        Write-CredentialLog "Failed to decrypt credential data: $($_.Exception.Message)" "ERROR" "Red"
        return $null
    }
}

# Store BT CloudVoice credentials securely
function Set-BTCloudVoiceCredential {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Environment,
        
        [Parameter(Mandatory = $true)]
        [string]$Username,
        
        [Parameter(Mandatory = $true)]
        [string]$Password,
        
        [Parameter(Mandatory = $true)]
        [string]$ApiUrl,
        
        [string]$Domain = "",
        [string]$Extension = "",
        [datetime]$ExpiryDate = (Get-Date).AddDays(90),
        [hashtable]$AdditionalSettings = @{}
    )
    
    Write-CredentialLog "Storing BT CloudVoice credentials for environment: $Environment" "INFO" "Yellow"
    
    try {
        # Initialize storage if needed
        if (!(Initialize-CredentialStorage)) {
            throw "Failed to initialize credential storage"
        }
        
        # Create credential object
        $credential = [BTCloudVoiceCredential]::new()
        $credential.Environment = $Environment
        $credential.Username = $Username
        $credential.EncryptedPassword = Protect-CredentialData -PlainText $Password
        $credential.ApiUrl = $ApiUrl
        $credential.Domain = $Domain
        $credential.Extension = $Extension
        $credential.ExpiryDate = $ExpiryDate
        $credential.AdditionalSettings = $AdditionalSettings
        
        # Validate required fields
        if (!$credential.EncryptedPassword) {
            throw "Failed to encrypt password"
        }
        
        # Save to secure file
        $credentialFile = Join-Path $script:CredentialPath "$Environment.credential"
        $credential | ConvertTo-Json -Depth 3 | Set-Content -Path $credentialFile -Encoding UTF8
        
        Write-CredentialLog "✓ Credentials stored successfully for environment: $Environment" "SUCCESS" "Green"
        Write-CredentialLog "Credential file: $credentialFile" "INFO" "Gray"
        
        return $true
    } catch {
        Write-CredentialLog "Failed to store credentials: $($_.Exception.Message)" "ERROR" "Red"
        return $false
    }
}

# Retrieve BT CloudVoice credentials
function Get-BTCloudVoiceCredential {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Environment,
        
        [switch]$IncludePassword
    )
    
    Write-CredentialLog "Retrieving BT CloudVoice credentials for environment: $Environment" "INFO" "Cyan"
    
    try {
        $credentialFile = Join-Path $script:CredentialPath "$Environment.credential"
        
        if (!(Test-Path $credentialFile)) {
            Write-CredentialLog "Credential file not found for environment: $Environment" "WARNING" "Yellow"
            return $null
        }
        
        # Load and parse credential file
        $credentialJson = Get-Content -Path $credentialFile -Raw -Encoding UTF8
        $credential = $credentialJson | ConvertFrom-Json
        
        # Check if credential is expired
        $expiryDate = [datetime]$credential.ExpiryDate
        if ($expiryDate -lt (Get-Date)) {
            Write-CredentialLog "Credential has expired for environment: $Environment" "WARNING" "Yellow"
            return $null
        }
        
        # Create return object
        $result = @{
            Environment = $credential.Environment
            Username = $credential.Username
            ApiUrl = $credential.ApiUrl
            Domain = $credential.Domain
            Extension = $credential.Extension
            CreatedDate = $credential.CreatedDate
            LastModified = $credential.LastModified
            ExpiryDate = $credential.ExpiryDate
            IsActive = $credential.IsActive
            AdditionalSettings = $credential.AdditionalSettings
        }
        
        # Include decrypted password if requested
        if ($IncludePassword) {
            $result.Password = Unprotect-CredentialData -EncryptedText $credential.EncryptedPassword
            Write-CredentialLog "Password included in credential retrieval" "INFO" "Gray"
        }
        
        Write-CredentialLog "✓ Credentials retrieved successfully for environment: $Environment" "SUCCESS" "Green"
        return $result
    } catch {
        Write-CredentialLog "Failed to retrieve credentials: $($_.Exception.Message)" "ERROR" "Red"
        return $null
    }
}

# List all stored BT CloudVoice credentials
function Get-BTCloudVoiceCredentialList {
    Write-CredentialLog "Retrieving list of stored BT CloudVoice credentials..." "INFO" "Cyan"
    
    try {
        if (!(Test-Path $script:CredentialPath)) {
            Write-CredentialLog "Credential storage not initialized" "WARNING" "Yellow"
            return @()
        }
        
        $credentialFiles = Get-ChildItem -Path $script:CredentialPath -Filter "*.credential"
        $credentials = @()
        
        foreach ($file in $credentialFiles) {
            try {
                $credentialJson = Get-Content -Path $file.FullName -Raw -Encoding UTF8
                $credential = $credentialJson | ConvertFrom-Json
                
                $credentials += @{
                    Environment = $credential.Environment
                    Username = $credential.Username
                    ApiUrl = $credential.ApiUrl
                    Domain = $credential.Domain
                    Extension = $credential.Extension
                    CreatedDate = $credential.CreatedDate
                    ExpiryDate = $credential.ExpiryDate
                    IsActive = $credential.IsActive
                    IsExpired = ([datetime]$credential.ExpiryDate -lt (Get-Date))
                }
            } catch {
                Write-CredentialLog "Failed to parse credential file: $($file.Name)" "WARNING" "Yellow"
            }
        }
        
        Write-CredentialLog "✓ Retrieved $($credentials.Count) credential entries" "SUCCESS" "Green"
        return $credentials
    } catch {
        Write-CredentialLog "Failed to retrieve credential list: $($_.Exception.Message)" "ERROR" "Red"
        return @()
    }
}

# Remove BT CloudVoice credentials
function Remove-BTCloudVoiceCredential {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Environment,
        
        [switch]$Force
    )
    
    Write-CredentialLog "Removing BT CloudVoice credentials for environment: $Environment" "WARNING" "Yellow"
    
    try {
        $credentialFile = Join-Path $script:CredentialPath "$Environment.credential"
        
        if (!(Test-Path $credentialFile)) {
            Write-CredentialLog "Credential file not found for environment: $Environment" "WARNING" "Yellow"
            return $false
        }
        
        if (!$Force) {
            $confirmation = Read-Host "Are you sure you want to remove credentials for environment '$Environment'? (Y/N)"
            if ($confirmation -notmatch '^[Yy]') {
                Write-CredentialLog "Credential removal cancelled by user" "INFO" "Gray"
                return $false
            }
        }
        
        Remove-Item -Path $credentialFile -Force
        Write-CredentialLog "✓ Credentials removed successfully for environment: $Environment" "SUCCESS" "Green"
        
        return $true
    } catch {
        Write-CredentialLog "Failed to remove credentials: $($_.Exception.Message)" "ERROR" "Red"
        return $false
    }
}

# Test BT CloudVoice connection using stored credentials
function Test-BTCloudVoiceConnection {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Environment
    )
    
    Write-CredentialLog "Testing BT CloudVoice connection for environment: $Environment" "INFO" "Yellow"
    
    try {
        $credential = Get-BTCloudVoiceCredential -Environment $Environment -IncludePassword
        
        if (!$credential) {
            Write-CredentialLog "No valid credentials found for environment: $Environment" "ERROR" "Red"
            return $false
        }
        
        # Basic connectivity test to API URL
        $testUrl = $credential.ApiUrl
        if ($testUrl -and $testUrl -ne "") {
            try {
                $response = Invoke-WebRequest -Uri $testUrl -Method Head -TimeoutSec 10 -ErrorAction Stop
                Write-CredentialLog "✓ API endpoint is reachable: $testUrl" "SUCCESS" "Green"
            } catch {
                Write-CredentialLog "API endpoint unreachable: $testUrl - $($_.Exception.Message)" "WARNING" "Yellow"
            }
        }
        
        Write-CredentialLog "✓ Connection test completed for environment: $Environment" "SUCCESS" "Green"
        return $true
    } catch {
        Write-CredentialLog "Connection test failed: $($_.Exception.Message)" "ERROR" "Red"
        return $false
    }
}

# Export credentials for backup (encrypted)
function Export-BTCloudVoiceCredentials {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ExportPath,
        
        [string[]]$Environments = @()
    )
    
    Write-CredentialLog "Exporting BT CloudVoice credentials to: $ExportPath" "INFO" "Yellow"
    
    try {
        $exportData = @{
            ExportDate = Get-Date
            Version = "1.0"
            Credentials = @()
        }
        
        $credentials = Get-BTCloudVoiceCredentialList
        
        foreach ($cred in $credentials) {
            if ($Environments.Count -eq 0 -or $cred.Environment -in $Environments) {
                $credentialFile = Join-Path $script:CredentialPath "$($cred.Environment).credential"
                if (Test-Path $credentialFile) {
                    $credentialData = Get-Content -Path $credentialFile -Raw -Encoding UTF8
                    $exportData.Credentials += @{
                        Environment = $cred.Environment
                        Data = $credentialData
                    }
                }
            }
        }
        
        $exportData | ConvertTo-Json -Depth 5 | Set-Content -Path $ExportPath -Encoding UTF8
        Write-CredentialLog "✓ Exported $($exportData.Credentials.Count) credential sets to: $ExportPath" "SUCCESS" "Green"
        
        return $true
    } catch {
        Write-CredentialLog "Failed to export credentials: $($_.Exception.Message)" "ERROR" "Red"
        return $false
    }
}

# Import credentials from backup
function Import-BTCloudVoiceCredentials {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ImportPath,
        
        [switch]$Overwrite
    )
    
    Write-CredentialLog "Importing BT CloudVoice credentials from: $ImportPath" "INFO" "Yellow"
    
    try {
        if (!(Test-Path $ImportPath)) {
            throw "Import file not found: $ImportPath"
        }
        
        Initialize-CredentialStorage | Out-Null
        
        $importData = Get-Content -Path $ImportPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $importedCount = 0
        
        foreach ($credentialEntry in $importData.Credentials) {
            $environment = $credentialEntry.Environment
            $credentialFile = Join-Path $script:CredentialPath "$environment.credential"
            
            if ((Test-Path $credentialFile) -and !$Overwrite) {
                Write-CredentialLog "Skipping existing credential for environment: $environment (use -Overwrite to replace)" "WARNING" "Yellow"
                continue
            }
            
            $credentialEntry.Data | Set-Content -Path $credentialFile -Encoding UTF8
            $importedCount++
            Write-CredentialLog "Imported credential for environment: $environment" "SUCCESS" "Green"
        }
        
        Write-CredentialLog "✓ Imported $importedCount credential sets from backup" "SUCCESS" "Green"
        return $true
    } catch {
        Write-CredentialLog "Failed to import credentials: $($_.Exception.Message)" "ERROR" "Red"
        return $false
    }
}

# Display credential storage information
function Show-BTCloudVoiceCredentialInfo {
    Write-CredentialLog "BT CloudVoice Credential Manager Information" "INFO" "Cyan"
    Write-Host ""
    
    Write-Host "Storage Locations:" -ForegroundColor Yellow
    Write-Host "  Credentials: $script:CredentialPath" -ForegroundColor Gray
    Write-Host "  Configuration: $script:ConfigPath" -ForegroundColor Gray
    Write-Host "  Logs: $script:LogPath" -ForegroundColor Gray
    Write-Host ""
    
    $credentials = Get-BTCloudVoiceCredentialList
    
    if ($credentials.Count -eq 0) {
        Write-Host "No stored credentials found." -ForegroundColor Yellow
    } else {
        Write-Host "Stored Credentials:" -ForegroundColor Yellow
        $credentials | Format-Table -Property Environment, Username, ApiUrl, ExpiryDate, IsExpired -AutoSize
    }
    
    Write-Host ""
    Write-Host "Usage Examples:" -ForegroundColor Yellow
    Write-Host "  Set-BTCloudVoiceCredential -Environment 'Production' -Username 'user@company.com' -Password 'password' -ApiUrl 'https://api.btcloudvoice.com'" -ForegroundColor Gray
    Write-Host "  Get-BTCloudVoiceCredential -Environment 'Production' -IncludePassword" -ForegroundColor Gray
    Write-Host "  Test-BTCloudVoiceConnection -Environment 'Production'" -ForegroundColor Gray
    Write-Host ""
}

# Export module functions
Export-ModuleMember -Function @(
    'Initialize-CredentialStorage',
    'Set-BTCloudVoiceCredential',
    'Get-BTCloudVoiceCredential',
    'Get-BTCloudVoiceCredentialList',
    'Remove-BTCloudVoiceCredential',
    'Test-BTCloudVoiceConnection',
    'Export-BTCloudVoiceCredentials',
    'Import-BTCloudVoiceCredentials',
    'Show-BTCloudVoiceCredentialInfo'
)

# Display module information on import
Write-CredentialLog "BT CloudVoice Credential Manager v1.0 loaded" "SUCCESS" "Green"
Write-CredentialLog "Use 'Show-BTCloudVoiceCredentialInfo' for usage information" "INFO" "Cyan"