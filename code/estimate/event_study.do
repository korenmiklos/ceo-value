use "temp/surplus.dta", clear
* to limit sample to giant component
merge 1:1 frame_id_numeric person_id year using "temp/manager_value.dta", keep(match) nogen
merge 1:1 frame_id_numeric person_id year using "temp/analysis-sample.dta", keep(match) nogen

* limit sample to clean changes between first and second CEO 
keep if max_ceo_spell >= 2
keep if ceo_spell <= 2
keep if n_ceo == 1
keep if !missing(lnStilde)

egen change_year = min(cond(ceo_spell == 2, year, .)), by(frame_id_numeric)
generate event_time = year - change_year
drop change_year

egen MS1 = min(cond(ceo_spell == 1, lnStilde, .)), by(frame_id_numeric)
egen MS2 = min(cond(ceo_spell == 2, lnStilde, .)), by(frame_id_numeric)
drop if missing(MS1, MS2)
egen firm_tag = tag(frame_id_numeric)

set seed 2181
scatter MS2 MS1 if firm_tag & uniform() < 0.1, ///
    title("Manager Skills of First and Second CEO") ///
    xtitle("Skill of First CEO (log points)") ///
    ytitle("Skill of Second CEO (log points)") ///
    msize(tiny) mcolor(blue%25)
graph export "output/figure/manager_skill_correlation.pdf", replace

generate skill_change = MS2 - MS1
replace skill_change = -1 if inrange(skill_change, -1e10, 0)
replace skill_change = 1 if inrange(skill_change, 0, 1e10)

tabulate skill_change if firm_tag, missing
tabulate event_time skill_change, missing

generate better_ceo = event_time >= 0 & skill_change == 1
generate worse_ceo = event_time >= 0 & skill_change == -1

egen n_before = sum(event_time < 0), by(frame_id_numeric)
egen n_after = sum(event_time >= 0), by(frame_id_numeric)

* prepare for event study estimation
keep if inrange(event_time, -10, 10) & n_before >= 5 & n_after >= 5
xtset frame_id_numeric year

xt2treatments lnStilde if inlist(skill_change, 1, -1), treatment(better_ceo) control(worse_ceo) pre(10) post(10) baseline(-2) weighting(optimal)
e2frame, generate(better_ceo)

frame better_ceo: graph twoway ///
    (rarea lower upper xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef xvar, lcolor(red) mcolor(red)) ///
    , graphregion(color(white)) xlabel(-10(1)10) legend(off) xline(-0.5) xscale(range (-10 10)) xtitle("Time since CEO change (year)") yline(0) ytitle("Log TFP relative to first CEO")

graph export "output/figure/event_study.pdf", replace
