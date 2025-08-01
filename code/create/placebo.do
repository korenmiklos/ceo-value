use "temp/analysis-sample.dta", clear

egen max_n_ceo = max(n_ceo), by(frame_id_numeric)
tabulate n_ceo max_n_ceo, missing

keep if max_n_ceo == 1
xtset frame_id_numeric year

* compute staistics to generate a placebo sample of CEOs
egen spell_begin = min(year), by(frame_id_numeric ceo_spell)
egen first_ever_year = min(year), by(frame_id_numeric)

* previous version was meassuring length of spell, but that inlcuded firm exits, not just CEO changes

* assume each manager exits with the same probability each year
generate byte actual_change = (year == spell_begin) & (year > first_ever_year)
summarize actual_change if year > first_ever_year
scalar p = r(mean)
display "Actual change probability: " p
set seed 8211
generate byte placebo_change = (uniform() < p) & (year > first_ever_year)

tabulate placebo_change actual_change, missing

* now build placebo spells. these will be further pruned to exclude times when the actual manager changed
bysort frame_id_numeric (year): generate placebo_spell = sum(placebo_change)
replace placebo_spell = placebo_spell + 1

correlate ceo_spell placebo_spell

* exclude firms where the two spells are too close
egen placebo_spell_begin = min(year), by(frame_id_numeric placebo_spell)
generate placebo_event_time = year - placebo_spell_begin
generate actual_event_time = year - spell_begin

* plot some stats first
tabulate actual_event_time if placebo_change, missing
tabulate placebo_event_time if actual_change, missing

egen too_close_after = min(cond(placebo_change, actual_event_time, .)), by(frame_id_numeric)
egen too_close_before = max(cond(actual_change, placebo_event_time, .)), by(frame_id_numeric)

* exclude entire firms where the change and placebo change are too close
drop if too_close_after <= 2 | too_close_before  <= 2

keep frame_id_numeric year placebo_spell
save "temp/placebo.dta", replace