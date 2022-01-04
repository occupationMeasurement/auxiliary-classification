##########################################
# Code zum Abspeichern von hilfsklassifikation.xml als Datenbank hilfsklassifikation.sqlite3
# zusätzlich einige beispielhafte Queries zur Abfrage von Daten

# install.packages(c("DBI", "RSQLite"))

library(DBI)
unlink("hilfsklassifikation.sqlite3")
con <- dbConnect(RSQLite::SQLite(), "hilfsklassifikation.sqlite3")

auxco_explorer_notes <- fread("auxco_explorer_notes.txt")

hilfskategorien[, valid_from := as.Date("2022-01-01")]
hilfskategorien[, valid_until := as.Date("9999-01-01")]
hilfskategorien[, cid := id] # concept id, not unique. generated when a new concept gets defined, but not updated if the concept changes
hilfskategorien[, id := 1:.N] # this is meant to be an integer primary key
# Variable mit kommentaren hinzufügen
answerOption <- merge(hilfskategorien, auxco_explorer_notes[, .(ids = as.character(ids), comment = notes)], by.x = "cid", by.y = "ids")[, .(id, cid, valid_from, valid_until, bezeichnung, taetigkeit, taetigkeitsbeschreibung, kldb_default, isco_default, comment)]

# in dieser Tabelle möchte ich den zeitlichen Verlauf speichern, wie die einzelnen ids miteinander zusammenhängen.
abstammung <- data.table(predecessor = NA_integer_, successor = NA_integer_)

# vermutlich braucht es die Datumsangaben hier gar nicht, weil die Zuordnung ohnehin einzeln für cnt angegeben wird?
#abgrenzungen[, valid_from := as.Date("2022-01-01")]
#abgrenzungen[, valid_until := as.Date("9999-01-01")]
# Ändere alte Namensgebung von id/refid in neue Namensgebung um und entferne bezeichnung/refbezeichnung
abgrenzung <- merge(merge(answerOption, abgrenzungen, by.x= "cid", by.y = "id")[, .(id, bezeichnung.y, refid, refbezeichnung, typ)], answerOption[,.(cid2 = cid, id2 = id, bezeichnung2 = bezeichnung)], by.x = "refid", by.y = "cid2")[,.(id, refid = id2, typ, bezeichnung = bezeichnung.y, refbezeichnung)][,.(id, refid, typ)]

#map_kldb_to_auxcoid[, valid_from := as.Date("2022-01-01")]
#map_kldb_to_auxcoid[, valid_until := as.Date("9999-01-01")]
# Ändere alte Namensgebung von id in neue Namensgebung (map_kldb_to_auxcoid[id == 4211] fällt dabei raus)
map_kldb_to_auxco <- merge(answerOption, map_kldb_to_auxcoid, by.x= "cid", by.y = "id")[, .(id, kldb)]
# entferne nicht-existente KldBs
map_kldb_to_auxco[nchar(kldb) > 5]
map_kldb_to_auxco[nchar(kldb) == 5, .N, by = kldb]
map_kldb_to_auxco <- map_kldb_to_auxco[nchar(kldb) == 5]

# folgefragen[, valid_from := as.Date("2022-01-01")]
# folgefragen[, valid_until := as.Date("9999-01-01")]
folgefrage <- merge(answerOption[,.(cid, id)], folgefragen, by.x= "cid", by.y = "id") # update id
# fill in typ and fragetext
folgefrage[typ == "", typ := NA]; folgefrage$typ <- zoo::na.locf(folgefrage$typ)
folgefrage[fragetextAktuellerBeruf == "", fragetextAktuellerBeruf := NA]; folgefrage$fragetextAktuellerBeruf <- zoo::na.locf(folgefrage$fragetextAktuellerBeruf)
folgefrage[fragetextVergangenerBeruf == "", fragetextVergangenerBeruf := NA]; folgefrage$fragetextVergangenerBeruf<- zoo::na.locf(folgefrage$fragetextVergangenerBeruf)
# entferne Zeilen mit Fragetexten
folgefrage <- folgefrage[antwort.pos != ""]
# erzeuge unique folgefrageid
folgefrage[, qid_temp := paste0(id, questionNumber)]
folgefrage <- merge(folgefrage, data.table(qid = 1:360, qid_temp = unique(folgefrage$qid_temp)), by = "qid_temp")
# follow-up Angaben auffüllen
folgefrage[is.na(followUp), followUp := "moeglich"]
folgefrage[followUp == FALSE, followUp := "unnoetig"]

folgefrage <- folgefrage[order(qid, questionNumber, antwort.pos), .(qid, qaid = 1:.N, id, questionNumber, typ, anforderungsniveau = NA_integer_, fuehrung = NA_character_, fragetextAktuellerBeruf, fragetextVergangenerBeruf, antworttext = antwort.text, position = antwort.pos, followUp, kldb = antwort.kldb, isco = antwort.isco, kldb1 = NA_character_, kldb2 = NA_character_, isco1 = NA_character_, isco2 = NA_character_, comment = NA_character_)]
folgefrage[qaid %in% c(791, 792), typ := "anforderungsniveau"]
folgefrage[typ == "anforderungsniveau", anforderungsniveau := as.integer(substring(kldb, 5,5))]
folgefrage[qid == 778, anforderungsniveau := 3]
folgefrage[qid == 679, anforderungsniveau := 2]
folgefrage[qid == 692, anforderungsniveau := 3]
folgefrage[qaid %in% c(691, 692), comment := "unnötige Folgefrage"]
folgefrage[qaid %in% c(693, 694), comment := "Warum entspricht diese Frage nicht der üblichen Formulierung zur Art der Aufsichtstätigkeit?"]
folgefrage[qaid %in% c(783, 784), comment := "schlecht formuliert, denn 4-jährige Master gibt es nicht"]
# Spalte fuehrung generieren
folgefrage[qaid %in% c(50, 219, 378, 380, 382, 536, 539, 542, 545, 549, 550, 553, 575, 587, 591, 593, 595, 597, 638, 642, 644, 646, 648, 656, 660, 662, 664, 668, 670, 672, 674, 868), fuehrung := "keine Fuehrungsverantwortung"]
folgefrage[qaid %in% c(3, 38, 52, 63, 69, 76, 78, 83, 85, 92, 158, 183, 237, 243, 251, 261, 263, 279, 285, 287, 289, 291, 343, 362, 364, 373, 375, 389, 421, 538, 541, 544, 547, 548, 552, 555, 574, 614, 627, 795, 797, 817, 821, 833, 835, 845, 855, 869, 884), fuehrung := "Fuehrungskraft"]
folgefrage[qaid %in% c(4, 39, 51, 64, 70, 77, 79, 84, 86, 93, 159, 184, 218, 238, 244, 252, 262, 264, 280, 286, 288, 290, 292, 344, 363, 365, 374, 376, 377, 379, 381, 390, 422, 537, 540, 543, 546, 551, 554, 586,
                        590, 592, 594, 596, 615, 628, 637, 641, 643, 645, 647, 655, 659, 661, 663, 667, 669, 671, 673, 796, 798, 818, 822, 834, 836, 846, 856, 867, 870, 885), fuehrung := "Aufsichtskraft"]
# korrigere kldb-/isco-Felder mit "bzw." und setze leere Felder auf NA
folgefrage[qaid == 177, kldb1 := "61204"]
folgefrage[qaid == 177, kldb2 := "61284"]
folgefrage[qaid == 177, comment := "61204 if qid 71 = Ja, else: 61284"]
folgefrage[qaid == 178, kldb1 := "61203"]
folgefrage[qaid == 178, kldb2 := "61283"]
folgefrage[qaid == 178, comment := "61203 if qid 71 = Ja, else: 61283"]
folgefrage[qaid == 181, kldb1 := "61214"]
folgefrage[qaid == 181, kldb2 := "61284"]
folgefrage[qaid == 181, comment := "61214 if qid 73 = Ja, else: 61284"]
folgefrage[qaid == 182, kldb1 := "61213"]
folgefrage[qaid == 182, kldb2 := "61283"]
folgefrage[qaid == 182, comment := "61213 if qid 73 = Ja, else: 61283"]
folgefrage[qaid == 130, isco1 := "2151"]
folgefrage[qaid == 130, isco2 := "2152"]
folgefrage[qaid == 130, comment := "2151 if qid 51 = Elektrotechnik, 2152 if qid 51 = Elektronik"]
folgefrage[qaid == 131, isco1 := "3113"]
folgefrage[qaid == 131, isco2 := "3114"]
folgefrage[qaid == 131, comment := "3113 if qid 51 = Elektrotechnik, 3114 if qid 51 = Elektronik"]
folgefrage[nchar(kldb) != 5, kldb := NA]
folgefrage[nchar(isco) != 4, isco := NA]

# evtl. wäre es besser statt dem aktuellen Format in folgefragen noch eine Tabelle zu erstellen, die für jede mögliche Antwortkombination aus Hilfsklassifikation/Folgefrage/sonstiger Fragebogeninput die KLDB-/ISCO-Kategorien zuordnet?

# die folgenden vier Tabellen wurden anhand von hilfklassifikation.xml mithilfe des Codes erstelle_hilfskategorien_abgrenzungen_folgefragen_aus_hilfsklassifikation.R erstellt.
dbWriteTable(con, "answeroption", answerOption)
dbWriteTable(con, "abstammung", abstammung)
dbWriteTable(con, "abgrenzung", abgrenzung)
dbWriteTable(con, "map_kldb_to_auxco", map_kldb_to_auxco)
dbWriteTable(con, "folgefrage", folgefrage)

# example queries to get data that is valid at :date
dbGetQuery(con, 'SELECT * FROM answeroption WHERE :date BETWEEN valid_from AND valid_until LIMIT 5', params = list(date = as.Date("2022-02-01")))
dbGetQuery(con, 'SELECT * FROM answeroption ao LEFT JOIN abgrenzung ab ON ao.id = ab.id WHERE :date BETWEEN valid_from AND valid_until LIMIT 5', params = list(date = as.Date("2022-02-01")))
dbGetQuery(con, 'SELECT * FROM abstammung')
dbGetQuery(con, 'SELECT * FROM abgrenzung ab LEFT JOIN answeroption ao ON ab.id = ao.id WHERE :date BETWEEN valid_from AND valid_until LIMIT 5', params = list(date = as.Date("2022-02-01")))
dbGetQuery(con, 'SELECT * FROM folgefrage f LEFT JOIN answeroption ao ON f.id = ao.id WHERE :date BETWEEN valid_from AND valid_until LIMIT 5', params = list(date = as.Date("2022-02-01")))
dbGetQuery(con, 'SELECT * FROM map_kldb_to_auxco kl LEFT JOIN answeroption ao ON kl.id = ao.id WHERE :date BETWEEN valid_from AND valid_until LIMIT 5', params = list(date = as.Date("2022-02-01")))

dbDisconnect(con)
