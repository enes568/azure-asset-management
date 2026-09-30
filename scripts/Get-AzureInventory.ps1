

$apiUrl = "https://func-demo-api-ec-fkfrbxd8aah2dthq.austriaeast-01.azurewebsites.net/api/GetAssets"

try {
    Write-Host "Verbinde mit Azure Function Backend..." -ForegroundColor Cyan
    $response = Invoke-RestMethod -Uri $apiUrl -Method Get
    
    Write-Host "Erfolgreich $($response.Count) Assets abgerufen." -ForegroundColor Green
    $response | Format-Table -AutoSize
}
catch {
    Write-Error "Fehler beim Abrufen der Daten aus Azure: $_"
}
