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

* compute p values for significance stars
local p3 2*normal(-abs((coef_beta1[7] - 1.0)/((upper_beta1[7] - coef_beta1[7]) / invnormal(0.975))))
local p4 2*normal(-abs((coef_dbeta[7] - 1.0)/((upper_dbeta[7] - coef_dbeta[7]) / invnormal(0.975))))
local p5 2*normal(-abs(coef_beta1[3]/((upper_beta1[3] - coef_beta1[3]) / invnormal(0.975))))
local p6 2*normal(-abs(coef_dbeta[3]/((upper_dbeta[3] - coef_dbeta[3]) / invnormal(0.975))))

local label1 "$\sigma(\Delta \hat z)$"
local label2 "$\sigma(\Delta \hat z)$ (debiased)"
local label3 "\addlinespace$\hat \beta_2$ (OLS)"
local label4 "$\hat \beta_2$ (debiased)"
local label5 "\addlinespace$\hat \beta_{-2}$ (OLS)"
local label6 "$\hat \beta_{-2}$ (debiased)"

matrix stats = J(6, 6, .)
matrix ps = J(6, 6, 0.99999)

* Loop through scenarios and extract ATET
local col = 1
foreach scenario of local scenarios {
    
    * Import CSV file
    import delimited "data/`scenario'_TFP.csv", clear varnames(1) case(preserve)

    forvalues row = 1/6 {
        matrix stats[`row', `col'] = `row`row''
        if "`p`row''" != "" {
            matrix ps[`row', `col'] = `p`row''
        }
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
        local stars ""
        if matrix(ps[`row', `i']) < 0.01 {
            local stars "***"
        }
        else if matrix(ps[`row', `i']) < 0.05 {
            local stars "**"
        }
        else if matrix(ps[`row', `i']) < 0.1 {
            local stars "*"
        }
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

