args sample outcome
confirm file "temp/placebo_`sample'.dta"
confirm existence `outcome'

global figure_window_start -9      // Figure window start
global figure_window_end 9         // Figure window end
global event_window_start = -($figure_window_end - $figure_window_start + 1)
global event_window_end = $figure_window_end
global baseline_year = $figure_window_start

do "code/estimate/setup_anova.do" `sample'
confirm numeric variable `outcome'

egen sometimes_missing = max(missing(`outcome')), by(fake_id)
drop if sometimes_missing == 1
drop sometimes_missing

drop if firm_age < 2
egen Y_at_2 = mean(cond(firm_age == 2, `outcome', .)), by(fake_id)
generate dY = `outcome' - Y_at_2

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

/*xt2treatments dY, treatment(actual_ceo) control(placebo_ceo) pre(`=-1*${event_window_start}') post(${event_window_end}) baseline(${baseline_year}) weighting(equal) cluster(${cluster})

xt2treatments dY, treatment(actual_ceo) control(placebo_ceo) pre(`=-1*${event_window_start}') post(${event_window_end}) baseline(${baseline_year}) weighting(optimal) cluster(${cluster})
e2frame, generate(ceo_mean)

forvalues t = `=100+$event_window_start'/`=100+$event_window_end' {
    generate byte E0_`t' = event_time == `t' - 100
    generate byte Ed_`t' = (placebo == 0) & (event_time == `t' - 100)
}
* no firm fixed effects, we assume that, without treatment, variance of control would be the same as variance of treated
reghdfe dY2 Ed* if event_window , a(event_time firm_age) cluster(frame_id_numeric ) resid nocons 
predict ATET2a, xb*/

egen control_variance = sd(cond(placebo == 1, dY, .)), by(event_time firm_age)
egen treated_variance = sd(cond(placebo == 0, dY, .)), by(event_time firm_age)
replace control_variance = control_variance^2
replace treated_variance = treated_variance^2

* firms may differ in variance of growth rates, which shows up as a pretrend for Var(dY)
* because dY is cumulated over firm age
* multiplicative pretrend in variance by firm age
egen v0a = mean(cond(event_time < 0, control_variance, .)), by(firm_age)
egen v1a = mean(cond(event_time < 0, treated_variance, .)), by(firm_age)
generate var_ratio = v1a/v0a
replace var_ratio = 1 if firm_age == 2

table firm_age, statistic(mean var_ratio)

generate ATET2b = cond(placebo == 0, treated_variance - var_ratio * control_variance, 0)

*correlate ATET2a ATET2b if event_window & !placebo

*table event_time placebo if event_window, statistic(mean dY2)
*table event_time if event_window & !placebo, statistic(mean ATET2a ATET2b)

* very similar estimates, we use simple means now
* FIXME: report standard errors
table firm_age if !placebo, statistic(variance dY) statistic(mean ATET2b)
egen sd_dY1 = sd(cond(placebo == 0, dY, .)), by(firm_age)
egen sd_dY00 = sd(cond(placebo == 1, dY, .)), by(firm_age)
generate var_dY00 = sd_dY00^2
generate var_dY1 = sd_dY1^2
egen var_dY0 = mean(cond(placebo == 0, var_dY1 - ATET2b, .)), by(firm_age)
generate sd_dY0 = sqrt(var_dY0)

egen fat = tag(firm_age)
line var_dY1 var_dY0 var_dY00 firm_age if fat & inrange(firm_age, 2, `=$figure_window_end-$figure_window_start+1'), sort ///
    title("Variance of TFP by Firm Age") ///
    xtitle("Firm Age (years)") ///
    xlabel(2(2)`=$figure_window_end-$figure_window_start+1') ///
    yscale(range(0 .)) ///
    ytitle("Variance of TFP (log points squared)") ///
    legend(order(1 "Total" 2 "Without CEO change" 3 "Placebo") rows(1) position(6)) ///
    aspectratio(1) xsize(5) ysize(5) ///
    lcolor(blue red black)

graph export "output/figure/variance_by_firm_age_`sample'_`outcome'.pdf", replace

drop sd_* var_*
egen sd_dY1 = sd(cond(placebo == 0, dY, .)), by(event_time firm_age)
generate var_dY1 = sd_dY1^2
egen sd_dY00 = sd(cond(placebo == 1, dY, .)), by(event_time firm_age)
generate var_dY00 = sd_dY00^2
egen var_dY0 = mean(cond(placebo == 0, var_dY1 - ATET2b, .)), by(event_time firm_age)
* compute mean variance by event time
egen Evar_dY1 = mean(var_dY1), by(event_time)
egen Evar_dY0 = mean(var_dY0), by(event_time)
egen Evar_dY00 = mean(var_dY00), by(event_time)

egen ett = tag(event_time)
line Evar_dY1 Evar_dY0 Evar_dY00 event_time if ett & inrange(event_time, $figure_window_start, $figure_window_end), sort ///
    title("Variance of TFP by Event Time") ///
    xtitle("Event Time (years)") ///
    xlabel($figure_window_start(1)$figure_window_end) ///
    xline(-0.5) xscale(range ($figure_window_start $figure_window_end)) ///
    ytitle("Variance of TFP (log points squared)") ///
    yscale(range(0 .)) ///
    legend(order(1 "Total" 2 "Without CEO change" 3 "Placebo") rows(1) position(6)) ///
    aspectratio(1) xsize(5) ysize(5) ///
    lcolor(blue red black)

graph export "output/figure/variance_by_event_time_`sample'_`outcome'.pdf", replace

drop Evar*
* remove firm age effect - variance naturally increases with firm age
egen A1 = mean(cond(placebo == 0, var_dY1, .)), by(firm_age)
egen A0 = mean(cond(placebo == 0, var_dY0, .)), by(firm_age)
* compute mean variance by event time
egen Evar_dY1 = mean(var_dY1 - A1), by(event_time)
egen Evar_dY0 = mean(var_dY0 - A0), by(event_time)
* normalize to baseline year
summarize Evar_dY1 if event_time == ${baseline_year}
local m1 = r(mean)
summarize Evar_dY0 if event_time == ${baseline_year}
local m0 = r(mean)
replace Evar_dY1 = Evar_dY1 - `m1'
replace Evar_dY0 = Evar_dY0 - `m0'

line Evar_dY1 Evar_dY0 event_time if ett & inrange(event_time, $figure_window_start, $figure_window_end), sort ///
    title("Variance of TFP by Event Time") ///
    xtitle("Event Time (years)") ///
    xlabel($figure_window_start(1)$figure_window_end) ///
    xline(-0.5) xscale(range ($figure_window_start $figure_window_end)) ///
    ytitle("Variance of TFP (log points squared)") ///
    legend(order(1 "Total" 2 "Without CEO change") rows(1) position(6)) ///
    aspectratio(1) xsize(5) ysize(5) ///
    lcolor(blue red)

graph export "output/figure/variance_wo_age_`sample'_`outcome'.pdf", replace
