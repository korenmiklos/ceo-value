use "temp/surplus.dta", clear
merge m:1 frame_id_numeric year using "temp/placebo.dta", keep(match) nogen
rename ceo_spell actual_spell

* pretend these spells are the real ones
rename placebo_spell ceo_spell

* limit sample to clean changes between first and second CEO 
egen max_ceo_spell = max(ceo_spell), by(frame_id_numeric)
keep if max_ceo_spell >= 2
keep if ceo_spell <= 2
keep if !missing(lnStilde)

egen change_year = min(cond(ceo_spell == 2, year, .)), by(frame_id_numeric)
generate event_time = year - change_year
drop change_year

* there is no separate measure of CEO skill, so we use lnStilde
egen MS1 = min(cond(ceo_spell == 1, lnStilde, .)), by(frame_id_numeric)
egen MS2 = min(cond(ceo_spell == 2, lnStilde, .)), by(frame_id_numeric)
drop if missing(MS1, MS2)
egen firm_tag = tag(frame_id_numeric)

generate skill_change = MS2 - MS1
egen cutoff1 = pctile(skill_change), p(33)
egen cutoff2 = pctile(skill_change), p(67)
replace skill_change = -1 if inrange(skill_change, -1e10, cutoff1)
replace skill_change = 0 if inrange(skill_change, cutoff1, cutoff2)
replace skill_change = 1 if inrange(skill_change, cutoff2, 1e10)
drop cutoff1 cutoff2

tabulate skill_change if firm_tag, missing
tabulate event_time skill_change, missing

generate same_ceo = event_time >= 0 & skill_change == 0
generate better_ceo = event_time >= 0 & skill_change == 1
generate worse_ceo = event_time >= 0 & skill_change == -1

egen n_before = sum(event_time < 0), by(frame_id_numeric)
egen n_after = sum(event_time >= 0), by(frame_id_numeric)

* prepare for event study estimation
keep if inrange(event_time, -10, 10) & n_before >= 3 & n_after >= 3
xtset frame_id_numeric year

* save snapshot for tests
save "output/test/placebo.dta", replace

xt2treatments lnStilde if inlist(skill_change, -1, 0), treatment(worse_ceo) control(same_ceo) pre(10) post(10) baseline(-10) weighting(optimal)
e2frame, generate(worse_ceo)

xt2treatments lnStilde if inlist(skill_change, 1, 0), treatment(better_ceo) control(same_ceo) pre(10) post(10) baseline(-10) weighting(optimal)
e2frame, generate(better_ceo)

* now link the two frames, better_ceo and worse_ceo and create the event study figure with two lines
foreach X in coef lower upper {
    frame better_ceo: rename `X' `X'_better
    frame worse_ceo: rename `X' `X'_worse
}
frame worse_ceo: frlink 1:1 xvar, frame(better_ceo)
frame worse_ceo: frget coef_better lower_better upper_better, from(better_ceo)

frame worse_ceo: graph twoway ///
    (rarea lower_worse upper_worse xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef_worse xvar, lcolor(blue) mcolor(blue)) ///
    (rarea lower_better upper_better xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef_better xvar, lcolor(red) mcolor(red)) ///
    , graphregion(color(white)) xlabel(-10(1)10) legend(order(4 "Improving firm" 2 "Worsening firm")) xline(-0.5) xscale(range (-10 10)) xtitle("Time since placebo change (year)") yline(0) ytitle("Log TFP relative to beginning of sample")

graph export "output/figure/placebo.pdf", replace
