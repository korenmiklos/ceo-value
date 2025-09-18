use "temp/surplus.dta", clear
merge 1:1 frame_id_numeric person_id year using "temp/analysis-sample.dta", keep(match) nogen
merge m:1 frame_id_numeric person_id using "temp/manager_value.dta", keep(master match) nogen

* the same firm may appear multipe times as control, repeat those observations
joinby frame_id_numeric using "temp/placebo.dta"

* limit to event window
keep if inrange(year, window_start, window_end)
* for 2-ceo firms, only keep 1 of them, these are only placebo anyway
tabulate n_ceo
bysort fake_id year: generate keep = _n == 1
tabulate n_ceo keep
keep if keep == 1
drop keep
* bad naming, sorry!

* check balance
tabulate year placebo [iw=weight]
tabulate change_year placebo [iw=weight]

* create fake CEO spells for placebo group
tabulate ceo_spell placebo
summarize ceo_spell if placebo == 0
local s1 = r(min)
local s2 = r(max)
replace ceo_spell = `s1' if placebo == 1 & year < change_year
replace ceo_spell = `s2' if placebo == 1 & year >= change_year
tabulate ceo_spell placebo

* CEO skill is also fake, computed from actual TFP
egen fake_manager_skill = mean(lnStilde), by(fake_id ceo_spell)
replace manager_skill = fake_manager_skill if placebo == 1
drop fake_manager_skill

egen MS1 = mean(cond(ceo_spell == `s1', manager_skill, .)), by(fake_id)
egen MS2 = mean(cond(ceo_spell == `s2', manager_skill, .)), by(fake_id)
generate byte good_ceo = (MS2 > MS1)

* now create helper variables for event study
egen byte firm_tag = tag(fake_id)
generate event_time = year - change_year

tabulate good_ceo if firm_tag, missing
tabulate event_time good_ceo, missing

generate byte actual_ceo = event_time >= 0 & placebo == 0
generate byte placebo_ceo = event_time >= 0 & placebo == 1
generate byte better_ceo = event_time >= 0 & good_ceo == 1
generate byte worse_ceo = event_time >= 0 & good_ceo == 0

xtset fake_id year
