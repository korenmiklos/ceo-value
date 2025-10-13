clear all
use "../../temp/surplus.dta", clear
merge 1:1 frame_id_numeric person_id year using "../../temp/analysis-sample.dta", keep(match) nogen
merge m:1 frame_id_numeric person_id using "../../temp/manager_value.dta", keep(master match) nogen

local lambda 0.5714

egen mean_lnR = mean(lnR), by(teaor08_2d year)
egen lnR_2 = mean(cond(firm_age == 2, lnR - mean_lnR, .)), by(frame_id_numeric)
egen ceo_2 = min(cond(firm_age == 2, ceo_spell, .)), by(frame_id_numeric)
generate dlnR = lnR - mean_lnR - lnR_2

generate variance = dlnR^2

generate ceos = (ceo_spell - ceo_2) * `lambda'
collapse (mean) variance ceos (sd) se_variance = variance se_ceos = ceos (count) n_variance = variance n_ceos = ceos, by(firm_age)

foreach X in variance ceos {
    replace se_`X' = se_`X' / sqrt(n_`X')
    generate lower_`X' = `X' - se_`X' * invnormal(0.975)
    generate upper_`X' = `X' + se_`X' * invnormal(0.975)
}

keep if inrange(firm_age, 2, 12)
sort firm_age

graph twoway ///
    (rarea lower_variance upper_variance firm_age, fcolor(gray%5) lcolor(gray%10)) ///
    (rarea lower_ceos upper_ceos firm_age, fcolor(gray%5) lcolor(gray%10)) ///
    (connected variance firm_age, lcolor(red) mcolor(red)) ///
    (connected ceos firm_age, lcolor(blue) mcolor(blue)) ///
    ,  title("Panel D: Variance and age", size(medium)) ///
    legend(order(3 "Variance" 4 "CEO changes") rows(1) position(6)) ///
    graphregion(color(white)) xlabel(2(2)12) ///
    xtitle("Firm age (year)") yline(0) ///
    `yline' ylabel(, angle(0) format(%9.2f)) ///
    aspectratio(1) xsize(5) ysize(5) ///
    name(panelD, replace)
