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
    mtitle("Revenue" "EBITDA" "Wagebill" "Materials" "Revenue" "Revenue") ///
    title("Surplus Function Estimation Results") ///
    keep(lnK foreign_owned has_intangible) ///
    order(lnK has_intangible foreign_owned) ///
    addnote("All models include firm-CEO-spell fixed effects and industry-year fixed effects. Outcome variables are" ///
            "log-transformed. Models (5) and (6) include quadratic controls for firm age and CEO tenure." ///
            "Model (6) restricts to largest connected component.")

display "Table 3 generated: output/table/table3.tex"