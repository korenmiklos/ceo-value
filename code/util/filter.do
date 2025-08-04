* drop if firm has ever more than 2 CEOs in a year
egen max_n_ceo = max(n_ceo), by(frame_id_numeric)
egen firm_tag = tag(frame_id_numeric)
tabulate max_n_ceo if firm_tag, missing

drop if max_n_ceo > 2
drop if max_ceo_spell > 6

* first year of firm is often incomplete, so we drop it
drop if firm_age == 0

* drop mining and finance sectors
tabulate sector if firm_tag
drop if inlist(sector, 2, 9)

egen ever_state_owned = max(state_owned), by(frame_id_numeric)
drop if ever_state_owned == 1

* clean up
drop max_n_ceo firm_tag