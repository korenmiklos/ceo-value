*! version 1.0.0 2025-01-02
* =============================================================================
* Table 4a: Variance Decomposition of Firm Performance
* Uses pre-computed variance components from manager_value.do
* =============================================================================

clear all

* Load components
frame create panel
frame panel: use "temp/within_firm.dta", clear
frame create cross
frame cross: use "temp/cross_section.dta", clear

* Extract values into locals
local outcomes lnR lnEBITDA lnL
local controls manager lnK foreign_owned has_intangible residual

foreach outcome of local outcomes {
    foreach control of local controls {
        * Panel data
        frame panel: summarize contribution if outcome == "`outcome'" & control == "`control'"
        local `outcome'_`control'_p = r(mean)
        if missing(r(mean)) local `outcome'_`control'_p = 0
        
        * Cross-section
        frame cross: summarize contribution if outcome == "`outcome'" & control == "`control'"
        local `outcome'_`control'_c = r(mean)
        if missing(r(mean)) local `outcome'_`control'_c = 0
    }
    
    * Get firm FE for cross-section only
    frame cross: summarize contribution if outcome == "`outcome'" & control == "firm"
    local `outcome'_firm_c = r(mean)
    if missing(r(mean)) local `outcome'_firm_c = 0
}

* Create table
file open table4a using "output/table/table4a.tex", write replace

file write table4a "\begin{table}[htbp]" _n
file write table4a "\centering" _n
file write table4a "\caption{Variance Decomposition of Firm Performance}" _n
file write table4a "\label{tab:variance_decomposition}" _n
file write table4a "\begin{tabular}{l*{6}{c}}" _n
file write table4a "\toprule" _n
file write table4a " & \multicolumn{3}{c}{Panel Data} & \multicolumn{3}{c}{Cross-Section} \\" _n
file write table4a "\cmidrule(lr){2-4} \cmidrule(lr){5-7}" _n
file write table4a " & Revenue & EBIT & Employment & Revenue & EBIT & Employment \\" _n
file write table4a " & (1) & (2) & (3) & (4) & (5) & (6) \\" _n
file write table4a "\midrule" _n

* Row labels and variable names
local rows "Capital:lnK" "Foreign ownership:foreign_owned" "Intangible assets:has_intangible" "Manager FE:manager" "Firm FE:firm" "Residual:residual"

foreach row of local rows {
    gettoken label varname : row, parse(":")
    local varname : subinstr local varname ":" ""
    
    file write table4a "`label' & "
    
    * Panel columns
    foreach outcome of local outcomes {
        if inlist("`varname'", "firm") {
            file write table4a "-- & "
        }
        else {
            file write table4a %5.1f (``outcome'_`varname'_p') " & "
        }
    }
    
    * Cross-section columns  
    foreach outcome of local outcomes {
        file write table4a %5.1f (``outcome'_`varname'_c') " "
        if "`outcome'" != "lnL" file write table4a "& "
    }
    file write table4a "\\" _n
}

file write table4a "\midrule" _n

file write table4a "\\" _n

file write table4a "\bottomrule" _n
file write table4a "\end{tabular}" _n
file write table4a "\begin{minipage}{14cm}" _n
file write table4a "\footnotesize" _n
file write table4a "\textit{Notes:} Variance decomposition of firm performance measures. "
file write table4a "Columns (1)-(3) show within-firm variation. "
file write table4a "Columns (4)-(6) show cross-sectional variation in the largest connected component. "
file write table4a "\end{minipage}" _n
file write table4a "\end{table}" _n

file close table4a

display "Table 4a generated: output/table/table4a.tex"