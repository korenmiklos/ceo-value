* =============================================================================
* PLACEBO CREATION PARAMETERS
* =============================================================================
local max_n_ceo 1            // Maximum number of CEOs per firm-year
local placebo_seed 8211           // Random seed for placebo generation
local first_placebo_spell 1       // First placebo spell number for analysis
local second_placebo_spell 2      // Second placebo spell number for analysis
local max_ceo_spells 6            // Maximum CEO spell threshold

use "temp/analysis-sample.dta", clear

egen max_n_ceo = max(n_ceo), by(frame_id_numeric)
tabulate n_ceo max_n_ceo, missing
keep if max_n_ceo <= `max_n_ceo'
xtset frame_id_numeric year

* compute staistics to generate a placebo sample of CEOs
egen spell_end = max(year), by(frame_id_numeric ceo_spell)

* previous version was meassuring length of spell, but that inlcuded firm exits, not just CEO changes

* assume each manager exits with the same probability each year
generate byte actual_change = (year == spell_end)  & (ceo_spell < max_ceo_spell)
summarize actual_change if ceo_spell < max_ceo_spell
scalar p = r(mean)
display "Actual change probability: " p
set seed `placebo_seed'
* pcb flags the last year of a spell
generate byte pcb = (uniform() < p)
xtset frame_id_numeric year
* we need the first year of a spell
generate byte placebo_change = (L.pcb == 1)
drop pcb

tabulate placebo_change actual_change, missing

* now build placebo spells. these will be further pruned to exclude times when the actual manager changed
bysort frame_id_numeric (year): generate placebo_spell = sum(placebo_change)
replace placebo_spell = placebo_spell + 1
egen max_placebo_spell = max(placebo_spell), by(frame_id_numeric)

* consistent sampling
drop if max_placebo_spell > `max_ceo_spells'
drop if max_placebo_spell < 2

correlate ceo_spell placebo_spell

egen has_actual_change = max(actual_change), by(frame_id_numeric placebo_spell)

tabulate placebo_spell has_actual_change, missing

egen has_actual_change_1 = max(cond(placebo_spell == `first_placebo_spell', actual_change, .)), by(frame_id_numeric)
egen has_actual_change_2 = max(cond(placebo_spell == `second_placebo_spell', actual_change, .)), by(frame_id_numeric)

tabulate placebo_spell if has_actual_change_1 == 0 & has_actual_change_2 == 0, missing

keep frame_id_numeric year placebo_spell
save "temp/placebo.dta", replace