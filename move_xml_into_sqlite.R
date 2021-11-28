##########################################
# Code zum Abspeichern von hilfsklassifikation.xml als Datenbank hilfsklassifikation.sqlite3
# zusätzlich einige beispielhafte Queries zur Abfrage von Daten

install.packages(c("DBI", "RSQLite"))

library(DBI)
con <- dbConnect(RSQLite::SQLite(), "hilfsklassifikation.sqlite3")

hilfskategorien[, valid_from := as.Date("2022-01-01")]
hilfskategorien[, valid_until := as.Date("9999-01-01")]
folgefragen[, valid_from := as.Date("2022-01-01")]
folgefragen[, valid_until := as.Date("9999-01-01")]
abgrenzungen[, valid_from := as.Date("2022-01-01")]
abgrenzungen[, valid_until := as.Date("9999-01-01")]
map_kldb_to_auxcoid[, valid_from := as.Date("2022-01-01")]
map_kldb_to_auxcoid[, valid_until := as.Date("9999-01-01")]

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
