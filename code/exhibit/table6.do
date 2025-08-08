*! Create Exhibit 6: CEO Patterns and Spell Length Analysis
*! Panel A: CEO patterns per firm-year and firm
*! Panel B: CEO spell length distribution (actual vs placebo)

local max_spell_analysis = 2

use "temp/balance.dta", clear
merge 1:m frame_id_numeric year using "temp/ceo-panel.dta", keep(master match) nogen

* Apply industry classification
do "code/util/industry.do"
do "code/util/variables.do"

* =============================================================================
* PANEL A: CEO PATTERNS ANALYSIS  
* =============================================================================

* Column 1: CEOs per firm-year analysis
preserve
    egen firm_year_tag = tag(frame_id_numeric year)
    keep if firm_year_tag

    * n_ceo already exists, don't recompute it
    recode n_ceo 4/max = 4

    * Generate statistics
    tempfile panel_a_col1
    collapse (count) n_obs = frame_id_numeric, by(n_ceo)
    generate total_obs = sum(n_obs)
    generate pct = round(n_obs / total_obs[_N] * 100)
    save `panel_a_col1'
restore

* Column 2: CEO spells per firm analysis  
preserve
    egen firm_tag = tag(frame_id_numeric)
    keep if firm_tag

    * max_ceo_spell already exists, don't recompute it
    recode max_ceo_spell (4/max = 4)

    * Generate statistics
    tempfile panel_a_col2
    collapse (count) n_firms = frame_id_numeric, by(max_ceo_spell)
    generate total_firms = sum(n_firms)
    generate pct = round(n_firms / total_firms[_N] * 100)
    save `panel_a_col2'
restore

* =============================================================================
* PANEL B: SPELL LENGTH ANALYSIS
* =============================================================================
preserve
    keep if ceo_spell <= `max_spell_analysis'
    keep if max_ceo_spell >= `max_spell_analysis'

    egen spell_tag = tag(frame_id_numeric ceo_spell)
    egen spell_year_tag = tag(frame_id_numeric ceo_spell year)
    egen T_spell = total(spell_year_tag), by(frame_id_numeric ceo_spell)
    keep if spell_tag 

    recode T_spell (4/max = 4)

    tempfile panel_b_col1
    collapse (count) n_spells = frame_id_numeric, by(T_spell)
    generate total_spells = sum(n_spells)
    generate pct = round(n_spells / total_spells[_N] * 100)
    save `panel_b_col1'
restore

* Placebo spell length analysis - merge placebo data with main data
merge m:1 frame_id_numeric year using "temp/placebo.dta", keep(match) nogen
preserve
    keep if !missing(placebo_spell)
    egen spell_tag = tag(frame_id_numeric placebo_spell)
    egen spell_year_tag = tag(frame_id_numeric placebo_spell year)
    egen T_spell = total(spell_year_tag), by(frame_id_numeric placebo_spell)
    keep if spell_tag

    recode T_spell 4/max = 4

    tempfile panel_b_col2
    collapse (count) n_spells = frame_id_numeric, by(T_spell)
    generate total_spells = sum(n_spells)
    generate pct = round(n_spells / total_spells[_N] * 100)
    save `panel_b_col2'
restore

* =============================================================================
* CREATE LATEX TABLES - SEPARATE PANELS
* =============================================================================

* Write Panel A LaTeX table
file open panelA using "output/table/table6_panelA.tex", write replace text

file write panelA "\begin{tabular}{lcc}" _n
file write panelA "\toprule" _n
file write panelA "CEOs & Firm-Year & Firm \\" _n
file write panelA "\midrule" _n

* Panel A data
use `panel_a_col1', clear
local N1 = _N
use `panel_a_col2', clear
local N2 = _N

forvalues i = 1/`=max(`N1',`N2')' {
    local row_label = cond(`i' <= 3, "`i'", "4+")
    
    * Get column 1 data
    use `panel_a_col1', clear
    local col1_pct ""
    local col1_obs ""
    if `i' <= `N1' {
        local col1_pct = pct[`i']
        local col1_obs = n_obs[`i']
    }
    
    * Get column 2 data  
    use `panel_a_col2', clear
    local col2_pct ""
    local col2_obs ""
    if `i' <= `N2' {
        local col2_pct = pct[`i']
        local col2_obs = n_firms[`i']
    }
    
    if "`col1_pct'" != "" | "`col2_pct'" != "" {
        file write panelA "`row_label' & `col1_pct'\% & `col2_pct'\% \\" _n
    }
}

* Panel A totals
use `panel_a_col1', clear
local total_firm_years = total_obs[_N]
use `panel_a_col2', clear  
local total_firms = total_firms[_N]

file write panelA "Total & " %12.0fc (`total_firm_years') " & " %12.0fc (`total_firms') " \\" _n
file write panelA "\bottomrule" _n
file write panelA "\end{tabular}" _n

file close panelA

* Write Panel B LaTeX table
file open panelB using "output/table/table6_panelB.tex", write replace text

file write panelB "\begin{tabular}{lcc}" _n
file write panelB "\toprule" _n
file write panelB "Length & Actual & Placebo \\" _n
file write panelB "(Years) & Spells & Spells \\" _n
file write panelB "\midrule" _n

* Panel B data - write rows by combining the two datasets
use `panel_b_col1', clear
local N1 = _N
use `panel_b_col2', clear  
local N2 = _N

forvalues i = 1/`=max(`N1',`N2')' {
    local row_label = cond(`i' <= 3, "`i'", "4+")
    
    * Get actual data
    use `panel_b_col1', clear
    local actual_pct ""
    if `i' <= `N1' {
        local actual_pct = pct[`i']
    }
    
    * Get placebo data  
    use `panel_b_col2', clear
    local placebo_pct ""
    if `i' <= `N2' {
        local placebo_pct = pct[`i']
    }
    
    if "`actual_pct'" != "" | "`placebo_pct'" != "" {
        file write panelB "`row_label' & `actual_pct'\% & `placebo_pct'\% \\" _n
    }
}

* Panel B totals  
use `panel_b_col1', clear
local total_actual = total_spells[_N]
use `panel_b_col2', clear
local total_placebo = total_spells[_N]
file write panelB "Total & " %12.0fc (`total_actual') " & " %12.0fc (`total_placebo') " \\" _n

file write panelB "\bottomrule" _n
file write panelB "\end{tabular}" _n

file close panelB

display "Exhibit 6 panels created: output/table/table6_panelA.tex and output/table/table6_panelB.tex"