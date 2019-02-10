################################################
# Der folgende Code lädt die Datei hilfsklassifikation.xml.
#
# Daraus werden im nachfolgenden Code die folgenden Dateien erstellt:
# - hilfskategorien_sortiert_nach_id.csv
# - abgrenzungen_sortiert_nach_kldb.csv
# - folgefragen.csv
# - hilfskategorien_kldb_mit_id.csv
# Sie stellen ausgewählte Inhalte übersichtlicher dar.
#
# hilfskategorien_sortiert_nach_id.csv enthält zu jeder Hilfskategorie die ID, die Bezeichnung, die Tätigkeit, die Tätigkeitsbeschreibung sowie zugeordnete Berufskategorien aus der KldB 2010 sowie aus ISCO-08.
# abgrenzungen_sortiert_nach_kldb.csv enthält die Abgrenzungen von allen Hilfskategorien. Zu jeder ID sind alle Abgrenzungen (REFID) und ihr jeweiliger TYP einzeln angegeben.
# folgefragen.csv enthält sämtliche Folgefragen. Dargestellt sind die Fragetexte, die einzelnen Antwortoptionen sowie die ihnen zugeordneten Berufskategorien aus der KldB 2010 und aus ISCO-08.
# hilfskategorien_kldb_mit_id.csv enthält zu jeder Hilfskategorie die zugeordneten KldB-Kategorien (Default-Kategorie und Kategorie aus Folgefrage). Und selbst für nicht in der Hilfsklassifikation enthaltene KldBs werden dort passende IDs aus der Hilfsklassifikation benannt.
# 
# Eine weitere Datei vergleich_hilfsklassifikation_berufenet.csv ist nur unter https://www.iab.de/183/section.aspx/Publikation/k180509301 verlinkt. Dort werden die Hilfskategorien der Hilfskategorien mit den Berufsbezeichnungen aus dem BERUFENET verglichen.
#
# Malte Schierholz
# 23. Februar 2018 (Ursprungsversion von https://www.iab.de/183/section.aspx/Publikation/k180509301)
# 10. Februar 2019 (Anpassung für Github, Berücksichtigung der Folgefragen-Syntax vom 7.2.2019, hilfskategorien_kldb_mit_id.csv hinzugefügt)
####################################################################################

library(xml2)
library(data.table)
library(stringdist)

# read auxiliary classification
src <- read_xml("https://raw.githubusercontent.com/malsch/occupationCodingAuxco/master/hilfsklassifikation.xml")

# remove all answer options that ask for an open-ended answer
# Not yet implemented, but it may be worth to look at this again.
# What if people do not find an answer option in follow-up questions that is appropriate for them?
category_node <- xml_find_all(src, xpath = paste0("//isco[@schluessel='????']/parent::antwort"))
xml_remove(category_node)

# select IDs
ids <- as.numeric(xml_text(xml_find_all(src, xpath = "//id")))

##############################################
### Write data to excel file, listing all auxiliary categories order by id
### Every category from the auxiliary classification must appear exactly once
### Create file: hilfskategorien_sortiert_nach_id.csv
##############################################

res <- NULL
for (cat_num in seq_along(ids)) {
  category_node <- xml_find_all(src, xpath = paste0("//klassifikation/*[", cat_num, "]"))
  id <- xml_text(xml_find_all(category_node, xpath = "./id"))
  taetigkeit <- xml_text(xml_find_all(category_node, xpath = "./taetigkeit"))
  taetigkeitsbeschreibung <- xml_text(xml_find_all(category_node, xpath = "./taetigkeitsbeschreibung"))
  bezeichnung <- xml_text(xml_find_all(category_node, xpath = "./bezeichnung"))
  kldb_id_default <- xml_attr(xml_find_all(category_node, xpath = ".//default/kldb"), "schluessel")
  isco_id_default <- xml_attr(xml_find_all(category_node, xpath = ".//default/isco"), "schluessel")
  kldb_id_folgefrage <- xml_attr(xml_find_all(category_node, xpath = ".//antwort/kldb"), "schluessel")
  isco_id_folgefrage <- xml_attr(xml_find_all(category_node, xpath = ".//antwort/isco"), "schluessel")
  res <- rbind(res, data.table(id, bezeichnung, kldb_default = kldb_id_default, kldb_folgefrage = paste(kldb_id_folgefrage, collapse = ", "), isco_default = isco_id_default, isco_folgefrage = paste(isco_id_folgefrage, collapse = ", "), taetigkeit, taetigkeitsbeschreibung))
}

write.csv2(res[order(id)], row.names = FALSE, file = "hilfskategorien_sortiert_nach_id.csv", fileEncoding = "UTF-8")

###############################################
### Write data to excel file, listing all abgrenzungen
### Create file: abgrenzungen_sortiert_nach_kldb.csv
###############################################

res <- NULL
for (cat_num in seq_along(ids)) {
  category_node <- xml_find_all(src, xpath = paste0("//klassifikation/*[", cat_num, "]"))
  id <- xml_text(xml_find_all(category_node, xpath = "./id"))
  bezeichnung <- xml_text(xml_find_all(category_node, xpath = "./bezeichnung"))
  kldb_id_default <- xml_attr(xml_find_all(category_node, xpath = ".//default/kldb"), "schluessel")
  
  abgrenzungen <- xml_find_all(category_node, xpath = "./abgrenzung")
  if (length(abgrenzungen) > 0) {
    res <- rbind(res, data.table(kldb_id_default, id, bezeichnung, refid = xml_attr(abgrenzungen, "refid"), refbezeichnung = xml_text(abgrenzungen), typ = xml_attr(abgrenzungen, "typ")))
  }
}

write.csv2(res[order(kldb_id_default)], row.names = FALSE, file = "abgrenzungen_sortiert_nach_kldb.csv", fileEncoding = "UTF-8")

###############################################
### Write data to excel file, listing all Folgefragen
### Create file: folgefragen.csv
###############################################

res <- NULL
for (cat_num in seq_along(ids)) { # 
  category_node <- xml_find_all(src, xpath = paste0("//klassifikation/*[", cat_num, "]"))
  id <- xml_text(xml_find_all(category_node, xpath = "./id"))
  
  for (folgefrage_node in xml_find_all(category_node, xpath = "./untergliederung/child::*")) {
    if (xml_name(folgefrage_node) == "fragetext") {
      typ <- xml_attr(folgefrage_node, "typ")
      fragetextAktuellerBeruf <- xml_text(xml_find_all(folgefrage_node, xpath = "./folgefrageAktuellerBeruf"))
      fragetextVergangenerBeruf <- xml_text(xml_find_all(folgefrage_node, xpath = "./folgefrageVergangenerBeruf"))
      
      res <- rbind(res, cbind(data.table(id, typ = typ, fragetextAktuellerBeruf = fragetextAktuellerBeruf, fragetextVergangenerBeruf = fragetextVergangenerBeruf, antwort.pos = "", antwort.text = "", antwort.kldb = "", antwort.isco = "", followUp = "")))
    }
    if (xml_name(folgefrage_node) == "antwort") {
      pos <- xml_attr(folgefrage_node, "position")
      followUp <- xml_attr(folgefrage_node, "follow-up")
      ant.text <- xml_text(xml_find_all(folgefrage_node, xpath = "./text"))
      ant.kldb <- xml_attr(xml_find_all(folgefrage_node, xpath = "./kldb"), "schluessel")
      if (length(ant.kldb) == 0) ant.kldb <- ""
      ant.isco <- xml_attr(xml_find_all(folgefrage_node, xpath = "./isco"), "schluessel")
      if (length(ant.isco) == 0) ant.isco <- ""
  
      res <- rbind(res, cbind(data.table(id, typ = "", fragetextAktuellerBeruf = "", fragetextVergangenerBeruf = "", antwort.pos = pos, antwort.text = ant.text, antwort.kldb = ant.kldb, antwort.isco = ant.isco, followUp = followUp)))
    }
  }
}

# number rows and number questions per id
res[, questionNumber := cumsum(fragetextAktuellerBeruf != ""), by = id]
res[, laufindexFolge := 1:.N]

write.csv2(res[order(id), list(laufindexFolge, id, questionNumber, fragetextAktuellerBeruf, fragetextVergangenerBeruf, antwort.pos, antwort.text, antwort.kldb, antwort.isco, followUp)], row.names = FALSE, file = "folgefragen.csv", fileEncoding = "UTF-8")


##############################################
# write data to excel file, listing all kldb categories (default and folgefrage) and their associated category ids
# Create file: hilfskategorien_kldb_mit_id.csv
##############################################

res <- NULL
for (cat_num in seq_along(ids)) {
  category_node <- xml_find_all(src, xpath = paste0("//klassifikation/*[", cat_num, "]"))
  id <- xml_text(xml_find_all(category_node, xpath = "./id"))
  kldb_id_default <- xml_attr(xml_find_all(category_node, xpath = ".//default/kldb"), "schluessel")
  kldb_id_folgefrage <- xml_attr(xml_find_all(category_node, xpath = ".//antwort/kldb"), "schluessel")
  res <- rbind(res, data.table(id, kldb = c(kldb_id_default, kldb_id_folgefrage)))
}

# nicht alle kldbs stehen in der Hilfsklassifikation, denn einzelne Kategorien in der KldB unterscheiden sich kaum. Für nicht enthaltene KldBs (Spalte kldb) füge Verknüpfungen zu sehr ähnlichen kldbs (Spalte aehnlich_zu) und zu den zugehörigen IDs aus der Hilfsklassifikation (Spalte id) hinzu. Dies ermöglicht Hilfskategorien vorzuschlagen, auch wenn die jeweilige KldB nicht in der Hilfsklassifikation steht.
res <- rbind(res,
             data.table(id =           c("1014",  "1015",  "1519",  "1518",  "5178",  "5179",  "1716",  "1716",  "2115",  "1733",  "1734",  "1790",   "3205",  "3206", "3205",  "3206",  "3573",  "3570",  "3550",   "3550", "3546",  "3542",   "7005", "3551",  "3552",  "3541",  "7104" , "7043",  "7043",  "7053",  "1828",  "1112" ), 
                        kldb =         c("11183", "11183", "11402", "11402", "22182", "22182", "22183", "22184", "26382", "26383", "26383", "41383", "71382", "71382", "71383", "71383", "72214", "72214", "73282", "73283", "73284", "73293", "73293", "73293", "73293", "73293", "81382", "81783", "81784", "81784", "82283", "91484") #,
#                       aehnlich_zu =  c("11103", "11104", "11412", "11422", "22102", "22102", "22103", "22104", "26302", "26303", "26303", "41303", "71302", "71302", "71302", "71302", "72234", "72294", "73202", "73203", "73204", "73214", "73224", "73234", "73244", "73254", "81302", "81713", "81714", "81783", "82233", "91404")
             ))
# Weitere KldBs stehen nicht mehr in der Hilfsklassifikation (in der Ursprungsversion waren sie noch enthalten), da diese Kategorien sehr allgemein gehalten sind und wir glauben, dass sich Beschäftigte im allgemeinen genauer einordnen können
res <- rbind(res,
             data.table(id =           c("2093",  "2018",  "1853",  "2022",  "2023",  "2029",  "2034",  "1722",  "1722",  "9041",  "9096",  "9087",   "9063",  "9065", "9067",  "9069",  "9040",  "9049",   "9076",  "9097",  "9062",  "9064", "9066",  "9068",   "9070", "9049",  "9047",  "9076",  "4002" , "4002",  "4002",  "4004",  "4005",  "4006" ,  "4007",  "4008",  "4210",  "4211",  "4212",  "4213",  "4214",  "1799",  "1785",  "6030",  "1750",  "3205",  "3206",  "3208",  "3210",  "3211",  "3599",  "3531",  "3530",  "3532",  "3533",  "3530",  "3537",  "3599",  "5128", "5141"), 
                        kldb =         c("24202", "24202", "24202", "24202", "24202", "24202", "24202", "27103", "27104", "29202", "29202", "29202", "29202", "29202", "29202", "29202", "29202", "29203", "29203", "29203", "29203", "29203", "29203", "29203", "29203", "29204", "29204", "29204", "41203", "41283", "41204", "41204", "41204", "41204", "41204", "41204", "41204", "41204", "41204", "41204", "41204", "42283", "42283", "62103", "62103", "71304", "71304", "71304", "71304", "71304", "71304", "73104", "73104", "73104", "73104", "73104", "73104", "73104", "93383", "93383") #,
#                       aehnlich_zu =  c("24201", "24203", "24212", "24222", "24232", "24302", "24412", "25103", "25104", "29201", "29212", "29222", "29232", "29242", "29252", "29262", "29282", "29283", "29293", "29213", "29223", "29233", "29243", "29253", "29263", "29283", "29284", "29294", "41213", "41213", "41214", "41234", "41244", "41254", "41264", "41274", "41284", "41284", "41284", "41284", "41284", "42203", "34313", "62102", "62193", "71303", "71303", "71314", "71394", "71394", "71594", "73124", "73134", "73144", "73154", "73183", "73194", "71394", "93303", "93393")
             ))
# Andere KldBs werden nicht erkannt (siehe Hilfsklassifikation), weil sie abhängig von zwei Folgefragen sind
res <- rbind(res,
             data.table(id =           c("1748",  "1749",  "1748",  "1749"), 
                        kldb =         c("61204", "61214", "61284", "61284")
             ))


res <- unique(res)

write.csv2(res, row.names = FALSE, file = "hilfskategorien_kldb_mit_id.csv", fileEncoding = "UTF-8")
