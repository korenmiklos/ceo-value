# Estimator – Manager Value and Bias‑Correction

The main statistical routine is implemented in `lib/estimate/manager_value.do`.  The script follows the procedure described in the manuscript and uses a two‑way fixed‑effects specification.

## Data used
- Sample: `temp/analysis-sample.dta` (post‑filtering; see *Filtering* page).  This file contains yearly fields (`frame_id_numeric`, `year`, `ceo_spell`, `employment`, `sales`, …) and the generated log‑transformed variables.
- Interval file: `temp/intervals.dta` (from `ceo-panel.do`) provides CEO spell duration `T` and the mapping from person to firm and year.

## Steps
1. **Expand intervals** – The script replicates each CEO spell into yearly observations (`expand T`) and joins to the panel via `joinby frame_id_numeric year`.
2. **Connected component flag** – `lib/create/network-sample.do` generates `giant_component = 1` for observations belonging to the largest connected component of the CEO‐firm network.
3. **Within‑firm manager skill** – Compute `within_firm = mean(fixed_effect)` per `(frame_id_numeric, person_id)`, demeaned by first spell.
4. **Scope bounds** – `within_firm_skill_min/max` enforce plausible skill range; out‑of‑range values are dropped.
5. **Cross‑sectional regression** – `reghdfe fixed_effect, absorb(firm_fixed_effect=frame_id_numeric manager_skill=person_id)` estimates the manager skill `manager_skill` as the residual of the fixed effects after removing firm and manager fixed effects.
6. **Faln** – The `manager_value.dta` output contains, for each `(frame_id_numeric, person_id)`: `manager_skill`, `firm_fixed_effect`, `component_id`, `component_size`.  A spell‑level collapse `manager_value_spell.dta` keeps the first non-missing `manager_skill` per spell.
7. **Bias correction** – The matcher (`lib/create/event_study_sample.do`) creates synthetic placebo samples; a final `temp/manager_value.dta` is later used with the placebo data to compute bias‑adjusted second moments (variance, R², event‑study coefficients) outside the estimator itself.  The exact manipulation is in subsequent `src/application/src/exhibit/*.do` scripts, but the key idea is subtraction of placebo moments from treated moments.

### Output
- `temp/manager_value.dta`: Manager skill and firm fixed effect for each firm–CEO pair.
- `temp/manager_value_spell.dta`: Manager skill aggregated to the spell level.
- `output/figure/manager_skill_within.pdf` / `manager_skill_connected.pdf`: visual diagnostics of skill distribution.

---

> _All steps are reproduced directly from the Stata scripts and rely on the variables described in the Variables page._