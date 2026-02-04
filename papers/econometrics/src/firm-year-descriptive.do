clear all
use "../../temp/analysis-sample.dta"

/*
sort frame_id_numeric person_id year
by frame_id_numeric person_id: egen min_ceo_spell = min(ceo_spell)
sort frame_id_numeric year person_id
by frame_id_numeric year: gen keep = (ceo_spell == min_ceo_spell)
keep if keep == 1
drop keep
*/
keep if n_ceo < 2
sort frame_id_numeric year person_id
by frame_id_numeric: gen ceo_switch = (ceo_spell != ceo_spell[_n-1])  if _n>1
by frame_id_numeric: gen prev_male = male[_n-1]                       if ceo_switch == 1
by frame_id_numeric: gen prev_founder = founder[_n-1]                 if ceo_switch == 1

replace ceo_switch = 0 if missing(ceo_switch)

sort person_id year
by person_id: gen prev_ind   = teaor08_1d[_n-1]                       if ceo_switch == 1

gen male_to_female  = (prev_male==1 & male==0)
gen female_to_male  = (prev_male==0 & male==1)
gen same_gender     = (prev_male == male)                              if !missing(prev_male)
gen fndr_to_nonfndr = (prev_founder == 1 & founder == 0)
gen insider         = (manager_category == 2)                          if ceo_switch == 1
gen diff_industry   = (teaor08_1d != prev_ind)                        if !missing(teaor08_1d) & !missing(prev_ind)

* Collapse data
collapse (count) nr_firms = frame_id_numeric  ///
         (sum) ceo_switch fndr_to_nonfndr male_to_female female_to_male ///
         same_gender diff_industry insider, by(year)

* Calculate shares
foreach var in fndr_to_nonfndr male_to_female female_to_male same_gender diff_industry insider {
    gen share_`var' = (`var' / ceo_switch) * 100
}

* Create summary statistics
estpost tabstat nr_firms ceo_switch share_*, by(year) statistics(mean) nototal

* Export to LaTeX
esttab using "table/firm-year-descriptives.tex", replace ///
       cells("nr_firms(fmt(0)) ceo_switch(fmt(0)) share_fndr_to_nonfndr(fmt(2)) share_male_to_female(fmt(2)) share_female_to_male(fmt(2)) share_same_gender(fmt(2)) share_diff_industry(fmt(2)) share_insider(fmt(2))") ///
       noobs nonumber nomtitle ///
       collabels("Firms" "CEO Switches" "Founder→Non (\%)" "M→F (\%)" "F→M (\%)" "Same Gender (\%)" "Diff Industry (\%)" "Insider (\%)") ///
       title("CEO Transition Statistics by Year")
