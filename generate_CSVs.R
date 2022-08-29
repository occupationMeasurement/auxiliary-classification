################################################
# Der folgende Code lädt die Datei hilfsklassifikation.xml.
#
# Daraus werden im nachfolgenden Code die folgenden Dateien erstellt:
# - auxco_categories.csv
# - auxco_distinctions.csv
# - auxco_followup_questions.csv
# - auxco_mapping_from_kldb.csv
# Sie stellen ausgewählte Inhalte übersichtlicher dar.
#
# auxco_categories.csv enthält zu jeder Hilfskategorie die ID, die Bezeichnung, die Tätigkeit, die Tätigkeitsbeschreibung sowie zugeordnete Berufskategorien aus der KldB 2010 sowie aus ISCO-08.
# auxco_distinctions.csv enthält die Abgrenzungen von allen Hilfskategorien. Zu jeder ID sind alle Abgrenzungen (REFID) und ihr jeweiliger TYP einzeln angegeben.
# auxco_followup_questions.csv enthält sämtliche Folgefragen. Dargestellt sind die Fragetexte, die einzelnen Antwortoptionen sowie die ihnen zugeordneten Berufskategorien aus der KldB 2010 und aus ISCO-08.
# auxco_mapping_from_kldb.csv enthält zu jeder Hilfskategorie die zugeordneten KldB-Kategorien (Default-Kategorie und Kategorie aus Folgefrage). Und selbst für nicht in der Hilfsklassifikation enthaltene KldBs werden dort passende IDs aus der Hilfsklassifikation benannt.
#
# Eine weitere Datei vergleich_hilfsklassifikation_berufenet.csv ist nur unter https://www.iab.de/183/section.aspx/Publikation/k180509301 verlinkt. Dort werden die Hilfskategorien der Hilfskategorien mit den Berufsbezeichnungen aus dem BERUFENET verglichen.
#
# Malte Schierholz
# 23. Februar 2018 (Ursprungsversion von https://www.iab.de/183/section.aspx/Publikation/k180509301)
# 10. Februar 2019 (Anpassung für Github, Berücksichtigung der Folgefragen-Syntax vom 7.2.2019, auxco_mapping_from_kldb.csv hinzugefügt)
####################################################################################

library(xml2)
library(data.table)
library(stringdist)

output_dir <- "output"
dir.create(output_dir, showWarnings = FALSE)

# read auxiliary classification
src <- read_xml("./hilfsklassifikation.xml")

# remove all answer options that ask for an open-ended answer
# Not yet implemented, but it may be worth to look at this again.
# What if people do not find an answer option in follow-up questions that is appropriate for them?
category_node <- xml_find_all(
  src,
  xpath = paste0("//isco[@schluessel='????']/parent::antwort")
)
xml_remove(category_node)

# select IDs
ids <- as.numeric(xml_text(xml_find_all(src, xpath = "//id")))

##############################################
### Write data to excel file, listing all auxiliary categories order by id
### Every category from the auxiliary classification must appear exactly once
### Create file: auxco_categories.csv
##############################################

auxco_categories <- NULL
for (cat_num in seq_along(ids)) {
  category_node <- xml_find_all(
    src,
    xpath = paste0("//klassifikation/*[", cat_num, "]")
  )
  auxco_id <- xml_find_all(category_node, xpath = "./id") |>
    xml_text()
  title <- xml_find_all(category_node, xpath = "./bezeichnung") |>
    xml_text()
  task <- xml_find_all(category_node, xpath = "./taetigkeit") |>
    xml_text()
  task_description <- xml_find_all(
    category_node,
    xpath = "./taetigkeitsbeschreibung"
  ) |>
    xml_text()
  default_kldb_id <- xml_find_all(category_node, xpath = ".//default/kldb") |>
    xml_attr("schluessel")
  default_isco_id <- xml_find_all(category_node, xpath = ".//default/isco") |>
    xml_attr("schluessel")
  auxco_categories <- rbind(
    auxco_categories,
    data.table(
      auxco_id,
      title,
      default_kldb_id,
      default_isco_id,
      task,
      task_description
    )
  )
}

# Order by id
auxco_categories <- auxco_categories[order(auxco_id)]

fwrite(
  auxco_categories,
  row.names = FALSE,
  file = file.path(output_dir, "auxco_categories.csv")
)

###############################################
### Write data to excel file, listing all abgrenzungen
### Create file: auxco_distinctions.csv
###############################################

auxco_distinctions <- NULL
for (cat_num in seq_along(ids)) {
  category_node <- xml_find_all(
    src,
    xpath = paste0("//klassifikation/*[", cat_num, "]")
  )
  auxco_id <- xml_find_all(category_node, xpath = "./id") |>
    xml_text()
  title <- xml_find_all(category_node, xpath = "./bezeichnung") |>
    xml_text()
  default_kldb_id <- xml_find_all(category_node, xpath = ".//default/kldb") |>
    xml_attr("schluessel")
  distinction_categories <- xml_find_all(category_node, xpath = "./abgrenzung")

  if (length(distinction_categories) > 0) {
    auxco_distinctions <- rbind(
      auxco_distinctions,
      data.table(
        auxco_id,
        title,
        similar_auxco_id = distinction_categories |> xml_attr("refid"),
        similar_title = distinction_categories |> xml_text(),
        similarity = distinction_categories |> xml_attr("typ"),
        default_kldb_id
      )
    )
  }
}

# Order by kldb_id, since it's better at showing similar categories
# next to each other
auxco_distinctions <- auxco_distinctions[order(default_kldb_id)]

fwrite(
  auxco_distinctions,
  row.names = FALSE,
  file = file.path(output_dir, "auxco_distinctions.csv")
)

###############################################
### Write data to excel file, listing all Folgefragen
### Create file: auxco_followup_questions.csv
###############################################

auxco_followup_questions <- NULL
for (cat_num in seq_along(ids)) { #
  category_node <- src |>
    xml_find_all(xpath = paste0("//klassifikation/*[", cat_num, "]"))
  auxco_id <- xml_find_all(category_node, xpath = "./id") |>
    xml_text()

  for (
    folgefrage_node in category_node |>
      xml_find_all(xpath = "./untergliederung/child::*")
  ) {
    # Handle questions
    if (xml_name(folgefrage_node) == "fragetext") {
      question_type <- xml_attr(folgefrage_node, "typ")
      question_text_present <- folgefrage_node |>
        xml_find_all(xpath = "./folgefrageAktuellerBeruf") |>
        xml_text()
      question_text_past <- folgefrage_node |>
        xml_find_all(xpath = "./folgefrageVergangenerBeruf") |>
        xml_text()

      auxco_followup_questions <- rbind(
        auxco_followup_questions,
        cbind(
          data.table(
            auxco_id,
            entry_type = "question",
            question_type,
            question_text_present,
            question_text_past,
            answer_id = "",
            answer_text = "",
            answer_kldb_id = "",
            answer_isco_id = "",
            explicit_has_followup = ""
          )
        )
      )
    }
    # Handle answers / answer options
    if (xml_name(folgefrage_node) == "antwort") {
      answer_id <- xml_attr(folgefrage_node, "position")
      explicit_has_followup <- xml_attr(folgefrage_node, "follow-up") |>
        as.logical()
      answer_text <- xml_find_all(folgefrage_node, xpath = "./text") |>
        xml_text()
      answer_kldb_id <- xml_find_all(folgefrage_node, xpath = "./kldb") |>
        xml_attr("schluessel")
      if (length(answer_kldb_id) == 0) answer_kldb_id <- ""
      answer_isco_id <- xml_find_all(folgefrage_node, xpath = "./isco") |>
        xml_attr("schluessel")
      if (length(answer_isco_id) == 0) answer_isco_id <- ""

      auxco_followup_questions <- rbind(
        auxco_followup_questions,
        cbind(data.table(
          auxco_id,
          entry_type = "answer_option",
          question_type = "",
          question_text_present = "",
          question_text_past = "",
          answer_id,
          answer_text,
          answer_kldb_id,
          answer_isco_id,
          explicit_has_followup
        ))
      )
    }
  }
}

# Add unique question_ids
auxco_followup_questions[
  ,
  question_index := cumsum(entry_type == "question"),
  by = auxco_id
]
auxco_followup_questions[, question_id := paste0(auxco_id, "_", question_index)]
auxco_followup_questions <- auxco_followup_questions[order(auxco_id)]

# Move the question_id forward in the column order
setcolorder(
  auxco_followup_questions,
  c("auxco_id", "question_id", "question_index")
)

# Compute a more intuitive "last_question" column in place of the
# explicit_has_followup from the xml.
auxco_followup_questions[
  entry_type == "answer_option",
  last_question :=
    (question_index == max(question_index)) |
    (!is.na(explicit_has_followup) & explicit_has_followup == FALSE)
  ,
  by = auxco_id
]
auxco_followup_questions[, explicit_has_followup := NULL]

fwrite(
  auxco_followup_questions,
  row.names = FALSE,
  file = file.path(output_dir, "auxco_followup_questions.csv")
)

##############################################
# ===== Mappings to other Coding Systems =====
##############################################

create_mapping <- function(target_name) {
  mapping <- NULL

  for (cat_num in seq_along(ids)) {
    category_node <- src |>
      xml_find_all(xpath = paste0("//klassifikation/*[", cat_num, "]"))
    auxco_id <- xml_find_all(category_node, xpath = "./id") |>
      xml_text()
    title <- xml_find_all(category_node, xpath = "./bezeichnung") |>
      xml_text()
    target_id_default <- category_node |>
      xml_find_all(xpath = paste0(".//default/", target_name)) |>
      xml_attr("schluessel")
    target_id_folgefrage <- category_node |>
      xml_find_all(xpath = paste0(".//antwort/", target_name)) |>
      xml_attr("schluessel")

    # Create the mapping table manually, as we have to generate some colnames
    mapping_to_add <- data.table()
    mapping_to_add[, (paste0(target_name, "_id")) := c(
      target_id_default,
      target_id_folgefrage
    )]
    mapping_to_add[, auxco_id := auxco_id]
    mapping_to_add[, title := title]

    # Combine mappin_to_add with the overall mapping
    mapping <- rbind(
      mapping,
      mapping_to_add
    )
  }

  return(mapping)
}

##############################################
# Mapping of all ISCO categories (default and folgefrage) to auxco_ids
# Create file: auxco_mapping_from_isco.csv
##############################################

auxco_mapping_from_isco <- create_mapping("isco")

fwrite(
  auxco_mapping_from_isco,
  row.names = FALSE,
  file = file.path(output_dir, "auxco_mapping_from_isco.csv")
)

##############################################
# Mapping of all kldb categories (default and folgefrage) to auxco_ids
# Create file: auxco_mapping_from_kldb.csv
##############################################

auxco_mapping_from_kldb <- create_mapping("kldb")

# TODO: These manual additions should live in the XML or at least a CSV

# nicht alle kldbs stehen in der Hilfsklassifikation, denn einzelne Kategorien
# in der KldB unterscheiden sich kaum. Für nicht enthaltene KldBs (Spalte kldb)
# füge Verknüpfungen zu sehr ähnlichen kldbs (Spalte aehnlich_zu) und zu den
# zugehörigen IDs aus der Hilfsklassifikation (Spalte id) hinzu. Dies ermöglicht
# Hilfskategorien vorzuschlagen, auch wenn die jeweilige KldB nicht in der
# Hilfsklassifikation steht.
manual_mapping_additions <- data.table(
  auxco_id = c("1014", "1015", "1519", "1518", "5178", "5179", "1716", "1716", "2115", "1733", "1734", "1790", "3205", "3206", "3205", "3206", "3573", "3570", "3550", "3550", "3546", "3542", "7005", "3551", "3552", "3541", "7104", "7043", "7043", "7053", "1828", "1112"),
  kldb_id = c("11183", "11183", "11402", "11402", "22182", "22182", "22183", "22184", "26382", "26383", "26383", "41383", "71382", "71382", "71383", "71383", "72214", "72214", "73282", "73283", "73284", "73293", "73293", "73293", "73293", "73293", "81382", "81783", "81784", "81784", "82283", "91484")
)
# Weitere KldBs stehen nicht mehr in der Hilfsklassifikation (in der
# Ursprungsversion waren sie noch enthalten), da diese Kategorien sehr allgemein
# gehalten sind und wir glauben, dass sich Beschäftigte im allgemeinen genauer
# einordnen können
manual_mapping_additions <- rbind(
  manual_mapping_additions,
  data.table(
    auxco_id = c("2093", "2018", "1853", "2022", "2023", "2029", "2034", "1722", "1722", "9041", "9096", "9087", "9063", "9065", "9067", "9069", "9040", "9049", "9076", "9097", "9062", "9064", "9066", "9068", "9070", "9049", "9047", "9076", "4002", "4002", "4002", "4004", "4005", "4006", "4007", "4008", "4210", "4211", "4212", "4213", "4214", "1799", "1785", "6030", "1750", "3205", "3206", "3208", "3210", "3211", "3599", "3531", "3530", "3532", "3533", "3530", "3537", "3599", "5128", "5141"),
    kldb_id = c("24202", "24202", "24202", "24202", "24202", "24202", "24202", "27103", "27104", "29202", "29202", "29202", "29202", "29202", "29202", "29202", "29202", "29203", "29203", "29203", "29203", "29203", "29203", "29203", "29203", "29204", "29204", "29204", "41203", "41283", "41204", "41204", "41204", "41204", "41204", "41204", "41204", "41204", "41204", "41204", "41204", "42283", "42283", "62103", "62103", "71304", "71304", "71304", "71304", "71304", "71304", "73104", "73104", "73104", "73104", "73104", "73104", "73104", "93383", "93383")
  )
)
# Andere KldBs werden nicht erkannt (siehe Hilfsklassifikation),
# weil sie abhängig von zwei Folgefragen sind
manual_mapping_additions <- rbind(
  manual_mapping_additions,
  data.table(
    auxco_id = c("1748", "1749", "1748", "1749"),
    kldb_id = c("61204", "61214", "61284", "61284")
  )
)

# Add title information and then combine the manual mapping
# with the existing auxco mapping
manual_mapping_additions <- merge(
  manual_mapping_additions,
  auxco_mapping_from_kldb[, list(auxco_id, title)],
  by = "auxco_id"
)
auxco_mapping_from_kldb <- rbind(
  auxco_mapping_from_kldb,
  manual_mapping_additions
)

# TODO: Add kldb_title via join

auxco_mapping_from_kldb <- unique(auxco_mapping_from_kldb)

fwrite(
  auxco_mapping_from_kldb,
  row.names = FALSE,
  file = file.path(output_dir, "auxco_mapping_from_kldb.csv")
)
