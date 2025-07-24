use "temp/surplus.dta", clear

* Create connected component indicator
do "code/create/network-sample.do"

egen max_ceo_spell = max(ceo_spell), by(frame_id_numeric)

egen within_firm = mean(lnStilde), by(frame_id_numeric person_id)
egen first_ceo = mean(cond(ceo_spell == 1, within_firm, .)), by(frame_id_numeric)
replace within_firm = within_firm - first_ceo
drop first_ceo

* convert manager skill to revenue/surplus contribution
summarize within_firm if ceo_spell > 1, detail
display "IQR of within-firm variation in manager skill: " exp(r(p75) - r(p25))*100 - 100
replace within_firm = within_firm / chi
summarize within_firm if ceo_spell > 1, detail
display "IQR of within-firm variation in manager surplus: " exp(r(p75) - r(p25))*100 - 100

local outcomes lnR lnEBITDA lnL
foreach outcome of local outcomes {
    display "Explaining within-firm variation in `outcome'..."
    reghdfe within_firm `outcome' if max_ceo_spell > 1, absorb(frame_id_numeric) vce(cluster frame_id_numeric)
}

* now do cross section, but only on connected components
keep if component_id == 1

reghdfe lnStilde, absorb(frame_id_numeric manager_skill=person_id) keepsingletons

summarize manager_skill, detail
replace manager_skill = manager_skill - r(mean)
display "IQR of manager skill: " exp(r(p75) - r(p25))*100 - 100
replace manager_skill = manager_skill / chi
summarize manager_skill, detail
display "IQR of manager surplus: " exp(r(p75) - r(p25))*100 - 100

local outcomes lnR lnEBITDA lnL
foreach outcome of local outcomes {
    display "Explaining variation in `outcome'..."
    reghdfe manager_skill `outcome', a(teaor08_2d##year) vce(cluster frame_id_numeric) keepsingletons
}
