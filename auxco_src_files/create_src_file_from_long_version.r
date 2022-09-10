# to replace complete hilfsklassifikation, replace line 8 with 'for (cat_num in 1:1132) {'
library(xml2)
library(data.table)

kldb_1_digits <- data.frame(kldb_id = c(1,2,3,4,5,6,7,8,9,0),
              title = c("1_Land-_Forst-_und_Tierwirtschaft_und_Gartenbau",
              "2_Rohstoffgewinnung_Produktion_Fertigung",
              "3_Bau_Architektur_Vermessung_Gebaeudetechnik",
              "4_Naturwissenschaft_Geografie_und_Informatik",
              "5_Verkehr_Logistik_Schutz_und_Sicherheit",
              "6_Kaufmaennische_Dienstleisungen_Warenhandel_Vertrieb_Hotel_und_Tourismus",
              "7_Unternehmensorganisation_Buchhaltung_Recht_und_Verwaltung",
              "8_Gesundheit_Soziales_Lehre_und_Erziehung",
              "9_Sprach-_Literatur-_Geistes-_Gesellschafts-_und-Wirtschaftswissenschaften_Medien_Kunst_Kultur_und_Gestaltung",
              "0_Militaer"))


## Loop over all categories in "auxco_src_files/00_hilfsklassifikation_all_categories_combined.xml" to create individual files for each category
## Code wird üblicherweise nicht benötigt. Liegt nur zu Dokumentationszwecken hier um zu zeigen, wie sich die Hilfsklassifikation automatisch verändern lässt!

# read auxiliary classification
src <- read_xml("./hilfsklassifikation_falscher_name.xml")
ids <- as.numeric(xml_text(xml_find_all(src, xpath = "//id")))

for (cat_num in seq_along(ids)) {
  category_node <- xml_find_all(
    src,
    xpath = paste0("//klassifikation/*[", cat_num, "]")
  )
  auxco_id <- xml_find_all(category_node, xpath = "./id") |>
    xml_text()

  title <- xml_find_all(category_node, xpath = "./bezeichnung") |>
    xml_text()

  default_kldb_id_1 <- xml_find_all(category_node, xpath = ".//default/kldb") |>
    xml_attr("schluessel") |> substr(1,1)

  kldb_1_title <- kldb_1_digits[kldb_1_digits$kldb_id == default_kldb_id_1, "title"]

  # # we will add two simple nodes/comments at the end of each category (in case they are needed)
  # category_node |> xml_add_child( 
  #     read_xml("<notes><note date='1970-01-01'>empty</note><note date='1970-01-01'>empty</note></notes>"))

  # generiere Infos zu Folgefragen und ihren Antworten
  auxco_followup_questions <- NULL
  for (
    folgefrage_node in category_node |>
      xml_find_all(xpath = "./untergliederung/child::*")
  ) {
    if (xml_name(folgefrage_node) == "fragetext") {
        question_type <- xml_attr(folgefrage_node, "typ")
        auxco_followup_questions <- rbind(
            auxco_followup_questions,
            cbind(
                data.table(entry_type = "question",
                question_type
                )
            )
        )
    }
    if (xml_name(folgefrage_node) == "antwort") {
        auxco_followup_questions <- rbind(
            auxco_followup_questions,
            cbind(
                data.table(entry_type = "answer",
                question_type
                )
            )
        )
    }
  }

# # Handle anforderungsniveau questions
# anf_ind <- which(auxco_followup_questions[entry_type == "answer", question_type] == "anforderungsniveau")

#   for (num in anf_ind) {
#     anforderungsniveau_answer <- xml_find_all(category_node,
#         xpath = paste0("./untergliederung/antwort[position()=", num, "]")
#         )
#     answer_kldb_id <- xml_find_all(anforderungsniveau_answer, xpath = "./kldb") |>
#             xml_attr("schluessel")
#     if (length(answer_kldb_id) == 0) answer_kldb_id <- "     "

#         xml_attr(anforderungsniveau_answer, "anforderungsniveau") <- substring(answer_kldb_id, 5, 5)
#   }

# # Handle aufsicht questions
# aufsicht_ind <- which(auxco_followup_questions[entry_type == "answer", question_type] == "aufsicht")

#   for (num in aufsicht_ind) {
#     aufsicht_answer <- xml_find_all(category_node,
#         xpath = paste0("./untergliederung/antwort[position()=", num, "]")
#         )
#     answer_kldb_id <- xml_find_all(aufsicht_answer, xpath = "./kldb") |>
#             xml_attr("schluessel")
#     if (length(answer_kldb_id) == 0) answer_kldb_id <- "     "

#     aufsicht <- "keine Führungsverantwortung"
#     if (substring(answer_kldb_id, 4, 5) == "93") aufsicht <- "Aufsichtskraft"
#     if (substring(answer_kldb_id, 4, 5) == "94") aufsicht <- "Führungskraft"
#     xml_attr(aufsicht_answer, "aufsicht") <- aufsicht
#   }

  write_xml(category_node, file = paste0("auxco_src_files/", kldb_1_title, "/", auxco_id, "_", gsub("/", "-", gsub(" ", "_", title)), ".xml"))

}


# clean up workspace.
rm(list=ls())

##################################################
## create a single combined file from all the documents.
hilfsklassifikation <- xml_new_root("klassifikation")
files <- list.files("./auxco_src_files", pattern = "xml", full.names = TRUE, recursive = TRUE)
files <- setdiff(files, "./auxco_src_files/00_hilfsklassifikation_all_categories_combined.xml")

for (doc in files) {
    kat <- read_xml(paste0(doc))
    xml_add_child(hilfsklassifikation, kat)
}

write_xml(hilfsklassifikation, file = paste0("auxco_src_files/00_hilfsklassifikation_all_categories_combined.xml"))

##########################################################
# Compare wheter the separate files are content-identical to the one-file-version.
is.equal_hilfsklassifikation <- function(folder, file) {
  files <- list.files(folder, pattern = "xml", full.names = TRUE, recursive = TRUE)
  files <- setdiff(files, "./auxco_src_files/00_hilfsklassifikation_all_categories_combined.xml")

  file_src <- read_xml(file)
  ids <- as.numeric(xml_text(xml_find_all(file_src, xpath = "//id")))

  folder_ids <- NULL
  agreement <- NULL

  for (doc in files) {
    kat <- read_xml(paste0(doc))

    cur_id <- as.numeric(xml_text(xml_find_all(kat, xpath = "//id")))
    cur_kat <- xml_find_all(kat, xpath = "./id/parent::node()")

    file_kat <- xml_find_all(file_src, xpath = paste0("//kategorie[id=", cur_id,"]"))
    
    folder_ids <- c(folder_ids, cur_id)
    agreement <- c(agreement, identical(as_list(cur_kat), as_list(file_kat)))

  }

  if (identical(sort(folder_ids), sort(ids)) & sum(agreement) == length(ids)) {
    cat("Comparison successful.", length(ids), "Kategorien in Hilfsklassifikation")
  }

}

# is.equal_hilfsklassifikation("./auxco_src_files", "auxco_src_files/00_hilfsklassifikation_all_categories_combined.xml")
