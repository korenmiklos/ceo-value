*Extract atet setimates from appliation and write to LaTeX table row
args sample FE
clear all

* Define outcomes in order matching table columns
local outcomes "lnR exporter lnL lnK ROA lnRL"

local row1 Rsq[1]
local row2 dRsq[1]
local row3 N[1]

local label1 "\addlinespace $ R^2$ (OLS)"
local label2 "$ R^2$ (debiased)"
local label3 "N"

local rows 3

matrix stats = J(`rows', 6, .)

* Loop through outcomes and extract ATET
local col = 1
foreach outcome of local outcomes {

    * Import CSV file
    import delimited "data/atet_`sample'_`outcome'-`FE'.csv", clear varnames(1) case(preserve)

    forvalues row = 1/`rows' {
        matrix stats[`row', `col'] = `row`row''
    }

    local ++col
}

matrix list stats

local texheader1 "\begin{tabular}{l*{6}{c}}"
local texheader2 "\hline\hline"
local texheader3 " Estimate & lnR & Exporter & lnL & lnK & ROA & lnRL \\"
local texheader4 "\hline"

local texfooter1 "\hline\hline"
local texfooter2 "\end{tabular}"


* Open LaTeX file for writing
file open texfile using "table/r2s_`sample'_`FE'.tex", write replace
forvalues num = 1/4{
  file write texfile "`texheader`num''" _n
}

* Function to write a row
forvalues row = 1/`rows' {
    * Set row label
    file write texfile "`label`row'' & "
    forvalues i = 1/6 {
        local coef = stats[`row', `i']
        if `row' < 3 {
          local coef_str = string(`coef', "%5.3f")
        }
        else {
          local coef_str = string(`coef', "%12.0fc")
        }
        if `i' < 6 {
          file write texfile "$`coef_str'$ & "
        }
        else {
          file write texfile "$`coef_str'$ \\" _n
        }
    }
}
file write texfile "`texfooter1'" _n
file write texfile "`texfooter2'" _n

file close texfile
