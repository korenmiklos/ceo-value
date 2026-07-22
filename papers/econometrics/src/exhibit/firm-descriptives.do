clear all
use "../../temp/analysis-sample.dta"

egen max_firm_age = max(firm_age), by(frame_id_numeric)
egen spell_year_tag = tag(frame_id_numeric ceo_spell year)
egen two_ceos = max(n_ceo==2), by(frame_id_numeric)

* first collapse by ceo spell
collapse (firstnm) max_firm_age max_ceo_spell two_ceos (sum) T = spell_year_tag, by(frame_id_numeric ceo_spell)
generate nr_ceo_switches = max_ceo_spell - 1
generate ceo_switch_at_least = max_ceo_spell - 1 if max_ceo_spell > 1
replace ceo_spell = 4 if ceo_spell > 4

* we leave last CEO spells in the sample
forvalues ceo_num = 1/4 {
    generate ceo`ceo_num'_tenure = T if ceo_spell == `ceo_num'
}

collapse (firstnm) firm_age = max_firm_age nr_ceo_switches ceo1_tenure ceo2_tenure ceo3_tenure ceo4_tenure two_ceos ceo_switch_at_least, by(frame_id_numeric)

* Calculate percentiles for CEO tenures (excluding last CEOs)
forvalues ceo_num = 1/4 {
    local row_num =  `ceo_num'
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

local rows = 4

matrix stats = J(`rows', 4, .)
matrix colnames stats = "Statistic" "P25" "P50" "P75"

forvalues row = 1/`rows'{
   forvalues col = 2/4{
    matrix stats[`row', `col'] = `row`row'col`col''
  }
}

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


local label1 "1st CEO tenure"
local label2 "2nd CEO tenure"
local label3 "3rd CEO tenure"
local label4 "4th or higher CEO tenure"

forvalues row = 1/`rows' {
  file write texfile "`label`row'' & "
  forvalues col = 2/4{
    local stat = stats[`row',`col']
    local stat_str = string(`stat', "%9.0f")
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
