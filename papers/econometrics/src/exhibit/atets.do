*! Extract ATET estimates from Monte Carlo scenarios and write to LaTeX table row

clear all

* Define scenarios in order matching table columns
local scenarios "baseline longpanel persistent unbalanced excessvariance all"
local scenario_labels `" "Baseline" "Long Panel" "Persistent Errors" "Unbalanced Panel" "Excess Variance" "All Complications" "'

* Initialize matrices to store results for three rows
matrix ols = J(1, 6, .)
matrix ols_lower = J(1, 6, .)
matrix ols_upper = J(1, 6, .)

matrix placebo = J(1, 6, .)
matrix placebo_lower = J(1, 6, .)
matrix placebo_upper = J(1, 6, .)

matrix debiased = J(1, 6, .)
matrix debiased_lower = J(1, 6, .)
matrix debiased_upper = J(1, 6, .)

* Loop through scenarios and extract ATET
local col = 1
foreach scenario of local scenarios {
    
    * Import CSV file
    import delimited "data/`scenario'_TFP.csv", clear varnames(1)
    
    * Extract ATET row (t==99)
    keep if xvar == "ATET"
    list
    
    * Store OLS (treated group beta1)
    matrix ols[1, `col'] = coef_beta1[1]
    matrix ols_lower[1, `col'] = lower_beta1[1]
    matrix ols_upper[1, `col'] = upper_beta1[1]
    
    * Store Placebo (control group beta0)
    matrix placebo[1, `col'] = coef_beta0[1]
    matrix placebo_lower[1, `col'] = lower_beta0[1]
    matrix placebo_upper[1, `col'] = upper_beta0[1]
    
    * Store Debiased (dbeta)
    matrix debiased[1, `col'] = coef_dbeta[1]
    matrix debiased_lower[1, `col'] = lower_dbeta[1]
    matrix debiased_upper[1, `col'] = upper_dbeta[1]
    
    local ++col
}

matrix list ols
matrix list placebo
matrix list debiased

* Open LaTeX file for writing
file open texfile using "table/atets.tex", write replace

* Function to write a row with significance stars
foreach row in "ols" "placebo" "debiased" {
    
    * Set row label
    if "`row'" == "ols" {
        file write texfile "OLS & "
    }
    else if "`row'" == "placebo" {
        file write texfile "\\ Placebo & "
    }
    else {
        file write texfile "\\ Debiased & "
    }
    
    forvalues i = 1/6 {
        
        local coef = `row'[1, `i']
        local lower = `row'_lower[1, `i']
        local upper = `row'_upper[1, `i']
        local se = (`upper' - `lower') / (2 * invnormal(0.975))
        * test relative to 1.0
        local p_value = 2 * (1 - normal(abs((`coef' - 1.0)/`se')))
        
        * Determine significance level (test if CI excludes 1.0)
        local stars ""
        if (`p_value' < 0.10) {
            local stars "`stars'*"
        }
        if (`p_value' < 0.05) {
            local stars "`stars'*"
        }
        if (`p_value' < 0.01) {
            local stars "`stars'*"
        }

        local coef_str = string(`coef', "%5.3f")

        * Write to file
        if `i' < 6 {
            file write texfile "$`coef_str'^{`stars'}$ & "
        }
        else {
            file write texfile "$`coef_str'^{`stars'}$"
        }
    }
}

file close texfile

* Display results for verification
display "ATET estimates written to table/atets.tex"
matrix list ols
matrix list placebo
matrix list debiased
