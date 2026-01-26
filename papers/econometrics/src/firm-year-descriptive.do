clear all
use "../../temp/analysis-sample.dta"

drop if n_ceo > 1

sort originalid year person_id
by originalid: gen ceo_switch = (person_id != person_id[_n-1])  if _n > 1
by originalid: gen prev_male  = male[_n-1]                      if ceo_switch == 1
by originalid: gen prev_found = founder[_n-1]                   if ceo_switch == 1

sort person_id year originalid 
by person_id: gen prev_ind   = teaor08_1d[_n-1]                if ceo_switch == 1

gen male_to_female  = (prev_male==1 & male==0)            if ceo_switch == 1
gen female_to_male  = (prev_male==0 & male==1)            if ceo_switch == 1
gen same_gender     = (prev_male == male)                 if ceo_switch == 1
gen fndr_to_nonfndr = (prev_found == 1 & founder == 0)    if ceo_switch == 1
gen diff_industry   = (teaor08_1d != prev_ind)            if ceo_switch == 1 & !missing(teaor08_1d) & !missing(prev_ind)


preserve

* Collapse data
collapse (count) nr_firms=originalid ///
         (sum) nr_ceo_switches=ceo_switch fndr_to_nonfndr ///
         male_to_female female_to_male same_gender diff_industry, by(year)

* Calculate shares
foreach var in fndr_to_nonfndr male_to_female female_to_male same_gender diff_industry {
    gen share_`var' = (`var' / nr_ceo_switches) * 100
}

* Create summary statistics
estpost tabstat nr_firms nr_ceo_switches share_*, by(year) statistics(mean) nototal

* Export to LaTeX
esttab using "table/firm-year-descriptives.tex", replace ///
       cells("nr_firms(fmt(0)) nr_ceo_switches(fmt(0)) share_fndr_to_nonfndr(fmt(2)) share_male_to_female(fmt(2)) share_female_to_male(fmt(2)) share_same_gender(fmt(2)) share_diff_industry(fmt(2))") ///
       noobs nonumber nomtitle ///
       collabels("Firms" "CEO Switches" "Founder→Non (\%)" "M→F (\%)" "F→M (\%)" "Same Gender (\%)" "Diff Industry (\%)") ///
       title("CEO Transition Statistics by Year")

restore
