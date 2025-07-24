use "temp/analysis-sample.dta", clear

* Create connected component indicator
do "code/create/network-sample.do"

local controls lnK intangible_share foreign_owned state_owned
local FEs frame_id_numeric##ceo_spell teaor08_2d##year

egen max_ceo_spell = max(ceo_spell), by(frame_id_numeric)
egen max_employment = max(employment), by(frame_id_numeric)

* samples for different models
local sample1 1
local sample2 ceo_spell == 1
local sample3 max_ceo_spell == 1
local sample4 max_ceo_spell > 1
local sample5 max_employment >= 5
local sample6 component_id == 1

local title1 "Full sample"
local title2 "First CEO spell"
local title3 "Single CEO spell"
local title4 "Multiple CEO spells"
local title5 "Firms with 5+ employees"
local title6 "Giant connected component"

local esttab_options replace se label ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3)  ///
    addnote("Controls: firm-CEO-spell fixed effects; industry-year fixed effects.") ///
    keep(`controls') nonotes 

eststo clear

local mtitle ""
forvalues i = 1/6 {
    local sample `sample`i''
    local title `title`i''
    reghdfe lnR `controls' if `sample', absorb(`FEs') vce(cluster frame_id_numeric)
    eststo
    local mtitle `mtitle' "`title'"
}

esttab using "output/table/revenue_function.tex", `esttab_options' mtitle(`mtitle') ///
    title("The revenue function in various samples")

levelsof sector, local(sectors)
eststo clear
local mtitle ""
foreach sector of local sectors {
    local lab : label (sector) `sector'
    reghdfe lnR `controls' if sector == `sector' & `sample1', absorb(`FEs') vce(cluster frame_id_numeric)
    eststo
    local mtitle `mtitle' "`lab'"
}

esttab using "output/table/revenue_sectors.tex", `esttab_options' mtitle(`mtitle') ///
    title("The revenue function by sector") 
