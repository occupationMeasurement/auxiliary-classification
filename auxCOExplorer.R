################################################
# Der folgende Code lädt die Hilfsklassifikation. Mithilfe einer interaktiven Darstellung können die Zusammenhänge
# zwischen der Hilfsklassifikation und den offiziellen Klassifikationen KldB 2010 und ISCO-08 erkundet werden.
#
# Der AuxCo-Explorer erlaubt das Anlegen von Notizen zu einzelnen Hilfskategorien. Dafür muss eine lokale Kopie der Datei https://raw.githubusercontent.com/malsch/occupationCodingAuxco/master/auxco_explorer_notes.txt erstellt werden.
# Die Pfad zu dieser lokalen Datei muss in folgender Variablen abgelegt werden.
# auxco_notes_filename <- "path/to/file"
#
# Weiterhin greift der AuxCo-Explorer auf die folgenden Dateien im Internet zurück:
# - Hilfsklassifikation: hilfsklassifikation.xml (aktuellste Version vom Github-Repository)
# - KldB 2010: https://www.klassifikationsserver.de/klassService/jsp/variant/downloadexport?type=EXPORT_CSV_VARIANT&variant=kldb2010&language=DE
# - KldB 2010 Umsteigeschlüssel zur ISCO-08: https://statistik.arbeitsagentur.de/Statischer-Content/Grundlagen/Klassifikation-der-Berufe/KldB2010/Arbeitshilfen/Umsteigeschluessel/Generische-Publikation/Umsteigeschluessel-KldB2010-ISCO-08.xls
# - ISCO-08: http://www.statistik.at/kdb/downloads/csv/ISCO08_EN_COT_20151120_150801.txt
# - ISCO-08 (deutsche Übersetzung): http://www.statistik.at/kdb/downloads/csv/ISCO08_DE_COT_20151120_150453.txt
# - Berufsbezeichnungen aus dem BERUFENET (verfügbar unter https://berufenet.arbeitsagentur.de/, Datenstand: 28.08.2017): http://doku.iab.de/discussionpapers/2018/dp1318_hilfsklassifikation.zip
#
# Zur Darstellung der Trees wird das JQuery-Plugin von https://www.jstree.com/ verwendet.

# Malte Schierholz
# 17. April 2019
####################################################################################

library(xml2)
library(readxl)
library(data.table)
library(shiny)
library(jsonlite)

temp_dir <- tempdir()

### auxco-notes-file öffnen
if (!exists("auxco_notes_filename")) {
  auxco_notes_filename <- "https://raw.githubusercontent.com/malsch/occupationCodingAuxco/master/auxco_explorer_notes.txt"
}
auxco_notes <- fread(auxco_notes_filename, colClasses = "character")



###############################
# read auxiliary classification
###############################

src <- read_xml("https://github.com/malsch/occupationCodingAuxco/blob/master/hilfsklassifikation.xml?raw=true")

# select IDs
ids <- as.numeric(xml_text(xml_find_all(src, xpath = "//id")))

###############################
# read kldb
###############################
temp <- tempfile(tmpdir = temp_dir)
download.file("https://www.klassifikationsserver.de/klassService/jsp/variant/downloadexport?type=EXPORT_CSV_VARIANT&variant=kldb2010&language=DE", temp, mode = "wb")
unzip(temp, exdir = temp_dir)
kldb2010 <- fread(paste0(temp_dir, "\\", list.files(temp_dir)[which(substr(list.files(temp_dir), 1, 8) == "KldB_201")]), skip = 8, sep = ";", encoding = "UTF-8", colClasses = "character")
# kldb2010 <- fread(paste("unzip -p", temp), skip = 8, sep = ";", encoding = "UTF-8", colClasses = "character")
unlink(temp)

names(kldb2010)[1] <- "kldb_id"
names(kldb2010)[4] <- "erlaeuterungstitel"
names(kldb2010)[9] <- "Umfasst"
names(kldb2010)[11] <- "Excludes"
# setnames(kldb, "ErlÃ¤uterungstitel", "")
setnames(kldb2010, "Allgemeine Bemerkungen", "Inhalt")
setnames(kldb2010, "Umfasst ferner", "Includes")


###############################
# Lade Umsteigeschlüssel KldB 2010 -> ISCO-08
###############################
temp <- tempfile(tmpdir = temp_dir)
download.file("https://statistik.arbeitsagentur.de/Statischer-Content/Grundlagen/Klassifikation-der-Berufe/KldB2010/Arbeitshilfen/Umsteigeschluessel/Generische-Publikation/Umsteigeschluessel-KldB2010-ISCO-08.xls", temp, mode = "wb")
schluessel <- data.table(read_xls(temp, range = "'Umsteiger KldB 2010 auf ISCO!A5:F1508", col_types = "text"))
unlink(temp)
setnames(schluessel, "KldB 2010\n(5-Steller)", "kldb_id")
setnames(schluessel, "Bezeichnungen der KldB2010 (5-Steller)", "kldb_titel")
setnames(schluessel, "ISCO-08\n(4-Steller)", "isco_id")
setnames(schluessel, "Bezeichnungen der ISCO-08 (4-Steller)", "isco_titel")
setnames(schluessel, "Umstieg eindeutig (1);\nnicht eindeutig (0)", "Eindeutig")
setnames(schluessel, "Schwerpunkt (1) und \nAnzahl der Alternativen", "Schwerpunkt")

# als zusätzliche Spalte bei der KldB 2010 hinzufügen
schluessel[, iscos := paste(isco_id, collapse = ","), by = kldb_id]
kldb2010 <- merge(kldb2010, schluessel[!duplicated(kldb_id, iscos), .(kldb_id, iscos)], by = "kldb_id", all.x = TRUE)
kldb2010[is.na(iscos), iscos := "-"]
###############################
# Lade ISCO-08
###############################
isco08_en <- fread("http://www.statistik.at/kdb/downloads/csv/ISCO08_EN_COT_20151120_150801.txt", colClasses = "character")
isco08_de <- fread("http://www.statistik.at/kdb/downloads/csv/ISCO08_DE_COT_20151120_150453.txt", colClasses = "character")
setnames(isco08_en, "Ebene Erl.", "erl_ebene")
names(isco08_en)[5] <- "erl_text"
# setnames(isco08_en, "Titel/Erläuterungstext", "erl_text")
setnames(isco08_de, "Ebene Erl.", "erl_ebene")
names(isco08_de)[5] <- "erl_text"
# setnames(isco08_de, "Titel/Erläuterungstext", "erl_text")
isco08_en[Code == "2261" | Code == "2351"] # here is some information missing (erl_ebene = 001, 002, ...)
isco08_en <- rbind(isco08_en, data.table("Ebene" = 4, "EDV-Code" = c("2261", "2351"), "Code" = c("2261", "2351"), "erl_ebene" = "001", "erl_text" = "Please refer to official documentation"))

isco08_en[erl_ebene == "000", type := "title"]
isco08_en[erl_ebene == "001", type := "firstStatement"]
isco08_en[erl_ebene == "002" & Ebene != 4, type := "secondStatement"] # overwrite below if different
isco08_en[erl_text == "Examples of the occupations classified here:", type := "occupations"]
isco08_en[erl_text == "Tasks include -", type := "tasks"]
isco08_en[erl_text == "Some related occupations classified elsewhere:", type := "excluded"]
isco08_en[erl_text == "Occupations in this minor group are classified into the following unit groups:", type := "examples"]
isco08_en[erl_text == "Notes", type := "Notes"]
isco08_en[erl_text == "Occupations in this sub-major group are classified into the following minor groups:", type := "examples"]
isco08_en[erl_text == "Occupations in this sub-major group are classified into the following minor group:", type := "examples"]
isco08_en[erl_text == "Tasks include ?", type := "tasks"]
isco08_en[erl_text == "In such cases tasks would include -", type := "tasks"]
isco08_en[erl_text == "Occupations in this minor group are classified into the following unit group:", type := "examples"]
isco08_en[erl_text == "Occupations in this major group are classified into the following sub-major groups:", type := "examples"]
isco08_en[erl_text == "Excluded from this group are:", type := "excluded"]
isco08_en[erl_text == "Notes:", type := "Notes"]

isco08_en[is.na(type), html_text := paste("<li>", erl_text, "</li>")]
isco08_en[!is.na(type) & erl_ebene != "000", html_text := paste("<p>", erl_text, "</p>")]
isco08_en[type == "examples", html_text := paste(html_text, "<ul>")]
isco08_en[type == "tasks", html_text := paste(html_text, "<ul>")]
isco08_en[type == "occupations", html_text := paste("</ul>", html_text, "<ul>")]
isco08_en[type == "excluded", html_text := paste("</ul>", html_text, "<ul>")]
isco08_en[type == "Notes", html_text := paste("</ul>", html_text, "<ul>")]

isco08_de[erl_ebene == "000", type := "title"]
isco08_de[erl_ebene == "001", type := "firstStatement"]
isco08_de[erl_ebene == "002" & Ebene != 4, type := "secondStatement"] # overwrite below if different
isco08_de[erl_text == "Anmerkungen", type := "Notes"]
isco08_de[erl_text == "Beispiele für hier zugeordnete Berufe:", type := "occupations"]
isco08_de[erl_text == "Aufgaben umfassen -", type := "tasks"]
isco08_de[erl_text == "Nicht in dieser Berufsgattung klassifizierte Berufe:", type := "excluded"]
isco08_de[erl_text == "Die Berufe dieser Untergruppe werden in folgende Berufsgattungen unterteilt:", type := "examples"]
isco08_de[erl_text == "Die Berufe dieser Gruppe werden in folgende Untergruppen unterteilt:", type := "examples"]
isco08_de[erl_text == "Die Berufe dieser Hauptgruppe werden in folgende Gruppen unterteilt:", type := "examples"]

isco08_de[is.na(type), html_text := paste("<li>", erl_text, "</li>")]
isco08_de[!is.na(type) & erl_ebene != "000", html_text := paste("<p>", erl_text, "</p>")]
isco08_de[type == "examples", html_text := paste(html_text, "<ul>")]
isco08_de[type == "tasks", html_text := paste(html_text, "<ul>")]
isco08_de[type == "occupations", html_text := paste("</ul>", html_text, "<ul>")]
isco08_de[type == "excluded", html_text := paste("</ul>", html_text, "<ul>")]
isco08_de[type == "Notes", html_text := paste("</ul>", html_text, "<ul>")]
###############################
# Lade Berufe aus dem Berufenet im Vergleich zur Hilfsklassifikation
###############################
temp <- tempfile(tmpdir = temp_dir)
download.file("http://doku.iab.de/discussionpapers/2018/dp1318_hilfsklassifikation.zip", destfile = temp, mode = "wb")
unzip(temp, exdir = temp_dir)
vergleich_hilfsklassifikation_berufenet <- fread(paste0(temp_dir, "\\vergleich_hilfsklassifikation_berufenet.csv"), colClasses = "character")
unlink(temp)
berufenet <- vergleich_hilfsklassifikation_berufenet[origin == "DKZ/Berufenet"]
berufenet[, Ebene := "6"]

################################
# prepare data
################################

hilfsklassifikation_by_kldb_id <- NULL
hilfsklassifikation_by_isco_id <- NULL
for (cat_num in seq_along(ids)) {
  category_node <- xml_find_all(src, xpath = paste0("//klassifikation/*[", cat_num, "]"))
  id <- xml_text(xml_find_all(category_node, xpath = "./id"))
  bezeichnung <- xml_text(xml_find_all(category_node, xpath = "./bezeichnung"))
  taetigkeit <- xml_text(xml_find_all(category_node, xpath = "./taetigkeit"))
  taetigkeitsbeschreibung <- xml_text(xml_find_all(category_node, xpath = "./taetigkeitsbeschreibung"))

  kldb_id_default <- xml_attr(xml_find_all(category_node, xpath = ".//default/kldb"), "schluessel")
  kldb_id_folgefrage <- xml_attr(xml_find_all(category_node, xpath = ".//antwort/kldb"), "schluessel")
  hilfsklassifikation_by_kldb_id <- rbind(hilfsklassifikation_by_kldb_id, data.table(id, bezeichnung, taetigkeit, taetigkeitsbeschreibung, kldb = c(kldb_id_default, kldb_id_folgefrage)))

  isco_id_default <- xml_attr(xml_find_all(category_node, xpath = ".//default/isco"), "schluessel")
  isco_id_folgefrage <- xml_attr(xml_find_all(category_node, xpath = ".//antwort/isco"), "schluessel")
  hilfsklassifikation_by_isco_id <- rbind(hilfsklassifikation_by_isco_id, data.table(id, bezeichnung, taetigkeit, taetigkeitsbeschreibung, isco = c(isco_id_default, isco_id_folgefrage)))
  }

# prepare kldb tree
kldb <- rbind(kldb2010[, .(kldb_id, Ebene, Titel = paste(kldb_id, Titel), erlaeuterungstitel, Kurztitel, Mitteltitel, Langtitel, Inhalt, Umfasst, Includes, Excludes, Maßeinheit)], 
              berufenet[, .(kldb_id, Ebene, Titel = paste("DKZ:", title2), Inhalt = taetigkeit, cat_id = paste0("DKZ-", title2))],
              unique(hilfsklassifikation_by_kldb_id[, .(kldb_id = kldb, Ebene = 6, Titel = paste0("AuxCo (", id, "): ", taetigkeit), Inhalt = taetigkeitsbeschreibung, Kurztitel = bezeichnung, cat_id = paste0("auxco-", id))]),
              fill = TRUE)
kldb[is.na(cat_id), cat_id := kldb_id]


# prepare isco tree
isco <- rbind(isco08_en[erl_ebene == "000", list(isco_id = Code, Ebene = Ebene, Titel = paste(Code, erl_text))],
              unique(hilfsklassifikation_by_isco_id[, .(isco_id = isco, Ebene = 5, Titel = paste0("AuxCo (", id, "): ", taetigkeit), Inhalt = taetigkeitsbeschreibung, Kurztitel = bezeichnung, cat_id = paste0("auxco-", id))]),
              fill = TRUE)
isco[is.na(cat_id), cat_id := isco_id]

rm(category_node, id, bezeichnung, taetigkeit, taetigkeitsbeschreibung, isco_id_default, isco_id_folgefrage, kldb_id_default, kldb_id_folgefrage)



################################
# helper Functions
################################

#### exclude non-valid kldb_ids for simplicity
kldb[, .N, by = nchar(kldb_id)]

# make cat_ids unique
kldb[Ebene == 6, count := 1:.N, by = cat_id]
kldb[Ebene == 6, cat_id := paste0(cat_id, "-", count)]

# bring in json format for search tree
kldb_json <- paste("'core' : {
    'data' :", toJSON(kldb[nchar(kldb_id) != 15, list(id = cat_id, parent = ifelse(Ebene == 1, "#", ifelse(Ebene == 6, kldb_id, substr(kldb_id, 1, as.numeric(Ebene) - 1))), text = Titel)]),
                   "}")

#### exclude non-valid isco_ids for simplicity
isco[, .N, by = nchar(isco_id)]

# make cat_ids unique
isco[Ebene == 5, count := 1:.N, by = cat_id]
isco[Ebene == 5, cat_id := paste0(cat_id, "-", count)]

# bring in json format for search tree
isco_json <- paste("'core' : {
    'data' :", toJSON(isco[nchar(isco_id) != 13 & isco_id != "????", list(id = cat_id, parent = ifelse(Ebene == 1, "#", ifelse(Ebene == 5, isco_id, substr(isco_id, 1, as.numeric(Ebene) - 1))), text = Titel)]),
                   "}")

############################################
# App
############################################
ui <- navbarPage("AuxCo Explorer", theme="https://cdnjs.cloudflare.com/ajax/libs/jstree/3.2.1/themes/default/style.min.css",
                 tabPanel("Erkunden", tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/jquery/1.12.1/jquery.min.js"),
                                      tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/jstree/3.2.1/jstree.min.js"),

                                      textInput("auxcoId", "Hilfskategorie-ID (4-stellig):"),
                                      uiOutput("erkunden"),
                          
                                      fluidRow(column(6,
                                                      h3("KldB 2010"),
HTML('  
  <form id="s">
    <input type="search" id="kldb_tree_q" size = "100" />
  </form>
  <div id="kldb_tree"></div>'),
tags$script(paste("
  $(function () { $('#kldb_tree').jstree({", kldb_json, ",
                                            'plugins' : [ 'search' ]}) });

  /* for search plugin */
  var to = false;
                                            $('#kldb_tree_q').keyup(function () {
                                            if(to) { clearTimeout(to); }
                                            to = setTimeout(function () {
                                            var v = $('#kldb_tree_q').val();
                                            $('#kldb_tree').jstree(true).search(v);
                                            }, 250);
                                            });

                                      "))
                          ),
                  column(6,
                         h3("ISCO-08"),
HTML('  
  <form id="s">
    <input type="search" id="isco_tree_q" size = "100" />
  </form>
  <div id="isco_tree"></div>
'),
tags$script(paste("
  $(function () { $('#isco_tree').jstree({", isco_json, ",
                  'plugins' : [ 'search' ]}) });
                  
                  /* for search plugin */
                  var to = false;
                  $('#isco_tree_q').keyup(function () {
                  if(to) { clearTimeout(to); }
                  to = setTimeout(function () {
                  var v = $('#isco_tree_q').val();
                  $('#isco_tree').jstree(true).search(v);
                  }, 250);
                  });
")),
# Listen for hilfskategorie_id_submitted messages
tags$script("
            /* JavaScript Function to search within both trees */
            Shiny.addCustomMessageHandler('hilfskategorie_id_submitted', function(msg) {
            $('#kldb_tree').jstree(true).search(msg);
            $('#isco_tree').jstree(true).search(msg);
            $('#kldb_tree_q').val(msg)
            $('#isco_tree_q').val(msg)
            });

            /* JavaScript Function to update the auxcoId (4-digit) search Box */
            function changeAuxcoId (new_id) {
              Shiny.setInputValue('auxcoId', new_id);
              $('#auxcoId').val(new_id);
            }

            /* If something from the tree is clicked, send this info to shiny */
            $('#kldb_tree').on('select_node.jstree', function (e, data) {
              Shiny.setInputValue('kldbIdClicked', data.selected);
            });
            $('#isco_tree').on('select_node.jstree', function (e, data) {
              Shiny.setInputValue('iscoIdClicked', data.selected);
            });
            /* and show the corresponding window */
            Shiny.addCustomMessageHandler('showHtmlPopup', function(message) {
              var myWindow = window.open('', message, 'width=800,height=400');
              myWindow.document.write(message);
            });
            

            alert('Ggf. Popups erlauben. ')

            ")
)

)), 
                 tabPanel("Kategorie erstellen", p("ToDo")),
                 tabPanel("Kategorie löschen", p("ToDo")),
                 tabPanel("Kategorien zusammenfügen", p("ToDo"))
)


server <- function(input, output, session) {
  
  output$erkunden <- renderUI({
    
    if (!is.null(input$auxcoId) && nchar(input$auxcoId) == 4 && input$auxcoId %in% ids) {
      category_node <- xml_find_all(src, xpath = paste0("//klassifikation/*[", which(ids == input$auxcoId), "]"))
      id <- xml_text(xml_find_all(category_node, xpath = "./id"))
      bezeichnung <- xml_text(xml_find_all(category_node, xpath = "./bezeichnung"))
      taetigkeit <- xml_text(xml_find_all(category_node, xpath = "./taetigkeit"))
      taetigkeitsbeschreibung <- xml_text(xml_find_all(category_node, xpath = "./taetigkeitsbeschreibung"))
      
      abgrenzung_refid <- xml_attr(xml_find_all(category_node, xpath = "./abgrenzung"), "refid")
      abgrenzung_typ <- xml_attr(xml_find_all(category_node, xpath = "./abgrenzung"), "typ")
      abgrenzung_text <- xml_text(xml_find_all(category_node, xpath = "./abgrenzung"))
      if (length(abgrenzung_text) > 0) {
        abgrenzungen_text <- paste0("<li>", abgrenzung_text, " (<a href=javascript:changeAuxcoId(", abgrenzung_refid, ")>", abgrenzung_refid, "</a>, ", abgrenzung_typ, ")</li>", collapse = "")
      } else {
        abgrenzungen_text <- ""
      }
      
      # folgefragen und antworten sind hier bisher sehr hässlich umgesetzt/dargestellt.
      folgefragen <- xml_text(xml_find_all(category_node, xpath = "./untergliederung/fragetext/folgefrageAktuellerBeruf"))
      
      antworten <- NULL
      for (folgefrage_node in xml_find_all(category_node, xpath = "./untergliederung/child::*")) {
        if (xml_name(folgefrage_node) == "antwort") {
          
          followUp <- xml_attr(folgefrage_node, "follow-up") # if(is.na(xml_attr(folgefrage_node, "follow-up"))) "Ja" else "Nein"
          ant.text <- xml_text(xml_find_all(folgefrage_node, xpath = "./text"))
          ant.kldb <- xml_attr(xml_find_all(folgefrage_node, xpath = "./kldb"), "schluessel")
          if (length(ant.kldb) == 0) ant.kldb <- ""
          ant.isco <- xml_attr(xml_find_all(folgefrage_node, xpath = "./isco"), "schluessel")
          if (length(ant.isco) == 0) ant.isco <- ""
          
          antworten <- rbind(antworten, data.table(ant.text = ant.text, ant.kldb = paste("(KldB:", ant.kldb, ","), ant.isco = paste("ISCO:", ant.isco), followUp = paste("FollowUp:", followUp, ")")))
        }
      }
      
      if (!is.null(antworten)) {
        antworten$text <- paste(antworten$ant.text, antworten$ant.kldb, antworten$ant.isco, antworten$followUp)
        folgefragen.text <- paste("<p>", paste(folgefragen, collapse = "<br>"), "<br><br>", paste(antworten$text, collapse = "<br>"), "</p>")
      } else {
        folgefragen.text <- ""
      }
      
      # Schicke an JavaScript eine Nachricht, damit dort die Suche nach der Tätigkeit im Tree beginnen kann
      session$sendCustomMessage("hilfskategorie_id_submitted", taetigkeit)
      
    return(list(
      textInput("notes", paste("Notiz zur ID", id), value = if (auxco_notes[ids == id, is.na(notes)]) "" else auxco_notes[ids == id, notes]),
      actionButton("notesSubmitted", "Notiz speichern/aktualisieren"),
      hr(),
      p("Tätigkeit:"), p(tags$b(taetigkeit)), p(paste0(id, ": ", bezeichnung)), p("Tätigkeitsbeschreibung:", taetigkeitsbeschreibung),
      p("Abgrenzungen:"),
      HTML(paste("<ul>", abgrenzungen_text, "</ul>")),
      p("Folgefrage(n):"),
      HTML(folgefragen.text),
      hr(), br()

    )) 
    } else {
      return(list(p("ID nicht vorhanden.")))
    }
  })
  
  # Notizen wurden ergänzt
  observeEvent(input$notesSubmitted, {
    
    # we cannot write to file if it in the web (default plcae)
    if (auxco_notes_filename != "https://raw.githubusercontent.com/malsch/occupationCodingAuxco/master/auxco_explorer_notes.txt") {
      auxco_notes[input$auxcoId == ids, notes := input$notes]
      write.csv2(auxco_notes, file = auxco_notes_filename, row.names = FALSE)
    }
    
  })
  

  observeEvent(input$kldbIdClicked, {

    if (nchar(input$kldbIdClicked) <= 5) { # show info only if a kldb-category was clicked
  session$sendCustomMessage("showHtmlPopup", paste("<html><head><title>", kldb2010[input$kldbIdClicked == kldb_id, paste(kldb_id, Titel)], "</title></head>
    <body>
    <h1>", kldb2010[input$kldbIdClicked == kldb_id, paste(kldb_id, Titel)], "</h1>
    <p>Zugeordnete ISCO-Kategorien laut KldB-Umsteigeschlüssel:", kldb2010[input$kldbIdClicked == kldb_id, iscos], "</p>
    <p>", kldb2010[input$kldbIdClicked == kldb_id, Inhalt], "</p>
    <p>", kldb2010[input$kldbIdClicked == kldb_id, Umfasst], "</p>
    <p>", kldb2010[input$kldbIdClicked == kldb_id, Includes], "</p>
    <p>", kldb2010[input$kldbIdClicked == kldb_id, Excludes], "</p>
    </body></html>"))
  }})
  
  observeEvent(input$iscoIdClicked, {
    
    if (nchar(input$iscoIdClicked) <= 4) { # show info only if a kldb-category was clicked
      
      session$sendCustomMessage("showHtmlPopup", paste("<html><head><title>", isco08_en[Code == input$iscoIdClicked & erl_ebene == "000", paste(Code, erl_text)], "</title></head>
                                                       <body>
                                                       <h1>", isco08_en[Code == input$iscoIdClicked & erl_ebene == "000", paste(Code, erl_text)], "</h1>",
                                                       isco08_en[Code == input$iscoIdClicked & erl_ebene != "000", paste(html_text, collapse = "")], "</ul>
                                                       <hr /><hr />
                                                      <h1>", isco08_de[Code == input$iscoIdClicked & erl_ebene == "000", paste(Code, erl_text)], "</h1>",
                                                       isco08_de[Code == input$iscoIdClicked & erl_ebene != "000", paste(html_text, collapse = "")], "</ul>
                                                       </body></html>"))
    }})
  
}

runApp(shinyApp(ui, server), launch.browser = TRUE)

# delete temporary files
unlink(temp_dir, recursive = TRUE)

