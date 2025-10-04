clear all

use "temp/analysis-sample.dta", clear

* Create connected component indicator
do "code/create/network-sample.do"


* Load all models from single file
forvalues model = 1/6 {
    estimate use "temp/revenue_models.ster", number(`model')
    eststo model`model'
}

local vars lnK has_intangible founder owner foreign_owned state_owned

* Generate LaTeX table using esttab 
esttab model1 model2 model3 model4 model5 model6 using "output/table/table3.tex", ///
    replace booktabs label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) ///
    mtitle("Revenue" "EBITDA" "Wagebill" "Materials" "Revenue" "Revenue") ///
    title("Surplus Function Estimation Results") ///
    keep(`vars') ///
    order(`vars') ///
    addnote("All models include firm fixed effects, industry-year fixed effects, and a step function for firm age." ///
            "Outcome variables are log-transformed. Models (5) and (6) include quadratic controls for CEO age and tenure." ///
            "Model (6) restricts to largest connected component of CEO-firm network.")

display "Table 3 generated: output/table/table3.tex"