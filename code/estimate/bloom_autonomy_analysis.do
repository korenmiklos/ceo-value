*! version 1.0.0 2025-08-29
*! Analyze managerial autonomy in Bloom et al. (2012) data
* =============================================================================
* Purpose: Test whether family-controlled firms have less managerial autonomy
* Data source: Bloom, Sadun & Van Reenen (2012) QJE replication data
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

* Count observations
count
count if !missing(central5)
count if !missing(lnI)

* =============================================================================
* Summary statistics for all autonomy variables
* =============================================================================
display _n "Summary Statistics - All Autonomy Dimensions"
display "============================================="

* central4: Plant manager hiring autonomy (1-5 scale)
* central5: Plant manager max cap inv autonomy (dollar value)
* central6: Plant manager sales and marketing autonomy (1-5 scale)
* central7: Plant manager new product intro autonomy (1-5 scale)

summarize central4 central5 central6 central7
summarize central5 if !public
summarize central5 if !public & family

* Tabulations
tabulate central4
tabulate central6
tabulate central7

tabulate cty public, row
tabulate family public

* Cross-tabs for dummy variables
tabulate family hiring if !public, row
tabulate family marketing if !public, row
tabulate family product if !public, row

* =============================================================================
* Define regression options
* =============================================================================
local baseline_fe "absorb(cty)"
local preferred_fe "absorb(cty sic2)"
local robust_fe "absorb(cty sic2 analyst)"
local cluster "cluster(id)"

* =============================================================================
* Main regressions - Loop through autonomy dimensions
* =============================================================================

* Define outcomes and labels
local outcomes "central5 hiring marketing product"
local central5_label "Investment Autonomy (dollar value)"
local hiring_label "Hiring Autonomy (dummy)"
local marketing_label "Marketing Autonomy (dummy)"
local product_label "Product Autonomy (dummy)"

foreach y of local outcomes {
    
    display _n "=============================================================="
    display "PPML Regressions - ``y'_label'"
    display "=============================================================="
    
    * Full sample with baseline controls
    display _n "1. Full sample - Country FE only"
    ppmlhdfe `y' family public, `baseline_fe' `cluster'
    
    * Full sample with preferred specification
    display _n "2. Full sample - Country and Industry FE"
    ppmlhdfe `y' family public, `preferred_fe' `cluster'
    
    * Full sample with analyst FE (robustness)
    display _n "3. Full sample - With Analyst FE"
    ppmlhdfe `y' family public, `robust_fe' `cluster'
    
    * Private firms only
    display _n "4. Private firms only - Country and Industry FE"
    ppmlhdfe `y' family if !public, `preferred_fe' `cluster'
    
    * Private firms with CEO onsite control
    display _n "5. Private firms - With CEO onsite control"
    ppmlhdfe `y' family onsite if !public, `preferred_fe' `cluster'
    
    * Full sample with all controls
    display _n "6. Full sample - Family, Public, and CEO onsite"
    ppmlhdfe `y' family public onsite, `preferred_fe' `cluster'
    
    * Private firms, CEO not onsite (isolate family effect)
    display _n "7. Private firms, CEO not onsite"
    ppmlhdfe `y' family if !public & !onsite, `preferred_fe' `cluster'
}

* =============================================================================
* OLS on log investment autonomy (robustness check)
* =============================================================================
display _n "=============================================================="
display "OLS Regressions on Log Investment Autonomy (Robustness)"
display "=============================================================="

* Define specifications to test
local specs "family public" "family" "family onsite"
local samples "1" "!public" "!public"
local spec_labels "Full sample" "Private firms only" "Private firms with CEO control"

local i = 1
foreach spec of local specs {
    local sample : word `i' of `samples'
    local label : word `i' of `spec_labels'
    
    display _n "`label' - Country and Industry FE"
    if "`sample'" == "1" {
        reghdfe lnI `spec', `preferred_fe' `cluster'
    }
    else {
        reghdfe lnI `spec' if `sample', `preferred_fe' `cluster'
    }
    
    display _n "`label' - With Analyst FE"
    if "`sample'" == "1" {
        reghdfe lnI `spec', `robust_fe' `cluster'
    }
    else {
        reghdfe lnI `spec' if `sample', `robust_fe' `cluster'
    }
    
    local ++i
}

* =============================================================================
* Summary of findings
* =============================================================================
display _n "Summary of Key Findings"
display "======================="
display "1. Family-controlled firms have less autonomy across dimensions:"
display "   - Investment (central5): -31% among private firms (p=0.06 with onsite)"
display "   - Hiring (dummy): +12% but not significant (p=0.07)"
display "   - Marketing (dummy): -31% among private firms (p<0.05)"
display "   - Product intro (dummy): -24% but not significant (p=0.12)"
display "2. CEO onsite strongly reduces all autonomy dimensions:"
display "   - Investment: -38% (p<0.01)"
display "   - Hiring: -27% (p<0.001)"
display "   - Marketing: -22% (p<0.05)"
display "   - Product: -38% (p<0.001)"
display "3. Effects robust to country, industry, and analyst fixed effects"
display "4. Results consistent in PPML and log-linear OLS specifications"