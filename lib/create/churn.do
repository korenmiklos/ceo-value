keep frame_id_numeric year person_id 
duplicates drop

drop if missing(frame_id_numeric, person_id, year)
egen fp = group(frame_id_numeric person_id)
xtset fp year, yearly

* we are glossing over potholes of 1 or 2 years
bysort fp (year): generate gap = year - year[_n-1] - 1
replace gap = 0 if missing(gap)
* number of clones to create of CEO
generate clones = 1
forvalues t = 1/2 {
    replace clones = `t' + 1 if gap == `t'
}
expand clones
bysort fp year: replace year = year - _n + 1

drop gap clones fp

* test whether potholes have been filled
* we are glossing over potholes of 1 or 2 years
bysort frame_id_numeric person_id (year): generate gap = year - year[_n-1] - 1
replace gap = 0 if missing(gap)
tabulate gap, missing

assert gap == 0 | gap > 2

egen fp = group(frame_id_numeric person_id)
xtset fp year, yearly

generate byte entering_ceo = missing(L.year)
generate byte leaving_ceo = missing(F.year)

* the same person may have multiple spells at the firm
bysort frame_id_numeric person_id (year): generate ceo_spell = sum(entering_ceo)
egen spell_start = min(year), by(frame_id_numeric person_id ceo_spell)
tabulate ceo_spell, missing

* our only goal is to count CEO spells in the life of the company
collapse (max) entering_ceo leaving_ceo (count) n_ceo = person_id (min) min_spell = spell_start, by(frame_id_numeric year)
xtset frame_id_numeric year, yearly
generate byte ceo_left = L.leaving_ceo == 1

bysort frame_id_numeric (year): generate ceo_spell = sum(entering_ceo | ceo_left)
egen spell_start = min(year), by(frame_id_numeric ceo_spell)

egen max_n_ceo = max(n_ceo), by(frame_id_numeric)
tabulate max_n_ceo 
drop if max_n_ceo > 2

* check for continuity of a single CEO, we keep her if there is turbulance for max 2 years
xtset frame_id_numeric year, yearly
egen T_spell = count(year), by(frame_id_numeric ceo_spell)
generate byte tbsp = (n_ceo > 1 | L.n_ceo > 1) & (L.ceo_spell != ceo_spell) & L.min_spell == min_spell
egen byte turbulent_spell = max(tbsp), by(frame_id_numeric ceo_spell)

tabulate T_spell turbulent_spell, missing

* newly count CEO spells, ignoring turbulent spells
bysort frame_id_numeric (year): generate new_ceo_spell = sum((entering_ceo | ceo_left) & !(turbulent_spell & (T_spell <= 2 | L.T_spell <= 2)))
keep frame_id_numeric year new_ceo_spell
