*! version 1.0.0 2025-08-08
* =============================================================================
* Exhibit 2: Industry-Level Summary Statistics (TEAOR08 Classification)
* =============================================================================

clear all

* =============================================================================
* Load analysis sample with balance data for comprehensive industry coverage
* =============================================================================

use "temp/balance.dta", clear

* Apply industry classification
do "code/util/industry.do"

* Create exclusion indicator based on filter criteria
generate byte excluded = inlist(sector, 2, 9)  // Mining and finance excluded
label define excluded 0 "Included" 1 "Excluded"
label values excluded excluded

* =============================================================================
* Calculate basic industry statistics from balance data
* =============================================================================

* Count total firm-year observations by industry
preserve
    collapse (count) n_obs = frame_id_numeric, by(sector excluded)
    tempfile industry_obs
    save `industry_obs'
restore

* Count distinct firms by industry
preserve
    egen firm_tag = tag(frame_id_numeric)
    keep if firm_tag
    collapse (count) n_firms = frame_id_numeric, by(sector excluded)
    tempfile industry_firms
    save `industry_firms'
restore

* =============================================================================
* Load analysis sample to get manager statistics
* =============================================================================

preserve
    use "temp/analysis-sample.dta", clear
    
    * Apply same industry classification
    capture label drop sector  // Avoid label redefinition error
    do "code/util/industry.do"
    generate byte excluded = inlist(sector, 2, 9)
    
    * Count distinct managers by industry (including excluded sectors)
    egen manager_tag = tag(person_id)
    keep if manager_tag
    collapse (count) n_managers = person_id, by(sector excluded)
    tempfile industry_managers
    save `industry_managers'
restore

* =============================================================================
* Load surplus data for surplus share calculation
* =============================================================================

preserve
    capture use "temp/surplus.dta", clear
    if _rc == 0 {
        * Surplus data already has sector variable from original processing
        * Just check if it has the surplus variable and sector classification
        capture confirm variable surplus sector
        if _rc == 0 {
            generate byte excluded = inlist(sector, 2, 9)
            
            * Calculate surplus share by industry
            * (Surplus share = mean surplus as share of revenue)
            collapse (mean) surplus_share = surplus, by(sector excluded)
            replace surplus_share = surplus_share * 100  // Convert to percentage
            format surplus_share %5.1f
            tempfile industry_surplus
            save `industry_surplus'
            
            local have_surplus = 1
        }
        else {
            * Surplus data doesn't have expected variables
            clear
            set obs 8
            generate sector = _n
            replace sector = 9 if sector == 8
            generate excluded = inlist(sector, 2, 9)
            generate surplus_share = .
            tempfile industry_surplus
            save `industry_surplus'
            
            local have_surplus = 0
            display "Note: surplus.dta missing surplus or sector variables"
        }
    }
    else {
        * Create empty surplus data if surplus.dta doesn't exist
        clear
        set obs 8
        generate sector = _n
        replace sector = 9 if sector == 8
        generate excluded = inlist(sector, 2, 9)
        generate surplus_share = .
        tempfile industry_surplus
        save `industry_surplus'
        
        local have_surplus = 0
        display "Note: surplus.dta not found, surplus share will be missing"
    }
restore

* =============================================================================
* Combine all statistics and create final table data
* =============================================================================

use `industry_obs', clear
merge 1:1 sector excluded using `industry_firms', nogen
merge 1:1 sector excluded using `industry_managers', nogen
merge 1:1 sector excluded using `industry_surplus', nogen

* Fill missing values with zeros where appropriate
foreach var in n_obs n_firms n_managers {
    replace `var' = 0 if missing(`var')
}

* Create industry labels
generate str industry_name = ""
replace industry_name = "Agriculture, Forestry, Fishing" if sector == 1
replace industry_name = "Mining, Quarrying" if sector == 2  
replace industry_name = "Manufacturing" if sector == 3
replace industry_name = "Wholesale, Retail, Transportation" if sector == 4
replace industry_name = "Telecom, Business Services" if sector == 5
replace industry_name = "Construction" if sector == 6
replace industry_name = "Nontradable Services" if sector == 7
replace industry_name = "Finance, Insurance, Real Estate" if sector == 9

* Create TEAOR08 codes for display
generate str teaor_code = ""
replace teaor_code = "A" if sector == 1
replace teaor_code = "B" if sector == 2
replace teaor_code = "C" if sector == 3
replace teaor_code = "G,H" if sector == 4
replace teaor_code = "J,M" if sector == 5
replace teaor_code = "F" if sector == 6
replace teaor_code = "Other" if sector == 7
replace teaor_code = "K,L" if sector == 9

* Create combined industry identifier for table
generate str industry_label = teaor_code + ": " + industry_name
replace industry_label = industry_label + " (Excluded)" if excluded == 1

* Sort by exclusion status and then by number of observations (descending)
sort excluded sector

* =============================================================================
* Create LaTeX table using programmatic generation
* =============================================================================

local outfile "output/table/table2.tex"

* Create table header
file open table using "`outfile'", write replace
file write table "\begin{table}[htbp]" _n
file write table "\centering" _n
file write table "\caption{Industry-Level Summary Statistics}" _n
file write table "\label{tab:industry_stats}" _n

* Determine number of columns based on surplus availability
if `have_surplus' {
    file write table "\begin{tabular}{*{6}{l}}" _n
    file write table "\toprule" _n
    file write table "Industry (TEAOR08) & \shortstack{Firm-year\\obs.} & \shortstack{Distinct\\firms} & \shortstack{Distinct\\managers} & \shortstack{Surplus\\share (\%)} & Status \\" _n
}
else {
    file write table "\begin{tabular}{*{5}{l}}" _n
    file write table "\toprule" _n
    file write table "Industry (TEAOR08) & \shortstack{Firm-year\\obs.} & \shortstack{Distinct\\firms} & \shortstack{Distinct\\managers} & Status \\" _n
}
file write table "\midrule" _n

* Write data rows
local prev_excluded = -1
forvalues i = 1/`=_N' {
    * Add separator when moving from included to excluded sectors
    if excluded[`i'] != `prev_excluded' & `prev_excluded' != -1 {
        file write table "\midrule" _n
    }
    local prev_excluded = excluded[`i']
    
    * Write row data
    file write table (industry_label[`i']) " & "
    file write table %12.0fc (n_obs[`i']) " & "
    file write table %12.0fc (n_firms[`i']) " & "
    file write table %12.0fc (n_managers[`i'])
    
    if `have_surplus' {
        if !missing(surplus_share[`i']) {
            file write table " & " %5.1fc (surplus_share[`i'])
        }
        else {
            file write table " & ---"
        }
    }
    
    * Status column
    if excluded[`i'] == 1 {
        file write table " & Excluded"
    }
    else {
        file write table " & Included"  
    }
    
    file write table " \\" _n
}

* Write table footer with comprehensive notes
file write table "\bottomrule" _n
file write table "\end{tabular}" _n
file write table "\begin{minipage}{\textwidth}" _n
file write table "\footnotesize" _n
file write table "\textit{Notes:} This table presents industry-level summary statistics using the TEAOR08 classification system. "
file write table "Column (1) shows the industry name and corresponding TEAOR08 sector codes. "
file write table "Column (2) shows the total number of firm-year observations in the balance sheet data (1992-2022). "
file write table "Column (3) shows the number of distinct firms with balance sheet data. "
file write table "Column (4) shows the number of distinct managers (CEOs) from the firm registry data. "
if `have_surplus' {
    file write table "Column (5) shows the average production function surplus as a percentage of revenue. "
    file write table "Column (6) indicates whether the industry is included in or excluded from the main analysis. "
}
else {
    file write table "Column (5) indicates whether the industry is included in or excluded from the main analysis. "
}
file write table "Mining (sector B) and Finance/Insurance/Real Estate (sectors K,L) are excluded from the main analysis "
file write table "due to different production function characteristics. "
file write table "The TEAOR08 classification follows the Hungarian adaptation of the NACE Rev. 2 system. "
file write table "Source: Hungarian administrative data combining firm balance sheets and CEO registry." _n
file write table "\end{minipage}" _n
file write table "\end{table}" _n
file close table

display "Table 2 written to `outfile'"

* =============================================================================
* Summary statistics for log file
* =============================================================================

display _n "Industry-level summary statistics:"
if `have_surplus' {
    list industry_name n_obs n_firms n_managers surplus_share excluded, sep(0) noobs
}
else {
    list industry_name n_obs n_firms n_managers excluded, sep(0) noobs
}

display _n "Total statistics:"
collapse (sum) n_obs n_firms n_managers, by(excluded)
list, sep(0) noobs

display _n "Table 2 generation completed successfully"