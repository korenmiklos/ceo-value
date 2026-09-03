args sample
confirm existence `sample'

local valid_samples full pre2000 post2000 size1 size2 size3 size4
assert strpos(" `valid_samples' ", " `sample' ") > 0

use "temp/unfiltered.dta", clear

* Note: unfiltered.dta already contains merged balance sheet and CEO data
* with industry classification and variables applied
do "lib/util/filter.do" `sample'

compress

save "temp/`sample'-analysis-sample.dta", replace
