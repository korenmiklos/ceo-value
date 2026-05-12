*! Extract ATET estimates from Monte Carlo scenarios and write to LaTeX table row

clear all

* Define scenarios in order matching table columns
local scenarios "baseline excessvariance excessvariance_corr longpanel"
local scenario_labels "& Baseline & Excess Variance & E. V. with Correction & Long Panel"

* which results to extract for the table
local row1 (Var1z1[1] + Var1z1[2])/2
local row2 (dVarz1[1] + dVarz1[2])/2
local row3 (Cov1[2]-Cov1[1])
local row4 (dCov1[2]-dCov1[1])
local row5 Rsq[1]
local row6 dRsq[1]
local row7 Rsq[8]
local row8 dRsq[8]
* compute p values for significance stars

local label1 "\addlinespace$\hat Var(dz) (OLS)"
local label2 "$\hat Var(dz)$ (debiased)"
local label3 "\addlinespace$\hat Cov(dz, dy)$ (OLS)"
local label4 "$\hat Cov(dz,dy)$ (debiased)"
local label5 "\addlinespace $ R^2$ (Naive)"
local label6 "$ R^2$ (debiased)"
local label7 "\addlinespace $ R^2$ at t=3 (Naive)"
local label8 "$ R^2$ at t=3 (debiased)"

local rows 8

matrix stats = J(`rows', 4, .)
matrix ps = J(`rows', 4, 0.99999)

* Loop through scenarios and extract ATET
local col = 1
foreach scenario of local scenarios {

    * Import CSV file
    import delimited "data/atet_`scenario'_lnR-lnR.csv", clear varnames(1) case(preserve)

    forvalues row = 1/6 {
        matrix stats[`row', `col'] = `row`row''
        if "`p`row''" != "" {
            matrix ps[`row', `col'] = `p`row''
        }
    }

    import delimited "data/`scenario'_lnR-lnR.csv", clear varnames(1) case(preserve)

    forvalues row = 7/`rows'{
      matrix stats[`row', `col'] = `row`row''
        if "`p`row''" != "" {
            matrix ps[`row', `col'] = `p`row''
        }

    }

    local ++col
}

matrix list stats

* Open LaTeX file for writing
file open texfile using "table/atets.tex", write replace
file write texfile "`scenario_labels'"
* Function to write a row
forvalues row = 1/`rows' {
    * Set row label
    file write texfile "\\" _n
    file write texfile "`label`row'' & "
    forvalues i = 1/4 {
        local coef = stats[`row', `i']
        local coef_str = string(`coef', "%5.3f")
        local stars ""
        if matrix(ps[`row', `i']) < 0.01 {
            local stars "***"
        }
        else if matrix(ps[`row', `i']) < 0.05 {
            local stars "**"
        }
        else if matrix(ps[`row', `i']) < 0.1 {
            local stars "*"
        }
        * Write to file
        if `i' < 6 {
            file write texfile "$`coef_str'^{`stars'}$ & "
        }
        else {
            file write texfile "$`coef_str'^{`stars'}$"
        }
    }
}

file close texfile

