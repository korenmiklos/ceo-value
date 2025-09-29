use "temp/unfiltered.dta", clear
merge m:1 frame_id_numeric person_id using "temp/manager_value.dta", keep(match) nogen

* for babyboom, we measure manager skills in revenue units, not as TFP
replace manager_skill = manager_skill / chi
* only deal with hungarian CEOs
generate byte hungarian_name = !missing(male)
keep if hungarian_name

keep if !missing(sales)
egen N_jobs = total(1), by(person_id year)
tabulate N_jobs
drop if N_jobs > 4
* keep largest firm only if multiple jobs
bysort person_id year (sales): keep if _n == _N
tabulate N_jobs
drop N_jobs

egen first_year = min(year), by(person_id)
tabulate first_year founder

* to calibrate alpha, we need to count founders
generate cohort = int(first_year/5)*5
tabulate cohort founder
* export a nice latex table for the paper
estpost tabulate cohort founder, matcell(freq) matrow(row) matcol(col)
matrix list r(freq)
esttab matrix(r(freq)) using "output/table/cohort_founders.tex", ///
    replace booktabs fragment ///
    b(0) se(0) ///
    label ///
    collabels("Non-Founder" "Founder" "Total") ///
    rowlabels("1985" "1990" "1995" "2000" "2005" "2010" "2015" "Total") ///
    prehead("\begin{table}[htbp]\centering" "\caption{Manager Cohort Entry and Founder Status}\label{tab:cohort_founders}" "\begin{threeparttable}" "\begin{tabular}{lccc}" "\toprule") ///
    posthead("\midrule") ///
    postfoot("\bottomrule" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item \textbf{Notes:} This table reports the number of managers entering each cohort by founder status. Cohorts are defined by the first year a manager appears in the data, grouped in 5-year bins. Founders are defined as CEOs who are also founders of the firm they manage. The sample is restricted to Hungarian managers with non-missing revenue data and at most 4 simultaneous positions. Data source: Hungarian Manager Database (CEU MicroData) merged with firm financial statements, 1986-2022." "\end{tablenotes}" "\end{threeparttable}" "\end{table}")

generate birth_cohort = int(birth_year/5)*5

egen skill_group = group(birth_cohort male)
egen tag = tag(person_id first_year skill_group)
egen n = total(tag), by(first_year skill_group)
* 1986 is the first measured year, captures the entire 1980s
replace n = n / 7 if first_year == 1986
generate ln_n = ln(n)

local controls male ceo_age ceo_age_sq founder firm_age firm_age_sq
local FEs teaor08_2d##year
local sample inrange(ceo_age, 18, 75) & year >= 1992

* to calibrate phi, report EBTA/sales ratios by founder status
generate double ebitda_sales = EBITDA / sales
replace ebitda_sales = . if ebitda_sales < 0 | ebitda_sales > 1
summarize ebitda_sales if `sample' & founder, detail
display "Mean EBITDA/Sales, Founders: " %6.4f r(mean)
display "Median EBITDA/Sales, Founders: " %6.4f r(p50)
summarize ebitda_sales [aw=sales] if `sample' & founder
display "Weighted Mean EBITDA/Sales, Founders: " %6.4f r(mean)
summarize ebitda_sales if `sample' & !founder, detail
display "Mean EBITDA/Sales, Non-Founders: " %6.4f r(mean)
display "Median EBITDA/Sales, Non-Founders: " %6.4f r(p50)
summarize ebitda_sales [aw=sales] if `sample' & !founder
display "Weighted Mean EBITDA/Sales, Non-Founders: " %6.4f r(mean)

generate ln_EBITDA_share = ln(ebitda_sales)

reghdfe ln_EBITDA_share `controls' if `sample', a(`FEs') cluster(frame_id_numeric)
* the founder needs to pay txes minimum wage, add this back to the observed surplus
merge m:1 year using "temp/minimum_wage.dta", keep(master match) nogen

generate payroll_tax = 27 if inrange(year, 2012, 2016)
replace payroll_tax = 22 if inrange(year, 2017, 2017)
replace payroll_tax = 19.5 if inrange(year, 2018, 2018)
* change was midyear from 19.5 to 17.5, use average
replace payroll_tax = 18.5 if inrange(year, 2019, 2019)
* similar in 2020 from 17.5 to 15.5
replace payroll_tax = 16.5 if inrange(year, 2020, 2020)
replace payroll_tax = 15.5 if inrange(year, 2021, 2021)
replace payroll_tax = 13 if inrange(year, 2022, 2022)

generate double founder_min_wage = guaranteed_minimum_wage * (payroll_tax/100) * 12 / 1000
replace EBITDA = EBITDA + founder_min_wage if founder
generate double adjusted_ebitda_sales = EBITDA / sales
replace adjusted_ebitda_sales = . if adjusted_ebitda_sales < 0 | adjusted_ebitda_sales > 1
replace ln_EBITDA_share = ln(adjusted_ebitda_sales) if founder 

summarize adjusted_ebitda_sales if `sample' & founder & !missing(adjusted_ebitda_sales), detail
display "Mean Adjusted EBITDA/Sales, Founders: " %6.4f r(mean)
summarize ebitda_sales if `sample' & !founder & !missing(adjusted_ebitda_sales), detail
display "Mean EBITDA/Sales, Non-Founders: " %6.4f r(mean)
reghdfe ln_EBITDA_share `controls' if `sample' & !missing(adjusted_ebitda_sales), a(`FEs') cluster(frame_id_numeric)

* firm size goes down. entry goes up
reghdfe lnR ib1985.cohort `controls' if `sample', a(`FEs') cluster(first_year )
reghdfe ln_n ib1985.cohort `controls' if `sample', a(`FEs') cluster(first_year )

* =============================================================================
* Store estimates and create table
* =============================================================================

* Store the key regression results
estimates clear
* ln_n captures degree of entry in cohort, its coefficient is -1/theta
reghdfe lnR ln_n `controls' if `sample', a(`FEs') cluster(first_year )
* if skill groups have difference baseline skills or different sizes (demographics), this can be taken out by fixed effects
reghdfe lnR ln_n `controls' if `sample', a(`FEs' skill_group) cluster(first_year )
estimates store col1

* only use stable, post-EU years
reghdfe lnR ln_n `controls' if `sample' & year >= 2004, a(`FEs' skill_group) cluster(first_year )
estimates store col4

* exclude pre-transition entry - this starting in 1992 are already post-transition
reghdfe lnR ln_n `controls' if `sample' & first_year >= 1992, a(`FEs' skill_group) cluster(first_year )
estimates store col3

* exclude founders
reghdfe lnR ln_n `controls' if `sample' & !founder, a(`FEs' skill_group) cluster(first_year )
estimates store col2

* add firm fixed effects - results are about half
reghdfe lnR ln_n `controls' if `sample', a(`FEs' frame_id_numeric) cluster(first_year )
reghdfe lnR ln_n `controls' if `sample', a(`FEs' skill_group frame_id_numeric) cluster(first_year )
estimates store col5


* Calculate theta parameters using delta method
foreach col in col1 col2 col3 col4 col5 {
    estimates restore `col'
    local theta_`col' = -1/_b[ln_n]
    local theta_se_`col' = abs(_se[ln_n]/(_b[ln_n]^2))
}

* Create table with esttab
esttab col1 col2 col3 col4 col5 using "output/table/cohort_selection.tex", ///
    replace booktabs fragment ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(ln_n ceo_age ceo_age_sq founder firm_age firm_age_sq _cons) ///
    order(ln_n ceo_age ceo_age_sq founder firm_age firm_age_sq _cons) ///
    coeflabels(ln_n "Number of CEO Entrants, log" ///
               ceo_age "CEO Age" ///
               ceo_age_sq "CEO Age Squared" ///
               founder "Founder CEO" ///
               firm_age "Firm Age" ///
               firm_age_sq "Firm Age Squared" ///
               _cons "Constant") ///
    refcat(ln_n "(\$\ln n\$)", nolabel) ///
    mtitles("Baseline" "No Founders" "Post-1992" "Post-2004" "Firm FE") ///
    mgroups("Dependent Variable: Log Revenue", pattern(1 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
    stats(N r2_a, fmt(%12.0fc 3) labels("Observations" "Adjusted R-squared")) ///
    prehead("\begin{table}[htbp]\centering" "\caption{Manager Selection and Cohort Entry Effects}\label{tab:cohort_selection}" "\begin{threeparttable}" "\begin{tabular}{lccccc}" "\toprule") ///
    posthead("\midrule") ///
    prefoot("\midrule" "\textbf{Fixed Effects:}" "Industry \$\times\$ Year & Yes & Yes & Yes & Yes & Yes \\" "Birth Cohort \$\times\$ Gender & Yes & Yes & Yes & Yes & Yes \\" "Firm & No & No & No & No & Yes \\" "\midrule" "\textbf{Selection Parameter:}" "\$\theta\$ & " %5.2f (`theta_col1') "*** & " %5.2f (`theta_col2') "*** & " %5.2f (`theta_col3') "*** & " %5.2f (`theta_col4') "*** & " %5.2f (`theta_col5') "*** \\" " & (" %4.2f (`theta_se_col1') ") & (" %4.2f (`theta_se_col2') ") & (" %4.2f (`theta_se_col3') ") & (" %4.2f (`theta_se_col4') ") & (" %4.2f (`theta_se_col5') ") \\") ///
    postfoot("\bottomrule" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item \textbf{Notes:} This table reports results from regressions of log firm revenue on cohort entry characteristics for Hungarian CEOs, 1992-2022. The key variable of interest is Log Entry Rate (\$\ln n\$), which measures the log number of managers entering in each cohort, normalized by demographic factors. Skill groups are defined by birth cohort (5-year bins) interacted with gender, capturing systematic differences in baseline skills and demographics across manager cohorts. Column (1) shows the baseline specification with industry-year and skill group fixed effects. Column (2) excludes founding owners from CEOs. Column (3) restricts to post-transition entrants (first year \$\geq\$ 1992). Column (4) uses only post-EU accession data (2004 onwards). Column (5) adds firm fixed effects. The selection parameter \$\theta\$ is computed as \$\theta = -1/\beta_{\ln n}\$ using the delta method for standard errors. Sample restricted to Hungarian managers aged 18-75 with non-missing revenue data and at most 4 simultaneous positions. Standard errors clustered by first entry year in parentheses." "\item \textbf{Significance levels:} * p \$<\$ 0.10, ** p \$<\$ 0.05, *** p \$<\$ 0.01." "\item \textbf{Data source:} Hungarian Manager Database (CEU MicroData) merged with firm financial statements, 1986-2022." "\end{tablenotes}" "\end{threeparttable}" "\end{table}")

* now do the founder discount regressions

estimates clear
reghdfe lnR founder if `sample', a(`FEs') cluster(person_id)
estimates store col1

reghdfe lnR `controls' if `sample', a(`FEs' skill_group) cluster(person_id)
estimates store col2

reghdfe lnR `controls' if `sample', a(`FEs' person_id) cluster(person_id)
estimates store col3

* create a similar latex table
esttab col1 col2 col3 using "output/table/founder_discount.tex", ///
    replace booktabs fragment ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(founder ceo_age ceo_age_sq firm_age firm_age_sq _cons) ///
    order(founder ceo_age ceo_age_sq firm_age firm_age_sq _cons) ///
    coeflabels(founder "Founder CEO" ///
               ceo_age "CEO Age" ///
               ceo_age_sq "CEO Age Squared" ///
               firm_age "Firm Age" ///
               firm_age_sq "Firm Age Squared" ///
               _cons "Constant") ///
    mtitles("No Controls" "With Controls" "CEO FE") /// 
    mgroups("Dependent Variable: Log Revenue", pattern(1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
    stats(N r2_a, fmt(%12.0fc 3) labels("Observations" "Adjusted R-squared")) ///
    prehead("\begin{table}[htbp]\centering" "\caption{Founder CEO Discount}\label{tab:founder_discount}" "\begin{threeparttable}" "\begin{tabular}{lccc}" "\toprule") ///
    posthead("\midrule") ///
    prefoot("\midrule" "\textbf{Fixed Effects:}" "Industry \$\times\$ Year & Yes & Yes & Yes \\" "Birth Cohort \$\times\$ Gender & No & Yes & No \\" "CEO & No & No & Yes \\" "\midrule") ///
    postfoot("\bottomrule" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item \textbf{Notes:} This table reports results from regressions of log firm revenue on a founder CEO indicator for Hungarian CEOs, 1992-2022. Column (1) shows the baseline specification with industry-year fixed effects. Column (2) adds controls for CEO age and firm age as well as skill group fixed effects defined by birth cohort (5-year bins) interacted with gender, capturing systematic differences in baseline skills and demographics across manager cohorts. Column (3) adds CEO fixed effects, so the founder coefficient is identified off CEOs who switch between founder and non-founder roles. The sample is restricted to Hungarian managers aged 18-75 with non-missing revenue data and at most 4 simultaneous positions. Standard errors clustered by manager in parentheses." "\item \textbf{Significance levels:} * p \$<\$ 0.10, ** p \$<\$ 0.05, *** p \$<\$ 0.01." "\item \textbf{Data source:} Hungarian Manager Database (CEU MicroData) merged with firm financial statements, 1992-2022." "\end{tablenotes}" "\end{threeparttable}" "\end{table}")
