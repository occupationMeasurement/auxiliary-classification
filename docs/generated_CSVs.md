# Documentation of Generated CSV Files

> Please refer to the main publication (and its appendix) for further information.

## Overview of files

- `auxco_categories.csv`: Main list of AuxCO categories including their descriptions etc.
- `auxco_distinctions.csv`: List of highly similar AuxCO categories that one may want to present to disambiguate between them.
- `auxco_followup_questions.csv`: Follow-up questions to specify final codings based on AuxCO categories. Includes the questions' answer options as well as information on how to encode more complex occupations which depend on multiple answers.
- `auxco_mapping_from_isco.csv`: Mapping from ISCO-08 categories to AuxCO categories.
- `auxco_mapping_from_kldb.csv`: Mapping from KldB 2010 categories to AuxCO categories.

> Many of the ids used in occupation coding may be numeric, but use leading zeros which must not be omitted. Please note that care has to be taken to load all columns holding ids as strings / characters to preserve leading zeros.

## Descriptions of Individual Tables / Files

### Description of Table `auxco_categories.csv`

Main table. Contains all answer options from the auxiliary classification.

- **auxco_id**: Unique identifier of AuxCO category.
- **title**: Job title. Usage is not recommended. Provided only for convenience.
- **task**: The core tasks and activities that are typically performed in a job. Defines the content of an AuxCO category. These texts should be precise and easy to understand for interviewers and respondents.
- **task_description**: Examples or other details that clarify the task.
- **default_kldb_id**: The KldB 2010 id associated with this AuxCO category by default. Depending on follow-up questions a different KldB 2010 id might be coded in the end.
- **default_isco_id**: The ISCO-08 id associated with this AuxCO category by default. Depending on follow-up questions a different KldB 2010 id might be coded in the end.
- **kldb_title_short**: Brief summary of the area of work. Derived from KldB 2010 (4-digit category names).
- **notes**: Comments from AuxCO creators. It may provide the rationale why the selected category is correct and a different category is considered wrong. If an answer option is problematic for some reason and might be improved, this is highlighted.


### Description of Table `auxco_distinctions.csv`

List of highly similar AuxCO categories that one may want to present to disambiguate between them.

- **auxco_id**: Unique identifier of the associated AuxCO category.
- **title**: Main title of the associated AuxCO category. Provided only for convenience.
- **similar_auxco_id**: Unique identifier of another similar AuxCO category.
- **similar_title**: Main title of the similar AuxCO category. Provided only for convenience.
- **similarity**: Categorical variable indicating the degree of similarity between the two categories.
> The similarity relation is not symetric.
- **default_kldb_id**: The KldB 2010 id associated with the AuxCO category of `auxco_id` by default. Used for ordering and provided only for convenience.

### Description of Table `auxco_followup_questions.csv`

- **auxco_id**: Unique identifier of the associated AuxCO category.
- **question_id**: Unique identifier of this question, provided for question answer entries.
- **question_index**: Running index identifying the order of questions for each **auxco_id** i.e. the first question for a specific **auxco_id** will have a **question_index** of `1`, the second `2`.
- **entry_type**: Which type of entry a row corresponds to. Three types of entry are present in this dataset, depending on the **entry_type** some columns might be empty:
  - `question`: Corresponding to a question itself.
  - `answer_option`: Corresponding to an answer option to a question.
  - `aggregated_answer_encoding`: Corresponding to a kldb / isco encoding which depends on multiple questions and their answers.
- **question_type**: `anforderungsniveau`-questions are meant to capture the ISCO-08 skill level, `aufsicht`-questions are related to the (ISCO-08) supervisory/managerial status, `spezialisierung`-questions probe for common job specializations, and `sonstige` is a residual category of questions that do not fit the standard question types.
- **question_text_present**: The question text to be shown to ask for current occupations.
- **question_text_past**:  The question text to be shown to ask for past occupations.
- **answer_id**: Numeric index identifying this answer option. Not unique across questions, only within. Defines the order of answer options.
- **answer_text**: The text to be shown for this answer option.
- **answer_id_combination**: Which combination of questions with their corresponding answers should lead to the associated encoding. The format of this column is similar to GET URL parameters e.g. `{question_id}={answer_id}&{question_id}={answer_id}`. Only for entries of type `aggregated_answer_encoding`.
- **answer_kldb_id**: The KldB 2010 id associated with this answer.
- **answer_isco_id**: The ISCO-08 id associated with this answer.
- **corresponding_answer_level**: Questions with question type `anforderungsniveau` or `aufsicht` correspond to standardized levels from the ISCO-08 manual. This column can be used to match answer options with the standardized levels when using external data.
- **last_question**: Is coding completed when this answer option has been selected? Used to identify the last answer in, as sometimes an AuxcCO entry might have multiple follow-up questions, but a certain answer to the first one might already be sufficient.

### Description of Table `auxco_mapping_from_isco.csv`

Mapping from ISCO-08 entries to AuxCO categories.

> This is not a unique 1:1 mapping. Moreover, for occupations that don't exist in Germany the ISCO-08 categories are missing.

- **isco_id**: The id of the associated ISCO-08 entry.
- **auxco_id**: The id of the associated AuxCO category.
- **auxco_title**: Main title of the associated AuxCO category, provided only for convenience.
- **isco_title**: Main title of the associated ISCO-08 entry, provided only for convenience.

### Description of Table `auxco_mapping_from_kldb.csv`

Mapping from KldB 2010 entries to AuxCO categories.

> This is not a unique 1:1 mapping. For each KldB 2010-category there are one or more mappings (never zero).

- **kldb_id**: The id of the associated KldB 2010 category entry.
- **auxco_id**: The id of the associated AuxCO category.
- **auxco_title**: Main title of the associated AuxCO category, provided only for convenience.
- **kldb_title**: Main title of the associated KldB 2010 entry, provided only for convenience.
