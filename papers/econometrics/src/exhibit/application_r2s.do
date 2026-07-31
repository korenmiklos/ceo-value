*Extract atet setimates from appliation and write to LaTeX table row
args sample
clear all

* Define outcomes in order matching table columns
local outcomes "lnR lnL lnK ROA lnRL"

local row1 Rsq[1]
local row2 dRsq[1]

local label1 "\addlinespace $ R^2$ (OLS)"
local label2 "$ R^2$ (debiased)"

local rows 2

matrix stats = J(`rows', 6, .)

* Loop through outcomes and extract ATET
local col = 1
foreach outcome of local outcomes {

    * Import CSV file
    import delimited "data/atet_`sample'_`outcome'-`outcome'.csv", clear varnames(1) case(preserve)

    forvalues row = 1/`rows'{
        matrix stats[`row', `col'] = `row`row''
    }

    local ++col
}

matrix list stats

local texheader1 "\begin{tabular}{l*{5}{c}}"
local texheader2 "\hline\hline"
local texheader3 " Estimate & lnR & lnL & lnK & ROA & lnRL \\"
local texheader4 "\hline"

local texfooter1 "\hline\hline"
local texfooter2 "\end{tabular}"


* Open LaTeX file for writing
file open texfile using "table/r2s_`sample'.tex", write replace
forvalues num = 1/4{
  file write texfile "`texheader`num''" _n
}

* Function to write a row
forvalues row = 1/`rows' {
    * Set row label
    file write texfile "`label`row'' & "
    forvalues i = 1/5 {
        local coef = stats[`row', `i']
        local coef_str = string(`coef', "%5.3f")
        if `i' < 5 {
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
