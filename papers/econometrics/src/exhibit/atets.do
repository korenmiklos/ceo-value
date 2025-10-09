*! Extract ATET estimates from Monte Carlo scenarios and write to LaTeX table row

clear all

* Define scenarios in order matching table columns
local scenarios "baseline longpanel persistent unbalanced excessvariance all"
local scenario_labels `" "Baseline" "Long Panel" "Persistent Errors" "Unbalanced Panel" "Excess Variance" "All Complications" "'

* which results to extract for the table
local row1 sqrt(Var1[1])
local row2 sqrt(dVar[1])
local row3 coef_beta1[7]
local row4 coef_dbeta[7]
local row5 coef_beta1[3]
local row6 coef_dbeta[3]

local label1 "$\sigma(\Delta \hat z)$"
local label2 "$\sigma(\Delta \hat z)$ (debiased)"
local label3 "\addlinespace$\hat \beta_2$ (OLS)"
local label4 "$\hat \beta_2$ (debiased)"
local label5 "\addlinespace$\hat \beta_{-2}$ (OLS)"
local label6 "$\hat \beta_{-2}$ (debiased)"

matrix stats = J(6, 6, .)

* Loop through scenarios and extract ATET
local col = 1
foreach scenario of local scenarios {
    
    * Import CSV file
    import delimited "data/`scenario'_TFP.csv", clear varnames(1) case(preserve)

    forvalues row = 1/6 {
        matrix stats[`row', `col'] = `row`row''
    }  
    
    local ++col
}

matrix list stats

* Open LaTeX file for writing
file open texfile using "table/atets.tex", write replace

* Function to write a row 
forvalues row = 1/6 {    
    * Set row label
    file write texfile "\\ `label`row'' & "
    forvalues i = 1/6 {
        local coef = stats[`row', `i']
        local coef_str = string(`coef', "%5.3f")
        * Write to file
        if `i' < 6 {
            file write texfile "$`coef_str'$ & "
        }
        else {
            file write texfile "$`coef_str'$"
        }
    }
}

file close texfile

* Display results for verification
display "ATET estimates written to table/atets.tex"
matrix list ols
matrix list placebo
matrix list debiased
