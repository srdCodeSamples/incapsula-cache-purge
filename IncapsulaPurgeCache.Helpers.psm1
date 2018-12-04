Import-Module $PSScriptRoot\PSFunctions_v3.psm1

function Get-IncapAllSites {
    [cmdletbinding()]
    Param (
    [Parameter(Mandatory=$True,Position=1)]
    [string]$incapGetSitesUri,
    [Parameter(Mandatory=$True,Position=2)]
    [string]$incapApiId,
    [Parameter(Mandatory=$True,Position=3)]
    [string]$incapApiKey,
    [Parameter(Mandatory=$True,Position=4)]
    [string]$LogFilePath
    )
    Process {
        Write-Host -Object "Getting all incapsula sites... " -NoNewline
        Write-CSTMLog -FilePath $logFilePath -Type 'DEBUG' -Message 'Getting all sites from incapsula'
        $allIncapSites = $null
        $reqBody = "api_id=$incapApiId&api_key=$incapApiKey&page_size=250"
        Write-CSTMLog -FilePath $logFilePath -Type 'DEBUG' -Message "Sending web request uri: $incapGetSitesUri body: $reqBody"
        try {
            $allIncapSites = Invoke-RestMethod -Uri $incapGetSitesUri -Method POST -Body $reqBody -UseDefaultCredentials
        }
        catch {
            Write-CSTMLog -FilePath $logFilePath -Type 'ERROR' -Message $Error[0]
            $Error[0]
        }
        if ($allIncapSites -eq $null) {
            Write-CSTMLog -FilePath $logFilePath -Type 'ERROR' -Message "Failed getting incapsula sites. Aborting script"
            Write-CSTMLog -FilePath $logFilePath -Type 'ERROR' -Message "[END]"
            Write-Host -Object "Failed getting all sites from incapsula. Aborting script. " -ForegroundColor Red
            Read-Host -Prompt "Press any key to exit"
            exit
        }
        elseif ($allIncapSites.res -ne 0) {
            Write-CSTMLog -FilePath $logFilePath -Type 'ERROR' -Message "Failed getting incapsula sites - error code: $($allIncapSites.res) message: $($allIncapSites.res_message). Aborting script"
            Write-CSTMLog -FilePath $logFilePath -Type 'ERROR' -Message "[END]"
            Write-Host -Object "Failed getting all sites from incapsula - error code: $($allIncapSites.res) message: $($allIncapSites.res_message). Aborting script" -ForegroundColor Red
            Read-Host -Prompt "Press any key to exit"
            exit
        }
        else {
            Write-CSTMLog -FilePath $logFilePath -Type 'INFO' -Message "Succeeded getting sites from incapsula"
            Write-Host -Object "Done."
            Write-CSTMLog -FilePath $logFilePath -Type 'INFO' -Message "Building sites DB for the script"
            Write-Host -Object "Building script's sites DB... " -NoNewline
            $sitesDb = @()
            foreach($incapSite in $allIncapSites.sites) {
                $sitesDb += New-Object -TypeName PSObject -Property @{
                    'WebSite' = $incapSite.domain
                    'SiteId' = $incapSite.site_id
                }
            }
            Write-CSTMLog -FilePath $logFilePath -Type 'INFO' -Message "Done."
            Write-Host -Object "Done."
            return $sitesDb
        }
    }
}
function Clear-IncapSitesCache {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True,Position=1)]
        [string]$incapPurgeCacheUri,
        [Parameter(Mandatory=$True,Position=2)]
        [string]$incapApiId,
        [Parameter(Mandatory=$True,Position=3)]
        [string]$incapApiKey,
        [Parameter(Mandatory=$True,Position=4)]
        [array]$sitesToPurge,
        [Parameter(Mandatory=$True,Position=5)]
        [string]$LogFilePath
    )

    process {
        Write-Host -Object "Initiating Sites purge..."
        foreach ($site in $sitesToPurge) {
            Write-Host -Object "Purging Incapsula cache for " -NoNewline
            Write-Host -Object "$($site.WebSite)" -NoNewline -ForegroundColor Yellow
            Write-Host -Object " ... " -NoNewline
            Write-CSTMLog -FilePath $logFilePath -Type 'INFO' -Message "Initiating cache purge for $($site.WebSite)"
            $response = $null
            $reqBody = "api_id=$incapApiId&api_key=$incapApiKey&site_id=$($site.SiteId)"
            Write-CSTMLog -FilePath $logFilePath -Type 'DEBUG' -Message "Sending web request uri: $incapPurgeCacheUri body: $reqBody"
            try {
                $response = Invoke-RestMethod -Uri $incapPurgeCacheUri -Method POST -Body $reqBody -UseDefaultCredentials
            }
            catch {
                Write-CSTMLog -FilePath $logFilePath -Type 'ERROR' -Message $Error[0]
                $Error[0]
            }
            if ($response -eq $null) {
                Write-Host -Object "Failed" -ForegroundColor Red
                Write-CSTMLog -FilePath $logFilePath -Type 'ERROR' -Message "Failed purging cache for $($site.WebSite)"
            }
            elseif ($response.res -ne 0) {
                Write-Host -Object "Failed - code: $($response.res) message: $($response.res_message)" -ForegroundColor Red
                Write-CSTMLog -FilePath $logFilePath -Type 'ERROR' -Message "Failed purging cache for $($site.WebSite) - code: $($response.res) message: $($response.res_message)"
            }
            else {
                Write-Host -Object "OK" -ForegroundColor Green
                Write-CSTMLog -FilePath $logFilePath -Type 'INFO' -Message "Succeeded purging cache for $($site.WebSite)"
            }
        }
    }
}