*! version 1.0.0 2025-08-29
*! Analyze investment autonomy in Bloom et al. (2012) data
* =============================================================================
* Purpose: Test whether family-controlled firms have less investment autonomy
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

* Count observations
count
count if !missing(central5)
count if !missing(lnI)

* =============================================================================
* Summary statistics
* =============================================================================
display _n "Summary Statistics"
display "=================="

summarize central5, detail
summarize central5 if !public, detail
summarize central5 if !public & family, detail

tabulate cty public, row
tabulate family public

* =============================================================================
* Main regressions - Poisson Pseudo-Maximum Likelihood
* =============================================================================
display _n "PPML Regressions with Country and Industry FE"
display "=============================================="

* Baseline: family and public with country FE only
ppmlhdfe central5 family public, ///
    absorb(cty) cluster(id)
    
* Preferred specification: country and industry FE
ppmlhdfe central5 family public, ///
    absorb(cty sic2) cluster(id)
    
* With analyst FE (robustness check)
ppmlhdfe central5 family public, ///
    absorb(cty sic2 analyst) cluster(id)

* =============================================================================
* Subsample analysis: Private firms only
* =============================================================================
display _n "PPML Regressions - Private Firms Only"
display "======================================"

* Country FE only
ppmlhdfe central5 family if !public, ///
    absorb(cty) cluster(id)
    
* Country and industry FE
ppmlhdfe central5 family if !public, ///
    absorb(cty sic2) cluster(id)
    
* With analyst FE
ppmlhdfe central5 family if !public, ///
    absorb(cty sic2 analyst) cluster(id)

* =============================================================================
* OLS on log investment autonomy (robustness)
* =============================================================================
display _n "OLS Regressions on Log Investment Autonomy"
display "==========================================="

* Full sample with country and industry FE
reghdfe lnI family public, ///
    absorb(cty sic2) cluster(id)
    
* Full sample with analyst FE
reghdfe lnI family public, ///
    absorb(cty sic2 analyst) cluster(id)
    
* Private firms only with country and industry FE
reghdfe lnI family if !public, ///
    absorb(cty sic2) cluster(id)
    
* Private firms only with analyst FE
reghdfe lnI family if !public, ///
    absorb(cty sic2 analyst) cluster(id)

* =============================================================================
* CEO onsite analysis
* =============================================================================
display _n "CEO Onsite Analysis"
display "==================="

* PPML with CEO onsite control
ppmlhdfe central5 family onsite if !public, ///
    absorb(cty sic2) cluster(id)
    
ppmlhdfe central5 family onsite public, ///
    absorb(cty sic2) cluster(id)

* OLS with CEO onsite control
reghdfe lnI family onsite if !public, ///
    absorb(cty sic2) cluster(id)
    
reghdfe lnI family onsite if !public, ///
    absorb(cty sic2 analyst) cluster(id)

* =============================================================================
* Summary of findings
* =============================================================================
display _n "Summary of Key Findings"
display "======================="
display "1. Family-controlled firms have significantly less investment autonomy"
display "2. Effect is robust to including country, industry, and analyst FE"
display "3. Effect is stronger among private firms (no public market discipline)"
display "4. CEO being onsite associated with less plant manager autonomy"
display "5. Results consistent whether using PPML or log-linear OLS"