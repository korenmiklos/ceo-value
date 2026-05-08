*Extract atet setimates from appliation and write to LaTeX table row
args sample FE
clear all

* Define outcomes in order matching table columns
local outcomes "lnR ROA lnL lnK exporter lnWL"

* which results to extract for the table
local row1 (Cov1[2]-Cov1[1])/(Var1z1[1] + Var1z1[2])*2
local row2 (dCov1[2]-dCov1[1])/(dVarz1[1] + dVarz1[2])*2
local row3 Rsq[1]
local row4 dRsq[1]
local row5 N[1]

local label1 "ATET (OLS)"
local label2 "ATET (debiased)"
local label3 "\addlinespace $ R^2$ (OLS)"
local label4 "$ R^2$ (debiased)"
local label5 "N"

local rows 5

matrix stats = J(`rows', 6, .)
matrix ps = J(`rows', 6, 0.99999)

* Loop through outcomes and extract ATET
local col = 1
foreach outcome of local outcomes {

    * Import CSV file
    import delimited "data/atet_`sample'_`outcome'-`FE'.csv", clear varnames(1) case(preserve)

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

