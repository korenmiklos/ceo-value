local sampleA baseline
local sampleB baseline
local sampleC baseline
local sampleD persistent
local sampleE persistent
local sampleF persistent
local sampleG excessvariance
local sampleH excessvariance
local sampleI excessvariance
local sampleJ all
local sampleK all
local sampleL all

local outcomeA VarY
local outcomeB Cov
local outcomeC beta
local outcomeD VarY
local outcomeE Cov
local outcomeF beta
local outcomeG VarY
local outcomeH Cov
local outcomeI beta
local outcomeJ VarY
local outcomeK Cov
local outcomeL beta


local titleA "Var (Base)"
local titleB "Cov (Base)"
local titleC "Beta (Base)"
local titleD "Var (Pers)"
local titleE "Cov (Pers)"
local titleF "Beta (Pers)"
local titleG "Var (Var)"
local titleH "Cov (Var)"
local titleI "Beta (Var)"
local titleJ "Var (All)"
local titleK "Cov (All)"
local titleL "Beta (All)"


foreach panel in A B C D E F G H I J K L {
    local sample  `sample`panel''
    local title  `title`panel''
    local outcome `outcome`panel''

    import delimited "data/`sample'_lnR-lnR.csv", clear case(preserve)
    * drop ATET estimates
    drop if xvar == "ATET"

    foreach X in `outcome'1 d`outcome' {
        capture generate upper_`X' = coef_`X' + 1.96*se_`X'
        capture generate lower_`X' = coef_`X' - 1.96*se_`X'
    }

    if "`sample'" == "all" {
        do "src/exhibit/event_study3.do" `panel' "`title'" "`ytitle'" `outcome'
    }
    else {
        do "src/exhibit/event_study2.do" `panel' "`title'" "`ytitle'" `outcome'
    }
}

graph combine panelA panelB panelC panelD panelE panelF panelG panelH panelI panelJ panelK panelL, ///
    cols(3) graphregion(color(white)) imargin(small) xsize(5) ysize(7.5) ycommon

graph export "figure/figuremc.pdf", replace
