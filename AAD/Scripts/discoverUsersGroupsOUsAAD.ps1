# ===============================================
# On-Premises Synced Users & Groups Export Script
# ===============================================
#
# This script exports information about on-premises synced users and groups
# from Microsoft Graph API using app-only authentication.
#
# What it exports:
# - Users: DisplayName, UPN, Domain, OU Path
# - Groups: DisplayName, Mail, Domain, OnPremisesDN, OnPremisesSID, Description, GroupTypes
# - OU List: List of unique OUs
#
# Prerequisites:
# - PowerShell 5.1 or later
# - Azure AD app registration with appropriate permissions
# - On-premises Active Directory synced to Azure AD
#
# Output files:
# - synced-users.csv: Detailed user information
# - synced-groups.csv: Detailed group information  
# - ou-list.txt: List of unique OUs
#
# ===============================================

# -----------------------------------------------
# 1) Configuration (fill these in)
# -----------------------------------------------
# IMPORTANT: Replace these values with your own tenant information
# 
# To get these values:
# 1. Go to Azure Portal → Azure Active Directory → App registrations
# 2. Create a new app registration or use existing one
# 3. Copy the Application (client) ID and Directory (tenant) ID
# 4. Go to Certificates & secrets → Create a new client secret
# 5. Copy the secret value (you won't see it again!)
#
# Required permissions for the app:
# - User.Read.All
# - Group.Read.All  
# - Directory.Read.All
#
# Grant admin consent for these permissions in your tenant

$tenantId     = 'YOUR_TENANT_ID_HERE'                    # e.g., '12345678-1234-1234-1234-123456789012'
$clientId     = 'YOUR_CLIENT_ID_HERE'                    # e.g., '87654321-4321-4321-4321-210987654321'
$clientSecret = 'YOUR_CLIENT_SECRET_HERE'                # e.g., 'abc123~xyz789~def456~ghi789~jkl012'
$scope        = 'https://graph.microsoft.com/.default'

# Output file paths (modify these if needed)
$userCsv = "$HOME/synced-users.csv"
$grpCsv  = "$HOME/synced-groups.csv"
$ouList  = "$HOME/ou-list.txt"

# -----------------------------------------------
# 2) Acquire App-Only Token
# -----------------------------------------------
# Validate configuration
if ($tenantId -eq 'YOUR_TENANT_ID_HERE' -or $clientId -eq 'YOUR_CLIENT_ID_HERE' -or $clientSecret -eq 'YOUR_CLIENT_SECRET_HERE') {
    Write-Error "❌ Please configure the tenant ID, client ID, and client secret in the script before running."
    Write-Host "   See the configuration section at the top of this script for instructions."
    exit 1
}

Write-Host "🔐 Acquiring authentication token..."
$tokenResp = Invoke-RestMethod `
  -Method POST `
  -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" `
  -Body @{
    grant_type    = 'client_credentials'
    client_id     = $clientId
    client_secret = $clientSecret
    scope         = $scope
  }

$token = $tokenResp.access_token
if (-not $token) {
    Write-Error "❌ Failed to acquire token. Check client secret and tenant ID."
    Write-Host "   Make sure your app registration has the required permissions and admin consent is granted."
    exit 1
}
Write-Host "✅ Authentication successful!"

# -----------------------------------------------
# 3) Helper: Paged Graph GET
# -----------------------------------------------
function Invoke-GraphPaged {
    param([string]$uri)
    $all = @()
    do {
        $resp = Invoke-RestMethod -Method GET `
            -Uri "https://graph.microsoft.com/v1.0$uri" `
            -Headers @{ Authorization = "Bearer $token" }
        $all += $resp.value
        $uri  = $resp.'@odata.nextLink' -replace 'https://graph.microsoft.com/v1.0',''
    } while ($uri)
    return $all
}

# -----------------------------------------------
# 4) Fetch On-Prem-Synced Users
# -----------------------------------------------
Write-Host "👥 Fetching on-premises synced users..."
$users = Invoke-GraphPaged -Uri "/users?`$filter=onPremisesSyncEnabled eq true&`$select=displayName,userPrincipalName,onPremisesDistinguishedName,onPremisesDomainName"
Write-Host "✅ Found $($users.Count) synced users"

# -----------------------------------------------
# 5) Filter & Export Users (+ parse OU path)
# -----------------------------------------------
Write-Host "📝 Exporting users to $userCsv..."
$users |
    Where-Object { $_.onPremisesDistinguishedName } |    # drop null DNs
    Select-Object `
        @{Name='DisplayName';Expression={$_.displayName}},
        @{Name='UPN';       Expression={$_.userPrincipalName}},
        @{Name='Domain';    Expression={$_.onPremisesDomainName}},
        @{Name='OU_Path';   Expression={
            # Split DN and drop CN=... plus DC=... segments
            $parts = $_.onPremisesDistinguishedName -split ','
            if ($parts.Count -gt 3) {
                $ouSegments = $parts[1..($parts.Count - 3)]
                return $ouSegments -join ';'
            } else {
                return ''
            }
        }} |
    Export-Csv $userCsv -NoTypeInformation

# -----------------------------------------------
# 6) Fetch On-Prem-Synced Groups
# -----------------------------------------------
Write-Host "👥 Fetching on-premises synced groups..."
$groups = Invoke-GraphPaged -Uri "/groups?`$filter=onPremisesSyncEnabled eq true&`$select=displayName,mail,onPremisesDomainName,onPremisesDistinguishedName,onPremisesSecurityIdentifier,description,groupTypes"
Write-Host "✅ Found $($groups.Count) synced groups"

# -----------------------------------------------
# 7) Export Groups
# -----------------------------------------------
Write-Host "📝 Exporting groups to $grpCsv..."
$groups |
    Select-Object `
        @{Name='DisplayName';Expression={$_.displayName}},
        @{Name='Mail';       Expression={$_.mail}},
        @{Name='Domain';     Expression={$_.onPremisesDomainName}},
        @{Name='OnPremisesDN';Expression={$_.onPremisesDistinguishedName}},
        @{Name='OnPremisesSID';Expression={$_.onPremisesSecurityIdentifier}},
        @{Name='Description';Expression={$_.description}},
        @{Name='GroupTypes';Expression={$_.groupTypes -join ';'}} |
    Export-Csv $grpCsv -NoTypeInformation

# -----------------------------------------------
# 8) Export Unique OU List
# -----------------------------------------------
Write-Host "📝 Exporting unique OU list to $ouList..."
$users |
    Where-Object { $_.onPremisesDistinguishedName } |
    ForEach-Object {
        $parts = $_.onPremisesDistinguishedName -split ','
        if ($parts.Count -gt 3) {
            $parts[1..($parts.Count - 3)] -join ';'
        }
    } |
    Sort-Object -Unique |
    Out-File $ouList

# -----------------------------------------------
# Complete
# -----------------------------------------------
Write-Host "`n✅ Exports complete:"
Write-Host "   • Users → $userCsv"
Write-Host "   • Groups → $grpCsv"
Write-Host "   • OU list → $ouList"
