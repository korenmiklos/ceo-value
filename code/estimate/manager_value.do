use "temp/surplus.dta", clear

* Create connected component indicator
do "code/create/network-sample.do"

egen max_ceo_spell = max(ceo_spell), by(frame_id_numeric)

egen within_firm = mean(cond(change_window, ., lnStilde)), by(frame_id_numeric person_id)
egen first_ceo = mean(cond(ceo_spell == 1, within_firm, .)), by(frame_id_numeric)
replace within_firm = within_firm - first_ceo
drop first_ceo

* convert manager skill to revenue/surplus contribution
summarize within_firm if ceo_spell > 1, detail
display "IQR of within-firm variation in manager skill: " exp(r(p75) - r(p25))*100 - 100
replace within_firm = . if !inrange(within_firm, -1, +1)

* Create histogram for within-firm manager skill variation
histogram within_firm if ceo_spell > 1, ///
    title("Panel A: Within-firm Manager Skill Distribution") ///
    xtitle("Manager Skill (log points)") ///
    ytitle("Density") ///
    normal
graph export "output/figure/manager_skill_within.pdf", replace

generate within_firm_chi = within_firm / chi
summarize within_firm_chi if ceo_spell > 1, detail
display "IQR of within-firm variation in manager surplus: " exp(r(p75) - r(p25))*100 - 100

local outcomes lnR lnEBITDA lnL
foreach outcome of local outcomes {
    display "Explaining within-firm variation in `outcome'..."
    reghdfe within_firm_chi `outcome' if max_ceo_spell > 1, absorb(frame_id_numeric) vce(cluster frame_id_numeric)
}
drop within_firm_chi

* now do cross section, but only on connected components
keep if component_id == 1

reghdfe lnStilde if change_window == 0, absorb(firm_fixed_effect=frame_id_numeric manager_skill=person_id) keepsingletons

summarize manager_skill, detail
replace manager_skill = manager_skill - r(mean)
display "IQR of manager skill: " exp(r(p75) - r(p25))*100 - 100
replace manager_skill = . if !inrange(manager_skill, -2, +2)

* Create histogram for connected component manager skill distribution
histogram manager_skill, ///
    title("Panel B: Connected Component Manager Skill Distribution") ///
    xtitle("Manager Skill (log points)") ///
    ytitle("Density") ///
    normal
graph export "output/figure/manager_skill_connected.pdf", replace

generate manager_skill_chi = manager_skill / chi
summarize manager_skill_chi, detail
display "IQR of manager surplus: " exp(r(p75) - r(p25))*100 - 100

* Create regression table for manager skill effects
eststo clear
local outcomes lnR lnEBITDA lnL
local titles "Revenue" "EBITDA" "Employment"
local i = 1
foreach outcome of local outcomes {
    display "Explaining variation in `outcome'..."
    eststo: reghdfe manager_skill_chi `outcome', a(teaor08_2d##year) vce(cluster frame_id_numeric) keepsingletons
    local ++i
}
drop manager_skill_chi

esttab using "output/table/manager_effects.tex", replace ///
    title("Manager Skill Effects on Firm Outcomes") ///
    label booktabs ///
    b(3) se(3) ///
    mtitles("Revenue" "EBITDA" "Employment") ///
    addnotes("Standard errors clustered at firm level." "All regressions include industry-year fixed effects.") ///
    stats(N r2_a, fmt(0 3) labels("Observations" "Adjusted R-squared"))

collapse (firstnm) firm_fixed_effect manager_skill chi, by(frame_id_numeric person_id)
save "temp/manager_value.dta", replace