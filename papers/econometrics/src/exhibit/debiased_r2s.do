*Extract atet setimates from appliation and write to LaTeX table rows
clear all

* Define outcomes in order matching table columns
local outcomes "lnR lnL lnK ROA lnRL"
local samples "full one2one twos fnd2non non2non gender nogender gap nogap"

local rows 9

local label1 "Full"
local label2 "One-to-One"
local label3 "Twos"
local label4 "Founder-to-Non"
local label5 "Non-to-Non"
local label6 "Gender switch"
local label7 "No gender switch"
local label8 "Age gap"
local label9 "No age gap"

matrix stats = J(`rows', 5, .)

* Loop through outcomes and extract ATET
local col = 1
foreach outcome of local outcomes {
  local row = 1
  foreach sample of local samples{
      * Import CSV file
      import delimited "data/atet_`sample'_`outcome'-lnR.csv", clear varnames(1) case(preserve)
      matrix stats[`row', `col'] = dRsq[1]
      local ++row
    }
    local ++col
}

matrix list stats

local texheader1 "\begin{tabular}{l*{5}{c}}"
local texheader2 "\hline\hline"
local texheader3 "Samples & lnR & lnL & lnK & ROA & lnRL \\"
local texheader4 "\hline"

local texfooter1 "\hline\hline"
local texfooter2 "\end{tabular}"


* Open LaTeX file for writing
file open texfile using "table/debiased_r2s.tex", write replace
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
