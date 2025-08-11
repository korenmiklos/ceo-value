* =============================================================================
* PLACEBO CREATION PARAMETERS
* =============================================================================
local max_n_ceo 1            // Maximum number of CEOs per firm-year
local placebo_seed 8211           // Random seed for placebo generation
local first_placebo_spell 1       // First placebo spell number for analysis
local second_placebo_spell 2      // Second placebo spell number for analysis
local max_ceo_spells 6            // Maximum CEO spell threshold
local longest_spell 31            // Maximum length of CEO spell for analysis
local pre 3                     // Pre-period for analysis
local post 3                    // Post-period for analysis

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

bysort frame_id_numeric ceo_spell (year): generate year_of_spell = sum(1)

tabulate year_of_spell actual_change if ceo_spell < max_ceo_spell , row
summarize year_of_spell if ceo_spell < max_ceo_spell
local max_spell_length = r(max)

* first estimate time varying hazard of CEO change
xtset frame_id_numeric year
set seed `placebo_seed'
forvalues t = 1/`max_spell_length' {
    summarize actual_change if year_of_spell == `t' & ceo_spell < max_ceo_spell
    local p_`t' = r(mean)
    display "Probability of change in year `t': " `p_`t''
}

egen T_actual = total(1), by(frame_id_numeric ceo_spell)
egen actual_spell_tag = tag(frame_id_numeric ceo_spell)
tabulate T_actual if actual_spell_tag & ceo_spell < max_ceo_spell, missing

* most relevant firms are those that WILL change CEO in the future
keep if max_ceo_spell >= 2
* only use long spells for placebo
keep if ceo_spell == 1
keep if T_actual >= `pre' + `post' + 1

* then simulate placebo spells with the same distribution
bysort frame_id_numeric (year): generate byte running_index = 1 if _n == 1
generate p_change = .
generate byte pcb = .
generate byte pointer = 1 if running_index == 1

local p_`longest_spell' = 1
forvalues t = 1/`longest_spell' {
    display "Simulating year `t' of placebo spells"
    * we may already have previous indexes
    forvalues s = 1/`t' {
        quietly replace p_change = `p_`s'' if running_index == `s'
    }
    quietly replace pcb = (uniform() < p_change) if pointer == 1
    * update running index if no change simulated
    * do not use lags, because sometimes there are holes in years
    quietly replace running_index = running_index[_n-1] + 1 if frame_id_numeric == frame_id_numeric[_n-1] & pointer[_n-1] == 1 & pcb[_n-1] == 0
    * start counting from 1 if there is a change
    quietly replace running_index = 1 if frame_id_numeric == frame_id_numeric[_n-1] & pointer[_n-1] == 1 & pcb[_n-1] == 1
    * move pointer one year ahead
    quietly replace pointer = 1 if !missing(pcb[_n-1])
    quietly replace pointer = 0 if !missing(pcb)

    tabulate running_index if pointer == 1
}

generate byte placebo_change = L.pcb == 1

tabulate placebo_change actual_change, missing

* now build placebo spells. these will be further pruned to exclude times when the actual manager changed
bysort frame_id_numeric (year): generate placebo_spell = sum(placebo_change)
replace placebo_spell = placebo_spell + 1
egen max_placebo_spell = max(placebo_spell), by(frame_id_numeric)

* consistent sampling
drop if max_placebo_spell > `max_ceo_spells'

egen T_placebo = total(1), by(frame_id_numeric placebo_spell)
egen placebo_spell_tag = tag(frame_id_numeric placebo_spell)

* compare distribution of actual and placebo spell lengths
tabulate T_placebo if placebo_spell_tag & placebo_spell < max_placebo_spell, missing

* drop last spell, it ends in firm exit, not manager change
drop if placebo_spell == max_placebo_spell

tabulate max_placebo_spell, missing

keep frame_id_numeric year placebo_spell
save "temp/placebo.dta", replace