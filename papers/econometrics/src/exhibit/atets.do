*! Extract ATET estimates from Monte Carlo scenarios and write to LaTeX table row

clear all

* Define scenarios in order matching table columns
local scenarios "baseline longpanel persistent unbalanced excessvariance all"
local scenario_labels `" "Baseline" "Long Panel" "Persistent Errors" "Unbalanced Panel" "Excess Variance" "All Complications" "'

* which results to extract for the table
local row1 Var1[1]
local row2 dVar[1]
local row3 coef_Cov1[7]
local row4 coef_dCov[7]
local row5 Rsq1[7]
local row6 dRsq[7]
local row7 coef_beta1[7]
local row8 coef_dbeta[7]
local row9 coef_beta1[3]
local row10 coef_dbeta[3]

* compute p values for significance stars
local p7 2*normal(-abs((coef_beta1[7] - 1.0)/((upper_beta1[7] - coef_beta1[7]) / invnormal(0.975))))
local p8 2*normal(-abs((coef_dbeta[7] - 1.0)/((upper_dbeta[7] - coef_dbeta[7]) / invnormal(0.975))))
local p9 2*normal(-abs(coef_beta1[3]/((upper_beta1[3] - coef_beta1[3]) / invnormal(0.975))))
local p10 2*normal(-abs(coef_dbeta[3]/((upper_dbeta[3] - coef_dbeta[3]) / invnormal(0.975))))

local label1 "$\sigma^2(\Delta \hat z)$ (OLS)"
local label2 "$\sigma^2(\Delta \hat z)$ (debiased)"
local label3 "\addlinespace $ \mathrm{Cov}(\Delta y_2, \Delta \hat z)$ (OLS)"
local label4 "$ \mathrm{Cov}(\Delta y_2, \Delta \hat z)$ (debiased)"

local label5 "\addlinespace $ R^2$ (OLS)"
local label6 "$ R^2$ (debiased)"
local label7 "\addlinespace$\hat \beta_2$ (OLS)"
local label8 "$\hat \beta_2$ (debiased)"
local label9 "\addlinespace$\hat \beta_{-2}$ (OLS)"
local label10 "$\hat \beta_{-2}$ (debiased)"

local rows 10

matrix stats = J(`rows', 6, .)
matrix ps = J(`rows', 6, 0.99999)

* Loop through scenarios and extract ATET
local col = 1
foreach scenario of local scenarios {
    
    * Import CSV file
    import delimited "data/`scenario'_lnR.csv", clear varnames(1) case(preserve)

    forvalues row = 1/`rows' {
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
forvalues row = 1/`rows' {    
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

