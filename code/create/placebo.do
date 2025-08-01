use "temp/analysis-sample.dta", clear

egen max_n_ceo = max(n_ceo), by(frame_id_numeric)
tabulate n_ceo max_n_ceo, missing

keep if max_n_ceo == 1
xtset frame_id_numeric year

* compute staistics to generate a placebo sample of CEOs
egen spell_begin = min(year), by(frame_id_numeric ceo_spell)
egen spell_tag = tag(frame_id_numeric ceo_spell)
egen T_spell = count(year), by(frame_id_numeric ceo_spell)
egen n_spell = total(spell_tag), by(frame_id_numeric)
egen firm_tag = tag(frame_id_numeric)
egen first_ever_year = min(year), by(frame_id_numeric)

tabulate T_spell if spell_tag, missing
* estimate 1-inflated geometric distribution
local T 20
quietly count if spell_tag & T_spell == 1
scalar n_1 = r(N)
quietly count if spell_tag & inrange(T_spell, 1, `T')
scalar n_total = r(N)
quietly count if spell_tag & inrange(T_spell, 3, `T')
scalar n_3plus = r(N)
quietly count if spell_tag & inrange(T_spell, 2, `T'-1)
scalar n_2plus = r(N)

scalar p = 1 - n_3plus / n_2plus

display "Estimated 1-inflated geometric distribution: p = " p
display "Ratio of 1 spells in the data: " n_1 / n_total
display "Inflate 1 with probability " (n_1 / n_total - p) / (1 - p)

* inflation probability is small, ignore it
* each manager exits with the same probability each year
generate byte actual_change = (year == spell_begin) & (year > first_ever_year)
summarize actual_change if year > first_ever_year
scalar p = r(mean)
display "Actual change probability: " p
generate byte placebo_change = (uniform() < p) & (year > first_ever_year)

tabulate placebo_change actual_change, missing

BRK

egen max_ceo_spell = max(ceo_spell), by(frame_id_numeric)

egen within_firm = mean(lnStilde), by(frame_id_numeric person_id)
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

reghdfe lnStilde, absorb(firm_fixed_effect=frame_id_numeric manager_skill=person_id) keepsingletons

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

keep frame_id_numeric person_id year manager_skill firm_fixed_effect lnStilde chi
save "temp/manager_value.dta", replace