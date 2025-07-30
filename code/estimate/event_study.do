use "temp/manager_value.dta", clear
merge 1:1 frame_id_numeric person_id year using "temp/analysis-sample.dta", keep(match) nogen

* limit sample to clean changes between first and second CEO 
keep if max_ceo_spell >= 2
keep if ceo_spell <= 2
keep if n_ceo == 1
keep if !missing(lnStilde)

egen change_year = min(cond(ceo_spell == 2, year, .)), by(frame_id_numeric)
generate event_time = year - change_year
drop change_year

egen MS1 = min(cond(ceo_spell == 1, manager_skill, .)), by(frame_id_numeric)
egen MS2 = min(cond(ceo_spell == 2, manager_skill, .)), by(frame_id_numeric)
drop if missing(MS1, MS2)
egen firm_tag = tag(frame_id_numeric)

scatter MS2 MS1 if firm_tag, ///
    title("Correlation of Manager Skill Before and After Change") ///
    xtitle("Manager Skill Before Change (log points)") ///
    ytitle("Manager Skill After Change (log points)") ///
    msize(tiny) mcolor(blue%10)
graph export "output/figure/manager_skill_correlation.pdf", replace

generate byte better_manager = (MS2 > MS1)
tabulate better_manager if firm_tag, missing

tabulate event_time better_manager, missing
generate good_ceo = event_time >= 0 & better_manager
generate bad_ceo = event_time >= 0 & !better_manager

* prepare for event study estimation
keep if inrange(event_time, -10, 10)
xtset frame_id_numeric year

xt2treatments lnStilde, treatment(good_ceo) control(bad_ceo) pre(10) post(10) baseline(-2) weighting(optimal)
e2frame, generate(ceo_fig)
frame ceo_fig: graph twoway (rarea lower upper xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef xvar, lcolor(cranberry)), graphregion(color(white)) xlabel(-10(1)10) legend(off) xline(-0.5) xscale(range (-10 10)) xtitle("Time since CEO change (year)") yline(0) ytitle("Residual surplus of new CEO (better - worse)")

graph export "output/figure/event_study.pdf", replace
