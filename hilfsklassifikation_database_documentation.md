## Overview of tables

- answerOption: contains all answer options
- abstammung: contains links between predecessor and succesor answer options (they may change over time)
- abgrenzungen: contains answer options that are (highly) similar to another

- folgefrage: contains follow-up questions

- map_kldb_to_auxcoid: a mapping from kldb-categories to auxco-answer options
- map_auxco_to_kldb_isco: a mapping from auxco answer options/follow up questions to KldB-/ISCO-categories

## Description of table ``answerOption``

- id: primary key, unique (updated with every change)
- cid: concept id, not unique (generated when a new concept gets defined, but not updated if the concept changes. Not sure if useful)
- valid_from, valid_until: time span during which this id was valid. If currently valid, valid_until = "9999-01-01"
- bezeichnung, taetigkeit, taetigkeitsbeschreibung: description of concept. taetigkeit has been worded more carefully than the others.
- kldb_default, isco_default: main KldB/ISCO-categories for which this answer option was created. It is the default category for coding, unless more information is available from a follow-up question
- comment: comments on this answer option, meant for future improvement

## Description of table ``abstammung``

- predecessor, successor: ids from table answerOption. NULL values are allowed if there is no predecessor/successor

Whenever an answer option changes, a new id will be generated in table answer option. The old id is the predecessor, the new id is the successor. valid_until (old id) must always be less than valid_from (new id).

## Description of table ``abgrenzung``

Each id in table answer option can have multiple abgrenzungen (indicated with refid). Typ can be mittel or hoch, depending on the strength of similarity. The relation between id and refid is not symmetric.

## Description of table ``map_kldb_to_auxcoid``

Every KldB is linked to at least one answerOption$id. KldB-categories must not be missing.

## Description of table ``folgefrage``

Each row corresponds to an answer from a folgefrage.

If `answerOption == id` gets selected, all folgefragen that have this ``id`` can/should be asked.

- fragetextAktuellerBeruf, fragetextVergangenerBeruf: exact question wording in present/past tense
- antworttext: wording of answers

- id: refers to table ``answerOption``
- qid: question id (Each id-questionNumber combination has a single qid.)
- qaid: question answer id (unique primary key of this table)
- questionNumber: More than one folgefragen may need to be asked. Question number determines the order of questions.
- position: position determines the place of an answer. E.g., the answer with position = 1 is shown first at the top of the page.

- typ: helps categorize the type of questions
- anforderungsniveau (only available if typ == anforderungsniveau): Selecting the antwort entails this anforderungsniveau (=skill level). Anforderungsniveau can have values 1-4. anforderungsniveau usually equals the 5-th digit of column kldb, except if the corresponding kldb-code does not exist in the official classification.
- fuehrung: (only available if typ == aufsicht): Selecting this antwort entails this level of supervisory skills. fuehrung can have values "keine Fuehrungsverantwortung", "Aufsichtskraft", "Fuehrungskraft". The kldb-column usually equals '93' if fuehrung = Aufsichtskraft and '94' if fuehrung = Fuehrungskraft, except if the corresponding kldb-code does not exist in the official classification.

If anforderungsniveau and/or fuehrung is already known upfront, we should not need to ask this question and can save time. However, problems arise if the known value from an external source is not a valid answer of this folgefrage. In this case, no decision is made how to code this person.

- kldb, isco: If this answer gets selected, use this kldb/isco code for classification, overwriting the default value from table answerOption. Missing if the question is only asked for coding into the alternative classification (or if kldb1, kldb2, isco1, isco2 is set).
- followUp: Sometimes more than one follow-up question is asked (see question number). If followUp = unnoetig, the selected answer already contains all the information we need, and the second followUp question should be skipped.
- kldb1, kldb2, isco1, isco2: In rare cases the final kldb/isco-code is jointly determined by two follow-up questions. See comment for explanation
- comment: Anything helpful to know about this question


## Basic example code to query the data base
```
# install.packages(c("DBI", "RSQLite"))
library(DBI)
con <- dbConnect(RSQLite::SQLite(), "hilfsklassifikation.sqlite3")

# example queries to get data that is valid at :date
dbGetQuery(con, 'SELECT * FROM answeroption WHERE :date BETWEEN valid_from AND valid_until LIMIT 5', params = list(date = as.Date("2022-02-01")))
dbGetQuery(con, 'SELECT * FROM answeroption ao LEFT JOIN abgrenzung ab ON ao.id = ab.id WHERE :date BETWEEN valid_from AND valid_until LIMIT 5', params = list(date = as.Date("2022-02-01")))
dbGetQuery(con, 'SELECT * FROM abstammung')
dbGetQuery(con, 'SELECT * FROM abgrenzung ab LEFT JOIN answeroption ao ON ab.id = ao.id WHERE :date BETWEEN valid_from AND valid_until LIMIT 5', params = list(date = as.Date("2022-02-01")))
dbGetQuery(con, 'SELECT * FROM folgefrage f LEFT JOIN answeroption ao ON f.id = ao.id WHERE :date BETWEEN valid_from AND valid_until LIMIT 5', params = list(date = as.Date("2022-02-01")))
dbGetQuery(con, 'SELECT * FROM map_kldb_to_auxco kl LEFT JOIN answeroption ao ON kl.id = ao.id WHERE :date BETWEEN valid_from AND valid_until LIMIT 5', params = list(date = as.Date("2022-02-01")))

dbDisconnect(con)
```
