* drop if firm has ever more than 2 CEOs in a year
egen max_n_ceo = max(n_ceo), by(frame_id_numeric)
egen firm_tag = tag(frame_id_numeric)
tabulate max_n_ceo if firm_tag, missing

drop if max_n_ceo > 2

drop if max_ceo_spell > 6

* drop agriculture, mining, construction and finance sectors
tabulate sector if firm_tag
drop if inlist(sector, 1, 2, 6, 9)

* clean up
drop max_n_ceo firm_tag max_ceo_spell