# WFM-TEST

Afzonderlijke testrepo voor de live WFM → rooster bridge.

## Wat staat er in deze repo?

- `index.html` — testreceiver. Ontvangt een My Schedule-scan via `postMessage`, toont direct de ontvangen roosterregels en bewaart de laatste testscan alleen in `sessionStorage`.
- `WFM-Planning-Scan-Send-Bookmarklet.txt` — bookmarklet op basis van de werkende My Schedule Planning Scan. Zet WFM zo snel mogelijk op **Planning period**, scant My Schedule, stuurt het resultaat naar deze testreceiver en probeert na ontvangstbevestiging het WFM-venster te sluiten.

## Testvolgorde

1. Publiceer deze repo via GitHub Pages vanaf branch `main` en map `/ (root)` als dat nog niet is ingesteld.
2. Open `https://svanbergen99.github.io/WFM-TEST/`.
3. Klik **WFM Login openen**.
4. Log officieel in bij WFM en ga naar **My Schedule** als WFM daar niet vanzelf uitkomt.
5. Maak een browserfavoriet van de volledige regel uit `WFM-Planning-Scan-Send-Bookmarklet.txt` en klik die op My Schedule.
6. De bookmarklet kiest automatisch de laatste radio-optie (**Planning period**), klikt **OK**, wacht alleen technisch totdat het rooster klaar is, scant de zichtbare My Schedule-data en verstuurt die naar de WFM-TEST-pagina.
7. Bij succes toont de WFM-TEST-pagina direct `WFM LIVE SCAN ONTVANGEN` met datums, roosterregels en activiteiten. De WFM-tab probeert daarna te sluiten.

## Belangrijk

Deze repo wijzigt niets in `Roosteroverzicht` en schrijft geen WFM-roosterdata naar GitHub. De ontvangen scan blijft alleen in de browsersessie van de testpagina.
