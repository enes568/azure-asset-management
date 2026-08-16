# ☁️ Azure Cloud Asset Dashboard

Eine moderne, serverlose Cloud-Asset-Management-Anwendung auf Basis von **Microsoft Azure** und **GitHub Actions**. Das Dashboard ruft System-Ressourcen über eine REST-API ab und stellt diese dynamisch in einer Weboberfläche dar.

---

## 🛠️ Architektur & Technologien

* **Frontend:** HTML5, CSS3, Modern JavaScript (Fetch API)
* **Backend:** Azure Functions (Serverless Node.js REST API)
* **Hosting:** Azure Static Web Apps
* **CI/CD Pipeline:** GitHub Actions (Automatisches Build & Deployment bei Code-Pushes)

---

## 🚀 Live Demo

Die Anwendung ist live erreichbar unter:  
👉 **[Azure Asset Manager Dashboard](https://gray-stone-09ea0b410.7.azurestaticapps.net)**

---

## 📋 Features

* **Serverless Backend:** Dynamische Bereitstellung von Cloud-Ressourcendaten über Azure Functions.
* **CORS-Sicherheit:** Sichere Kommunikation zwischen Frontend und Backend-API.
* **Automated Deployment:** Vollautomatische CI/CD-Pipeline via GitHub Actions bei Änderungen im `main`-Branch.


## ⚡ Azure Infrastructure & Deployment (PowerShell)

Die Verwaltung und Bereitstellung der Azure-Ressourcen sowie der Test der API erfolgt über die **Azure PowerShell CLI**:

```powershell
# 1. Verbindung zu Azure herstellen
Connect-AzAccount

# 2. Azure Function App & Static Web App Status prüfen
Get-AzResource -ResourceGroupName "dein-ressourcen-gruppen-name" | Select-Object Name, ResourceType, Location

# 3. REST-API Endpunkt via PowerShell testen
$apiUrl = "https://func-demo-api-ec-fkfrbxd8aah2dthq.austriaeast-01.azurewebsites.net/api/GetAssets"
Invoke-RestMethod -Uri $apiUrl -Method Get
