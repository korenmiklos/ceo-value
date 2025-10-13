args outcome
local sample fnd2non12

confirm file "temp/placebo_`sample'.dta"
confirm existence `outcome'

global figure_window_start -5      // Figure window start
global figure_window_end 5         // Figure window end
global event_window_start = -($figure_window_end - $figure_window_start + 1)
global event_window_end = $figure_window_end
global baseline_year = $figure_window_start
local graph_options ///
    lcolor(blue red) mcolor(blue red)), /// 
    yscale(range(0 .)) ///
    ylabel(#5) ///
    ytitle("Variance of `lbl' Growth") ///
    legend(order(1 "Total" 2 "Without CEO change") rows(1) position(6)) ///
    aspectratio(1) xsize(5) ysize(5) ///


do "lib/estimate/setup_anova.do" `sample'
confirm numeric variable `outcome'
local lbl : variable label `outcome'

egen sometimes_missing = max(missing(`outcome')), by(fake_id)
drop if sometimes_missing == 1
drop sometimes_missing

drop if firm_age < 2
egen Y_at_2 = mean(cond(firm_age == 2, `outcome', .)), by(fake_id)
generate dY = `outcome' - Y_at_2

generate age_at_change = change_year - foundyear 

local lbl : variable label `outcome'
label variable dY "Change in `lbl' relative to t-1"

generate event_time = year - change_year
generate byte event_window = inrange(event_time, ${event_window_start}, ${event_window_end})

table event_time placebo if event_window, stat(mean dY)
table event_time placebo if event_window, stat(var dY)

egen control_mean = mean(cond(placebo == 1, dY, .)), by(event_time firm_age)
egen treated_mean = mean(cond(placebo == 0, dY, .)), by(event_time firm_age)
generate ATET1 = cond(placebo == 0, treated_mean - control_mean, 0)

generate dY2 = (dY - ATET1)^2

* firms may differ in variance of growth rates, which shows up as a pretrend for Var(dY)
* because dY is cumulated over firm age
* multiplicative pretrend in variance by firm age
* estimate pretrends with PPML
ppmlhdfe dY2 placebo ib3.firm_age if (event_time <=0 | placebo == 1) & (firm_age > 2), cluster(frame_id_numeric)
predict V, mu
replace V = 0 if firm_age == 2

* expand V to every firm in the cell
egen age_pretrend = mean(V), by(firm_age placebo)
table firm_age placebo, statistic(mean age_pretrend)

egen control_variance = mean(cond(placebo == 1, dY2 - age_pretrend, .)), by(event_time firm_age)
egen treated_variance = mean(cond(placebo == 0, dY2 - age_pretrend, .)), by(event_time firm_age)
generate ATET2b = cond(placebo == 0, treated_variance - control_variance, 0)
* treated firms should change CEO in the event window
keep if age_at_change <= $figure_window_end - $figure_window_start + 2 | placebo == 1

* very similar estimates, we use simple means now
* FIXME: report standard errors
table firm_age if !placebo, statistic(variance dY) statistic(mean ATET2b)
egen sd_dY1 = sd(cond(placebo == 0 & event_time >= 0, dY, .)), by(firm_age)
generate var_dY1 = sd_dY1^2
egen var_dY0 = mean(cond(placebo == 0 & event_time >= 0, var_dY1 - ATET2b, .)), by(firm_age)
generate sd_dY0 = sqrt(var_dY0)

egen fat = tag(firm_age)
graph twoway (connected var_dY1 var_dY0 firm_age if fat & inrange(firm_age, 2, `=$figure_window_end-$figure_window_start+2'), sort ///
    `graph_options' ///
    title("Panel A: By Firm Age") ///
    xtitle("Firm Age (years)") ///
    xlabel(2(2)`=$figure_window_end-$figure_window_start+2') ///
    name(panelA, replace)

drop sd_* var_*
egen sd_dY1 = sd(cond(placebo == 0, dY, .)), by(event_time firm_age)
generate var_dY1 = sd_dY1^2
replace var_dY1 = 0 if firm_age == 2
egen var_dY0 = mean(cond(placebo == 0, var_dY1 - ATET2b, .)), by(event_time firm_age)
* compute mean variance by event time
egen Evar_dY1 = mean(var_dY1), by(event_time)
egen Evar_dY0 = mean(var_dY0), by(event_time)

egen ett = tag(event_time)
graph twoway (connected Evar_dY1 Evar_dY0 event_time if ett & inrange(event_time, $figure_window_start, $figure_window_end), sort ///
    `graph_options' ///
    title("Panel B: By Event Time") ///
    xtitle("Time Since CEO change (years)") ///
    xlabel($figure_window_start(1)$figure_window_end) ///
    xline(-0.5) ///
    name(panelB, replace)

graph combine panelA panelB, cols(2) ycommon graphregion(color(white)) imargin(small) xsize(5) ysize(2.5)

graph export "output/figure/anova_`outcome'.pdf", replace

* now create table
keep if inrange(firm_age, 2, 12)
* compute mean and variance of TFP growth

summarize dY if placebo == 0 & firm_age == 2, meanonly
assert abs(r(mean)) < 1e-6

forvalues a = 3/12 {
    display "Variance decomposition for firm age `a'" _newline
    summarize dY if placebo == 0 & firm_age == `a' & age_at_change <= `a'
    scalar mean_dY`a' = r(mean)
    scalar var_dY`a' = r(Var)

    summarize dY if placebo == 1 & firm_age == `a'
    scalar mean_dY`a'_placebo = r(mean)
    scalar var_dY`a'_placebo = r(Var)

    summarize var_dY1 if firm_age == `a' & age_at_change <= `a'
    scalar var_dY`a'b = r(mean)

    summarize var_dY0 if firm_age == `a' & age_at_change <= `a'
    scalar var_dY`a'_counterfactual = r(mean)

    reghdfe dY manager_skill if inlist(firm_age, 2, `a') & placebo == 0  & age_at_change <= `a', absorb(frame_id_numeric) cluster(frame_id_numeric)
    scalar naive_share_`a' = e(r2_within)
    scalar adjusted_share_`a' = 1 - (var_dY`a'_counterfactual / var_dY`a'b)
}
scalar list

/*
Put this in a latex table

Firm age | Var TFP growth since age 2 | Naive ANOVA share | Adjusted ANOVA share
---------|---------------------------|------------------|-----------------------
4        | var_dY4                   | naive_share_4    | adjusted_share_4
8        | var_dY8                   | naive_share_8    | adjusted_share_8
12       | var_dY12                  | naive_share_12   | adjusted_share_12

*/

file open results using "output/table/anova_`outcome'.tex", write replace
file write results "\begin{tabular}{lccc}" _newline
file write results "Firm age & Var `lbl' growth since age 2 & Naive ANOVA share & Adjusted ANOVA share \\" _newline
file write results "\hline" _newline
foreach a of numlist 4 8 12 {
    file write results (`a') " & " 
    file write results %9.3f (var_dY`a') " & " 
    file write results %6.3f (naive_share_`a') " & " 
    file write results %6.3f (adjusted_share_`a') " \\" _newline
}
file write results "\end{tabular}" _newline
file close results
