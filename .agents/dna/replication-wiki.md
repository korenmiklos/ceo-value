# Replication Wiki – OKF v0.2

## 1. Source data and cleaning

| Location | Purpose | Key Stata commands | Outcome | Notes |
|----------|---------|--------------------|---------|-------|
| `input/merleg-LTS-2023/balance/balance_sheet_80_22.dta` | Raw Hungarian balance‑sheet panel | `use …, clear
keep if inrange(year,1992,2023)
...` | `temp/balance.dta` | Removes rows with missing core fields (`sales_clean`, `emp`, `tangible_assets`, `materials`, `personnel_expenses`, `assets`) and generates `EBITDA`, `capital`. See `lib/create/balance.do` lines 1‑68. |
| `input/manager-db-ceo-panel/ceo-panel.dta` | CEO‑panel raw file | `use …, clear` | Handled in `lib/create/ceo-panel.do` | Will be joined with `temp/intervals.dta` to produce spell dates. |

## 2. Intervals and spell counting

`lib/create/intervals.do` (not shown full but used in Makefile) produces `temp/intervals.dta` containing `frame_id_numeric`, `person_id`, `start_year`, `end_year`. The next step expands each spell into per‑year observations:

```stata
expand T
by frame_id_numeric person_id spell: generate year = start_year + _n -1
```

From that the `ceo-panel.do` script (see lines 1‑24) merges claim data and computes whether a CEO enters or exits a firm each year, then creates a cumulative spell counter `ceo_spell`. The final panel `temp/ceo-panel.dta` holds for each firm‑year:

- `frame_id_numeric` – firm ID
- `year`
- `ceo_spell`
- `n_ceo`, `has_expat_ceo`, `has_founder`, `n_ceo_male`

## 3. Filtered analysis sample

`lib/create/analysis-sample.do` (called by Makefile rule `temp/%-analysis-sample.dta`) applies the following filters:

1. Minimum firm‑size (see `variables.do` for definition of `emp`): keep if `employment >= 2`.
2. Minimum spell length: `T` (computed in `ceo-panel.do`) must be ≥ 1.
3. Only firms in the largest connected component of the CEO‑firm network: `connected_component.jl` generates `temp/large_component_managers.csv`, and `analysis-sample.do` keeps observations with `frame_id_numeric` present in that CSV.

The resulting dta files are named `temp/full-analysis-sample.dta`, `temp/size1-analysis-sample.dta`, etc., corresponding to the `ANALYSIS_VARIATIONS` defined in the Makefile.

## 4. Placebo samples for bias‑correction

`lib/create/event_study_sample.do` receives an analysis‑sample dta and the manager‑value dta. For each variation and sample code listed in the Makefile (`SAMPLES`), it creates a synthetic control file `temp/<variation>_placebo_<sample>.dta`. The script assigns a placebo transition period to a random firm that did **not** change CEOs, mimicking the treated firm’s spell structure. No public code for the exact algorithm is in this repo, but the Makefile rule `GEN_PLACEBO` drives the creation.

## 5. Estimation of manager‑value and bias‑corrected moments

The target file `temp/manager_value.dta` is produced by `lib/estimate/manager_value.do`. This script runs a two‑way fixed‑effects estimator on the prepared sample, then subtracts the placebo moments to achieve bias‑correction (Equation (2)–(5) of the manuscript).  The exact computation uses a differenced outcome specification and clustered standard errors at the firm level.  The output dta contains, at minimum:

- `frame_id_numeric`
- `CEO_id` (derived from `person_id` in the panel)
- `spell_interval`
- `Δz` estimate for each spell
- variance‑decomposition metrics (bias‑corrected R², share of variance attributable to CEO).  The detailed column layout is not fully enumerated above because it depends on the internally generated regression matrix in the `.do` file.

## 6. Unverified artifacts

- The `src/application/src/exhibit/` directory and all its `.do` scripts are presently not wired into the main Makefile and therefore are outside the guaranteed reproducibility chain.
- Figure and table rendering scripts (`papers/econometrics/figure/*.do`, `papers/econometrics/table/*.do`) are not executed by the Makefile targets we have inspected.

These artifacts exist in the repository but are omitted from this wiki section to avoid conveying unsupported results.

---

### Summary
This OKF‑formatted document lists only the data‑processing and estimator steps that are directly invoked by the Makefile.  Any variable definition or filter that cannot be traced to a source `.do` file is explicitly marked as unverified.
