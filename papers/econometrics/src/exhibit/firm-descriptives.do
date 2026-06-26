clear all
use "../../temp/analysis-sample.dta"

egen max_firm_age = max(firm_age), by(frame_id_numeric)
egen spell_year_tag = tag(frame_id_numeric ceo_spell year)
egen two_ceos = max(n_ceo==2), by(frame_id_numeric)

* first collapse by ceo spell
collapse (firstnm) max_firm_age max_ceo_spell two_ceos (sum) T = spell_year_tag, by(frame_id_numeric ceo_spell)
generate nr_ceo_switches = max_ceo_spell - 1
replace ceo_spell = 4 if ceo_spell > 4

* we leave last CEO spells in the sample
forvalues ceo_num = 1/4 {
    generate ceo`ceo_num'_tenure = T if ceo_spell == `ceo_num'
}

collapse (firstnm) firm_age = max_firm_age nr_ceo_switches ceo1_tenure ceo2_tenure ceo3_tenure ceo4_tenure two_ceos, by(frame_id_numeric)
* verify there are no zero spells
forvalues ceo_num = 1/4 {
    count if ceo`ceo_num'_tenure == 0
    assert r(N) == 0
}

* Overall number of firms
count
local n_firms = r(N)
count if two_ceos
local two_ceos = r(N)/`n_firms'
count if nr_ceo_switches > 0
local ceo_switches = r(N)/`n_firms'


* Calculate percentiles for firm years
_pctile firm_age, p(25 50 75)
local row1col2 = r(r1)
local row1col3 = r(r2)
local row1col4 = r(r3)

* Calculate percentiles for CEO switches
_pctile nr_ceo_switches, p(25 50 75)
local row3col2 = r(r1)
local row3col3 = r(r2)
local row3col4 = r(r3)

* Calculate percentiles for CEO tenures (excluding last CEOs)
forvalues ceo_num = 1/4 {
    local row_num =  `ceo_num' + 1
    qui count if !missing(ceo`ceo_num'_tenure)
    if r(N) > 0 {
        _pctile ceo`ceo_num'_tenure if !missing(ceo`ceo_num'_tenure), p(25 50 75)
        local row`row_num'col2 = r(r1)
        local row`row_num'col3 = r(r2)
        local row`row_num'col4 = r(r3)
    }
    else {
        local row`row_num'col2 = .
        local row`row_num'col3 = .
        local row`row_num'col4 = .
    }
}

local rows = 8

matrix stats = J(`rows', 4, .)
matrix colnames stats = "Statistic" "P25" "P50" "P75"

forvalues row = 2/5{
   forvalues col = 2/4{
    matrix stats[`row', `col'] = `row`row'col`col''
  }
}

* Row 6: % of firms that ever had 2 ceos in one year
matrix stats[6, 2] = `two_ceos'
matrix stats[6, 3] = .
matrix stats[6, 4] = .

* Row 7: % of firms with ceo switches
matrix stats[7, 2] = `ceo_switches'
matrix stats[7, 3] = .
matrix stats[7, 4] = .

* Row 8: Number of firms
matrix stats[8, 2] = `n_firms'
matrix stats[8, 3] = .
matrix stats[8, 4] = .

local texheader1 "\begin{tabular}{l*{3}{c}}"
local texheader2 "\hline\hline"
local texheader3 "Statistic & P25 & P50 & P75 \\"
local texheader4 "\hline"

local texfooter1 "\hline\hline"
local texfooter2 "\end{tabular}"

file open texfile using "table/firm-descriptives.tex", write replace
forvalues num = 1/4{
  file write texfile "`texheader`num''" _n
}


local label1 "Firm max age"
local label2 "1st CEO tenure"
local label3 "2nd CEO tenure"
local label4 "3rd CEO tenure"
local label5 "4th or higher CEO tenure"
local label6 "% of firms with 2 CEOs"
local label7 "% of firms with CEO switches"
local label8 "Nr. of Firms"

forvalues row = 1/`rows' {
  file write texfile "`label`row'' & "
  forvalues col = 2/4{
    local stat = stats[`row',`col']
    local stat_str = string(`stat', "%9.2f")
    if `col' < 4{
      file write texfile "$`stat_str'$ & "
    }
    else {
      file write texfile "$`stat_str'$ \\" _n
    }
  }
}
file write texfile "`texfooter1'" _n
file write texfile "`texfooter2'" _n

file close texfile
