*Extract atet setimates from appliation and write to LaTeX table row
args sample FE
clear all

* Define outcomes in order matching table columns
local outcomes "lnR exporter lnL lnK ROA lnYL"

* which results to extract for the table
local row1 Cov1[1]/Var1z1[1]
*se: sqrt(vary*(1-rsq)/((n-2)*varx))
local row2 dCov1[1]/dVarz1[1]
local row3 Rsq[1]
local row4 dRsq[1]
local row5 N[1]

local label1 "ATET (OLS)"
local label2 "ATET (debiased)"
local label3 "\addlinespace $ R^2$ (OLS)"
local label4 "$ R^2$ (debiased)"
local label5 "N"

local p1 se_naive[1]
local p2 dse[1]

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

local texheader1 "\begin{tabular}{l*{6}{c}}"
local texheader2 "\hline\hline"
local texheader3 " Estimate & lnR & export & lnL & lnK & ROA & lnYL \\"
local texheader4 "\hline"

local texfooter1 "\hline\hline"
local texfooter2 "\end{tabular}"


* Open LaTeX file for writing
file open texfile using "table/atets_`sample'_`FE'.tex", write replace
forvalues num = 1/4{
  file write texfile "`texheader`num''" _n
}

* Function to write a row
forvalues row = 1/`rows' {
    * Set row label
    file write texfile "`label`row'' & "
    forvalues i = 1/6 {
        local coef = stats[`row', `i']
        if `row' < 5 {
          local coef_str = string(`coef', "%5.3f")
        }
        else {
          local coef_str = string(`coef', "%12.0fc")
        }
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
        if `row' < 5 {
          if `i' < 6 {
            file write texfile "$`coef_str'^{`stars'}$ & "
            }
          else {
            file write texfile "$`coef_str'^{`stars'}$ \\" _n
            }
          }
        else {
          if `i' < 6 {
            file write texfile "$`coef_str'$ & "
            }
          else {
            file write texfile "$`coef_str'$ \\" _n
            }
          }
        }
}
file write texfile "`texfooter1'" _n
file write texfile "`texfooter2'" _n

file close texfile
