*! version 1.0.0 2025-08-29
*! Create Table A0: Managerial Autonomy in Family Firms (Bloom et al. 2012 data)
* =============================================================================

clear all

* =============================================================================
* Load and prepare data
* =============================================================================
use "input/bloom-et-al-2012/replication.dta", clear

* Clean public variable (coded as -99 for missing)
replace public = 0 if public == -99

* Generate log investment autonomy (exclude zeros)
generate lnI = ln(central5)
label variable lnI "Log investment autonomy"

* Create dummy variables for full autonomy (score = 5)
generate byte hiring = central4 == 5
generate byte marketing = central6 == 5
generate byte product = central7 == 5

label variable hiring "Full hiring autonomy"
label variable marketing "Full sales/marketing autonomy"
label variable product "Full product intro autonomy"

* =============================================================================
* Run specification 4: Private firms only with country and industry FE
* =============================================================================

* Define regression options
local fe_spec "absorb(cty sic2)"
local clustering "cluster(id)"
local sample "if !public"

* Define outcomes and methods
local outcomes "central5 lnI marketing product hiring"
local methods "ppml ols ppml ppml ppml"
local labels "ppml_investment ols_investment ppml_marketing ppml_product ppml_hiring"

* Loop through outcomes and run regressions
local i = 1
foreach outcome of local outcomes {
    local method : word `i' of `methods'
    local label : word `i' of `labels'
    
    * Run appropriate regression
    if "`method'" == "ppml" {
        quietly ppmlhdfe `outcome' family `sample', `fe_spec' `clustering'
    }
    else {
        quietly reghdfe `outcome' family `sample', `fe_spec' `clustering'
    }
    
    * Store results
    eststo `label'
    estadd local country_fe "Yes"
    estadd local industry_fe "Yes"
    estadd scalar observations = e(N)
    
    local ++i
}

* =============================================================================
* Generate LaTeX table
* =============================================================================

* Generate LaTeX table using esttab
esttab ppml_investment ols_investment ppml_marketing ppml_product ppml_hiring ///
    using "papers/application/table/tableA0.tex", ///
    replace booktabs label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) ///
    mtitle("Investment" "Investment" "Marketing" "Product" "Hiring" ///
           "\small (PPML)" "\small (Log OLS)" "\small (PPML)" "\small (PPML)" "\small (PPML)") ///
    title("Plant Manager Autonomy in Family-Controlled Firms") ///
    keep(family) ///
    varlabels(family "Family ownership") ///
    stats(observations country_fe industry_fe, ///
          labels("Observations" "Country FE" "Industry FE") ///
          fmt(%12.0fc %s %s)) ///
    addnote("Data source: Bloom, Sadun, and Van Reenen (2012). Sample restricted to private (non-publicly traded) firms." ///
            "Investment autonomy measured as maximum capital investment plant manager can approve (USD)." ///
            "Other autonomy dimensions are binary indicators for full autonomy (score = 5 on 1-5 scale)." ///
            "PPML = Poisson Pseudo-Maximum Likelihood. Standard errors clustered at firm level." ///
            "All specifications include country and 2-digit SIC industry fixed effects.")

* Clean up LaTeX output to remove underscores in labels
filefilter "papers/application/table/tableA0.tex" "papers/application/table/tableA0_clean.tex", ///
    from("country_fe") to("Country FE") replace
filefilter "papers/application/table/tableA0_clean.tex" "papers/application/table/tableA0.tex", ///
    from("industry_fe") to("Industry FE") replace
erase "papers/application/table/tableA0_clean.tex"

display "Table A0 generated: papers/application/table/tableA0.tex"

* =============================================================================
* Summary statistics for table notes
* =============================================================================
display _n "Summary Statistics for Table Notes"
display "==================================="

* Count observations
count if !public
local n_private = r(N)
count if !public & !missing(central5)
local n_investment = r(N)
count if !public & !missing(lnI)
local n_log_investment = r(N)

display "Private firms: `n_private'"
display "With investment data: `n_investment'"
display "With log investment data: `n_log_investment'"

* Mean autonomy by family status
summarize central5 if !public & family==0, meanonly
local mean_nonfamily = r(mean)
summarize central5 if !public & family==1, meanonly
local mean_family = r(mean)
display "Mean investment autonomy - Non-family: " %12.0fc `mean_nonfamily'
display "Mean investment autonomy - Family: " %12.0fc `mean_family'

* Percentage with full autonomy
foreach var in hiring marketing product {
    summarize `var' if !public & family==0, meanonly
    local pct_nonfamily = r(mean)*100
    summarize `var' if !public & family==1, meanonly
    local pct_family = r(mean)*100
    display "% with full `var' autonomy - Non-family: " %5.1f `pct_nonfamily'
    display "% with full `var' autonomy - Family: " %5.1f `pct_family'
}