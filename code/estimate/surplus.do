use "temp/analysis-sample.dta", clear

local FEs frame_id_numeric##ceo_spell teaor08_2d##year
local controls lnK foreign_owned state_owned

levelsof sector, local(sectors)
foreach sector of local sectors {
    reghdfe lnR lnK foreign_owned state_owned if sector == `sector' & component_id == 1, absorb(`FEs') vce(cluster frame_id_numeric)
    eststo, title("`lab'") 
}

esttab using "output/table/EBITDA_sectors.tex", `esttab_options'
