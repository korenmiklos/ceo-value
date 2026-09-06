---
type: integration reference
title: Stata Ecosystem and Required Packages
description: Documents the Stata 18.0 environment, required packages (reghdfe, estout, xt2treatments, e2frame), installation workflow, key commands, estimate persistence conventions, and log management for the CEO value pipeline.
tags: [stata, packages, reghdfe, xt2denoise, event-study, estimation, build-automation]
verified:
  - by: openwiki/0.5.0
    at: 2026-09-06T17:56:56.777Z
sources:
  - id: openwiki-source-f626faeec630004c3392a141
    resource: repo://lib/estimate/event_study.do
  - id: openwiki-source-6c17ee820f3a743f1061bc3c
    resource: repo://lib/estimate/manager_value.do
  - id: openwiki-source-f4654182fa577f7165a11860
    resource: repo://lib/estimate/revenue_function.do
  - id: openwiki-source-e9e02b9d834f8e298693cb09
    resource: repo://lib/estimate/setup_event_study.do
  - id: openwiki-source-4b49034ab235be7909aa1dc7
    resource: repo://lib/util/asset-descriptive.do
  - id: openwiki-source-0b4443606c794d02e5f3fdc1
    resource: repo://lib/util/install.do
  - id: openwiki-source-012f2c78e3b1446dfc35803f
    resource: repo://Makefile
  - id: openwiki-source-23775c3de52f3ab95a13cb8b
    resource: repo://README.md
generated: { by: "openwiki/0.5.0", at: "2026-09-06T17:56:56.777Z" }
---

# Stata Ecosystem and Required Packages

## Overview

The entire data processing, econometric estimation, and exhibit generation pipeline runs in **Stata 18.0**. All `.do` scripts execute via `stata-mp -b do <script>` (multi-processor batch mode) driven by the Makefile, which tracks file dependencies and produces compressed `.log` files for every run.

The Stata environment depends on four user-contributed packages—two from SSC and two from GitHub—which a one-time install script provisions automatically. The `.ster` binary format persists estimation results for downstream exhibit scripts.

## Required Packages

| Package | Version | Source | Purpose |
|---------|---------|--------|---------|
| `reghdfe` | 6.12.3 (08aug2023) | SSC | High-dimensional fixed-effects linear regression with multi-way clustering |
| `estout` | 3.31 (26apr2022) | SSC | Formatted regression-table output (estimates tables, LaTeX export) |
| `xt2treatments` | 0.9.0 (19sep2025) | GitHub (`codedthinking`) | Debiased event-study estimation via `xt2denoise`; panel matching with placebo controls |
| `e2frame` | 0.1.0 (21may2024) | GitHub (`codedthinking`) | Extract Stata matrices (e(b), e(V), etc.) into Stata frames for post-estimation manipulation |

Version 0.9.0 of `xt2treatments` is required for clustering support during event study estimation.

## Installation

The script `lib/util/install.do` provisions all four packages:

```stata
foreach X in xt2treatments e2frame {
    net install `X', from(https://raw.githubusercontent.com/codedthinking/`X'/main/) replace
    which `X'
}

foreach X in reghdfe estout {
    ssc install `X', replace
    which `X'
}
```

Invocation (from project root):

```bash
make install                    # delegates to install.log target
stata -b do lib/util/install.do # manual alternative
```

The Makefile `install` target writes `install.log` to confirm successful installation.

## Key Stata Patterns Used in the Pipeline

### `reghdfe` — High-Dimensional Fixed Effects

`reghdfe` is the central estimation engine, used in three distinct roles:

**Revenue function estimation** (`lib/estimate/revenue_function.do`):
```stata
reghdfe lnR `controls', absorb(frame_id_numeric firm_age teaor08_2d##year) ///
    vce(cluster frame_id_numeric)
eststo model1
estimates save "temp/revenue_models.ster", replace
```
Six specifications are estimated (lnR, lnEBITDA, lnWL, lnM, rich controls, and connected-component subsample), each appended to the same `.ster` file.

**Manager fixed-effects decomposition** (`lib/estimate/manager_value.do`):
```stata
reghdfe `fixed_effect', absorb(firm_fixed_effect=frame_id_numeric ///
    manager_skill=person_id) keepsingletons
```
This two-way fixed-effects specification identifies `manager_skill` as the residual person-level effect, which is then collapsed to spell level and stored in `temp/manager_value_spell.dta`.

**Clustering convention**: All specifications use `vce(cluster frame_id_numeric)` (clustering at the firm level).

### `xtset` — Panel Data Declaration

Every data-processing script declares the panel structure with:

```stata
xtset frame_id_numeric year
```

The event-study scripts instead declare:
```stata
xtset fake_id year
```
where `fake_id` is a synthetic identifier grouping a real treated firm with its matched placebo controls.

### `xt2denoise` — Debiased Event Study (xt2treatments package)

The cornerstone of the placebo-controlled event study design. Called twice in `lib/estimate/event_study.do`:

**Call 1 — Beta coefficients (mean treatment effect)**:
```stata
xt2denoise `outcome', ///
    z(manager_skill) treatment(actual_ceo) control(placebo_ceo) ///
    pre(4) post(3) detail
```
Returns matrices `e(b)` (denoised coefficients), `e(b_naive)` (uncorrected coefficients), `e(cov_diff)` and `e(cov1)` (covariance terms), plus `e(var_z1)` and `e(var_z_diff)` for variance decomposition.

**Call 2 — Variance decomposition**:
```stata
xt2denoise `outcome', ///
    z(manager_skill) treatment(actual_ceo) control(placebo_ceo) ///
    pre(4) post(3) cov detail
```
The `cov` option enables covariance output needed to compute `Var1` (treated outcome variance), `dVar` (variance difference), and `Var0 = Var1 - dVar` (control outcome variance).

A variant in `lib/estimate/event_study_atet.do` uses `baseline(atet)` to compute average treatment effects with a single pre/post summary rather than full event-time coefficients.

### `e2frame` — Matrix-to-Frame Extraction

Because `xt2denoise` stores results in matrices nested under non-standard return names (`e(b_naive)`, `e(V_naive)`, `e(cov_diff)`, etc.), the event-study scripts post-process them through `e2frame`:

```stata
* Capture denoised coefficients
ereturn post `b_naive' `V_naive', obs(`=_N_obs')
e2frame, generate(_beta1) numeric

* Capture covariance differences
ereturn post `Cov' `V_Cov', obs(`=_N_obs')
e2frame, generate(_dCov) numeric
```

Each call creates a named Stata frame (e.g., `_dbeta`, `_beta1`, `_dCov`, `_Cov1`, `_dVarY`, `_VarY1`). These are later merged into a unified `dCov` frame and exported to CSV for figure generation.

### `estout` / `esttab` — Table Output

`estout` provides `esttab` for regression-table LaTeX export. Used in `lib/util/asset-descriptive.do` for summary statistics tables:

```stata
esttab using "output/assets-summary-analysis.tex", replace ///
    cells("mean(fmt(2)) median(fmt(2)) p25 p75 min max") ///
    label title("Asset Statistics by Year")
```

The Makefile's exhibit targets depend on `temp/revenue_models.ster` and call scripts that use `esttab` with the `booktabs` option for clean LaTeX formatting.

### Panel Data Manipulation Patterns

Several idiomatic Stata patterns recur across the codebase:

| Pattern | Purpose | Example Location |
|---------|---------|------------------|
| `joinby frame_id_numeric using "..."` | Merge treated spells with placebo | `lib/estimate/setup_event_study.do` |
| `collapse (mean) MS=manager_skill (count) T=...` | Aggregation to spell level | `lib/create/event_study_sample.do` |
| `preserve`/`restore` with `tempfile` | Temporary data operations | `lib/estimate/manager_value.do` |
| `egen tag(...)` + `egen max(...), by(...)` | Unique firm/group tagging for subsampling | `lib/estimate/setup_event_study.do` |
| `reshape wide ...`, `expand`, `bysort` | From long to spell-pair structure | `lib/create/event_study_sample.do` |
| `merge ... using ..., keep(master match) nogen` | Clean keyed merges | Throughout |

## Estimate Persistence Convention

The `.ster` format (Stata binary estimates file) stores estimation results for late-binding exhibit generation:

- **`temp/revenue_models.ster`**: Six `eststo`-named models appended sequentially via `estimates save ... , append`. The Makefile's `output/table/table3.tex` target reads this file.

The `.ster` file is computationally expensive to regenerate and is marked `.PRECIOUS` in the Makefile to prevent automatic deletion.

## Log File Convention

Every `stata-mp -b do <script>` invocation produces a `<script>.log` file at the project root. These logs capture all `display` output, `tabulate` summaries, `summarize` statistics, and error messages. The Makefile does not explicitly suppress or rotate logs; they accumulate across runs. Key log files:

- `analysis-sample.log`, `balance.log`, `ceo-panel.log`, `unfiltered.log`
- `event_study.log`, `manager_value.log`, `surplus.log`
- `edgelist.log`, `intervals.log`, `sorting_windows.log`

Partial log parsing is shown in `README.md` for sample verification.

## Version Compatibility

The Stata 18.0 environment interacts with package versions in specific ways:

- **`xt2treatments >= 0.9.0`**: Required for clustering support (`cluster(frame_id_numeric)`) in `xt2denoise`. Earlier versions lack the clustering covariance estimator.
- **`reghdfe 6.12.3`**: Compatible with Stata 18's `absorb()` syntax and multi-way clustering. Issues with earlier Stata versions may affect `keepsingletons` behavior.
- **`.ster` format**: Bound to Stata 18's estimates binary format. `.ster` files from different Stata major versions are incompatible.

There is no explicit version pinning in the install script; replicators should verify versions via `which <package>` calls, which `setup_event_study.do` performs at runtime:

```stata
which xt2treatments
which estout
which reghdfe
which e2frame
```

## Interaction with the Build System

The Makefile (`Makefile`) drives all Stata invocations. Each target tracks the dependency between a `.dta` input, a `.do` script, and the expected output:

```makefile
temp/revenue_models.ster: lib/estimate/revenue_function.do temp/analysis-sample.dta
    $(STATA) $<
```

The `STATA` variable is defined as `stata-mp -b do`. The Makefile uses `$(foreach ...)` generators to create placebo-sample targets for every combination of analysis variation and sample type (e.g., `full`, `one2one`, `fnd2non`, `non2non`).

All scripts must be run from the project root directory so that relative paths resolve correctly.
