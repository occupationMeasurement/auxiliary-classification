# German Auxiliary Classification of Occupations (AuxCO) // Berufs-Hilfsklassifikation mit Tätigkeitsbeschreibungen

This folder contains the electronic appendix of the following publication:
Dieser Ordner enthält den elektronischen Anhang zu folgender Publikation:

Schierholz, Malte; Brenner, Lorraine; Cohausz, Lea; Damminger, Lisa; Fast, Lisa; Hörig, Ann-Kathrin; Huber, Anna-Lena; Ludwig, Theresa; Petry, Annabell; Tschischka, Laura (2018):
 Vorstellung einer Hilfsklassifikation mit Tätigkeitsbeschreibungen für Zwecke der Berufskodierung.
 (IAB-Discussion Paper, 2018), Nürnberg, 45 S. https://www.iab.de/183/section.aspx/Publikation/k180509301

A summarized description is published in

Schierholz, Malte (2018): Eine Hilfsklassifikation mit Tätigkeitsbeschreibungen für Zwecke der Berufskodierung. AStA Wirtschafts- und Sozialstatistisches Archiv 12(3-4). 14 S. https://doi.org/10.1007/s11943-018-0231-2

# Usage
The folder ```auxco_src_files``` contains the auxiliary classification source files. We run the following R code to convert the source files into four easy-to-read tables. They can be immediately downloaded under "Realeases".

```
install.packages(c("xml2", "data.table", "stringdist"))
source("https://raw.githubusercontent.com/malsch/occupationCodingAuxco/master/generate_CSVs.R")
```

# Changelog

* 12.09.2022: Forked from https://github.com/malsch/occupationCodingAuxco/. Some content corrected (minor). AuxCo-Explorer no longer supported.

* 12.09.2022: New format: one xml-file for each answer option; output tables revised

# Mitwirkende
Folgende Personen waren bei der Erstellung beteiligt.

Bauriegel, Mario; Brenner, Lorraine; Cohausz, Lea; Damminger, Lisa; Digiser, Marie-Luise; Fast, Lisa; Hörig, Ann-Kathrin; Huber, Anna-Lena; Ludwig, Theresa; Petry, Annabell; Rosebrock, Antje; Schierholz, Malte; Simson, Jan; Tschischka, Laura

