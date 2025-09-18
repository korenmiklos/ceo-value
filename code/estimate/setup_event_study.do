use "temp/surplus.dta", clear
merge 1:1 frame_id_numeric person_id year using "temp/analysis-sample.dta", keep(match) nogen
merge m:1 frame_id_numeric person_id using "temp/manager_value.dta", keep(master match) nogen

* the same firm may appear multipe times as control, repeat those observations
joinby frame_id_numeric using "temp/placebo.dta"

* limit to event window
keep if inrange(year, window_start, window_end)

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