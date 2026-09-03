args variation
*Extract atet setimates from appliation and write to LaTeX table rows
clear all

* Define outcomes in order matching table columns
local outcomes "lnR lnL lnK ROA lnRL"
if "`variation'" == "size4"{
  local samples "one2one twos fnd2non non2non gender nogender gap"
}
else{
  local samples "one2one twos fnd2non non2non gender nogender gap nogap"
}

local rows 8

local label1  "One-to-One"
local label2  "Twos"
local label3  "Founder-to-Non"
local label4  "Non-to-Non"
local label5  "Gender switch"
local label6  "No gender switch"
local label7  "Age gap"
local label8  "No age gap"

matrix stats = J(`rows', 6, .)

* Loop through outcomes and extract ATET
local row = 1
foreach sample of local samples {
  local col = 1
  foreach outcome of local outcomes{
      * Import CSV file
      import delimited "data/atet_`variation'_`sample'_`outcome'-`outcome'.csv", clear varnames(1) case(preserve)
      matrix stats[`row', `col'] = dRsq[1]
      local ++col
    }
    matrix stats[`row', `col'] = N[1]
    local ++row
}

matrix list stats

local texheader1 "\begin{tabular}{l*{5}{c}}"
local texheader2 "\hline\hline"
local texheader3 "Samples & lnR & lnL & lnK & ROA & lnRL & N \\"
local texheader4 "\hline"

local texfooter1 "\hline\hline"
local texfooter2 "\end{tabular}"


* Open LaTeX file for writing
file open texfile using "table/`variation'_debiased_r2s.tex", write replace
forvalues num = 1/4{
  file write texfile "`texheader`num''" _n
}

* Function to write a row
forvalues row = 1/`rows' {
    * Set row label
    file write texfile "`label`row'' & "
    forvalues i = 1/6 {
        local coef = stats[`row', `i']
        if `i' < 6 {
          local coef_str = string(`coef', "%5.3f")
          file write texfile "$`coef_str'$ & "
        }
        else {
          local coef_str = string(`coef', "%5.0f")
          file write texfile "$`coef_str'$ \\" _n
        }
    }
}
file write texfile "`texfooter1'" _n
file write texfile "`texfooter2'" _n

file close texfile
