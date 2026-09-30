# ☁️ Azure Cloud Asset Management & Dashboard

[![Azure Static Web Apps](https://img.shields.io/badge/Azure-Static_Web_Apps-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white)](https://azure.microsoft.com/)
[![Azure Functions](https://img.shields.io/badge/Azure-Functions_Serverless-0078D4?style=for-the-badge&logo=azurefunctions&logoColor=white)](https://azure.microsoft.com/)
[![GitHub Actions](https://img.shields.io/badge/CI%2FCD-GitHub_Actions-2088FF?style=for-the-badge&logo=githubactions&logoColor=white)](https://github.com/features/actions)

Ein serverloses Cloud Asset Management Dashboard zur zentralen Erfassung und Visualisierung von IT-Ressourcen. Das Projekt demonstriert eine moderne Cloud-Infrastruktur auf Basis von **Microsoft Azure**, **PowerShell-Automatisierung** und einer **CI/CD-Pipeline**.

🚀 **Live-Demo:** https://gray-stone-09ea0b410.7.azurestaticapps.net

---

## 🏗️ Architektur & Komponenten

1. **Frontend:** Gehostet über **Azure Static Web Apps** mit Azure Dark Theme, Live-Filtern und dynamischen Statusanzeigen.
2. **Backend API:** **Azure Functions (Serverless)** als RESTful API Endpoint (`/api/GetAssets`).
3. **Automatisierung:** PowerShell-Skripte im Ordner `/scripts` zur direkten API-Abfrage der Cloud-Ressourcen.
4. **CI/CD:** **GitHub Actions** Workflow für automatisierte Builds und Deploys bei jedem `git push`.

---

## 🛠️ Verwendete Technologien

- **Cloud & Identity:** Microsoft Azure (Static Web Apps, Functions, Resource Groups, Entra ID / RBAC-Konzepte)
- **Programming & Automation:** JavaScript (ES6+ async/await), HTML5/CSS3, PowerShell
- **DevOps & Infrastructure:** GitHub Actions, Git
- **Zertifizierungen:** Microsoft Certified: Azure Fundamentals (AZ-900) | AZ-104 in Vorbereitung

---

## 👤 Autor

**Enes Can**  
*IT-Systemtechniker & Cloud Administrator (AZ-900 certified)*
