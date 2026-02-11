local T 2
local max_ceo_spells 12            // Must match lib/util/filter.do max_ceo_spells

use "input/manager-db-ceo-panel/ceo-panel.dta", clear

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
bysort frame_id_numeric person_id (year): generate spell = sum(entering_ceo)

* aggregate to actual intervals so that we can do interval algebra later
collapse (min) start_year = year (max) end_year = year, by(frame_id_numeric person_id spell)
tempfile clean_intervals
save "`clean_intervals'", replace
egen N = count(spell), by(frame_id_numeric)
drop spell

* single-ceo firms need not be touched
drop if N == 1

* limit to firms with not too many managers
drop if N > `max_ceo_spells'

* create all pairwise combinations of intervals for each firm
drop N
* which interval within the firm?
bysort frame_id_numeric (start_year person_id): generate interval_id = _n
rename (person_id start_year end_year interval_id) (person_id_1 start_year_1 end_year_1 interval_id_1)
tempfile intervals
save "`intervals'", replace
rename (person_id_1 start_year_1 end_year_1 interval_id_1) (person_id_2 start_year_2 end_year_2 interval_id_2)
joinby frame_id_numeric using "`intervals'"

* self-matches dropped and only of the pair is kept
drop if (interval_id_1 == interval_id_2) | (interval_id_1 > interval_id_2)

* we are using https://en.wikipedia.org/wiki/Allen%27s_interval_algebra
label define relation 1 "before" 2 "meets" 3 "overlaps" 4 "starts" 5 "during" 6 "finishes" 7 "equal" 8 "finished_by" 9 "contains" 10 "started_by" 11 "overlapped_by" 12 "met_by" 13 "after"
generate byte relation = .
replace relation = 1 if end_year_1 < start_year_2 
replace relation = 2 if end_year_1 == start_year_2
replace relation = 3 if end_year_1 > start_year_2 & end_year_1 < end_year_2 & start_year_1 < start_year_2
replace relation = 4 if start_year_1 == start_year_2 & end_year_1 < end_year_2
replace relation = 5 if start_year_1 > start_year_2 & end_year_1 < end_year_2
replace relation = 6 if end_year_1 == end_year_2 & start_year_1 > start_year_2
replace relation = 7 if start_year_1 == start_year_2 & end_year_1 == end_year_2
replace relation = 8 if end_year_1 == end_year_2 & start_year_1 < start_year_2
replace relation = 9 if start_year_1 < start_year_2 & end_year_1 > end_year_2
replace relation = 10 if start_year_1 == start_year_2 & end_year_1 > end_year_2
replace relation = 11 if end_year_1 > start_year_2 & end_year_1 < end_year_2 & start_year_1 > start_year_2
replace relation = 12 if end_year_1 == start_year_2
replace relation = 13 if start_year_1 > end_year_2

label values relation relation
tabulate relation, missing

/* interval cleaning: 
1. if there is a during, contains, starts, finishes, started_by, finished_by, the smaller interval is dropped if less than equal T years
2. if overlaps or overlapped_by, we truncate the earlier interval's end to coincide with the later interval's start if the overlap is less than equal T years
*/

* compute length of intervals
generate length_1 = end_year_1 - start_year_1 + 1
generate length_2 = end_year_2 - start_year_2 + 1

* 1. use inlist
generate byte drop_1 = inlist(relation, 4, 5, 6, 8, 9, 10) & length_1 <= `T'
generate byte drop_2 = inlist(relation, 4, 5, 6, 8, 9, 10) & length_2 <= `T'
* if both are shorter than T, we drop only the shorter
replace drop_1 = 0 if drop_1 == 1 & drop_2 == 1 & length_1 > length_2
replace drop_2 = 0 if drop_1 == 1 & drop_2 == 1 & length_1 < length_2

* 2. flag overlaps to use in #2 with an inlist and compute overlap length with cond()
generate overlap_length = cond(relation == 3, end_year_1 - start_year_2 + 1, end_year_2 - start_year_1 + 1) if inlist(relation, 3, 11)
* which to trance, what year to put in
generate byte truncate_1 = relation == 3 & overlap_length <= `T'
generate byte truncate_2 = relation == 11 & overlap_length <= `T'
generate truncate_year_1 = cond(truncate_1, start_year_2, .)
generate truncate_year_2 = cond(truncate_2, start_year_1, .)

* all other relations are kept intact. sine we only care about moditifcations, they can be dropped from data
drop if !drop_1 & !drop_2 & !truncate_1 & !truncate_2

* now execute all drops and truncations
replace end_year_1 = truncate_year_1 if truncate_1 == 1
replace end_year_2 = truncate_year_2 if truncate_2 == 1

keep person_id_? start_year_? end_year_? interval_id_? truncate_? drop_? frame_id_numeric
generate index = _n
reshape long person_id_ start_year_ end_year_ interval_id_ truncate_ drop_, i(index frame_id_numeric) j(j)
rename *_ *

* of each pair of intervals, exactly one should be modified, otherwise we have a problem
egen Nmod = total(drop | truncate), by(index)
assert Nmod == 1

keep if drop | truncate
keep frame_id_numeric person_id start_year end_year truncate drop
duplicates drop

merge 1:1 frame_id_numeric person_id start_year using "`clean_intervals'", keep(match using match_update match_conflict) update 
tabulate _merge

drop if drop == 1
drop _merge drop truncate

save "temp/intervals.dta", replace
