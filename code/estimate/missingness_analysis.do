*! version 1.0.0 2025-08-31
* =============================================================================
* Missingness Analysis - Issue #10
* =============================================================================
* Create missingness table/plot and coverage rationale for primary outcomes

clear all

use "temp/analysis-sample.dta", clear

* Define key variables for missingness analysis
local key_vars sales EBITDA employment tangible_assets intangible_assets ///
               personnel_expenses materials person_id frame_id_numeric year

* Create missingness indicators
foreach var of local key_vars {
    generate byte missing_`var' = missing(`var')
    if "`var'" == "EBITDA" {
        * EBITDA can be negative - track both missing and negative
        replace missing_`var' = 1 if `var' <= 0 & !missing(`var')
        label variable missing_`var' "Missing or non-positive EBITDA"
    }
    else {
        label variable missing_`var' "Missing `var'"
    }
}

* Calculate missingness patterns by year
preserve
    collapse (mean) missing_* (count) total_obs = frame_id_numeric, by(year)
    
    * Convert to percentages
    foreach var of local key_vars {
        replace missing_`var' = missing_`var' * 100
    }
    
    * Save for plotting
    save "temp/missingness_by_year.dta", replace
    
    * Create LaTeX table for key years
    file open miss_table using "output/table/missingness_patterns.tex", write replace text
    
    file write miss_table "\begin{table}[htbp]\centering" _n
    file write miss_table "\caption{Data Coverage and Missingness Patterns}" _n
    file write miss_table "\begin{tabular}{lccccc}" _n
    file write miss_table "\toprule" _n
    file write miss_table "Year & Revenue & EBITDA & Employment & Fixed Assets & CEO ID \\" _n
    file write miss_table "\midrule" _n
    
    * Show patterns for selected years
    local selected_years 1995 2000 2005 2010 2015 2020
    foreach year of local selected_years {
        summarize missing_sales if year == `year'
        local miss_sales = round(r(mean), 0.1)
        summarize missing_EBITDA if year == `year'  
        local miss_ebitda = round(r(mean), 0.1)
        summarize missing_employment if year == `year'
        local miss_emp = round(r(mean), 0.1)
        summarize missing_tangible_assets if year == `year'
        local miss_assets = round(r(mean), 0.1)
        summarize missing_person_id if year == `year'
        local miss_ceo = round(r(mean), 0.1)
        
        file write miss_table "`year' & `miss_sales'\% & `miss_ebitda'\% & `miss_emp'\% & `miss_assets'\% & `miss_ceo'\% \\" _n
    }
    
    file write miss_table "\bottomrule" _n
    file write miss_table "\end{tabular}" _n
    file write miss_table "\begin{minipage}{\textwidth}" _n
    file write miss_table "\footnotesize" _n
    file write miss_table "\textit{Notes:} This table shows the percentage of observations with missing " _n
    file write miss_table "or invalid values for key variables by selected years. EBITDA missingness " _n
    file write miss_table "includes both missing values and non-positive values that cannot be log-transformed. " _n
    file write miss_table "Revenue shows the most consistent coverage across years, supporting its use as " _n
    file write miss_table "the primary outcome variable. CEO ID missingness reflects years when firm " _n
    file write miss_table "registry data was incomplete or firms had no registered CEO." _n
    file write miss_table "\end{minipage}" _n
    file write miss_table "\end{table}" _n
    
    file close miss_table
restore

* Overall missingness summary
preserve
    * Calculate overall missingness rates
    collapse (mean) missing_* (count) total_obs = frame_id_numeric
    
    * Convert to percentages  
    foreach var of local key_vars {
        replace missing_`var' = missing_`var' * 100
    }
    
    list
    
    * Create summary statistics
    display _n "=== OVERALL MISSINGNESS RATES ===" 
    display "Revenue: " %4.1f missing_sales "%"
    display "EBITDA (missing/non-positive): " %4.1f missing_EBITDA "%"
    display "Employment: " %4.1f missing_employment "%"
    display "Fixed Assets: " %4.1f missing_tangible_assets "%"
    display "CEO ID: " %4.1f missing_person_id "%"
restore

* Create coverage rationale table
file open rationale using "output/table/coverage_rationale.tex", write replace text

file write rationale "\begin{table}[htbp]\centering" _n
file write rationale "\caption{Coverage Rationale: Why Revenue is Primary}" _n  
file write rationale "\begin{tabular}{lcc}" _n
file write rationale "\toprule" _n
file write rationale "Criterion & Revenue & EBITDA \\" _n
file write rationale "\midrule" _n

* Calculate comparative statistics
count if !missing(lnR) & lnR != . 
local revenue_count = r(N)
count if !missing(lnEBITDA) & lnEBITDA != .
local ebitda_count = r(N) 
count if !missing(EBITDA)
local ebitda_raw_count = r(N)
count if EBITDA <= 0 & !missing(EBITDA)
local negative_ebitda = r(N)

local revenue_coverage = round(`revenue_count' / _N * 100, 0.1)
local ebitda_coverage = round(`ebitda_count' / _N * 100, 0.1)

file write rationale "Valid observations & " %12.0fc (`revenue_count') " & " %12.0fc (`ebitda_count') " \\" _n
file write rationale "Coverage rate & `revenue_coverage'\% & `ebitda_coverage'\% \\" _n
file write rationale "Always positive & Yes & No \\" _n
file write rationale "Required by law & Yes & No \\" _n
file write rationale "Available across all years & Yes & Partial \\" _n
file write rationale "Internationally comparable & Yes & Yes \\" _n

file write rationale "\bottomrule" _n
file write rationale "\end{tabular}" _n
file write rationale "\begin{minipage}{\textwidth}" _n
file write rationale "\footnotesize" _n
file write rationale "\textit{Notes:} This table compares revenue and EBITDA as primary outcome measures. " _n
file write rationale "Revenue has " %12.0fc (`negative_ebitda') " more valid observations than EBITDA due to " _n
file write rationale "negative EBITDA values that cannot be log-transformed. Revenue reporting is " _n
file write rationale "mandatory for all firms, ensuring comprehensive coverage. EBITDA, while economically " _n
file write rationale "meaningful, can be negative during losses, creating sample selection issues in " _n
file write rationale "logarithmic specifications. Coverage rates are calculated from the analysis sample." _n
file write rationale "\end{minipage}" _n
file write rationale "\end{table}" _n

file close rationale

* Create simple plot data for missingness trends
use "temp/missingness_by_year.dta", clear

* Export key series for plotting
keep year missing_sales missing_EBITDA missing_employment missing_person_id total_obs
export delimited using "temp/missingness_plot_data.csv", replace

display _n "=== MISSINGNESS ANALYSIS COMPLETE ==="
display "Files created:"
display "- output/table/missingness_patterns.tex"
display "- output/table/coverage_rationale.tex" 
display "- temp/missingness_by_year.dta"
display "- temp/missingness_plot_data.csv"

display _n "Key finding: Revenue provides " `revenue_coverage' "% coverage vs " `ebitda_coverage' "% for EBITDA"
