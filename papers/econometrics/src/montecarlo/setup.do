*! Monte Carlo simulation for placebo-controlled event study
*! Expects locals: rho, sigma_epsilon0, sigma_epsilon1, hazard, T_max

confirm existence "`rho_control'"
confirm existence "`rho_treated'"
confirm existence "`sigma_epsilon0'"
confirm existence "`sigma_epsilon1'"
confirm existence "`hazard'"
confirm existence "`T_max'"
confirm existence "`N_changes'"
confirm existence "`sigma_z'"
confirm existence "`control_treated_ratio'"

assert `rho_control' >= 0 & `rho_control' < 1
assert `rho_treated' >= 0 & `rho_treated' < 1
assert `sigma_epsilon0' > 0
assert `sigma_epsilon1' > 0
assert `hazard' >= 0
assert `T_max' > 0
assert `N_changes' > 0 & `N_changes' == floor(`N_changes')
assert `sigma_z' > 0
assert `control_treated_ratio' >= 0 

clear all

set seed 2191
set obs `N_changes'
generate frame_id_numeric = _n

if `hazard' == 0 {
	generate T1 = `T_max'
	generate T2 = `T_max'
}
else {
	generate T1 = invexponential(1/`hazard', uniform())
	generate T2 = invexponential(1/`hazard', uniform())
	replace T1 = ceil(T1)
	replace T2 = ceil(T2)
}

keep if T1 <= `T_max' & T2 <= `T_max'
tabulate T1

* now construct placebo pairs
expand 1 + `control_treated_ratio', generate(placebo)
bysort frame_id_numeric (placebo): generate index = _n
tabulate index placebo
egen fake_id = group(frame_id_numeric index)

* now add the time dimension
expand T1 + T2
bysort fake_id: generate year = _n
generate byte ceo_spell = cond(year <= T1, 1, 2)

xtset fake_id year
generate change_year = T1 + 1

tabulate T1 placebo, row

generate dlnR = rnormal(0, cond(placebo == 1, `sigma_epsilon0', `sigma_epsilon1'))
bysort fake_id (year): generate lnR = 0 if _n == 1
bysort fake_id (year): replace lnR = `rho_control' * lnR[_n-1] + dlnR if _n > 1 & placebo == 1
bysort fake_id (year): replace lnR = `rho_treated' * lnR[_n-1] + dlnR if _n > 1 & placebo == 0


generate dz = rnormal(0, `sigma_z')
summarize dz
* only one dz per treated firm
egen z = mean(cond(year == change_year & placebo == 0, dz, .)), by(fake_id)

replace lnR = lnR + z if placebo == 0 & year >= change_year

* measured manager skill will include noise
egen manager_skill = mean(lnR), by(fake_id ceo_spell)
* demean manager skill
summarize manager_skill if placebo == 0, meanonly
replace manager_skill = manager_skill - r(mean)

* verify I have all the variables I need
local vars frame_id_numeric year lnR ceo_spell manager_skill change_year placebo fake_id
confirm numeric variable `vars'
keep `vars'

/*
## Required Variables (Contract Inputs)

Panel structure:

• frame_id_numeric - Firm identifier
• year - Time variable
• lnR - Outcome variable (must be non-missing)

CEO tracking:

• ceo_spell - CEO tenure periods within firm
• manager_skill - Manager quality measure

From placebo structure:

• change_year - Year of CEO transition
• placebo - Binary (0=actual, 1=placebo)
• fake_id - Synthetic firm identifier

## Key Expectations

1. Panel completeness: Firms must have observations in both CEO spells (ceo_spell
1 and 2) with non-missing lnR
2. CEO spell numbering: ceo_spell should be sequential integers starting from some
value (script normalizes to 1,2)
3. Time consistency: year values must align with window_start/window_end and
change_year relationships
4. Skill assignment: manager_skill should be consistent within CEO spells but can
vary between spells

That's the contract - your simulation needs to generate these variables with the
expected structure and relationships.
*/

