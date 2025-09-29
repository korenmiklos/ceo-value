local panelA "output/figure/anova_TFP_event_time.gph"
local panelB "output/figure/anova_TFP_firm_age.gph"
local panelC "output/figure/anova_lnR_event_time.gph"
local panelD "output/figure/anova_lnR_firm_age.gph"

graph combine `panelA' `panelB' `panelC' `panelD', ///
    cols(2) ycommon graphregion(color(white)) imargin(small) xsize(5) ysize(5)

graph export "output/figure/figure3.pdf", replace
