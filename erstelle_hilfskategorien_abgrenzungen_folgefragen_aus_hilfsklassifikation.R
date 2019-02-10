################################################
# Der folgende Code lädt die Datei hilfsklassifikation.xml.
#
# Daraus werden im nachfolgenden Code die folgenden Dateien erstellt:
# - hilfskategorien_sortiert_nach_id.csv
# - abgrenzungen_sortiert_nach_kldb.csv
# - folgefragen.csv
# Sie stellen ausgewählte Inhalte übersichtlicher dar.
#
# hilfskategorien_sortiert_nach_id.csv enthält zu jeder Hilfskategorie die ID, die Bezeichnung, die Tätigkeit, die Tätigkeitsbeschreibung sowie zugeordnete Berufskategorien aus der KldB 2010 sowie aus ISCO-08.
# abgrenzungen_sortiert_nach_kldb.csv enthält die Abgrenzungen von allen Hilfskategorien. Zu jeder ID sind alle Abgrenzungen (REFID) und ihr jeweiliger TYP einzeln angegeben.
# folgefragen.csv enthält sämtliche Folgefragen. Dargestellt sind die Fragetexte, die einzelnen Antwortoptionen sowie die ihnen zugeordneten Berufskategorien aus der KldB 2010 und aus ISCO-08.
#
# Eine weitere Datei vergleich_hilfsklassifikation_berufenet.csv ist nur unter https://www.iab.de/183/section.aspx/Publikation/k180509301 verlinkt. Dort werden die Hilfskategorien der Hilfskategorien mit den Berufsbezeichnungen aus dem BERUFENET verglichen.
#
# Malte Schierholz
# 23. Februar 2018 (Ursprungsversion von https://www.iab.de/183/section.aspx/Publikation/k180509301)
# 10. Februar 2019 (Anpassung für Github)
####################################################################################

library(xml2)
library(data.table)
library(stringdist)

# read auxiliary classification
src <- read_xml("https://raw.githubusercontent.com/malsch/occupationCodingAuxco/master/hilfsklassifikation.xml")

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

write.csv2(res[order(id)], row.names = FALSE, file = "hilfskategorien_sortiert_nach_id.csv")

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

write.csv2(res[order(kldb_id_default)], row.names = FALSE, file = "abgrenzungen_sortiert_nach_kldb.csv")

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

write.csv2(res[order(id)], row.names = FALSE, file = "folgefragen.csv")
