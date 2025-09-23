# BT CloudVoice Credential Setup Example
# Perfect layout implementation for storing BT CloudVoice login details
# This script demonstrates how to securely store and manage credentials

<#
.SYNOPSIS
    Example implementation of BT CloudVoice credential management
    
.DESCRIPTION
    This script shows the perfect layout for storing BT CloudVoice login details
    with enterprise-grade security, encryption, and management features.
    
.EXAMPLE
    .\BT-CloudVoice-Setup-Example.ps1
    
.NOTES
    Run this script as Administrator for full functionality
#>

# Import the credential manager module
. "$PSScriptRoot\BT-CloudVoice-CredentialManager.ps1"

Write-Host "BT CloudVoice Credential Setup Example" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""

# Display current credential information
Show-BTCloudVoiceCredentialInfo

Write-Host "Setting up example BT CloudVoice credentials..." -ForegroundColor Yellow
Write-Host ""

# Example 1: Production Environment Setup
Write-Host "1. Setting up Production Environment Credentials" -ForegroundColor Cyan
$productionSetup = Set-BTCloudVoiceCredential `
    -Environment "Production" `
    -Username "admin@yourcompany.com" `
    -Password "SecureP@ssw0rd123!" `
    -ApiUrl "https://api.btcloudvoice.com" `
    -Domain "yourcompany.btcloudvoice.com" `
    -Extension "1001" `
    -ExpiryDate (Get-Date).AddDays(90) `
    -AdditionalSettings @{
        "Department" = "IT Administration"
        "AccessLevel" = "Administrator"
        "Region" = "UK"
        "CostCenter" = "CC-IT-001"
        "Manager" = "john.doe@yourcompany.com"
    }

if ($productionSetup) {
    Write-Host "✓ Production credentials stored successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to store production credentials" -ForegroundColor Red
}

Write-Host ""

# Example 2: Staging Environment Setup
Write-Host "2. Setting up Staging Environment Credentials" -ForegroundColor Cyan
$stagingSetup = Set-BTCloudVoiceCredential `
    -Environment "Staging" `
    -Username "testuser@yourcompany.com" `
    -Password "Test123!@#" `
    -ApiUrl "https://staging-api.btcloudvoice.com" `
    -Domain "staging.yourcompany.btcloudvoice.com" `
    -Extension "2001" `
    -ExpiryDate (Get-Date).AddDays(30) `
    -AdditionalSettings @{
        "Department" = "Quality Assurance"
        "AccessLevel" = "Standard User"
        "Region" = "UK"
        "Purpose" = "Testing and Validation"
    }

if ($stagingSetup) {
    Write-Host "✓ Staging credentials stored successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to store staging credentials" -ForegroundColor Red
}

Write-Host ""

# Example 3: Development Environment Setup
Write-Host "3. Setting up Development Environment Credentials" -ForegroundColor Cyan
$devSetup = Set-BTCloudVoiceCredential `
    -Environment "Development" `
    -Username "developer@yourcompany.com" `
    -Password "Dev456!@#" `
    -ApiUrl "https://dev-api.btcloudvoice.com" `
    -Domain "dev.yourcompany.btcloudvoice.com" `
    -Extension "3001" `
    -ExpiryDate (Get-Date).AddDays(60) `
    -AdditionalSettings @{
        "Department" = "Software Development"
        "AccessLevel" = "Developer"
        "Region" = "UK"
        "Team" = "Platform Engineering"
        "Project" = "Voice Integration"
    }

if ($devSetup) {
    Write-Host "✓ Development credentials stored successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to store development credentials" -ForegroundColor Red
}

Write-Host ""
Write-Host "Credential Setup Complete!" -ForegroundColor Green
Write-Host "=========================" -ForegroundColor Green
Write-Host ""

# Display updated credential list
Write-Host "Current Stored Credentials:" -ForegroundColor Yellow
$credentialList = Get-BTCloudVoiceCredentialList
if ($credentialList.Count -gt 0) {
    $credentialList | Format-Table -Property Environment, Username, ApiUrl, Extension, ExpiryDate, IsExpired -AutoSize
} else {
    Write-Host "No credentials found." -ForegroundColor Red
}

Write-Host ""

# Example credential retrieval
Write-Host "Example: Retrieving Production Credentials" -ForegroundColor Cyan
$prodCred = Get-BTCloudVoiceCredential -Environment "Production"
if ($prodCred) {
    Write-Host "Environment: $($prodCred.Environment)" -ForegroundColor Gray
    Write-Host "Username: $($prodCred.Username)" -ForegroundColor Gray
    Write-Host "API URL: $($prodCred.ApiUrl)" -ForegroundColor Gray
    Write-Host "Domain: $($prodCred.Domain)" -ForegroundColor Gray
    Write-Host "Extension: $($prodCred.Extension)" -ForegroundColor Gray
    Write-Host "Expiry Date: $($prodCred.ExpiryDate)" -ForegroundColor Gray
    Write-Host "Department: $($prodCred.AdditionalSettings.Department)" -ForegroundColor Gray
    Write-Host "Access Level: $($prodCred.AdditionalSettings.AccessLevel)" -ForegroundColor Gray
}

Write-Host ""

# Test connections
Write-Host "Testing Connections..." -ForegroundColor Yellow
$environments = @("Production", "Staging", "Development")
foreach ($env in $environments) {
    Write-Host "Testing $env environment..." -ForegroundColor Gray
    $testResult = Test-BTCloudVoiceConnection -Environment $env
    if ($testResult) {
        Write-Host "✓ $env connection test completed" -ForegroundColor Green
    } else {
        Write-Host "✗ $env connection test failed" -ForegroundColor Red
    }
}

Write-Host ""

# Example backup creation
Write-Host "Creating Backup..." -ForegroundColor Yellow
$backupPath = "$env:TEMP\BT-CloudVoice-Backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$backupResult = Export-BTCloudVoiceCredentials -ExportPath $backupPath
if ($backupResult) {
    Write-Host "✓ Backup created: $backupPath" -ForegroundColor Green
} else {
    Write-Host "✗ Backup creation failed" -ForegroundColor Red
}

Write-Host ""
Write-Host "Setup Examples Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Review stored credentials with: Get-BTCloudVoiceCredentialList" -ForegroundColor Gray
Write-Host "2. Retrieve credentials with: Get-BTCloudVoiceCredential -Environment 'Production' -IncludePassword" -ForegroundColor Gray
Write-Host "3. Update credentials with: Set-BTCloudVoiceCredential ..." -ForegroundColor Gray
Write-Host "4. Remove credentials with: Remove-BTCloudVoiceCredential -Environment 'Environment'" -ForegroundColor Gray
Write-Host "5. Create backups with: Export-BTCloudVoiceCredentials -ExportPath 'path'" -ForegroundColor Gray
Write-Host ""

# Integration example with existing Windows scripts
Write-Host "Integration with Windows 11 Upgrade Scripts:" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "You can now integrate these credentials with the existing Windows 11 upgrade scripts:" -ForegroundColor Gray
Write-Host ""
Write-Host "Example PowerShell integration:" -ForegroundColor Yellow
Write-Host @"
# Load BT CloudVoice credentials in your Windows upgrade script
. "$PSScriptRoot\BT-CloudVoice-CredentialManager.ps1"

# Retrieve credentials for production use
`$btCredentials = Get-BTCloudVoiceCredential -Environment "Production" -IncludePassword

if (`$btCredentials) {
    Write-LogMessage "BT CloudVoice credentials loaded successfully" "SUCCESS" "Green"
    
    # Use credentials in your application
    `$apiUrl = `$btCredentials.ApiUrl
    `$username = `$btCredentials.Username
    `$password = `$btCredentials.Password
    
    # Connect to BT CloudVoice API
    # Your integration code here...
} else {
    Write-LogMessage "Failed to load BT CloudVoice credentials" "ERROR" "Red"
}
"@ -ForegroundColor Gray

Write-Host ""