* =============================================================================
* SAMPLE FILTER PARAMETERS
* =============================================================================
local max_ceos_per_year 2         // Maximum number of CEOs allowed per firm per year
local max_ceo_spells 6            // Maximum CEO spell threshold
local min_firm_age 1              // Minimum firm age (drops age 0)
local excluded_sectors "2, 9"     // Sector codes to exclude (mining, finance)

* drop if firm has ever more than specified number of CEOs in a year
egen max_n_ceo = max(n_ceo), by(frame_id_numeric)
egen firm_tag = tag(frame_id_numeric)
tabulate max_n_ceo if firm_tag, missing

drop if max_n_ceo > `max_ceos_per_year'
drop if max_ceo_spell > `max_ceo_spells'

* first year of firm is often incomplete, so we drop it
drop if firm_age < `min_firm_age'

* drop mining and finance sectors
tabulate sector if firm_tag
drop if inlist(sector, `excluded_sectors')

egen ever_state_owned = max(state_owned), by(frame_id_numeric)
drop if ever_state_owned == 1

* clean up
drop max_n_ceo firm_tag