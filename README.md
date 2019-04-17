# Berufs-Hilfsklassifikation mit Tätigkeitsbeschreibungen

Dieser Ordner enthält den elektronischen Anhang zu folgender Publikation:

Schierholz, Malte; Brenner, Lorraine; Cohausz, Lea; Damminger, Lisa; Fast, Lisa; Hörig, Ann-Kathrin; Huber, Anna-Lena; Ludwig, Theresa; Petry, Annabell; Tschischka, Laura (2018):
 Vorstellung einer Hilfsklassifikation mit Tätigkeitsbeschreibungen für Zwecke der Berufskodierung.
 (IAB-Discussion Paper, 2018), Nürnberg, 45 S.

Das genannte Discussion-Paper ist online verfügbar unter 
https://www.iab.de/183/section.aspx/Publikation/k180509301

Ein zusammenfassende Darstellung ist publiziert in

Schierholz, Malte (2018): Eine Hilfsklassifikation mit Tätigkeitsbeschreibungen für Zwecke der Berufskodierung. AStA Wirtschafts- und Sozialstatistisches Archiv 12(3-4). 14 S. https://doi.org/10.1007/s11943-018-0231-2

# Verwendung
Die Datei hilfsklassifikation.xml enthält die Hilfsklassifikation. Zur übersichtlichen Darstellung (nahezu) derselben Inhalte können mit dem R-Skript vier Excel-Tabellen (csv) erstellt werden. Vergleiche auch die Kommentare dort.

Der folgende Code kann in R ausgeführt werden um die vier Excel-Tabellen im aktuellen Working Directory zu erstellen.

```
install.packages(c("xml2", "data.table", "stringdist"))
source("https://raw.githubusercontent.com/malsch/occupationCodingAuxco/master/erstelle_hilfskategorien_abgrenzungen_folgefragen_aus_hilfsklassifikation.R")
```

Alternativ kann die Hilfsklassifikation auch mithilfe eines interaktiven Explorers erkundet werden. 

```
install.packages(c("xml2", "data.table", "readxl", "shiny", "jsonlite"))

# Notizen werden nur gespeichert, wenn folgendes gemacht wird:
# 1. Kopiere https://raw.githubusercontent.com/malsch/occupationCodingAuxco/master/auxco_explorer_notes.txt in das lokale Filesystem
# 2. Gebe den Pfadnamen an, wo die Notizen gespeichert werden:
# auxco_notes_filename <- "path/to/auxco_explorer_notes.txt"

source("https://raw.githubusercontent.com/malsch/occupationCodingAuxco/master/auxCoExplorer.R")
```

# Changelog
Seit der ursprünglichen Publikation wurden zahlreiche Verbesserungen und Erweiterungen vorgenommen.

* 18.09.2018: Standardisierung und Überarbeitung der "Taetigkeit"-Formulierungen; Zusammenfügen von Kategorien, Einfügen von Folgefragen und weitere kleinere Änderungen

* 07.02.2019: Kleinere Anpassungen und Korrekturen (hauptsächlich bei zugeordneten ISCO-Codes). Außerdem: Veränderte Syntax der Hilfsklassifikation:
    * Jeder `<fragetext>`-Tag hat nun das `typ`-Attribut
    * Fragetexte sind nun unterteilt in zwei Tags `<folgefrageAktuellerBeruf>` und `<folgefrageVergangenerBeruf>`
    * `<antwort>`-Tags haben ein optionales Attribut `follow-up="FALSE"` wenn nach Auswahl dieser Antwort keine weitere Follow-Up Frage benötigt wird. (bereits seit dem September-Upgrade)
    
* 17.04.2019: AuxCo-Explorer hinzugefügt.


# Mitwirkende
Folgende Personen waren bei der Erstellung beteiligt.

Bauriegel, Mario; Brenner, Lorraine; Cohausz, Lea; Damminger, Lisa; Digiser, Marie-Luise; Fast, Lisa; Hörig, Ann-Kathrin; Huber, Anna-Lena; Ludwig, Theresa; Petry, Annabell; Rosebrock, Antje; Schierholz, Malte; Tschischka, Laura

