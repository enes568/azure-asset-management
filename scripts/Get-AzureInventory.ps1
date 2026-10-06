<#
.SYNOPSIS
    Ruft die Asset-Liste aus der Azure Function (GetAssets) ab.

.DESCRIPTION
    Fragt den API-Endpunkt ab und wiederholt die Anfrage bei Fehlern mit
    wachsender Wartezeit (Cold Start der Function). Die Ausgabe erscheint als
    Tabelle und kann optional als CSV gespeichert werden.

.PARAMETER ApiUrl
    URL des GetAssets-Endpunkts.

.PARAMETER MaxRetries
    Maximale Anzahl an Versuchen.

.PARAMETER TimeoutSec
    Timeout pro Anfrage in Sekunden.

.PARAMETER ExportCsv
    Optionaler Pfad, unter dem die Assets als CSV gespeichert werden.

.EXAMPLE
    .\Get-AzureInventory.ps1

.EXAMPLE
    .\Get-AzureInventory.ps1 -ExportCsv .\assets.csv
#>
[CmdletBinding()]
param(
    [string]$ApiUrl = "https://func-demo-api-ec-fkfrbxd8aah2dthq.austriaeast-01.azurewebsites.net/api/GetAssets",
    [int]$MaxRetries = 5,
    [int]$TimeoutSec = 30,
    [string]$ExportCsv
)

$assets = $null

for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
    try {
        Write-Host "Verbinde mit Azure Function Backend (Versuch $attempt von $MaxRetries) ..." -ForegroundColor Cyan
        $assets = Invoke-RestMethod -Uri $ApiUrl -Method Get -TimeoutSec $TimeoutSec -ErrorAction Stop
        break
    }
    catch {
        Write-Warning "Versuch $attempt fehlgeschlagen: $($_.Exception.Message)"
        if ($attempt -eq $MaxRetries) {
            Write-Host "Die API ist nach $MaxRetries Versuchen nicht erreichbar." -ForegroundColor Red
            exit 1
        }
        # Wartezeit verdoppelt sich: 1, 2, 4, 8 Sekunden
        Start-Sleep -Seconds ([math]::Pow(2, $attempt - 1))
    }
}

if ($null -eq $assets) { $assets = @() } else { $assets = @($assets) }

Write-Host "Erfolgreich $($assets.Count) Assets abgerufen." -ForegroundColor Green
$assets | Format-Table -AutoSize

if ($ExportCsv) {
    $assets | Export-Csv -Path $ExportCsv -NoTypeInformation -Encoding UTF8
    Write-Host "CSV gespeichert unter: $ExportCsv" -ForegroundColor Green
}
