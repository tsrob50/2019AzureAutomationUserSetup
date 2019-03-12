<#
.SYNOPSIS 
    This automation runbook adds users to Active Directory.

.DESCRIPTION
    This automation runbook takes information from the UserSetupAction runbook and adds users to Azure AD.
    Once setup, the script will force AD Connect to sync.
    Requires Password object in Azure Automation account

.PARAMETER InputJson
    Required, user data input as JSON.

.NOTES
    AUTHOR: Travis Roberts
    LASTEDIT: February 23rd, 2019
#>

param(
    $inputJson
)

$users = ConvertFrom-Json -InputObject $inputJson

# Get default password
# Added as an Azure Automation Shared Encrypted Variable 
# Change 'DefaultPassword' to the name of the Shared Variable
$pw = Get-AutomationVariable -Name 'DefaultPassword' | ConvertTo-SecureString -AsPlainText -Force

# Get Admin Credentials
# should be an account with rights to add user
# Do not install the Azure Automation Authoring toolkit from the Hybrid worker.  If needed, install as current user
# Update ADMINACCOUNT, @DOMAIN.com, and all instances of COMPUTERNAME as needed
$adminCredential = Get-AutomationPSCredential -Name 'ADMINACCOUNT'

ForEach ($user in $users) {
    $userName = ($user.First).Substring(0,1) + $user.Last 
    $samAccount = $userName -replace '\A(.{1,20}).*', '$1'
    $upn = $user.first + '.' + $user.last + '@DOMAIN.com'
    $name = $user.first + ' ' + $user.last

    Invoke-Command -computername COMPUTERNAME -Credential $adminCredential -ScriptBlock {
        New-ADUser -SamAccountName $using:samAccount `
        -UserPrincipalName $using:upn `
        -Name $using:name `
        -Title $using:user.Title `
        -Department $using:user.Dept `
        -GivenName $using:user.First `
        -SurName $using:user.Last `
        -OfficePhone $using:user.Phone `
        -ChangePasswordAtLogon $True `
        -AccountPassword $using:pw `
        -enable $True
    } 

}

# wait for replication
Start-Sleep -s 60

# Start AD Sync
# Change Computername to the name of the AD Connect server
$sync = Invoke-Command -computername COMPUTERNAME -Credential $adminCredential -ScriptBlock { start-adsyncsynccycle -policyType Delta } 
