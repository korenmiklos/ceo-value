*! version 1.0.0 2025-01-08
* =============================================================================
* Exhibit 1: Descriptive Statistics Over Time (1992-2022)
* =============================================================================

clear all

* Load analysis sample
use "temp/analysis-sample.dta", clear

* =============================================================================
* Create year-level statistics
* =============================================================================

* Tag unique firms per year
egen firm_year_tag = tag(frame_id_numeric year)

* Count total firms per year (after filtering)
preserve
    keep if firm_year_tag
    collapse (count) n_firms_filtered = frame_id_numeric, by(year)
    tempfile filtered_firms
    save `filtered_firms'
restore

* Count distinct CEOs per year
preserve
    egen ceo_year_tag = tag(person_id year)
    keep if ceo_year_tag
    collapse (count) n_ceos = person_id, by(year)
    tempfile ceo_counts
    save `ceo_counts'
restore

* =============================================================================
* Load raw balance sheet data for total firm counts
* =============================================================================

preserve
    use "temp/balance.dta", clear
    egen firm_year_tag = tag(frame_id_numeric year)
    keep if firm_year_tag
    collapse (count) n_firms_total = frame_id_numeric, by(year)
    tempfile total_firms
    save `total_firms'
restore

* =============================================================================
* Process largest connected component
* =============================================================================

* Load connected component managers
preserve
    import delimited "temp/large_component_managers.csv", clear
    tempfile connected_managers
    save `connected_managers'
restore

* Count CEOs in connected component
preserve
    merge m:1 person_id using `connected_managers', keep(match) nogen
    egen ceo_year_tag = tag(person_id year)
    keep if ceo_year_tag
    collapse (count) n_ceos_connected = person_id, by(year)
    tempfile connected_ceos
    save `connected_ceos'
restore

* Count firms in connected component
preserve
    merge m:1 person_id using `connected_managers', keep(match) nogen
    drop if missing(frame_id_numeric)
    egen firm_year_tag_conn = tag(frame_id_numeric year)
    keep if firm_year_tag_conn
    collapse (count) n_firms_connected = frame_id_numeric, by(year)
    tempfile connected_firms
    save `connected_firms'
restore

* =============================================================================
* Combine all statistics
* =============================================================================

use `total_firms', clear
merge 1:1 year using `filtered_firms', nogen
merge 1:1 year using `ceo_counts', nogen
merge 1:1 year using `connected_ceos', nogen
merge 1:1 year using `connected_firms', nogen

* Fill missing values with zeros
foreach var in n_firms_total n_firms_filtered n_ceos n_ceos_connected n_firms_connected {
    replace `var' = 0 if missing(`var')
}

* Keep years 1992-2022
keep if inrange(year, 1992, 2022)
sort year

* =============================================================================
* Create LaTeX table
* =============================================================================

* Format numbers with thousand separators
foreach var of varlist n_* {
    format `var' %12.0fc
}

* Since table is long (31 years), we'll show every 5 years plus first, last, and totals
generate byte show_row = mod(year, 5) == 0 | year == 1992 | year == 2022

* Calculate totals
preserve
    collapse (sum) n_firms_total n_firms_filtered n_ceos n_ceos_connected n_firms_connected
    generate year = 9999  // Use 9999 as indicator for total row
    tempfile totals
    save `totals'
restore

append using `totals'

* Create labels for display
generate str year_label = string(year) if year != 9999
replace year_label = "Total" if year == 9999

* Export to LaTeX
local outfile "output/table/table1.tex"
local columns "Year & Total firms & Filtered firms & CEOs & CEOs (connected) & Firms (connected)"

* Write table header
file open table using `outfile', write replace
file write table "\begin{table}[htbp]" _n
file write table "\centering" _n
file write table "\caption{Sample Description Over Time}" _n
file write table "\label{tab:sample}" _n
file write table "\begin{tabular}{lccccc}" _n
file write table "\toprule" _n
file write table "`columns' \\" _n
file write table "\midrule" _n

* Write data rows (selected years only)
local count = 0
forvalues i = 1/`=_N' {
    if (show_row[`i'] == 1 | year[`i'] == 9999) {
        local count = `count' + 1
        
        * Add separation before total row
        if year[`i'] == 9999 {
            file write table "\midrule" _n
        }
        
        file write table (year_label[`i']) " & "
        file write table %12.0fc (n_firms_total[`i']) " & "
        file write table %12.0fc (n_firms_filtered[`i']) " & "
        file write table %12.0fc (n_ceos[`i']) " & "
        file write table %12.0fc (n_ceos_connected[`i']) " & "
        file write table %12.0fc (n_firms_connected[`i']) " \\" _n
    }
}

* Write table footer with notes
file write table "\bottomrule" _n
file write table "\end{tabular}" _n
file write table "\begin{minipage}{\textwidth}" _n
file write table "\footnotesize" _n
file write table "\textit{Notes:} This table presents the evolution of the sample from 1992 to 2022. "
file write table "Column (1) shows the total number of firms with balance sheet data. "
file write table "Column (2) shows the number of firms after applying sample filters "
file write table "(excluding financial and real estate sectors, requiring positive employment and revenue). "
file write table "Column (3) shows the number of distinct CEOs (person IDs) in each year. "
file write table "Columns (4) and (5) show the subset of CEOs and firms that belong to the largest connected component "
file write table "of the manager network, where managers are connected if they have worked at the same firm. "
file write table "The table shows every fifth year plus the first year (1992), last year (2022), and totals. "
file write table "Source: Hungarian administrative data combining firm balance sheets and CEO registry." _n
file write table "\end{minipage}" _n
file write table "\end{table}" _n
file close table

display "Table 1 written to `outfile'"

* =============================================================================
* Summary statistics for log file
* =============================================================================

display _n "Summary of years included in table:"
list year_label n_firms_total n_firms_filtered n_ceos n_ceos_connected n_firms_connected if show_row | year == 9999, sep(0) noobs

display _n "Share of connected component:"
generate share_ceos_connected = n_ceos_connected / n_ceos * 100
generate share_firms_connected = n_firms_connected / n_firms_filtered * 100
format share_* %5.1f
summarize share_ceos_connected share_firms_connected if year != 9999, detail