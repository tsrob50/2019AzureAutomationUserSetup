<#
.SYNOPSIS 
    This automation runbook updates the Manager Azure AD group with managers from the new user CSV.

.DESCRIPTION
    This automation runbook is called by the UserSetupAction runbook and updates the Manager Azure AD group with any user in with the title "Manager".

.PARAMETER inputData
    Required. PSCustomObject of use setup data.

.NOTES
    Requires importing the AzureAD module into the Azure Automation Account
    Requires granting Azure AD rights to the runas account

    AUTHOR: Travis Roberts
    LASTEDIT: February 23rd, 2019
#>
param(
    $inputData
)

# Domain used for UPN
$domain = '@ciraltos.com'

# Connect to Azure AD
# Connect to Azure with RunAs account
# AzureRunAsConnection must be granted rights to Azure AD
# as an Enterprise Application
$conn = Get-AutomationConnection -Name "AzureRunAsConnection"

# Connect to Azure AD
$null = Connect-AzureAD `
  -TenantId $conn.TenantId `
  -ApplicationId $conn.ApplicationId `
  -CertificateThumbprint $conn.CertificateThumbprint

#Get the Azure AD Group
$mgrGroup = Get-AzureADGroup -Filter "DisplayName eq 'Managers'"

foreach ($user in $inputData) {
    if ($user.title -eq 'Manager') {
        #Get the user object from AAD
        $upn = $user.first + '.' + $user.last + $domain
        $aadUser = Get-AzureADUser -ObjectId $upn
        #Add user to group
        Add-AzureADGroupMember -ObjectId $mgrGroup.ObjectId -RefObjectId $aadUser.ObjectId
    }
}