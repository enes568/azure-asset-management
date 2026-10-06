# RBAC-Ausbau: Managed Identity + Resource Graph

Ziel: Die Function (PowerShell) liest echte Ressourcen aus deiner Ressourcengruppe, ohne Passwort und mit minimalen Rechten. Alles hier ist kostenlos (Managed Identity, Rollenzuweisungen und Resource-Graph-Abfragen kosten nichts).

## Ablauf in Kurzform

1. Alten Function-Code sichern.
2. Managed Identity der Function App aktivieren.
3. Rolle **Reader** nur auf die Ressourcengruppe vergeben.
4. App-Einstellungen und CORS setzen.
5. Ordner `api/` und Workflow ins Repo, pushen, testen.
6. Optional: GitHub Actions per OIDC statt Passwort anmelden.

## 0. Variablen (Azure Cloud Shell oder lokale Azure CLI)

```bash
SUB=<deine-subscription-id>
RG=<deine-ressourcengruppe>
FUNC=<name-der-function-app>        # vermutlich func-demo-api-ec
SWA_URL=https://gray-stone-09ea0b410.7.azurestaticapps.net
```

## 1. Alten Code sichern

Portal: Function App → Übersicht → **Download app content**. Das nächste Deployment ersetzt den Inhalt der Function App.

## 2. Managed Identity aktivieren

```bash
PRINCIPAL=$(az functionapp identity assign -g $RG -n $FUNC --query principalId -o tsv)
```

## 3. Minimale Rechte: Reader nur auf die Ressourcengruppe

```bash
az role assignment create \
  --assignee-object-id $PRINCIPAL \
  --assignee-principal-type ServicePrincipal \
  --role Reader \
  --scope /subscriptions/$SUB/resourceGroups/$RG
```

Prüfen (gut für einen Screenshot im Portfolio):

```bash
az role assignment list --assignee $PRINCIPAL --all -o table
```

## 4. App-Einstellungen und CORS

```bash
az functionapp config appsettings set -g $RG -n $FUNC \
  --settings SUBSCRIPTION_ID=$SUB RESOURCE_GROUP=$RG

az functionapp cors remove -g $RG -n $FUNC --allowed-origins
az functionapp cors add    -g $RG -n $FUNC --allowed-origins $SWA_URL
```

Prüfe die PowerShell-Version der Function App (sollte 7.4 sein) und stelle sie bei Bedarf um:

```bash
az functionapp config show -g $RG -n $FUNC --query powerShellVersion -o tsv
az functionapp config set  -g $RG -n $FUNC --powershell-version 7.4
```

## 5. Code ins Repo und deployen

Kopiere `api/`, `.github/workflows/deploy-api.yml` und `docs/` in dein Repo und lege unter *Settings → Secrets and variables → Actions → Variables* diese Repository-Variablen an: `AZURE_FUNCTIONAPP_NAME`, `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` (die Werte entstehen in Schritt 6).

Ohne Schritt 6 kannst du einmalig manuell deployen, z. B. mit der Azure Functions Core Tools (`func azure functionapp publish $FUNC` im Ordner `api/`).

Danach im Browser testen: `https://<deine-function>/api/GetAssets` muss eine JSON-Liste liefern.

## 6. Anmeldung für GitHub Actions per OIDC (kein Secret im Repo)

```bash
APP_ID=$(az ad app create --display-name gh-azure-asset-management --query appId -o tsv)
az ad sp create --id $APP_ID

az ad app federated-credential create --id $APP_ID --parameters '{
  "name": "github-main",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:enes568/azure-asset-management:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}'

FUNC_ID=$(az functionapp show -g $RG -n $FUNC --query id -o tsv)
az role assignment create --assignee $APP_ID --role "Website Contributor" --scope $FUNC_ID
```

`AZURE_CLIENT_ID` ist `$APP_ID`, die Tenant-ID zeigt `az account show --query tenantId -o tsv`. Die Rolle gilt nur für diese eine Function App.

## Was das im Gespräch belegt

- **Managed Identity:** Die Function hat keine Zugangsdaten im Code.
- **Least Privilege:** Reader nur auf eine Ressourcengruppe, kein Contributor auf das Abonnement.
- **OIDC:** Die Pipeline meldet sich ohne Passwort bei Azure an, mit Rechten nur auf die Function App.
- **Datenschutz:** Die API gibt nur Name, Typ, Status und eine gekürzte ID zurück, nicht die Subscription-ID.

## Grenzen

- Die Benutzeranmeldung im Dashboard (eigenes Entra-ID-Login) ist in Static Web Apps nur im kostenpflichtigen Standard-Plan verfügbar. Deshalb ist das Dashboard weiter öffentlich lesbar.
- Resource Graph drosselt pro Benutzer. Die Function speichert das Ergebnis deshalb 60 Sekunden.
- Als Status steht der `provisioningState` (z. B. "Succeeded"), nicht der Laufzustand einer VM.
