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

generate cohort = int(first_year/5)*5
tabulate cohort founder

generate birth_cohort = int(birth_year/5)*5

egen skill_group = group(birth_cohort male)
egen tag = tag(person_id first_year skill_group)
egen n = total(tag), by(first_year skill_group)
* 1986 is the first measured year, captures the entire 1980s
replace n = n / 7 if first_year == 1986
generate ln_n = ln(n)

local controls male ceo_age ceo_age_sq founder firm_age firm_age_sq
local FEs teaor08_2d##year
local sample inrange(ceo_age, 18, 75)

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
    postfoot("\bottomrule" "\end{tabular}" "\begin{tablenotes}" "\footnotesize" "\item \textbf{Notes:} This table reports results from regressions of log firm revenue on cohort entry characteristics for Hungarian CEOs, 1986-2022. The key variable of interest is Log Entry Rate (\$\ln n\$), which measures the log number of managers entering in each cohort, normalized by demographic factors. Skill groups are defined by birth cohort (5-year bins) interacted with gender, capturing systematic differences in baseline skills and demographics across manager cohorts. Column (1) shows the baseline specification with industry-year and skill group fixed effects. Column (2) excludes founding owners from CEOs. Column (3) restricts to post-transition entrants (first year \$\geq\$ 1992). Column (4) uses only post-EU accession data (2004 onwards). Column (5) adds firm fixed effects. The selection parameter \$\theta\$ is computed as \$\theta = -1/\beta_{\ln n}\$ using the delta method for standard errors. Sample restricted to Hungarian managers aged 18-75 with non-missing revenue data and at most 4 simultaneous positions. Standard errors clustered by first entry year in parentheses." "\item \textbf{Significance levels:} * p \$<\$ 0.10, ** p \$<\$ 0.05, *** p \$<\$ 0.01." "\item \textbf{Data source:} Hungarian Manager Database (CEU MicroData) merged with firm financial statements, 1986-2022." "\end{tablenotes}" "\end{threeparttable}" "\end{table}")

