import delimited "data/full_lnK-ROA.csv", clear case(preserve)
do "src/exhibit/final_event_study.do" lnK "lnK" "lnK" beta
graph export "figure/outcomes_full_lnK_ROA.pdf", replace

import delimited "data/full_lnWL-lnR.csv", clear case(preserve)
do "src/exhibit/final_event_study.do" lnWL "lnWL" "lnWL" beta
graph export "figure/outcomes_full_lnWL_lnR.pdf", replace
