<#
.SYNOPSIS 
    This automation runbook is designed to be used in a watcher task that takes action
    on data passed in from a watcher runbook.

.DESCRIPTION
    This automation runbook is designed to be used in a watcher task that takes action
    on data passed in from a watcher runbook. It is required to have a parameter called $EVENTDATA in
    watcher action runbooks to receive information from the watcher runbook.
    This runbook is based on an example by the Microsoft Automation Team (2017)

.PARAMETER EVENTDATA
    Optional. Contains the information passed in from the watcher runbook.

.NOTES
    AUTHOR: Travis Roberts
    LASTEDIT: February 23rd 2019
#>

param(
    $EventData
)

# Name of Hybrid Worker Group used to setup the user accounts
$hybridGroup = "DomainGroup"

# Convert EventData to PSCustomObject to use in the rest of the runbooks.
$InputJson = $EventData.EventProperties.Data 
$InputData = ($InputJson | ConvertFrom-Json)


# Authenticate first
# Connect to Azure with RunAs account
$conn = Get-AutomationConnection -Name "AzureRunAsConnection"

# Connect to Azure Automaiton
$null = Add-AzureRmAccount `
  -ServicePrincipal `
  -TenantId $conn.TenantId `
  -ApplicationId $conn.ApplicationId `
  -CertificateThumbprint $conn.CertificateThumbprint


# Set Paramaters to pass to the runbook
$params = @{
  inputJson = $InputJson
}

# Call the addadusers runbook
# Pass JSON data to the runbook
$addAdUsers = Start-AzureRmAutomationRunbook -AutomationAccountName "CiraltosAutomation" -Name "AddAdUsers" -ResourceGroupName "ciraltosautomationrg" -Parameters $params -RunOn $hybridGroup -Wait

# Wait for Replication to take place
Start-Sleep -s 120

#Call the runbook to add managers to the manager AAD group
#Using inline method
.\AddAADGroup.ps1 -inputData $InputData
