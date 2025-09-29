*! Create Table 2: Average Treatment Effects on the Treated (ATET) Analysis
*! Compares naive, placebo, and debiased estimates across samples and CEO quality

* Import ATET estimates from all samples
clear
tempfile atet_data

* Import full sample
import delimited "output/estimate/atet_full.csv", clear
generate str20 sample = "full"
save `atet_data', replace

* Import fnd2non sample
import delimited "output/estimate/atet_fnd2non.csv", clear
generate str20 sample = "fnd2non"
append using `atet_data'
save `atet_data', replace

* Import non2non sample
import delimited "output/estimate/atet_non2non.csv", clear
generate str20 sample = "non2non" 
append using `atet_data'

* Create column identifiers based on sample and treatment group
generate str30 column = ""
replace column = "full_all" if sample == "full" & treatment_group == "all"
replace column = "fnd2non_all" if sample == "fnd2non" & treatment_group == "all"
replace column = "non2non_all" if sample == "non2non" & treatment_group == "all"
replace column = "full_better" if sample == "full" & treatment_group == "better"
replace column = "full_worse" if sample == "full" & treatment_group == "worse"

* Keep only the columns we want for the table
keep if inlist(column, "full_all", "fnd2non_all", "non2non_all", "full_better", "full_worse")

* Create row identifiers
generate str30 row = ""
replace row = "naive" if method == "naive"
replace row = "placebo" if method == "placebo"
replace row = "debiased" if method == "debiased"

* Reshape data to have columns as variables
keep column row atet se n_obs
reshape wide atet se n_obs, i(row) j(column) string

* Create formatted coefficient strings with standard errors
foreach col in full_all fnd2non_all non2non_all full_better full_worse {
    generate str20 coef_`col' = ""
    replace coef_`col' = string(atet`col', "%9.4f") if !missing(atet`col')
    replace coef_`col' = coef_`col' + "***" if abs(atet`col'/se`col') > 2.576 & !missing(atet`col') & !missing(se`col')
    replace coef_`col' = coef_`col' + "**" if abs(atet`col'/se`col') > 1.96 & abs(atet`col'/se`col') <= 2.576 & !missing(atet`col') & !missing(se`col')
    replace coef_`col' = coef_`col' + "*" if abs(atet`col'/se`col') > 1.645 & abs(atet`col'/se`col') <= 1.96 & !missing(atet`col') & !missing(se`col')
    
    generate str20 se_`col' = "(" + string(se`col', "%9.4f") + ")"
}

* Create observation count row
expand 2 if _n == _N
replace row = "observations" if _n == _N
foreach col in full_all fnd2non_all non2non_all full_better full_worse {
    replace coef_`col' = string(n_obs`col'[1], "%12.0fc") if row == "observations"
    replace se_`col' = "" if row == "observations"
}

* Set the order of rows
generate order = .
replace order = 1 if row == "naive"
replace order = 2 if row == "placebo" 
replace order = 3 if row == "debiased"
replace order = 4 if row == "observations"
sort order

* Create LaTeX table
file open table using "output/table/table2.tex", write replace

file write table "\begin{tabular}{lccccc}" _newline
file write table "\toprule" _newline
file write table " & \multicolumn{3}{c}{All Changes} & \multicolumn{2}{c}{Full Sample} \\" _newline
file write table "\cmidrule(lr){2-4} \cmidrule(lr){5-6}" _newline
file write table " & Full & Founder$\to$Outsider & Outsider$\to$Outsider & Better CEOs & Worse CEOs \\" _newline
file write table " & (1) & (2) & (3) & (4) & (5) \\" _newline
file write table "\midrule" _newline

local row_labels `" "TWFE (OLS on actual)" "TWFE (OLS on placebo)" "ATET (debiased)" "Observations" "'
local row_names naive placebo debiased observations

forvalues i = 1/4 {
    local row_name : word `i' of `row_names'
    local row_label : word `i' of `row_labels'
    
    file write table ("`row_label'")
    foreach col in full_all fnd2non_all non2non_all full_better full_worse {
        local coef = coef_`col'[`i']
        file write table " & " ("`coef'")
    }
    file write table " \\" _newline
    
    * Add standard error row (except for observations)
    if "`row_name'" != "observations" {
        file write table " "
        foreach col in full_all fnd2non_all non2non_all full_better full_worse {
            local se = se_`col'[`i']
            file write table " & " ("`se'")
        }
        file write table " \\" _newline
    }
}

file write table "\bottomrule" _newline
file write table "\end{tabular}" _newline
file write table "\begin{tablenotes}[flushleft]" _newline
file write table "\footnotesize" _newline
file write table "\item \textbf{Notes:} This table compares Average Treatment Effects on the Treated (ATET) estimates " _newline
file write table "across different samples and CEO types. TWFE refers to Two-Way Fixed Effects regressions " _newline
file write table "with firm and year fixed effects. The naive estimator uses actual CEO transitions, " _newline
file write table "while the placebo estimator uses randomly assigned fake transitions. The debiased " _newline
file write table "ATET estimator uses the \texttt{xt2treatments} command with optimal weighting and " _newline
file write table "placebo controls. Better/worse CEOs are classified based on estimated manager fixed effects. " _newline
file write table "Standard errors are clustered by firm. Significance levels: *** p$<$0.01, ** p$<$0.05, * p$<$0.10." _newline
file write table "\end{tablenotes}" _newline
file write table "\end{tabular}" _newline
file close table

display "Table 2 created: output/table/table2.tex"

* Show summary statistics in log
display _newline "=== ATET ESTIMATES SUMMARY ===" _newline
list row coef_full_all coef_fnd2non_all coef_non2non_all coef_full_better coef_full_worse if inlist(row, "naive", "placebo", "debiased"), clean noobs