*! Create Exhibit 6: CEO Patterns and Spell Length Analysis
*! Panel A: CEO patterns per firm-year and firm
*! Panel B: CEO spell length distribution (actual vs placebo)

use "temp/analysis-sample.dta", clear

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
    egen spell_tag = tag(frame_id_numeric ceo_spell)
    egen T_spell = total(1), by(frame_id_numeric ceo_spell)
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
    egen T_spell = total(1), by(frame_id_numeric placebo_spell)
    keep if spell_tag 

    recode T_spell 4/max = 4

    tempfile panel_b_col2
    collapse (count) n_spells = frame_id_numeric, by(T_spell)
    generate total_spells = sum(n_spells)
    generate pct = round(n_spells / total_spells[_N] * 100)
    save `panel_b_col2'
restore

* =============================================================================
* CREATE LATEX TABLE
* =============================================================================

* Write LaTeX table
file open table using "output/table/table6.tex", write replace text

file write table "\begin{table}[htbp]" _n
file write table "\centering" _n
file write table "\caption{CEO Patterns and Spell Length Analysis}" _n
file write table "\label{tab:ceo_patterns}" _n
file write table "\begin{tabular}{lcc}" _n
file write table "\toprule" _n

* Panel A header
file write table "\multicolumn{3}{l}{\textbf{Panel A: CEO Patterns}} \\" _n
file write table " & CEOs per & CEO Spells per \\" _n
file write table " & Firm-Year & Firm \\" _n
file write table "\midrule" _n

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
        file write table "`row_label' & `col1_pct'\% & `col2_pct'\% \\" _n
    }
}

* Panel A totals
use `panel_a_col1', clear
local total_firm_years = total_obs[_N]
use `panel_a_col2', clear  
local total_firms = total_firms[_N]

file write table "Total & " %12.0fc (`total_firm_years') " & " %12.0fc (`total_firms') " \\" _n
file write table "\midrule" _n

* Panel B header
file write table "\multicolumn{3}{l}{\textbf{Panel B: CEO Spell Length Distribution}} \\" _n
file write table "Spell Length (Years) & Actual Spells & Placebo Spells \\" _n
file write table "\midrule" _n

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
        file write table "`row_label' & `actual_pct'\% & `placebo_pct'\% \\" _n
    }
}

* Panel B totals  
use `panel_b_col1', clear
local total_actual = total_spells[_N]
use `panel_b_col2', clear
local total_placebo = total_spells[_N]
file write table "Total & " %12.0fc (`total_actual') " & " %12.0fc (`total_placebo') " \\" _n

file write table "\bottomrule" _n
file write table "\end{tabular}" _n

* Table notes
file write table "\begin{tablenotes}[flushleft]" _n
file write table "\footnotesize" _n
file write table "\item \textbf{Panel A} reports the distribution of CEOs at firms. Column 1 shows the percentage of firm-year observations with 1, 2, 3, or 4+ CEOs. Column 2 shows the percentage of firms with 1, 2, 3, or 4+ CEO spells over the sample period." _n
file write table "\item \textbf{Panel B} reports the distribution of CEO spell lengths. Actual spells are computed from the administrative data (1992-2022). Placebo spells follow an exponential distribution with the same transition probability as actual CEO changes, but exclude periods of actual CEO transitions." _n
file write table "\item A CEO spell is defined as a continuous period of employment by the same person at the same firm. Spell length is measured in years." _n
file write table "\item Sample includes Hungarian firms with complete balance sheet and CEO data. Firms with more than 6 CEO spells are excluded from the analysis sample." _n
file write table "\item Percentages are rounded to whole numbers. Total observations reported in bottom rows." _n
file write table "\end{tablenotes}" _n
file write table "\end{table}" _n

file close table

display "Exhibit 6 table created: output/table/table6.tex"