args sample outcome montecarlo

confirm file "data/placebo_`sample'.dta"

* =============================================================================
* EVENT STUDY PARAMETERS
* =============================================================================
global event_window_start -4      // Event study window start
global event_window_end 3         // Event study window end
global baseline_year -1            // Baseline year for event study
global random_seed 2181            // Random seed for reproducibility
global sample 100                   // Sample selection for analysis
global cluster frame_id_numeric     // Clustering variable
global T_min 1

* report package versions
which xt2treatments
* clustering requites xt2treatments 0.9 or higher
which estout
which reghdfe
which e2frame

if !("`montecarlo'" == "montecarlo") {
    use "../../temp/surplus.dta", clear
    merge 1:1 frame_id_numeric person_id year using "../../temp/analysis-sample.dta", keep(match) nogen
    merge m:1 frame_id_numeric person_id using "../../temp/manager_value.dta", keep(master match) nogen
    confirm numeric variable `outcome'

    * sample for performance when testing
    set seed ${random_seed}
    egen firm_tag = tag(frame_id_numeric)
    generate byte in_sample = uniform() < ${sample}/100 if firm_tag
    egen ever_in_sample = max(in_sample), by(frame_id_numeric)
    keep if ever_in_sample == 1
    drop ever_in_sample in_sample firm_tag

    * the same firm may appear multipe times as control, repeat those observations
    joinby frame_id_numeric using "data/placebo_`sample'.dta"

    * limit to relevant CEO spells
    keep if inrange(year, window_start, window_end)
    * for 2-ceo firms, only keep 1 of them, these are only placebo anyway
    tabulate n_ceo
    bysort fake_id year (person_id): generate keep = _n == 1
    tabulate n_ceo keep
    keep if keep == 1
    drop keep
    * bad naming, sorry!
}
else {
    use "data/placebo_`sample'.dta", clear
}
* check balance
tabulate year placebo
tabulate change_year placebo

* reindex CEO spells, 1 is found, 2 is non-founder
egen first_spell = min(ceo_spell), by(fake_id)
replace ceo_spell = ceo_spell - first_spell + 1

* create fake CEO spells for placebo group
tabulate ceo_spell placebo
* should be 1 and 2 only
summarize ceo_spell if placebo == 0
local s1 = r(min)
local s2 = r(max)
assert `s1' == 1
assert `s2' == 2
replace ceo_spell = `s1' if placebo == 1 & year < change_year
replace ceo_spell = `s2' if placebo == 1 & year >= change_year
tabulate ceo_spell placebo

* CEO skill is also fake, computed from actual outcome
egen fake_manager_skill = mean(`outcome'), by(fake_id ceo_spell)
* always use fake manager skill, we are doing dynamic estimates here
replace manager_skill = fake_manager_skill
drop fake_manager_skill

* limit event window here, not sooner so that placebo is constructed correctly
keep if inrange(year, change_year + ${event_window_start}, change_year + ${event_window_end})

keep if !missing(`outcome')
egen T1 = total(cond(ceo_spell == `s1', !missing(`outcome'), .)), by(fake_id)
egen T2 = total(cond(ceo_spell == `s2', !missing(`outcome'), .)), by(fake_id)
keep if T1 >= ${T_min} & T2 >= ${T_min}
drop T1 T2

* now create helper variables for event study
egen MS1 = mean(cond(ceo_spell == `s1', manager_skill, .)), by(fake_id)
egen MS2 = mean(cond(ceo_spell == `s2', manager_skill, .)), by(fake_id)
generate byte good_ceo = (MS2 > MS1)

egen byte firm_tag = tag(fake_id)
generate event_time = year - change_year

tabulate good_ceo if firm_tag, missing
tabulate event_time good_ceo, missing

generate byte actual_ceo = event_time >= 0 & placebo == 0
generate byte placebo_ceo = event_time >= 0 & placebo == 1
generate byte better_ceo = event_time >= 0 & good_ceo == 1
generate byte worse_ceo = event_time >= 0 & good_ceo == 0

xtset fake_id year
