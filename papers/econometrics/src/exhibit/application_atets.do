*Extract atet setimates from appliation and write to LaTeX table row
args sample FE
clear all

* Define outcomes in order matching table columns
local outcomes "lnR ROA lnL lnK exporter lnWL"

* which results to extract for the table
local row1 (coef_beta1[5] + coef_beta1[6] + coef_beta1[7] + coef_beta1[8])/4 - (coef_beta1[3] + coef_beta1[2] + coef_beta1[1])/3
local row2 (coef_dbeta[5] + coef_dbeta[6] + coef_dbeta[7] + coef_dbeta[8])/4 - (coef_beta1[3] + coef_beta1[2] + coef_beta1[1])/3
local row3 Rsq[7]
local row4 dRsq[7]

local label1 "ATET (OLS)"
local label2 "ATET (debiased)"
local label3 "\addlinespace $ R^2$ (OLS)"
local label4 "$ R^2$ (debiased)"

local rows 4

matrix stats = J(`rows', 6, .)
matrix ps = J(`rows', 6, 0.99999)

* Loop through outcomes and extract ATET
local col = 1
foreach outcome of local outcomes {

    * Import CSV file
    import delimited "data/`sample'_`outcome'-`FE'.csv", clear varnames(1) case(preserve)

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
file open texfile using "table/atets_`sample'_`FE'.tex", write replace
file write texfile "Estimate"
foreach outcome of local outcomes{
  file write texfile " & `outcome'"
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

