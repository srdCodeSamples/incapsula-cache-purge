#region Initial configurations
Import-Module $PSScriptRoot\PSFunctions_v3.psm1
Import-Module $PSScriptRoot\IncapsulaPurgeCache.Helpers.psm1
$logFilePath = "$PSScriptRoot\Logs\$(Get-date -Format 'yyyyMMdd').log"

$incapBaseApiUri = 'https://my.incapsula.com'
$incapPurgeCacheUri = "$incapBaseApiUri/api/prov/v1/sites/cache/purge"
$incapGetSitesUri = "$incapBaseApiUri/api/prov/v1/sites/list"
$incapApiId = '*****'
$incapApiKey = '********-****-****-****-************'

Write-CSTMLog -FilePath $logFilePath -Type 'INFO' -Message '[BEGIN]'
Write-CSTMLog -FilePath $logFilePath -Type 'DEBUG' -Message 'Prompting user to select mode'
$env = Set-CSTMChoice -Prompt "Choose which Incapsul site's cache to purge." -Choices "PROD","ST","Full","Manual"
Write-CSTMLog -FilePath $logFilePath -Type 'DEBUG' -Message "Selected mode: $env"
switch($env) {
    "PROD" {
        $SitesDbPath = "$PSScriptRoot\incapSites_PROD.csv"
        Write-CSTMLog -FilePath $logFilePath -Type 'INFO' -Message "Loading Incapsula sites data from $SitesDbPath"
        $sitesToPurge = Import-Csv -Path "$SitesDbPath" -ErrorAction Inquire
        break
    }
    "ST" {
        $SitesDbPath = "$PSScriptRoot\incapSites_ST.csv"
        Write-CSTMLog -FilePath $logFilePath -Type 'INFO' -Message "Loading Incapsula sites data from $SitesDbPath"
        $sitesToPurge = Import-Csv -Path "$SitesDbPath" -ErrorAction Inquire
        break
    }
    "Full" {
        $sitesToPurge = @(Get-IncapAllSites -incapGetSitesUri $incapGetSitesUri -incapApiId $incapApiId -incapApiKey $incapApiKey -LogFilePath $logFilePath)
        break
    }
    "Manual" {
        Write-Host -Object "Enter Incapsula sites that you want to purge." -ForegroundColor Yellow
        Write-Host -Object "Multiple entries devided by `',`' are accepted as well as wildcards - '*','?'." -ForegroundColor Yellow
        $sites = @(($(Read-Host -Prompt "Sites") -split ',').Trim())
        Write-CSTMLog -FilePath $logFilePath -Type 'INFO' -Message "User input:"
        Out-File -FilePath $logFilePath -InputObject $sites -Append
        $allIncapSites = @(Get-IncapAllSites -incapGetSitesUri $incapGetSitesUri -incapApiId $incapApiId -incapApiKey $incapApiKey -LogFilePath $logFilePath)
        Write-CSTMLog -FilePath $logFilePath -Type 'INFO' -Message "Building sites to purge DB based on the user's input"
        $sitesToPurge = @()
        foreach ($site in $sites)
        {
            $sitesToPurge += $allIncapSites.Where({$PSItem.WebSite -like $site})
        }
        if($sitesToPurge.Count -eq 0) {
            Write-CSTMLog -FilePath $logFilePath -Type 'INFO' -Message "No sites found in Incapsula matching user's input."
            Write-CSTMLog -FilePath $logFilePath -Type 'INFO' -Message "[END]"
            Write-host -Object "No sites found in Incapsula matching your input."
            Read-Host -Prompt "Press any key to exit"
            exit
        } else {
            Write-CSTMLog -FilePath $logFilePath -Type 'INFO' -Message "Found sites to purge:"
            Out-File -FilePath $logFilePath -InputObject $sitesToPurge.WebSite -Append
        }
        break
    }
}

#endregion

#region Incapsula Sites Purge
Clear-IncapSitesCache -incapPurgeCacheUri $incapPurgeCacheUri -incapApiId $incapApiId -incapApiKey $incapApiKey -sitesToPurge $sitesToPurge -LogFilePath $logFilePath

Write-CSTMLog -FilePath $logFilePath -Type 'INFO' -Message '[END]'
Read-Host -Prompt "Finished purging Incapsula cache. Press any key to exit"

#endregion




