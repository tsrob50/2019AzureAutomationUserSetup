<#
.SYNOPSIS 
    This sample automation runbook is designed to be used in a watcher task that
    looks for new files in a directory. When a new file is found, it calls the action
    runbook associated with the watcher task.

.DESCRIPTION
    This runbook is designed to be used in a watcher task that
    looks for new files in a directory. When a new file is found, it calls the action
    runbook associated with the watcher task. It requires that a variable called "Watch-NewUserFileTimestamp"
    be created in automation account that is used to hold the timestamp of the last file processed.
    This runbook is based on an example by the Microsoft Automation Team (2017)

.PARAMETER FolderPath
    Required. The name of a folder that you wish to watch for new files.

.PARAMETER Recurse
    Optional. Determines whether to look for all files under all directories or just the specific
    folder. Default is the folder only.

.EXAMPLE
    .\Watch-NewFile -FolderPath c:\FinanceFiles

.EXAMPLE
    .\Watch-NewFile -FolderPath c:\FinanceFiles -Extension "*.csv" -Recurse $True

.NOTES
    AUTHOR: Travis Roberts
    LASTEDIT: February 23rd 2019
#>

Param
(
    [Parameter(Mandatory=$true)]
    $FolderPath,

    [Parameter(Mandatory=$false)]
    [boolean] $Recurse = $false 
)

$FolderWatcherWatermark = "Watch-NewUserFileTimestamp"
$FolderWatermark =  (Get-Date (Get-AutomationVariable -Name $FolderWatcherWatermark)).ToLocalTime()

$Extension = '*.csv'
$Files = Get-ChildItem -Path $FolderPath -Filter $Extension -Recurse:$Recurse | Where-Object {$_.LastWriteTime -gt $FolderWatermark} | Sort-Object -Property LastWriteTime

# Iterate through any new files 
# Convert .CSV content to JSON
# and trigger an action runbook
foreach ($File in $Files)
{
    if (!$File.PSIsContainer)
    {
        $Path = $FolderPath + "\" + $File
        $FileData = Import-Csv -path $Path
        $Data = @{}
        #-Compress needed to eliminate \r\n 
        $Data = $FileData | ConvertTo-Json -Compress
        Invoke-AutomationWatcherAction -Message "Process new file..." -Data $Data
    
        # Update watermark using last modified so we only get new files
        Set-AutomationVariable -Name $FolderWatcherWatermark -Value (Get-Date $File.LastWriteTime).AddMilliseconds(1).ToLocalTime()
    }
}

