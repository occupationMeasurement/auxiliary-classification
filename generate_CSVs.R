################################################
# Der folgende Code lädt die Datei hilfsklassifikation.xml.
#
# Daraus werden im nachfolgenden Code die folgenden Dateien erstellt:
# - auxco_categories.csv
# - auxco_distinctions.csv
# - auxco_followup_questions.csv
# - auxco_mapping_from_kldb.csv
# - auxco_mapping_from_isco.csv
# Sie stellen ausgewählte Inhalte übersichtlicher dar.
#
# auxco_categories.csv enthält zu jeder Hilfskategorie die ID, die Bezeichnung, die Tätigkeit, die Tätigkeitsbeschreibung sowie zugeordnete Berufskategorien aus der KldB 2010 sowie aus ISCO-08.
# auxco_distinctions.csv enthält die Abgrenzungen von allen Hilfskategorien. Zu jeder ID sind alle Abgrenzungen (REFID) und ihr jeweiliger TYP einzeln angegeben.
# auxco_followup_questions.csv enthält sämtliche Folgefragen. Dargestellt sind die Fragetexte, die einzelnen Antwortoptionen sowie die ihnen zugeordneten Berufskategorien aus der KldB 2010 und aus ISCO-08.
# auxco_mapping_from_kldb.csv enthält zu jeder Hilfskategorie die zugeordneten KldB-Kategorien (Default-Kategorie und Kategorie aus Folgefrage). Und selbst für nicht in der Hilfsklassifikation enthaltene KldBs werden dort passende IDs aus der Hilfsklassifikation benannt.
# auxco_mapping_from_isco.csv enthält zu jeder Hilfskategorie die zugeordneten ISCO-Kategorien (Default-Kategorie und Kategorie aus Folgefrage). Einige ISCO-Kategorien fehlen, da einige Berufe in Deutschland nicht vorkommen.

#
# Eine weitere Datei vergleich_hilfsklassifikation_berufenet.csv ist nur unter https://www.iab.de/183/section.aspx/Publikation/k180509301 verlinkt. Dort werden die Hilfskategorien der Hilfskategorien mit den Berufsbezeichnungen aus dem BERUFENET verglichen.
#
# 23. Februar 2018 (Ursprungsversion von https://www.iab.de/183/section.aspx/Publikation/k180509301)
# 10. Februar 2019 (Anpassung für Github, Berücksichtigung der Folgefragen-Syntax vom 7.2.2019, auxco_mapping_from_kldb.csv hinzugefügt)
# 31. August 2022 (Neue, standardisierte Bezeichnungen, auxco_mapping_from_isco.csv hinzugefügt)
####################################################################################

library(xml2)
library(data.table)
library(stringdist)

output_dir <- "output"
dir.create(output_dir, showWarnings = FALSE)

##################################################
# read auxiliary classification
## create a single combined file from all the documents.
src <- xml_new_root("klassifikation")
files <- list.files("./auxco_src_files", pattern = "xml", full.names = TRUE, recursive = TRUE)
files <- setdiff(files, "./auxco_src_files/00_hilfsklassifikation_all_categories_combined.xml")

for (doc in files) {
    kat <- read_xml(paste0(doc))
    xml_add_child(src, kat)
}
# update in github file
write_xml(src, file = file.path(output_dir, "/00_hilfsklassifikation_all_categories_combined.xml"))

##################################################
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

# Preparation: Download KldB 10
load_kldb_raw <- function() {
  terms_of_use <- "
    © Statistik der Bundesagentur für Arbeit
    Sie können Informationen speichern, (auch auszugsweise) mit Quellenangabe
    weitergeben, vervielfältigen und verbreiten. Die Inhalte dürfen nicht
    verändert oder verfälscht werden. Eigene Berechnungen sind erlaubt, jedoch
    als solche kenntlich zu machen. Im Falle einer Zugänglichmachung im
    Internet soll dies in Form einer Verlinkung auf die Homepage der Statistik
    der Bundesagentur für Arbeit erfolgen. Die Nutzung der Inhalte für
    gewerbliche Zwecke, ausgenommen Presse, Rundfunk und Fernsehen und
    wissenschaftliche Publikationen, bedarf der Genehmigung durch die Statistik
    der Bundesagentur für Arbeit.
  "

  # Create cache dir if it doesn't exist yet
  cache_path <- file.path("cache")
  dir.create(cache_path, showWarnings = FALSE)

  kldb_archive_path <- file.path(cache_path, "kldb_2010_archive.zip")
  if (!file.exists(kldb_archive_path)) {
    print(paste(
      "Using a modified version of the KldB 2010.",
      "Please mind the terms of use of the original KldB dataset (German):",
      terms_of_use,
      sep = "\n"
    ))

    # Download the kldb file (which is a zip archive)
    url <- "https://www.klassifikationsserver.de/klassService/jsp/variant/downloadexport?type=EXPORT_CSV_VARIANT&variant=kldb2010&language=DE"
    download.file(url, destfile = kldb_archive_path, mode = "wb")
  }

  # Get the CSV filename
  # (R cannot extract the file directly due to special characters in the name)
  filename_in_zip <- unzip(zipfile = kldb_archive_path, list = TRUE)[1, "Name"]

  # Unzip the file in-place and read its' contents
  # (fread does not support reading from this kind of stream)
  kldb_df <- read.csv2(
    unz(kldb_archive_path, filename_in_zip),
    skip = 8,
    sep = ";",
    encoding = "UTF-8",
    check.names = FALSE,
    colClasses = "character"
  )
  kldb_df$Ebene <- as.integer(kldb_df$Ebene)

  return(as.data.table(kldb_df))
}

#' Clean & Load KldB 2010 dataset.
#'
#' Use load_kldb_raw() to load the whole dataset.
#'
#' @return A cleaned / slimmed version of the KldB 2010.
#' @export
load_kldb <- function() {
  # nolint start

  kldb_data <- load_kldb_raw()

  kldb_new_names <- c(
    # old name => new name
    "Schlüssel KldB 2010" = "kldb_id",
    "Ebene" = "level",
    "Titel" = "title",
    "Allgemeine Bemerkungen" = "description",
    "Ausschlüsse" = "excludes"
  )

  setnames(
    kldb_data,
    old = names(kldb_new_names),
    new = kldb_new_names
  )

  # Only keep the new kldb columns
  # If you want to look at the whole dataset, use load_kldb_raw()
  kldb_data <- kldb_data[, ..kldb_new_names]

  # Generate Clean level-4 Job Titles (i.e. labels)
  kldb_data[
    level == 4 & grepl("Berufe", title),
    label := gsub(
      "Berufe in der |Berufe im Bereich |Berufe im |Berufe in |Berufe für ",
      "",
      title
    )
  ]
  kldb_data[
    level == 4 & grepl("^[[:lower:]]", label),
    label := gsub(
      "technischen Laboratorium", "technisches Laboratorium",
      label,
      perl = TRUE
    )
  ]
  kldb_data[
    level == 4 & grepl("^[[:lower:]]", label),
    label := gsub("^([[:lower:]-]{1,})(n )", "\\1 ", label, perl = TRUE)
  ]
  kldb_data[
    label == "technische Eisenbahnbetrieb",
    label := "technischer Eisenbahnbetrieb"
  ]
  kldb_data[
    label == "technische Luftverkehrsbetrieb",
    label := "technischer Luftverkehrsbetrieb"
  ]
  kldb_data[
    label == "technische Schiffsverkehrsbetrieb",
    label := "technischer Schiffsverkehrsbetrieb"
  ]
  kldb_data[
    label == "technische Betrieb des Eisenbahn-, Luft- und Schiffsverkehrs (sonstige spezifische Tätigkeitsangabe)",
    label := "technischer Betrieb des Eisenbahn-, Luft- und Schiffsverkehrs (sonstige spezifische Tätigkeitsangabe)"
  ]
  kldb_data[
    label == "visuelle Marketing",
    label := "visuelles Marketing"
  ]
  kldb_data[
    title == "Verwaltende Berufe im Sozial- und Gesundheitswesen",
    label := "Verwaltung im Sozial- und Gesundheitswesen"
  ]
  kldb_data[
    label == "kaufmännischen und technischen Betriebswirtschaft (ohne Spezialisierung)",
    label := "kaufmännische und technische Betriebswirtschaft (ohne Spezialisierung)"
  ]
  kldb_data[
    label == "öffentlichen Verwaltung (ohne Spezialisierung)",
    label := "Öffentliche Verwaltung (ohne Spezialisierung)"
  ]
  kldb_data[
    label == "öffentlichen Verwaltung (sonstige spezifische Tätigkeitsangabe)",
    label := "Öffentliche Verwaltung (sonstige spezifische Tätigkeitsangabe)"
  ]
  kldb_data[
    label == "operations-/medizintechnischen Assistenz",
    label := "operations-/medizintechnische Assistenz"
  ]
  kldb_data[
    label == "nicht klinischen Psychologie",
    label := "nicht klinische Psychologie"
  ]
  kldb_data[
    label == "nicht ärztlichen Psychotherapie",
    label := "nicht ärztliche Psychotherapie"
  ]
  kldb_data[
    label == "nicht ärztlichen Therapie und Heilkunde (sonstige spezifische Tätigkeitsangabe)",
    label := "nicht ärztliche Therapie und Heilkunde (sonstige spezifische Tätigkeitsangabe)"
  ]
  # Uppercase the first letter
  kldb_data[
    level == 4,
    label := gsub("^([[:lower:]])", "\\U\\1", label, perl = TRUE)
  ]
  kldb_data[
    level == 4 & is.na(label),
    label := title
  ]
  kldb_data[
    level == 4,
    label := gsub(" \\(sonstige spezifische Tätigkeitsangabe\\)", "", label)
  ]
  # Handle titles for Leitungsfunktion
  kldb_data[
    level == 4 & substr(kldb_id, 4, 4) == 9,
    label := paste(
      gsub(
        "Aufsichts- und Führungskräfte - |Aufsichtskräfte - |Führungskräfte - ",
        "",
        label
      ),
      "(Führungskraft)"
    )
  ]

  # Convert kldb_id to character for overall consistency, joins etc.
  kldb_data[, kldb_id := as.character(kldb_id)]

  # Only export the standard set of columns
  # Note: Column "excludes" is currently still used, but can hopefully be
  # dropped in the future or be handled in a more generic usecase
  # Note: Using two separate columns, label & title here.
  # We might want to only use one going forward,
  # but both are needed atm. to support previous code
  kldb_data <- kldb_data[
    ,
    c("kldb_id", "level", "label", "description", "excludes", "title")
  ]

  return(kldb_data)
  # nolint end
}

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
      task,
      task_description,
      default_kldb_id,
      default_isco_id
    )
  )
}

# Order by id
auxco_categories <- auxco_categories[order(auxco_id)]

# Add kldb_title_short by joining with the KldB 10 and
# shortening titles from there
kldb_10 <- load_kldb()

# Match with titles using level-4 KldB Ids
auxco_categories[
  ,
  kldb_id_to_match := substring(default_kldb_id, 1, 4)
]
auxco_categories <- merge(
  auxco_categories,
  kldb_10[level == 4, list(kldb_id, label)],
  all.x = TRUE,
  by.x = "kldb_id_to_match",
  by.y = "kldb_id"
)
setnames(auxco_categories, "label", "kldb_title_short")

# Fill missing kldb titles using the auxco title
auxco_categories[
  is.na(kldb_title_short),
  kldb_title_short := title
]

# Remove "(ohne Spezialisierung)" but correct this default for some titles
# Zentrales Kriterium: Der Zusatz "ohne Spezialisierung" wird beibehalten,
# wenn es stärker spezialsierte Berufe gibt. Wünschenswert wäre es in solchen
# Fällen, wenn sich Befragte auf einer genaueren Ebene einordnen könnten
# (was aber wohl nicht immer möglich ist)
auxco_categories[
  ,
  kldb_title_short := gsub(
    " \\(ohne Spezialisierung\\)",
    "",
    kldb_title_short
  )
]
auxco_categories[
  title == "Landwirt/in",
  kldb_title_short := "Landwirtschaft (ohne Spezialisierung)"
]
auxco_categories[
  title == "Acker- und Erntehelfer/in",
  kldb_title_short := "Landwirtschaft (ohne Spezialisierung)"
]
auxco_categories[
  title == "Agraringenieur/in",
  kldb_title_short := "Landwirtschaft (ohne Spezialisierung)"
]
auxco_categories[
  title == "Helfer/in - Tierwirtschaft und im Ackerbau",
  kldb_title_short := "Landwirtschaft (ohne Spezialisierung)"
]
auxco_categories[
  title == "Landwirtschaftsberater/in",
  kldb_title_short := "Landwirtschaft (ohne Spezialisierung)"
]
auxco_categories[
  title == "Tierpflegehelfer/in",
  kldb_title_short := "Tierpflege (ohne Spezialisierung)"
]
auxco_categories[
  title == "Tierpfleger/in",
  kldb_title_short := "Tierpflege (ohne Spezialisierung)"
]
auxco_categories[
  title == "Gärtner/in",
  kldb_title_short := "Gartenbau (ohne Spezialisierung)"
]
auxco_categories[
  title == "Gartenbautechniker/in",
  kldb_title_short := "Gartenbau (ohne Spezialisierung)"
]
auxco_categories[
  title == "Helfer/in - Baustoffherstellung",
  kldb_title_short := "Baustoffherstellung"
]
auxco_categories[
  title == "Helfer/in - Rohkohlenaufbereitung",
  kldb_title_short := "Naturstein- und Mineralaufbereitung"
]
auxco_categories[
  title == "Helfer/in - Mineralgewinnung, -aufbereitung",
  kldb_title_short := "Naturstein- und Mineralaufbereitung"
]
auxco_categories[
  title %in% c("Lackiererhelfer/in", "Lackierer/in",
   "Farb- und Lacktechniker/in", "Farb- und Lackingenieur/in"),
  kldb_title_short := "Farb- und Lacktechnik (ohne Spezialisierung)"
]
auxco_categories[
  title %in% c("Helfer/in - Holz und Flechtwaren",
  "Holzbearbeitungsmechaniker/in", "Holztechniker/in", "Holzingenieur/in"),
  kldb_title_short := "Holzbe- und -verarbeitung (ohne Spezialisierung)"
]
auxco_categories[
  title == "Gießereihelfer/in",
  kldb_title_short := "Metallerzeugung (ohne Spezialisierung)"
]
auxco_categories[
  title == "Metallbearbeitungshelfer/in",
  kldb_title_short := "Metallbearbeitung (ohne Spezialisierung)"
]
auxco_categories[
  title == "Metallbearbeitungstechniker/in",
  kldb_title_short := "Metallbearbeitung (ohne Spezialisierung)"
]
auxco_categories[
  kldb_id_to_match == "2510",
  kldb_title_short := "Maschinenbau- und Betriebstechnik (ohne Spezialisierung)"
]
auxco_categories[
  title == "Maschinenbau- und Betriebstechnik (ohne Spezialisierung)",
  kldb_title_short := "Kraftfahrzeugtechnik"
]
auxco_categories[
  kldb_id_to_match == "2630",
  kldb_title_short := "Elektrotechnik (ohne Spezialisierung)"
]
auxco_categories[
  title == "Bediener/in von Lederzurichtungsmaschinen",
  kldb_title_short := "Lederherstellung"
]
auxco_categories[
  title == "Lederverarbeitungshelfer/in",
  kldb_title_short := "Lederherstellung und -verarbeitung (ohne Spezialisierung)"
]
auxco_categories[
  title == "Pelzverarbeitungshelfer/in",
  kldb_title_short := "Pelzbe- und -verarbeitung"
]
auxco_categories[
  kldb_id_to_match == "2910",
  kldb_title_short := "Getränkeherstellung (ohne Spezialisierung)"
]
auxco_categories[
  title == "Helfer/in - Lebensmitteltechnik",
  kldb_title_short := "Lebensmittelherstellung (ohne Spezialisierung)"
]
auxco_categories[
  title == "Bautechniker/in",
  kldb_title_short := "Bauplanung und -überwachung (ohne Spezialisierung)"
]
auxco_categories[
  title == "Bauingenieur/in",
  kldb_title_short := "Bauplanung und -überwachung (ohne Spezialisierung)"
]
auxco_categories[
  title == "Hochbauarbeiter/in",
  kldb_title_short := "Hochbau (ohne Spezialisierung)"
]
auxco_categories[
  title == "Bauhelfer/in",
  kldb_title_short := "Hochbau, Tiefbau (ohne Spezialisierung)"
]
auxco_categories[
  kldb_id_to_match == "3310",
  kldb_title_short := "Bodenverlegung (ohne Spezialisierung)"
]
auxco_categories[
  title == "Chemiker/in",
  kldb_title_short := "Chemie (ohne Spezialisierung)"
]
auxco_categories[
  title == "Physiker/in",
  kldb_title_short := "Physik (ohne Spezialisierung)"
]
auxco_categories[
  title == "Informatiker/in",
  kldb_title_short := "Informatik (ohne Spezialisierung)"
]
auxco_categories[
  title == "Betriebs- und Verkehrstechniker/in",
  kldb_title_short := "Überwachung und Steuerung des Verkehrsbetriebs (ohne Spezialisierung)"
]
auxco_categories[
  title == "Lebensmittelfachverkäufer/in",
  kldb_title_short := "Verkauf von Lebensmitteln (ohne Spezialisierung)"
]
auxco_categories[
  title == "Fast-Food- und Imbisskoch/-köchin",
  kldb_title_short := "Gastronomieservice (ohne Spezialisierung)"
]
auxco_categories[
  kldb_id_to_match == "7130",
  kldb_title_short := "Kaufmännische und technische Betriebswirtschaft (ohne Spezialisierung)"
]
auxco_categories[
  title == "Bürohilfskraft",
  kldb_title_short := "Büro- und Sekretariatskräfte (ohne Spezialisierung)"
]
auxco_categories[
  title == "Sekretär/in",
  kldb_title_short := "Büro- und Sekretariatskräfte (ohne Spezialisierung)"
]
auxco_categories[
  kldb_id_to_match == "7320",
  kldb_title_short := "Öffentliche Verwaltung (ohne Spezialisierung)"
]
auxco_categories[
  title == "Allgemeinarzt /-ärztin",
  kldb_title_short := "Ärzte/Ärztinnen (ohne Spezialisierung)"
]
auxco_categories[
  title == "Dozent/in - Erwachsenenbildung",
  kldb_title_short := "Erwachsenenbildung (ohne Spezialisierung)"
]
auxco_categories[
  kldb_id_to_match == "8450",
  kldb_title_short := "Sportlehrer/innen (ohne Spezialisierung)"
]
auxco_categories[
  kldb_id_to_match == "9330",
  kldb_title_short := "Kunsthandwerk und bildende Kunst (ohne Spezialisierung)"
]
auxco_categories[
  kldb_id_to_match == "9360",
  kldb_title_short := "Musikinstrumentenbau (ohne Spezialisierung)"
]
auxco_categories[
  title == "Entertainer/in",
  kldb_title_short := "Moderation und Unterhaltung (ohne Spezialisierung)"
]

# Remove the level 4 kldb_ids again
auxco_categories[, kldb_id_to_match := NULL]

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
            answer_id_combination = "",
            answer_kldb_id = "",
            answer_isco_id = "",
            explicit_has_followup = "",
            corresponding_answer_level = "",
            list_of_answer_ids = NA
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

      # Convert certain answers with standardized levels
      if (question_type %in% c("aufsicht", "anforderungsniveau")) {
        answer_level_raw <- folgefrage_node |>
          xml_attr(question_type)

        # Recode to correspond to isco standards
        level_conversions <- list(
          aufsicht = c(
            "keine Führungsverantwortung" = "isco_not_supervising",
            "Aufsichtskraft" = "isco_supervisor",
            "Führungskraft" = "isco_manager"
          ),
          anforderungsniveau = c(
            "1" = "isco_skill_level_1",
            "2" = "isco_skill_level_2",
            "3" = "isco_skill_level_3",
            "4" = "isco_skill_level_4"
          )
        )

        stopifnot(
          question_type %in% names(level_conversions) &&
          answer_level_raw %in% names(level_conversions[[question_type]])
        )

        # Pick the correct level from level_conversions
        corresponding_answer_level <- level_conversions[[
          question_type
        ]][
          answer_level_raw
        ]
      } else {
        corresponding_answer_level <- ""
      }

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
          answer_id_combination = "",
          answer_kldb_id,
          answer_isco_id,
          explicit_has_followup,
          corresponding_answer_level,
          list_of_answer_ids = NA
        ))
      )
    }
    # Handle aggregation info (combining multiple followup question answers)
    if (xml_name(folgefrage_node) == "aggregation") {
      current_auxco_id <- auxco_id
      n_questions <- auxco_followup_questions[
        auxco_id == current_auxco_id & entry_type == "question"
      ] |> nrow()

      conditions <- xml_find_all(folgefrage_node, xpath = "./bedingung")
      for (condition_node in conditions) {
        aggregated_answer_ids <- c()
        for (question_number in 1:n_questions) {
          aggregated_answer_ids <- c(
            aggregated_answer_ids,
            condition_node |>
              xml_attr(paste0("frage_", question_number, "_antwort_pos"))
          )
        }

        condition_kldb_id <- xml_find_all(condition_node, xpath = "./kldb") |>
          xml_attr("schluessel")
        if (length(condition_kldb_id) == 0) condition_kldb_id <- ""
        condition_isco_id <- xml_find_all(condition_node, xpath = "./isco") |>
          xml_attr("schluessel")
        if (length(condition_isco_id) == 0) condition_isco_id <- ""

        auxco_followup_questions <- rbind(
          auxco_followup_questions,
          data.table(
            auxco_id,
            entry_type = "aggregated_answer_encoding",
            question_type = "",
            question_text_present = "",
            question_text_past = "",
            answer_id = "",
            answer_text = "",
            answer_id_combination = NA,
            answer_kldb_id = condition_kldb_id,
            answer_isco_id = condition_isco_id,
            explicit_has_followup = "",
            corresponding_answer_level = "",
            list_of_answer_ids = list(aggregated_answer_ids)
          )
        )
      }
    }
  }
}

# Add unique question_ids
should_get_question_id <- auxco_followup_questions$entry_type %in% c(
  "question", "answer_option"
)
auxco_followup_questions[
  should_get_question_id,
  question_index := cumsum(entry_type == "question"),
  by = auxco_id
]
auxco_followup_questions[
  should_get_question_id,
  question_id := paste0("Q", auxco_id, "_", question_index)
]
auxco_followup_questions <- auxco_followup_questions[order(auxco_id)]

# Generate combined answer_ids in URL format e.g. 1749_1=1&1749_2=1
auxco_followup_questions[
  entry_type == "aggregated_answer_encoding",
  # The column where the combined ids are saved *must* be different from the one
  # where answer_ids are stored as a list, else typing issues will occur.
  answer_id_combination := apply(
    .SD,
    1,
    # Iterate over rows, as we need data from multiple columns
    function(row) {
      answer_ids <- row$list_of_answer_ids
      # Get the correct question_ids
      question_ids <- auxco_followup_questions[
        auxco_id == row$auxco_id,
        question_id
      ] |>
        unique() |>
        na.omit()

      # Check that the number of answer options matches
      stopifnot(length(answer_ids) == length(question_ids))

      # Convert into url format e.g. a=1&b=2
      return(
        question_ids |>
          # Combine question and answer_ids with a =
          paste0("=", answer_ids) |>
          # Combine all questions-answer pairs with &
          paste(collapse = "&")
      )
    }
  )
]
# Remove helper column with separate answer_ids
auxco_followup_questions[, list_of_answer_ids := NULL]

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
      (!is.na(explicit_has_followup) & explicit_has_followup == FALSE),
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
    auxco_title <- xml_find_all(category_node, xpath = "./bezeichnung") |>
      xml_text()
    target_id_default <- category_node |>
      xml_find_all(xpath = paste0(".//default/", target_name)) |>
      xml_attr("schluessel")
    target_text_default <- category_node |>
      xml_find_all(xpath = paste0(".//default/", target_name)) |>
      xml_text()
    target_ids_followup <- category_node |>
      xml_find_all(
        xpath = paste0(
          ".//*[name() = 'antwort' or name() = 'bedingung']/",
          target_name
        )
      ) |>
      xml_attr("schluessel")
    target_texts_followup <- category_node |>
      xml_find_all(
        xpath = paste0(
          ".//*[name() = 'antwort' or name() = 'bedingung']/",
          target_name
        )
      ) |>
      xml_text()

    # Create the mapping table manually, as we have to generate some colnames
    mapping_to_add <- data.table()
    mapping_to_add[, (paste0(target_name, "_id")) := c(
      target_id_default,
      target_ids_followup
    )]
    mapping_to_add[, auxco_id := auxco_id]
    mapping_to_add[, auxco_title := auxco_title]
    mapping_to_add[, (paste0(target_name, "_title")) := c(
      target_text_default,
      target_texts_followup
    )]

    # Combine mappin_to_add with the overall mapping
    mapping <- rbind(
      mapping,
      mapping_to_add
    )
  }

  # Remove duplicates, while ignoring misspelled titles
  dup_ind <- duplicated(mapping[, .(auxco_id, get(paste0(target_name, "_id")))])
  mapping <- mapping[!dup_ind]

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

# Add title information and then combine the manual mapping
# with the existing auxco mapping
manual_mapping_additions <- manual_mapping_additions |>
  # Add auxco titles
  merge(
    auxco_categories[, list(auxco_id, auxco_title = title)],
    by = "auxco_id"
  ) |>
  # Add KldB titles
  merge(
    kldb_10[, list(kldb_id, kldb_title = title)],
    by = "kldb_id"
  )

setcolorder(manual_mapping_additions, colnames(auxco_mapping_from_kldb))
auxco_mapping_from_kldb <- rbind(
  auxco_mapping_from_kldb,
  manual_mapping_additions
)

auxco_mapping_from_kldb <- unique(auxco_mapping_from_kldb)

fwrite(
  auxco_mapping_from_kldb,
  row.names = FALSE,
  file = file.path(output_dir, "auxco_mapping_from_kldb.csv")
)
