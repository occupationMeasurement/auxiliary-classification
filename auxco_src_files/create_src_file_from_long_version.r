# to replace complete hilfsklassifikation, replace line 8 with 'for (cat_num in 1:1132) {'
library(xml2)
library(data.table)

# read auxiliary classification
src <- read_xml("./hilfsklassifikation.xml")
ids <- as.numeric(xml_text(xml_find_all(src, xpath = "//id")))



for (cat_num in 1:40) {
  category_node <- xml_find_all(
    src,
    xpath = paste0("//klassifikation/*[", cat_num, "]")
  )
  auxco_id <- xml_find_all(category_node, xpath = "./id") |>
    xml_text()

  title <- xml_find_all(category_node, xpath = "./bezeichnung") |>
    xml_text()

  # we will add two simple nodes/comments at the end of each category (in case they are needed)
  category_node |> xml_add_child( 
      read_xml("<notes><note date='1970-01-01'>empty</note><note date='1970-01-01'>empty</note></notes>"))

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

# Handle anforderungsniveau questions
anf_ind <- which(auxco_followup_questions$entry_type == "answer" &
        auxco_followup_questions$question_type == "anforderungsniveau")

  for (num in (anf_ind - 1)) {
    anforderungsniveau_answer <- xml_find_all(category_node,
        xpath = paste0("./untergliederung/antwort[position()=", num, "]")
        )
    answer_kldb_id <- xml_find_all(anforderungsniveau_answer, xpath = "./kldb") |>
            xml_attr("schluessel")
    if (length(answer_kldb_id) == 0) answer_kldb_id <- "     "

        xml_attr(anforderungsniveau_answer, "anforderungsniveau") <- substring(answer_kldb_id, 5, 5)
  }

# Handle aufsicht questions
aufsicht_ind <- which(auxco_followup_questions$entry_type == "answer" &
        auxco_followup_questions$question_type == "aufsicht")

  for (num in (aufsicht_ind - 1)) {
    aufsicht_answer <- xml_find_all(category_node,
        xpath = paste0("./untergliederung/antwort[position()=", num, "]")
        )
    answer_kldb_id <- xml_find_all(aufsicht_answer, xpath = "./kldb") |>
            xml_attr("schluessel")
    if (length(answer_kldb_id) == 0) answer_kldb_id <- "     "

    aufsicht <- "keine Führungsverantwortung"
    if (substring(answer_kldb_id, 4, 5) == "93") aufsicht <- "Aufsichtskraft"
    if (substring(answer_kldb_id, 4, 5) == "94") aufsicht <- "Führungskraft"
    xml_attr(aufsicht_answer, "aufsicht") <- aufsicht
  }

  write_xml(category_node, file = paste0("auxco_src_files/", auxco_id, "_", gsub("/", "-", title), ".xml"))

}


# clean up workspace.
rm(list=ls())

# create a single combined file from all the documents.
hilfsklassifikation <- xml_new_root("klassifikation")
files <- list.files("./auxco_src_files/", pattern = "xml")

for (doc in files) {
    kat <- read_xml(paste0("./auxco_src_files/", doc))
    xml_add_child(hilfsklassifikation, kat)
}

write_xml(hilfsklassifikation, file = paste0("auxco_src_files/hilfsklassifikation_all_categories_combined.xml"))
