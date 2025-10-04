* =============================================================================
* SAMPLE FILTER PARAMETERS
* =============================================================================
local max_ceos_per_year 2         // Maximum number of CEOs allowed per firm per year
local max_ceo_spells 6            // Maximum CEO spell threshold
local min_firm_age 1              // Minimum firm age (drops age 0)
local excluded_sectors "2, 9"     // Sector codes to exclude (mining, finance)
local min_employment 5           // Minimum employment for analysis

/*
    1 Vállalat
    2 Szövetkezet
    3 Közkereseti társaság
    4 Gazdasági munkaközösség
    5 Jogi személy felelősségvállalásával működő gazdasági munkaközösség
    6 Betéti társaság
    7 Egyesülés
    8 Közös vállalat
    9 Korlátolt felelősségű társaság
    10 Részvénytársaság
    11 Egyéni cég
    12 Külföldiek magyarországi közvetlen kereskedelmi képviselete
    13 Oktatói munkaközösség
    14 Közhasznú társaság
    15 Erdőbirtokossági társulat
    16 Vízgazdálkodási társulat
    17 Külföldi vállalkozás magyarországi fióktelepe
    18 Végrehajtói iroda
    19 Európai gazdasági egyesülés
    20 Európai részvénytársaság
    21 Közjegyzői iroda
    22 Külföldi székhelyű európai gazdasági egyesülés magyarországi telephelye
    23 Európai szövetkezet

*/
* drop firm-years that do not have a CEO
drop if ceo_spell == 0

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

* drop firms with too few employees
summarize max_employment if firm_tag, detail
drop if max_employment < `min_employment'

* clean up
drop max_n_ceo firm_tag