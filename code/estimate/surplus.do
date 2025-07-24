use "temp/analysis-sample.dta", clear

* Create connected component indicator
do "code/create/network-sample.do"

* Check component distribution by employment
tabulate component_id [aw=employment], missing

local FEs frame_id_numeric##ceo_spell teaor08_2d##year
local outcomes lnEBITDA lnR lnL
local esttab_options replace se label title("Non-CEO determinants firm performance") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3)  ///
    addnote("Controls: firm-CEO-spell fixed effects; industry-year fixed effects.") ///
    keep(lnK foreign_owned state_owned) nonotes

eststo clear

foreach outcome of local outcomes {
    reghdfe `outcome' lnK foreign_owned state_owned if component_id == 1, absorb(`FEs') vce(cluster frame_id_numeric)
    eststo
}

esttab using "output/table/full_sample.tex", `esttab_options' mtitle("EBITDA" "Sales" "Employment")

levelsof sector, local(sectors)
eststo clear
foreach sector of local sectors {
    local lab : label (sector) `sector'
    reghdfe lnEBITDA lnK foreign_owned state_owned if sector == `sector' & component_id == 1, absorb(`FEs') vce(cluster frame_id_numeric)
    eststo, title("`lab'") 
}

esttab using "output/table/EBITDA_sectors.tex", `esttab_options'
