clear all
use "../../temp/analysis-sample.dta"

egen max_firm_age = max(firm_age), by(frame_id_numeric)

egen spell_year_tag = tag(frame_id_numeric ceo_spell year)

* first collapse by ceo spell
collapse (firstnm) max_firm_age max_ceo_spell (sum) T = spell_year_tag, by(frame_id_numeric ceo_spell)
generate nr_ceo_switches = max_ceo_spell - 1

* we leave last CEO spells in the sample
forvalues ceo_num = 1/4 {
    generate ceo`ceo_num'_tenure = T if ceo_spell == `ceo_num'
}

collapse (firstnm) firm_age = max_firm_age nr_ceo_switches ceo1_tenure ceo2_tenure ceo3_tenure ceo4_tenure, by(frame_id_numeric)
* veriy there are no zero spells
forvalues ceo_num = 1/4 {
    count if ceo`ceo_num'_tenure == 0
    assert r(N) == 0
}

* Overall number of firms
count
local n_firms = r(N)

* Calculate percentiles for firm years
_pctile firm_age, p(25 50 75)
local row2col2 = r(r1)
local row2col3 = r(r2)
local row2col4 = r(r3)

* Calculate percentiles for CEO switches
_pctile nr_ceo_switches, p(25 50 75)
local row3col2 = r(r1)
local row3col3 = r(r2)
local row3col4 = r(r3)

* Calculate percentiles for CEO tenures (excluding last CEOs)
forvalues ceo_num = 1/4 {
    local row_num =  `ceo_num' + 3
    qui count if !missing(ceo`ceo_num'_tenure)
    if r(N) > 0 {
        * FIXME: also compute weighted percentiles
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

local rows = 7

matrix stats = J(`rows', 4, .)
matrix colnames stats = "Statistic" "P25" "P50" "P75"


* Row 1: Number of firms
matrix stats[1, 2] = `n_firms'
matrix stats[1, 3] = .
matrix stats[1, 4] = .

forvalues row = 2/`rows'{
   forvalues col = 2/4{
    matrix stats[`row', `col'] = `row`row'col`col''
  }
}

file open texfile using "table/firm-descriptives.tex", write replace

local label1 "Nr. of Firms"
local label2 "Lived years"
local label3 "Nr of CEO switches"
local label4 "Years with 1st CEO"
local label5 "Years with 2nd CEO"
local label6 "Years with 3rd CEO"
local label7 "Years with 4th CEO"

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

file close texfile
