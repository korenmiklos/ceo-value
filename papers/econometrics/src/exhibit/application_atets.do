*Extract atet setimates from appliation and write to LaTeX table row
args sample outcome
clear all

* Define scenarios in order matching table columns
local scenarios "lnR ROA lnL lnK exporter lnWL"

* which results to extract for the table
local row1 Rsq[7]
local row2 dRsq[7]
local row3 coef_beta1[7]
local row4 coef_dbeta[7]
local row5 coef_beta1[3]
local row6 coef_dbeta[3]
local row7 coef_beta1[9]
local row8 coef_dbeta[9]

* compute p values for significance stars
local p3 2*normal(-abs((coef_beta1[7] - 1.0)/((upper_beta1[7] - coef_beta1[7]) / invnormal(0.975))))
local p4 2*normal(-abs((coef_dbeta[7] - 1.0)/((upper_dbeta[7] - coef_dbeta[7]) / invnormal(0.975))))
local p5 2*normal(-abs(coef_beta1[3]/((upper_beta1[3] - coef_beta1[3]) / invnormal(0.975))))
local p6 2*normal(-abs(coef_dbeta[3]/((upper_dbeta[3] - coef_dbeta[3]) / invnormal(0.975))))


local label1 "\addlinespace $ R^2$ (OLS)"
local label2 "$ R^2$ (debiased)"
local label3 "\addlinespace$\hat \beta_2$ (OLS)"
local label4 "$\hat \beta_2$ (debiased)"
local label5 "\addlinespace$\hat \beta_{-2}$ (OLS)"
local label6 "$\hat \beta_{-2}$ (debiased)"
local label7 "ATET (OLS)"
local label8 "ATET (debiased)"

local rows 8

matrix stats = J(`rows', 6, .)
matrix ps = J(`rows', 6, 0.99999)

* Loop through scenarios and extract ATET
local col = 1
foreach scenario of local scenarios {

    * Import CSV file
    import delimited "data/`sample'_`scenario'-`outcome'.csv", clear varnames(1) case(preserve)

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
file open texfile using "table/atets_`sample'_`outcome'.tex", write replace
file write texfile "Estimate"
foreach scenario of local scenarios{
  file write texfile " & `scenario'"
}
* Function to write a row
forvalues row = 1/`rows' {
    * Set row label
    file write texfile "\\" _n
    file write texfile "`label`row'' & "
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

