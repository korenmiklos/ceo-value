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

* Extract all values into named locals
local outcomes lnR lnEBITDA lnL

foreach outcome of local outcomes {
    * Panel data
    frame panel: summarize contribution if outcome == "`outcome'" & control == "manager"
    local `outcome'_manager_p = r(mean)
    
    frame panel: summarize contribution if outcome == "`outcome'" & control == "lnK"
    local `outcome'_capital_p = r(mean)
    
    frame panel: summarize contribution if outcome == "`outcome'" & control == "foreign_owned"
    local `outcome'_foreign_p = r(mean)
    
    frame panel: summarize contribution if outcome == "`outcome'" & control == "has_intangible"
    local `outcome'_intangible_p = r(mean)
    
    frame panel: summarize contribution if outcome == "`outcome'" & control == "residual"
    local `outcome'_residual_p = r(mean)
    
    * Cross-section
    frame cross: summarize contribution if outcome == "`outcome'" & control == "manager"
    local `outcome'_manager_c = r(mean)
    
    frame cross: summarize contribution if outcome == "`outcome'" & control == "firm"
    local `outcome'_firm_c = r(mean)
    
    frame cross: summarize contribution if outcome == "`outcome'" & control == "lnK"
    local `outcome'_capital_c = r(mean)
    
    frame cross: summarize contribution if outcome == "`outcome'" & control == "foreign_owned"
    local `outcome'_foreign_c = r(mean)
    
    frame cross: summarize contribution if outcome == "`outcome'" & control == "has_intangible"
    local `outcome'_intangible_c = r(mean)
    
    frame cross: summarize contribution if outcome == "`outcome'" & control == "residual"
    local `outcome'_residual_c = r(mean)
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

* Write rows
file write table4a "Capital & "
file write table4a %5.1f (`lnR_capital_p') " & " %5.1f (`lnEBITDA_capital_p') " & " %5.1f (`lnL_capital_p') " & "
file write table4a %5.1f (`lnR_capital_c') " & " %5.1f (`lnEBITDA_capital_c') " & " %5.1f (`lnL_capital_c') " \\" _n

file write table4a "Foreign ownership & "
file write table4a %5.1f (`lnR_foreign_p') " & " %5.1f (`lnEBITDA_foreign_p') " & " %5.1f (`lnL_foreign_p') " & "
file write table4a %5.1f (`lnR_foreign_c') " & " %5.1f (`lnEBITDA_foreign_c') " & " %5.1f (`lnL_foreign_c') " \\" _n

file write table4a "Intangible assets & "
file write table4a %5.1f (`lnR_intangible_p') " & " %5.1f (`lnEBITDA_intangible_p') " & " %5.1f (`lnL_intangible_p') " & "
file write table4a %5.1f (`lnR_intangible_c') " & " %5.1f (`lnEBITDA_intangible_c') " & " %5.1f (`lnL_intangible_c') " \\" _n

file write table4a "Manager FE & "
file write table4a %5.1f (`lnR_manager_p') " & " %5.1f (`lnEBITDA_manager_p') " & " %5.1f (`lnL_manager_p') " & "
file write table4a %5.1f (`lnR_manager_c') " & " %5.1f (`lnEBITDA_manager_c') " & " %5.1f (`lnL_manager_c') " \\" _n

file write table4a "Firm FE & "
file write table4a "-- & -- & -- & "
file write table4a %5.1f (`lnR_firm_c') " & " %5.1f (`lnEBITDA_firm_c') " & " %5.1f (`lnL_firm_c') " \\" _n

file write table4a "Residual & "
file write table4a %5.1f (`lnR_residual_p') " & " %5.1f (`lnEBITDA_residual_p') " & " %5.1f (`lnL_residual_p') " & "
file write table4a %5.1f (`lnR_residual_c') " & " %5.1f (`lnEBITDA_residual_c') " & " %5.1f (`lnL_residual_c') " \\" _n

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