*! version 1.0.0 2025-08-08
* =============================================================================
* Create unfiltered dataset for table creation
* Combines balance sheet and CEO data with industry classification and variables
* =============================================================================

clear all

use "temp/balance.dta", clear
merge 1:m frame_id_numeric year using "temp/ceo-panel.dta", keep(master match) nogen

* Apply industry classification
do "code/util/industry.do"
do "code/util/variables.do"

* Save unfiltered dataset
save "temp/unfiltered.dta", replace

display "Unfiltered dataset created: temp/unfiltered.dta"