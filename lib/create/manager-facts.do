use "input/manager-db-ceo-panel/ceo-panel.dta", clear

keep frame_id_numeric person_id male birth_year manager_category owner
generate byte hungarian_name = !missing(male)
duplicates drop 

preserve
    drop male birth_year hungarian_name
    save "temp/manager-firm-facts.dta", replace
restore

collapse (firstnm) male birth_year (max) hungarian_name, by(person_id)
save "temp/manager-facts.dta", replace
