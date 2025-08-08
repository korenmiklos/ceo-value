*! version 1.0.0 2025-08-08
* =============================================================================
* Exhibit 3: Revenue Function Estimation Results Table
* =============================================================================

clear all

use "temp/analysis-sample.dta", clear

* Create connected component indicator
do "code/create/network-sample.do"


* Load all models from single file
forvalues model = 1/6 {
    estimate use "temp/revenue_models.ster", number(`model')
    eststo model`model'
}

* Generate LaTeX table using esttab 
esttab model1 model2 model3 model4 model5 model6 using "output/table/table3.tex", ///
    replace booktabs label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) ///
    mtitle("Log Revenue" "Log EBITDA" "Log Employment" "Log Revenue" "Log Revenue" "Log Revenue") ///
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

display "Table 3 generated: output/table/table3.tex"