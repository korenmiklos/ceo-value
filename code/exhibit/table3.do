*! version 1.0.0 2025-08-08
* =============================================================================
* Exhibit 3: Revenue Function Estimation Results Table
* =============================================================================

clear all

use "temp/analysis-sample.dta", clear

* Create connected component indicator
do "code/create/network-sample.do"

* Define rich controls for models 4-6
local rich_controls lnK intangible_share foreign_owned firm_age firm_age_sq ceo_tenure ceo_tenure_sq

* Fixed effects specifications
local FEs frame_id_numeric##ceo_spell teaor08_2d##year

eststo clear

* Model 1: Log revenue ~ log assets (baseline)
reghdfe lnR lnK, absorb(`FEs') vce(cluster frame_id_numeric)
eststo model1

* Model 2: Log EBIT ~ log assets  
reghdfe lnEBIT lnK, absorb(`FEs') vce(cluster frame_id_numeric)
eststo model2

* Model 3: Log employment ~ log assets
reghdfe lnL lnK, absorb(`FEs') vce(cluster frame_id_numeric) 
eststo model3

* Model 4: Log revenue ~ log assets + rich controls
reghdfe lnR `rich_controls', absorb(`FEs') vce(cluster frame_id_numeric)
eststo model4

* Model 5: Log revenue ~ log assets + rich controls (1st CEO spell only)
reghdfe lnR `rich_controls' if ceo_spell == 1, absorb(`FEs') vce(cluster frame_id_numeric)
eststo model5

* Model 6: Log revenue ~ log assets + rich controls (largest connected component)
reghdfe lnR `rich_controls' if component_id == 1, absorb(`FEs') vce(cluster frame_id_numeric)
eststo model6

* Generate LaTeX table using esttab 
esttab model1 model2 model3 model4 model5 model6 using "output/table/table3.tex", ///
    replace booktabs label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) ///
    mtitle("Log Revenue" "Log EBIT" "Log Employment" "Log Revenue" "Log Revenue" "Log Revenue") ///
    title("Revenue Function Estimation Results") ///
    keep(lnK intangible_share foreign_owned firm_age firm_age_sq ceo_tenure ceo_tenure_sq) ///
    order(lnK intangible_share foreign_owned firm_age firm_age_sq ceo_tenure ceo_tenure_sq) ///
    addnote("All models include firm-CEO-spell fixed effects and industry-year fixed effects." ///
            "Standard errors (in parentheses) are clustered at the firm level." ///
            "Models (1)-(3) include only log capital as control." ///
            "Models (4)-(6) include rich controls." ///
            "Model (5) restricts to first CEO spells only." ///
            "Model (6) restricts to largest connected component." ///
            "Significance levels: *** p<0.01, ** p<0.05, * p<0.1.")

* Fix the label in the generated .tex file to avoid LaTeX issues
local oldlabel `"tab:revenue\_function"'
local newlabel "tab:revenuefunction"  
filefilter "output/table/table3.tex" "output/table/table3.tex", from("`oldlabel'") to("`newlabel'") replace

display "Table 3 generated: output/table/table3.tex"