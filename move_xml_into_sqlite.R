##########################################
# Code zum Abspeichern von hilfsklassifikation.xml als Datenbank hilfsklassifikation.sqlite3
# zusätzlich einige beispielhafte Queries zur Abfrage von Daten

install.packages(c("DBI", "RSQLite"))

library(DBI)
unlink("hilfsklassifikation.sqlite3")
con <- dbConnect(RSQLite::SQLite(), "hilfsklassifikation.sqlite3")

hilfskategorien[, valid_from := as.Date("2022-01-01")]
hilfskategorien[, valid_until := as.Date("9999-01-01")]
hilfskategorien[, cnt := 1:.N] # this is meant to be an integer primary key
# anders als ID ist cnt eine Hilfskategorie für einen spezifischen Zeitraum (oder sollte ID so definiert werden, weil es keinen Sinn ergibt derselben Hilfskategorie nach Änderungen noch diese selbe ID zu geben?)

# in dieser Tabelle möchte ich den zeitlichen Verlauf speichern, in wie die einzelnen cnt miteinander zusammenhängen.
predecessor <- data.table(predecessor = NULL, followedBy = NULL)

# vermutlich braucht es die Datumsangaben hier gar nicht, weil die Zuordnung ohnehin einzeln für cnt angegeben wird?
abgrenzungen[, valid_from := as.Date("2022-01-01")]
abgrenzungen[, valid_until := as.Date("9999-01-01")]
map_kldb_to_auxcoid[, valid_from := as.Date("2022-01-01")]
map_kldb_to_auxcoid[, valid_until := as.Date("9999-01-01")]

# bei den Folgefragen ist noch besonders viel Arbeit zu tun um diese Tabelle zu standardisieren
# folgefragen[, valid_from := as.Date("2022-01-01")]
# folgefragen[, valid_until := as.Date("9999-01-01")]

# Vermutlich wird zusätzlich auch noch eine Tabelle benötigt, die für jede mögliche Antwortkombination aus Hilfsklassifikation/Folgefrage/sonstiger Fragebogeninput die KLDB-/ISCO-Kategorien zuordnet?

# die folgenden vier Tabellen wurden anhand von hilfklassifikation.xml mithilfe des Codes erstelle_hilfskategorien_abgrenzungen_folgefragen_aus_hilfsklassifikation.R erstellt.
dbWriteTable(con, "hilfskategorien", hilfskategorien)
dbWriteTable(con, "folgefragen", folgefragen)
dbWriteTable(con, "abgrenzungen", abgrenzungen)
dbWriteTable(con, "map_kldb_to_auxcoid", map_kldb_to_auxcoid)

# example queries to get data that is valid at :date
dbGetQuery(con, 'SELECT * FROM hilfskategorien WHERE :date BETWEEN valid_from AND valid_until LIMIT 5', params = list(date = as.Date("2022-02-01")))
dbGetQuery(con, 'SELECT * FROM folgefragen WHERE :date BETWEEN valid_from AND valid_until LIMIT 5', params = list(date = as.Date("2022-02-01")))
dbGetQuery(con, 'SELECT * FROM abgrenzungen WHERE :date BETWEEN valid_from AND valid_until LIMIT 5', params = list(date = as.Date("2022-02-01")))
dbGetQuery(con, 'SELECT * FROM map_kldb_to_auxcoid WHERE :date BETWEEN valid_from AND valid_until LIMIT 5', params = list(date = as.Date("2022-02-01")))

dbDisconnect(con)
