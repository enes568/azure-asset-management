// Ersetze den Link in den Anführungszeichen mit deiner echten Azure Function URL
const API_URL = "https://func-asset-management-ec-cdg8g3bgfubdaffx.austriaeast-01.azurewebsites.net/api/GetAssets";

async function fetchAssets() {
    try {
        const response = await fetch(API_URL);
        const data = await response.text(); // oder .json() je nachdem was die Function zurückgibt
        console.log("Antwort von Azure Function:", data);
        
        // Zeigt das Ergebnis zum Testen direkt auf der Seite an (optional)
        document.body.innerHTML += `<p>Backend-Antwort: ${data}</p>`;
    } catch (error) {
        console.error("Fehler beim Abrufen:", error);
    }
}

// Funktion beim Laden der Seite ausführen
fetchAssets();