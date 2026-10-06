using namespace System.Net

param($Request, $TriggerMetadata)

# Resource Graph ist kostenlos, wird aber pro Benutzer gedrosselt.
# Darum wird das Ergebnis kurz zwischengespeichert.
$cacheSeconds = 60

# Optional: Typen, die nicht öffentlich erscheinen sollen, als App-Einstellung, z. B.
# EXCLUDE_TYPES=microsoft.keyvault/vaults,microsoft.sql/servers
$excluded = @(($env:EXCLUDE_TYPES -split ',') | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ })

$typeLabels = @{
    'microsoft.web/serverfarms'                        = 'App Service Plan'
    'microsoft.web/staticsites'                        = 'Static Web App'
    'microsoft.storage/storageaccounts'                = 'Storage Account'
    'microsoft.insights/components'                    = 'Application Insights'
    'microsoft.insights/actiongroups'                  = 'Action Group'
    'microsoft.operationalinsights/workspaces'         = 'Log Analytics'
    'microsoft.managedidentity/userassignedidentities' = 'Managed Identity'
    'microsoft.keyvault/vaults'                        = 'Key Vault'
    'microsoft.sql/servers'                            = 'SQL Server'
    'microsoft.sql/servers/databases'                  = 'SQL Database'
}

function Get-Category([string]$Type, [string]$Kind) {
    $t = $Type.ToLower()
    if ($t -eq 'microsoft.web/sites') {
        if ($Kind -match 'functionapp') { return 'Function App' }
        return 'Web App'
    }
    if ($typeLabels.ContainsKey($t)) { return $typeLabels[$t] }
    $last = $t.Split('/')[-1]
    if ($last) { return $last }
    return 'Azure Resource'
}

function Get-Assets {
    $subscriptionId = $env:SUBSCRIPTION_ID
    $resourceGroup  = $env:RESOURCE_GROUP

    if (-not $subscriptionId -or -not $resourceGroup) {
        throw 'App-Einstellungen SUBSCRIPTION_ID und RESOURCE_GROUP fehlen.'
    }
    # Erlaubte Zeichen für Ressourcengruppen; verhindert Probleme in der KQL-Abfrage
    if ($resourceGroup -notmatch '^[\w.()-]{1,90}$') {
        throw 'Ungültiger Name der Ressourcengruppe.'
    }
    if (-not $env:IDENTITY_ENDPOINT) {
        throw 'Managed Identity ist nicht aktiviert.'
    }

    # Token der Managed Identity holen, ohne Az-Module (startet schneller)
    $tokenUri = "$($env:IDENTITY_ENDPOINT)?resource=https://management.azure.com/&api-version=2019-08-01"
    $token = (Invoke-RestMethod -Uri $tokenUri -Headers @{ 'X-IDENTITY-HEADER' = $env:IDENTITY_HEADER }).access_token

    $query = @"
resources
| where resourceGroup =~ '$resourceGroup'
| project id, name, type, kind, state = tostring(properties.provisioningState)
| order by name asc
"@

    $body = @{
        subscriptions = @($subscriptionId)
        query         = $query
        options       = @{ resultFormat = 'objectArray' }
    } | ConvertTo-Json -Depth 5

    $result = Invoke-RestMethod -Method Post `
        -Uri 'https://management.azure.com/providers/Microsoft.ResourceGraph/resources?api-version=2022-10-01' `
        -Headers @{ Authorization = "Bearer $token" } `
        -ContentType 'application/json' `
        -Body $body

    $result.data |
        Where-Object { $excluded -notcontains ([string]$_.type).ToLower() } |
        ForEach-Object {
            [pscustomobject]@{
                # Die Subscription-ID soll nicht öffentlich im Dashboard auftauchen
                id       = ([string]$_.id) -replace '^/subscriptions/[^/]+', ''
                name     = $_.name
                category = Get-Category $_.type $_.kind
                status   = if ($_.state) { $_.state } else { 'Unknown' }
            }
        }
}

try {
    $age = if ($global:AssetCacheTime) { ((Get-Date) - $global:AssetCacheTime).TotalSeconds } else { [double]::MaxValue }

    if (-not $global:AssetCacheJson -or $age -gt $cacheSeconds) {
        $assets = @(Get-Assets)
        $global:AssetCacheJson = ConvertTo-Json -InputObject $assets -Depth 4 -AsArray
        $global:AssetCacheTime = Get-Date
    }

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Headers    = @{ 'Content-Type' = 'application/json'; 'Cache-Control' = 'public, max-age=30' }
        Body       = $global:AssetCacheJson
    })
}
catch {
    Write-Warning "GetAssets fehlgeschlagen: $($_.Exception.Message)"

    if ($global:AssetCacheJson) {
        # Lieber veraltete Daten als gar keine
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Headers    = @{ 'Content-Type' = 'application/json'; 'X-Cache' = 'stale' }
            Body       = $global:AssetCacheJson
        })
    }
    else {
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::ServiceUnavailable
            Headers    = @{ 'Content-Type' = 'application/json' }
            Body       = '{"error":"Die Asset-Abfrage ist zurzeit nicht möglich."}'
        })
    }
}
