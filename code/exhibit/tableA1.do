clear all

* =============================================================================
* Load analysis sample with balance data for comprehensive industry coverage
* =============================================================================

use "temp/balance.dta", clear
merge 1:m frame_id_numeric year using "temp/ceo-panel.dta", keep(master match) nogen

* Apply industry classification
do "code/util/industry.do"
do "code/util/variables.do"

* Create exclusion indicator based on filter criteria
generate byte excluded = inlist(sector, 2, 9)  // Mining and finance excluded
label define excluded 0 "" 1 "*"
label values excluded excluded

* =============================================================================
* Calculate basic industry statistics from balance data
* =============================================================================

egen firm_year_tag = tag(frame_id_numeric year)

* Count total firm-year observations by industry
preserve
    keep if firm_year_tag
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
    egen manager_tag = tag(frame_id_numeric person_id)
    keep if manager_tag
    collapse (count) n_managers = person_id, by(sector excluded)
    tempfile industry_managers
    save `industry_managers'
restore

* =============================================================================
* Load surplus data for surplus share calculation
* =============================================================================

preserve
    keep if firm_year_tag
    collapse (mean) EBITDA sales, by(sector excluded)
    generate surplus_share = (EBITDA / sales) * 100
    drop EBITDA sales
    tempfile industry_surplus
    save `industry_surplus'
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
generate str industry_label = industry_name + " (" + teaor_code + ")"
replace industry_label = industry_label + "*" if excluded == 1

* Sort by exclusion status and then by number of observations (descending)
sort excluded sector

* =============================================================================
* Create LaTeX table using programmatic generation
* =============================================================================

local outfile "output/table/tableA1.tex"

* Create table header
file open table using "`outfile'", write replace
file write table "\begin{table}[htbp]" _n
file write table "\centering" _n
file write table "\caption{Industry Breakdown}" _n
file write table "\label{tab:industry_stats}" _n

* Determine number of columns based on surplus availability
file write table "\begin{tabular}{l*{5}{r}}" _n
file write table "\toprule" _n
file write table "Industry (NACE) & \shortstack{Obs.} & \shortstack{Firms} & \shortstack{CEOs} & \shortstack{Surplus\\share (\%)} \\" _n

file write table "\midrule" _n

* Write data rows
forvalues i = 1/`=_N' {    
    * Write row data
    file write table (industry_label[`i']) " & "
    file write table %12.0fc (n_obs[`i']) " & "
    file write table %12.0fc (n_firms[`i']) " & "
    file write table %12.0fc (n_managers[`i'])
    
    file write table " & " %5.1fc (surplus_share[`i'])
    
    file write table " \\" _n
}

* Write table footer with comprehensive notes
file write table "\bottomrule" _n
file write table "\end{tabular}" _n
file write table "\begin{minipage}{\textwidth}" _n
file write table "\footnotesize" _n
file write table "\textit{Notes:} This table presents industry-level summary statistics using the TEAOR08 classification system. "
file write table "Column (1) shows the industry name and corresponding NACE sector codes. "
file write table "Column (2) shows the total number of firm-year observations in the balance sheet data (1992-2022). "
file write table "Column (3) shows the number of distinct firms with balance sheet data. "
file write table "Column (4) shows the number of distinct managers (CEOs) from the firm registry data. "
file write table "Column (5) shows the average EBITDA as a percentage of revenue. "
file write table "Mining (sector B) and Finance/Insurance/Real Estate (sectors K,L) are excluded from the main analysis "
file write table "due to different production function characteristics. "
file write table "The NACE classification follows the Hungarian adaptation of the NACE Rev. 2 system. "
file write table "\end{minipage}" _n
file write table "\end{table}" _n
file close table

display "Table A1 written to `outfile'"

* =============================================================================
* Summary statistics for log file
* =============================================================================

display _n "Industry-level summary statistics:"
list industry_name n_obs n_firms n_managers surplus_share excluded, sep(0) noobs

display _n "Total statistics:"
collapse (sum) n_obs n_firms n_managers, by(excluded)
list, sep(0) noobs

display _n "Table A1 generation completed successfully"