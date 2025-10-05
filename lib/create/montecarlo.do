clear all

* number of CEO changes
local N_changes = 10000
* hazard rate of CEO change
local hazard = 0.2
* stdev of CEO ability, sqrt(0.01)
local sigma_z = 0.1
local half_normal = 0.797885
local true_effect = `half_normal' * `sigma_z'
* stdev of TFP growth, sqrt(0.025/10)
local sigma_epsilon0 = 0.05
* add some excess variance to treated firms
local sigma_epsilon1 = 0.06
local rho = 0.97
* control to treated N
local control_treated_ratio = 9
* longest spell to consider
local T_max = 20

set seed 2191
set obs `N_changes'
generate frame_id_numeric = _n

generate T1 = invexponential(1/`hazard', uniform())
generate T2 = invexponential(1/`hazard', uniform())
replace T1 = ceil(T1)
replace T2 = ceil(T2)

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

generate dTFP = rnormal(0, cond(placebo == 0, `sigma_epsilon0', `sigma_epsilon1'))
bysort fake_id (year): generate TFP = 0 if _n == 1
bysort fake_id (year): replace TFP = `rho' * TFP[_n-1] + dTFP if _n > 1

generate dz = rnormal(0, `sigma_z')
summarize dz
* only one dz per treated firm
egen z = mean(cond(year == change_year & placebo == 0, dz, .)), by(fake_id)

replace TFP = TFP + z if placebo == 0 & year >= change_year

* measured manager skill will include noise
egen manager_skill = mean(TFP), by(fake_id ceo_spell)
* demean manager skill
summarize manager_skill if placebo == 0, meanonly
replace manager_skill = manager_skill - r(mean)

* verify I have all the variables I need
local vars frame_id_numeric year TFP ceo_spell manager_skill change_year placebo fake_id
confirm numeric variable `vars'
keep `vars'

/*
## Required Variables (Contract Inputs)

Panel structure:

• frame_id_numeric - Firm identifier
• year - Time variable
• TFP - Outcome variable (must be non-missing)

CEO tracking:

• ceo_spell - CEO tenure periods within firm
• manager_skill - Manager quality measure

From placebo structure:

• change_year - Year of CEO transition
• placebo - Binary (0=actual, 1=placebo)
• fake_id - Synthetic firm identifier

## Key Expectations

1. Panel completeness: Firms must have observations in both CEO spells (ceo_spell
1 and 2) with non-missing TFP
2. CEO spell numbering: ceo_spell should be sequential integers starting from some
value (script normalizes to 1,2)
3. Time consistency: year values must align with window_start/window_end and
change_year relationships
4. Skill assignment: manager_skill should be consistent within CEO spells but can
vary between spells

That's the contract - your simulation needs to generate these variables with the
expected structure and relationships.
*/

generate true_effect = `true_effect'
save "temp/placebo_montecarlo.dta", replace

* check no mean ATET but 0.01 variance ATET

generate TFP2 = TFP^2
generate byte treatment = placebo == 0 & year >= change_year
reghdfe TFP treatment, absorb(fake_id year) vce(cluster frame_id_numeric)
reghdfe TFP2 treatment, absorb(fake_id year) vce(cluster frame_id_numeric)
