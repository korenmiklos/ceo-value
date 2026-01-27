*! version 1.0 2026-01-27
* CEO Overlap Analysis - Investigates CEO transition quality

clear all

* ==============================================================================
* Load data
* ==============================================================================
use temp/analysis-sample.dta, clear

display "CEO overlap analysis started"

* ==============================================================================
* Summary of CEO spells and number of CEOs per year
* ==============================================================================
display "Tabulating CEO spells by number of CEOs per year"
tabulate ceo_spell n_ceo

display "Tabulating for firms with at least one CEO transition"
tabulate ceo_spell n_ceo if max_ceo_spell > 1

* ==============================================================================
* Identify potential overlap cases (2 CEOs during first two spells)
* ==============================================================================
generate byte weird = n_ceo == 2 & max_ceo_spell > 1 & inrange(ceo_spell, 1, 2)

display "Number of overlap cases: " _N
display "Unique firms with overlap cases: "
codebook frame_id_numeric if weird

* ==============================================================================
* Examine sample of firms with overlap
* ==============================================================================
display "Random sample of firms with overlap"
list frame_id_numeric if weird & uniform() < 10/87000, clean noobs

display "Examining specific firm with overlap"
list frame_id_numeric year person_id ceo_spell if frame_id_numeric == 10649259, clean

* ==============================================================================
* Process data to identify CEO overlap patterns
* ==============================================================================
preserve

sort frame_id_numeric year person_id
display "Sorted by firm, year, and person ID"

collapse (firstnm) n_ceo, by(frame_id_numeric ceo_spell person_id)
display "Collapsed to firm-spell-CEO level"

drop if missing(person_id)
display "Dropped " _N " observations with missing person_id"

sort frame_id_numeric ceo_spell person_id

collapse (min) min_person_id = person_id (max) max_person_id = person_id (firstnm) n_ceo, by(frame_id_numeric ceo_spell)
display "Collapsed to firm-spell level with min/max person IDs"

xtset frame_id_numeric ceo_spell
display "Set panel structure"

generate byte common_ceo = (max_person_id == L.min_person_id) | (max_person_id == L.max_person_id) | (min_person_id == L.min_person_id) | (min_person_id == L.max_person_id)
display "Created common_ceo indicator for overlapping CEOs"

tabulate ceo_spell n_ceo
display "Summary of CEO spells by number of CEOs per year (all)"

tabulate ceo_spell n_ceo if !common_ceo
display "Summary excluding cases with common CEOs"

* ==============================================================================
* Focus on transition periods (firms with multiple CEO spells)
* ==============================================================================
egen max_ceo_spell_check = max(ceo_spell), by(frame_id_numeric)

display "Analysis of transition periods (spells 2+)"
tabulate ceo_spell n_ceo if max_ceo_spell_check >= 2 & ceo_spell > 1

display "Analysis excluding cases with common CEOs"
tabulate ceo_spell n_ceo if max_ceo_spell_check >= 2 & ceo_spell > 1 & !common_ceo

display "Cross-tabulation of n_ceo and common_ceo for transition periods"
tabulate n_ceo common_ceo if max_ceo_spell_check >= 2 & ceo_spell > 1, row

display "Transition from 1 to 2 CEOs"
tabulate n_ceo common_ceo if max_ceo_spell_check >= 2 & ceo_spell > 1 & L.n_ceo == 1, row

* ==============================================================================
* Correct n_ceo based on actual CEO overlap
* ==============================================================================
display "Correcting n_ceo: cases with overlapping CEOs marked as 2 CEOs"
replace n_ceo = 2 if min_person_id < max_person_id
display "Made " _N " corrections"

display "Transition from 1 to 2 CEOs after correction"
tabulate n_ceo common_ceo if max_ceo_spell_check >= 2 & ceo_spell > 1 & L.n_ceo == 1, row

display "All transition periods after correction"
tabulate n_ceo common_ceo if max_ceo_spell_check >= 2 & ceo_spell > 1, row

display "Transition from 2 to 1 CEOs after correction"
tabulate n_ceo common_ceo if max_ceo_spell_check >= 2 & ceo_spell > 1 & L.n_ceo == 2, row

restore

display "CEO overlap analysis completed"
