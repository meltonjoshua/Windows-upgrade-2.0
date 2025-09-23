# BT CloudVoice Credential Management - Perfect Layout Documentation

## Overview

This documentation provides a comprehensive guide for the **perfect layout for storing BT CloudVoice login details** within the Windows 11 upgrade automation environment. The solution provides enterprise-grade security, encryption, and management capabilities.

## 🏗️ Architecture Overview

### File Structure
```
Windows-upgrade-2.0/
├── BT-CloudVoice-CredentialManager.ps1  # Main credential management module
├── BT-CloudVoice-Config.json           # Configuration template and settings
├── BT-CloudVoice-Setup-Example.ps1     # Example implementation and setup
└── BT-CloudVoice-Documentation.md      # This documentation
```

### Storage Layout
```
%APPDATA%\BTCloudVoice\
├── Credentials\                         # Encrypted credential files
│   ├── Production.credential           # Production environment credentials
│   ├── Staging.credential             # Staging environment credentials
│   └── Development.credential         # Development environment credentials
├── Config\                            # Configuration files
│   └── settings.json                 # User-specific settings
└── Logs\                             # Audit and operation logs
    ├── BT-CloudVoice-2024-12-19.log  # Daily log files
    └── audit.log                     # Security audit log
```

## 🔐 Security Features

### Encryption
- **Windows DPAPI**: Uses Windows Data Protection API for credential encryption
- **User-Scope Encryption**: Credentials encrypted for current user only
- **AES-256 Encryption**: Strong encryption for sensitive data
- **Secure Memory Handling**: Passwords cleared from memory after use

### Access Control
- **File System Permissions**: Restricted access to credential directories
- **User-Only Access**: Credentials accessible only to the user who created them
- **Audit Logging**: All credential access operations logged
- **Expiry Management**: Automatic credential expiration and validation

### Security Best Practices
- **No Plain Text Storage**: Passwords never stored in plain text
- **Secure Configuration**: Settings validate against security policies
- **Permission Validation**: Directory permissions set to user-only access
- **Encrypted Backups**: Backup files maintain encryption

## 📋 Core Components

### 1. BT-CloudVoice-CredentialManager.ps1

Main PowerShell module providing credential management functionality.

#### Key Functions:
- `Set-BTCloudVoiceCredential`: Store new credentials securely
- `Get-BTCloudVoiceCredential`: Retrieve stored credentials
- `Get-BTCloudVoiceCredentialList`: List all stored credentials
- `Remove-BTCloudVoiceCredential`: Remove credentials
- `Test-BTCloudVoiceConnection`: Test credential connectivity
- `Export-BTCloudVoiceCredentials`: Create encrypted backups
- `Import-BTCloudVoiceCredentials`: Restore from backups

#### BTCloudVoiceCredential Class:
```powershell
class BTCloudVoiceCredential {
    [string]$Environment        # Environment name (Production, Staging, etc.)
    [string]$Username          # BT CloudVoice username
    [string]$EncryptedPassword # DPAPI encrypted password
    [string]$ApiUrl            # API endpoint URL
    [string]$Domain            # BT CloudVoice domain
    [string]$Extension         # Phone extension number
    [datetime]$CreatedDate     # Creation timestamp
    [datetime]$LastModified    # Last modification timestamp
    [datetime]$ExpiryDate      # Credential expiry date
    [bool]$IsActive            # Active status flag
    [hashtable]$AdditionalSettings # Custom settings and metadata
}
```

### 2. BT-CloudVoice-Config.json

Configuration template providing structured settings for different environments.

#### Environment Configuration:
- **Production**: Live system settings with full security
- **Staging**: Testing environment with standard security
- **Development**: Development system with relaxed security

#### Settings Categories:
- **API Settings**: Endpoints, timeouts, retry logic
- **Authentication**: OAuth2, session management
- **Security**: Encryption levels, TLS versions
- **Features**: Available BT CloudVoice features
- **Logging**: Audit and operation logging
- **Validation**: Input validation patterns

### 3. BT-CloudVoice-Setup-Example.ps1

Example implementation showing how to use the credential management system.

#### Examples Included:
- Setting up credentials for multiple environments
- Retrieving credentials with and without passwords
- Testing connections to BT CloudVoice APIs
- Creating and restoring backups
- Integration with existing Windows scripts

## 🚀 Quick Start Guide

### 1. Initial Setup

```powershell
# Import the credential manager
. ".\BT-CloudVoice-CredentialManager.ps1"

# Initialize storage (automatic on first use)
Initialize-CredentialStorage
```

### 2. Store Credentials

```powershell
# Store production credentials
Set-BTCloudVoiceCredential `
    -Environment "Production" `
    -Username "admin@yourcompany.com" `
    -Password "SecureP@ssw0rd123!" `
    -ApiUrl "https://api.btcloudvoice.com" `
    -Domain "yourcompany.btcloudvoice.com" `
    -Extension "1001" `
    -AdditionalSettings @{
        "Department" = "IT Administration"
        "AccessLevel" = "Administrator"
        "Region" = "UK"
    }
```

### 3. Retrieve Credentials

```powershell
# Get credentials without password
$credentials = Get-BTCloudVoiceCredential -Environment "Production"

# Get credentials with password (for authentication)
$fullCredentials = Get-BTCloudVoiceCredential -Environment "Production" -IncludePassword
```

### 4. List All Credentials

```powershell
# Display all stored credentials
Get-BTCloudVoiceCredentialList | Format-Table
```

### 5. Test Connection

```powershell
# Test connection to BT CloudVoice
Test-BTCloudVoiceConnection -Environment "Production"
```

## 🔧 Advanced Usage

### Multi-Environment Management

```powershell
# Set up multiple environments
$environments = @{
    "Production" = @{
        Username = "prod-admin@company.com"
        ApiUrl = "https://api.btcloudvoice.com"
        Extension = "1001"
    }
    "Staging" = @{
        Username = "test-user@company.com"
        ApiUrl = "https://staging-api.btcloudvoice.com"
        Extension = "2001"
    }
    "Development" = @{
        Username = "dev-user@company.com"
        ApiUrl = "https://dev-api.btcloudvoice.com"
        Extension = "3001"
    }
}

foreach ($env in $environments.Keys) {
    $settings = $environments[$env]
    Set-BTCloudVoiceCredential `
        -Environment $env `
        -Username $settings.Username `
        -Password (Read-Host "Enter password for $env" -AsSecureString | ConvertFrom-SecureString) `
        -ApiUrl $settings.ApiUrl `
        -Extension $settings.Extension
}
```

### Backup and Restore

```powershell
# Create backup of all credentials
$backupPath = "C:\Backups\BT-CloudVoice-$(Get-Date -Format 'yyyyMMdd').json"
Export-BTCloudVoiceCredentials -ExportPath $backupPath

# Restore from backup
Import-BTCloudVoiceCredentials -ImportPath $backupPath -Overwrite
```

### Integration with Existing Scripts

```powershell
# Example integration in Windows 11 upgrade script
function Initialize-BTCloudVoiceIntegration {
    param([string]$Environment = "Production")
    
    # Load credential manager
    . "$PSScriptRoot\BT-CloudVoice-CredentialManager.ps1"
    
    # Get credentials
    $credentials = Get-BTCloudVoiceCredential -Environment $Environment -IncludePassword
    
    if ($credentials) {
        Write-LogMessage "BT CloudVoice credentials loaded for $Environment" "SUCCESS" "Green"
        return $credentials
    } else {
        Write-LogMessage "Failed to load BT CloudVoice credentials for $Environment" "ERROR" "Red"
        return $null
    }
}

# Use in main script
$btCredentials = Initialize-BTCloudVoiceIntegration -Environment "Production"
if ($btCredentials) {
    # Connect to BT CloudVoice API
    # Your integration code here
}
```

## 🛡️ Security Considerations

### Credential Protection
1. **DPAPI Encryption**: Credentials encrypted using Windows DPAPI
2. **User-Scope Security**: Only accessible by the user who created them
3. **No Network Transmission**: Credentials stored locally only
4. **Secure Memory Handling**: Passwords cleared from memory after use

### File System Security
1. **Restricted Permissions**: Credential directories accessible only to current user
2. **Secure Locations**: Stored in user's protected AppData directory
3. **Audit Logging**: All access operations logged with timestamps
4. **Backup Encryption**: Backup files maintain encryption

### Best Practices
1. **Regular Rotation**: Set expiry dates and rotate credentials regularly
2. **Environment Separation**: Use different credentials for different environments
3. **Principle of Least Privilege**: Grant minimum necessary access levels
4. **Audit Reviews**: Regularly review credential access logs

## 📊 Monitoring and Logging

### Log Files
- **Daily Logs**: `%APPDATA%\BTCloudVoice\Logs\BT-CloudVoice-YYYY-MM-DD.log`
- **Audit Logs**: Security and access audit trails
- **Error Logs**: Detailed error information for troubleshooting

### Log Levels
- **INFO**: General information and status updates
- **SUCCESS**: Successful operations
- **WARNING**: Non-critical issues that should be reviewed
- **ERROR**: Critical errors requiring immediate attention

### Monitoring Examples
```powershell
# Check credential expiry
$credentials = Get-BTCloudVoiceCredentialList
$expiringSoon = $credentials | Where-Object { 
    $_.ExpiryDate -lt (Get-Date).AddDays(7) -and !$_.IsExpired 
}

if ($expiringSoon) {
    Write-Host "Credentials expiring soon:" -ForegroundColor Yellow
    $expiringSoon | Format-Table Environment, Username, ExpiryDate
}
```

## 🔄 Maintenance Tasks

### Regular Tasks
1. **Credential Rotation**: Update passwords before expiry
2. **Backup Creation**: Regular encrypted backups
3. **Log Review**: Review access and error logs
4. **Permission Audit**: Verify file system permissions

### Automated Maintenance Script
```powershell
# Daily maintenance script
function Invoke-BTCloudVoiceMaintenance {
    # Check for expiring credentials
    $expiring = Get-BTCloudVoiceCredentialList | Where-Object { 
        $_.ExpiryDate -lt (Get-Date).AddDays(7) 
    }
    
    if ($expiring) {
        Write-Warning "Found $($expiring.Count) credentials expiring within 7 days"
        $expiring | Format-Table Environment, Username, ExpiryDate
    }
    
    # Create daily backup
    $backupPath = "$env:APPDATA\BTCloudVoice\Backups\Daily-$(Get-Date -Format 'yyyyMMdd').json"
    Export-BTCloudVoiceCredentials -ExportPath $backupPath
    
    # Clean old logs (older than 30 days)
    $logPath = "$env:APPDATA\BTCloudVoice\Logs"
    Get-ChildItem -Path $logPath -Filter "*.log" | 
        Where-Object { $_.CreationTime -lt (Get-Date).AddDays(-30) } |
        Remove-Item -Force
}
```

## 🆘 Troubleshooting

### Common Issues

#### 1. Permission Denied Errors
**Symptoms**: Access denied when creating or accessing credential files
**Solution**: 
```powershell
# Run PowerShell as Administrator and reset permissions
$credPath = "$env:APPDATA\BTCloudVoice"
$acl = Get-Acl $credPath
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $env:USERNAME, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
)
$acl.SetAccessRule($accessRule)
Set-Acl -Path $credPath -AclObject $acl
```

#### 2. Encryption/Decryption Failures
**Symptoms**: Unable to decrypt stored credentials
**Causes**: User profile changes, system restoration, different user context
**Solution**: 
```powershell
# Re-encrypt credentials with current user context
$credential = Get-BTCloudVoiceCredential -Environment "Production"
if (!$credential) {
    # Re-create credential with fresh encryption
    Set-BTCloudVoiceCredential -Environment "Production" -Username "..." -Password "..."
}
```

#### 3. Missing Configuration Files
**Symptoms**: Configuration files not found
**Solution**:
```powershell
# Reinitialize storage
Initialize-CredentialStorage

# Copy configuration template
Copy-Item "BT-CloudVoice-Config.json" "$env:APPDATA\BTCloudVoice\Config\settings.json"
```

#### 4. Network Connectivity Issues
**Symptoms**: Connection tests fail
**Solution**:
```powershell
# Test basic connectivity
Test-NetConnection -ComputerName "api.btcloudvoice.com" -Port 443

# Check proxy settings
netsh winhttp show proxy

# Test with different timeout values
Test-BTCloudVoiceConnection -Environment "Production" -Timeout 60
```

### Debug Mode
```powershell
# Enable verbose logging
$VerbosePreference = "Continue"
$DebugPreference = "Continue"

# Run operations with detailed output
Get-BTCloudVoiceCredential -Environment "Production" -Verbose -Debug
```

## 📚 API Reference

### Core Functions

#### Set-BTCloudVoiceCredential
Stores BT CloudVoice credentials securely.

**Parameters:**
- `Environment` (Mandatory): Environment identifier
- `Username` (Mandatory): BT CloudVoice username
- `Password` (Mandatory): User password (encrypted automatically)
- `ApiUrl` (Mandatory): BT CloudVoice API endpoint
- `Domain` (Optional): BT CloudVoice domain
- `Extension` (Optional): Phone extension
- `ExpiryDate` (Optional): Credential expiry date (default: 90 days)
- `AdditionalSettings` (Optional): Custom settings hashtable

**Returns:** Boolean indicating success/failure

#### Get-BTCloudVoiceCredential
Retrieves stored BT CloudVoice credentials.

**Parameters:**
- `Environment` (Mandatory): Environment identifier
- `IncludePassword` (Switch): Include decrypted password in result

**Returns:** Credential object or $null if not found

#### Get-BTCloudVoiceCredentialList
Lists all stored credentials.

**Parameters:** None

**Returns:** Array of credential summary objects

#### Remove-BTCloudVoiceCredential
Removes stored credentials.

**Parameters:**
- `Environment` (Mandatory): Environment identifier
- `Force` (Switch): Skip confirmation prompt

**Returns:** Boolean indicating success/failure

#### Test-BTCloudVoiceConnection
Tests connectivity using stored credentials.

**Parameters:**
- `Environment` (Mandatory): Environment identifier

**Returns:** Boolean indicating connection success/failure

### Utility Functions

#### Export-BTCloudVoiceCredentials
Creates encrypted backup of credentials.

**Parameters:**
- `ExportPath` (Mandatory): Backup file path
- `Environments` (Optional): Specific environments to export

**Returns:** Boolean indicating export success/failure

#### Import-BTCloudVoiceCredentials
Restores credentials from backup.

**Parameters:**
- `ImportPath` (Mandatory): Backup file path
- `Overwrite` (Switch): Overwrite existing credentials

**Returns:** Boolean indicating import success/failure

## 🔗 Integration Examples

### Windows 11 Upgrade Script Integration

```powershell
# Add to existing Windows 11 upgrade script
function Add-BTCloudVoiceSupport {
    param(
        [string]$Environment = "Production",
        [string]$LogFile = $global:LogFile
    )
    
    try {
        # Load credential manager
        . "$PSScriptRoot\BT-CloudVoice-CredentialManager.ps1"
        
        # Get credentials
        $credentials = Get-BTCloudVoiceCredential -Environment $Environment
        
        if ($credentials) {
            Write-LogMessage "BT CloudVoice integration enabled for $Environment" "SUCCESS" "Green"
            
            # Store in global variable for use throughout script
            $global:BTCloudVoiceCredentials = $credentials
            
            return $true
        } else {
            Write-LogMessage "BT CloudVoice credentials not found for $Environment" "WARNING" "Yellow"
            return $false
        }
    } catch {
        Write-LogMessage "BT CloudVoice integration failed: $($_.Exception.Message)" "ERROR" "Red"
        return $false
    }
}

# Use in main Windows 11 upgrade script
if (Add-BTCloudVoiceSupport -Environment "Production") {
    Write-LogMessage "BT CloudVoice support available during upgrade" "INFO" "Cyan"
    # Your BT CloudVoice integration code here
}
```

### PowerShell Profile Integration

```powershell
# Add to PowerShell profile for automatic loading
$btCredentialManagerPath = "C:\Scripts\BT-CloudVoice-CredentialManager.ps1"
if (Test-Path $btCredentialManagerPath) {
    . $btCredentialManagerPath
    Write-Host "BT CloudVoice Credential Manager loaded" -ForegroundColor Green
}

# Create aliases for common operations
Set-Alias -Name "bt-cred-list" -Value Get-BTCloudVoiceCredentialList
Set-Alias -Name "bt-cred-get" -Value Get-BTCloudVoiceCredential
Set-Alias -Name "bt-cred-set" -Value Set-BTCloudVoiceCredential
Set-Alias -Name "bt-cred-test" -Value Test-BTCloudVoiceConnection
```

This comprehensive documentation provides everything needed to implement the perfect layout for storing BT CloudVoice login details securely within the Windows 11 upgrade automation environment.