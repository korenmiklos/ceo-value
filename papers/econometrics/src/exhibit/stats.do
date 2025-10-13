*! Extract ATET estimates from Monte Carlo scenarios and write to LaTeX table row

clear all

* Define scenarios in order matching table columns
local scenarios "full_lnR full_exporter"
local scenario_labels `" "Revenue" "Exporter" "'

* which results to extract for the table
local row1 sqrt(Var1[1])
local row2 sqrt(dVar[1])
local row3 Rsq1[7]
local row4 dRsq[7]
local row5 coef_beta1[7]
local row6 coef_dbeta[7]
local row7 coef_beta1[3]
local row8 coef_dbeta[3]

* compute p values for significance stars
local p5 2*normal(-abs((coef_beta1[7] - 1.0)/((upper_beta1[7] - coef_beta1[7]) / invnormal(0.975))))
local p6 2*normal(-abs((coef_dbeta[7] - 1.0)/((upper_dbeta[7] - coef_dbeta[7]) / invnormal(0.975))))
local p7 2*normal(-abs(coef_beta1[3]/((upper_beta1[3] - coef_beta1[3]) / invnormal(0.975))))
local p8 2*normal(-abs(coef_dbeta[3]/((upper_dbeta[3] - coef_dbeta[3]) / invnormal(0.975))))

local label1 "$\sigma(\Delta \hat z)$ (OLS)"
local label2 "$\sigma(\Delta \hat z)$ (debiased)"
local label3 "\addlinespace $ R^2$ (OLS)"
local label4 "$ R^2$ (debiased)"
local label5 "\addlinespace$\hat \beta_2$ (OLS)"
local label6 "$\hat \beta_2$ (debiased)"
local label7 "\addlinespace$\hat \beta_{-2}$ (OLS)"
local label8 "$\hat \beta_{-2}$ (debiased)"

matrix stats = J(8, 2, .)
matrix ps = J(8, 2, 0.99999)

* Loop through scenarios and extract ATET
local col = 1
foreach scenario of local scenarios {
    
    * Import CSV file
    import delimited "data/`scenario'.csv", clear varnames(1) case(preserve)

    forvalues row = 1/8 {
        matrix stats[`row', `col'] = `row`row''
        if "`p`row''" != "" {
            matrix ps[`row', `col'] = `p`row''
        }
    }  
    
    local ++col
}

matrix list stats

* Open LaTeX file for writing
file open texfile using "table/stats.tex", write replace

* Function to write a row 
forvalues row = 1/8 {    
    * Set row label
    file write texfile "\\ `label`row'' & "
    forvalues i = 1/2 {
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
        if `i' < 2 {
            file write texfile "$`coef_str'^{`stars'}$ & "
        }
        else {
            file write texfile "$`coef_str'^{`stars'}$"
        }
    }
}

file close texfile

