---
type: Reference
title: Monte Carlo placebo generator code
description: Evidence excerpts from lib/create/montecarlo.do, thenon-paper Monte Carlo placebo simulation.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
---

# Monte Carlo placebo generator code

## Source

- Path: `lib/create/montecarlo.do`
- SHA-256: `5deaa2da9c9cefa5d2e8e1bca094904eb754b1eda065c3a68404f2b02eb6596a`
- Inspected: exact source slices below

## Excerpts

### Lines 3-19
```text
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
```

### Lines 33-44
```text
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
```

### Lines 49-64
```text
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
```

### Lines 106-114
```text
generate true_effect = `true_effect'
save "temp/placebo_montecarlo.dta", replace

* check no mean ATET but 0.01 variance ATET

generate TFP2 = TFP^2
generate byte treatment = placebo == 0 & year >= change_year
reghdfe TFP treatment, absorb(fake_id year) vce(cluster frame_id_numeric)
reghdfe TFP2 treatment, absorb(fake_id year) vce(cluster frame_id_numeric)
```

## Notes

- This script is NOT referenced by any Makefile in the checkout  dormant relative to the active pipelines(though `temp/placebo_montecarlo.dta` does NOT appear in che current temp listing either; the output `montecarlo_TFP.csv` in `output/event_study/` and `papers/application/data/` comes from the paper-specific Monte Carlo flow (`papers/econometrics/src/montecarlo/`}, a different generator.
- The paper-specific Monte Carlo flow: `src/montecarlo/{scenario}.do` + `params.do` + `setup.do`, driven by `src/montecarlo/run.do $*`, produces `data/placebo_{scenario}.dta` (observed files: placebo_baseline.dta, placebo_persistent.dta, placebo_excessvariance.dta, placebo_excessvariance_corr placeholders?  observed: baseline, persistent, excessvariance, longpanel, all, unbalanced`}.
