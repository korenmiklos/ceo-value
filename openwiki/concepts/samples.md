---
type: concept
title: Analysis Samples Catalogue
description: Documents all sample definitions across the codebase — analysis variations (full, size1–size4, pre2000, post2000) applied via filter.do, and event study sample filters (full, one2one, twos, fnd2non, non2non, gap, nogap, gender, nogender, small, large) applied in event_study_sample.do — their Stata conditions, dual-layer architecture, and interlocking role in the Makefile's cross-product build targets.
tags: [samples, analysis variations, event study, sample restrictions, placebo, cross-product, Makefile]
verified:
  - by: openwiki/0.5.0
    at: 2026-09-06T19:57:00.087Z
sources:
  - id: openwiki-source-46db84383d79696b4d341df2
    resource: repo://lib/create/analysis-sample.do
  - id: openwiki-source-f85faafafeb554812fa0eed3
    resource: repo://lib/create/event_study_sample.do
  - id: openwiki-source-7e4320e30e1e1d1a93089417
    resource: repo://lib/util/filter.do
  - id: openwiki-source-012f2c78e3b1446dfc35803f
    resource: repo://Makefile
  - id: openwiki-source-668d3dee65423484e813acea
    resource: repo://papers/application/Makefile
  - id: openwiki-source-59f2f40c6cfbe469fc787915
    resource: repo://papers/econometrics/Makefile
generated: { by: "openwiki/0.5.0", at: "2026-09-06T19:57:00.087Z" }
---

# Analysis Samples Catalogue

## Overview

The CEO value project uses a **two-layer sample architecture**:

1. **Analysis Variations** — Filters applied to the unfiltered firm-year panel to produce `temp/{variation}-analysis-sample.dta`. These restrict on time period (`pre2000`, `post2000`) and firm size (`size1`–`size4`), and always include a `full` (no additional restriction) baseline.

2. **Event Study Sample Filters** — Conditions applied within `event_study_sample.do` to the spell-level dataset, selecting which CEO transitions are kept for analysis. These restrict on founder status, gender change, firm size, age gap, and number of CEOs per spell.

The Makefile cross-joins both layers: every analysis variation is combined with every event study sample to produce `temp/{variation}_placebo_{sample}.dta`. The root project uses 7 × 11 = 77 possible combinations; downstream paper Makefiles use subsets.

## Layer 1: Analysis Variations (`filter.do`)

**Entrypoint:** `lib/util/filter.do`
**Called by:** `lib/create/analysis-sample.do` (via `do "lib/util/filter.do" \`sample'\`)
**Output:** `temp/{variation}-analysis-sample.dta`

The filter script is parameterized by a single `sample` argument (called an analysis variation in Makefile terminology). It loads `temp/unfiltered.dta` and applies:

- Universal quality filters (described below)
- One of seven variation-specific `keep if` conditions

### Universal Filters (Applied to All Variations)

These are common rules in `lib/util/filter.do` executed before the variation-specific condition:

| Rule | Condition | Rationale |
|------|-----------|-----------|
| No CEO | `ceo_spell == 0` | Firm-years without a CEO record |
| CEO overload | `max_n_ceo > 2` | Firms with >2 simultaneous CEOs in any year |
| Too many spells | `max_ceo_spell > 12` | Firms with >12 CEO spells (noisy firms) |
| Age zero | `firm_age < 1` | Incomplete first year of operation |
| Finance sector | `sector in {9}` | Excluded industry (Korlátolt felelősségű társaság) |
| Too small | `max_employment < 3` | Never reaches minimum employment threshold |
| Missing outcomes | `missing(lnR)` or `missing(ROA)` or `missing(lnL)` or `missing(lnK)` or `missing(lnRL)` or `missing(export)` | Core regression variables missing |

These quality filters are documented in `lib/util/filter.do` lines 21–26 as local parameters (`max_ceos_per_year`, `max_ceo_spells`, `min_firm_age`, `excluded_sectors`, `min_employment`).

### Variation-Specific Conditions

After universal filters, exactly one of these `keep if` conditions is applied:

| Variation | Condition | Semester |
|-----------|-----------|----------|
| `full` | (no additional condition) | All firms passing quality filters |
| `pre2000` | `year <= 2000` | Pre-millennium subsample |
| `post2000` | `year > 2000` | Post-millennium subsample |
| `size1` | `employment <= 5` | Micro firms |
| `size2` | `employment > 5 & employment <= 10` | Very small firms |
| `size3` | `employment > 10 & employment <= 25` | Small-to-medium firms |
| `size4` | `employment > 25` | Medium-to-large firms |

Source: `lib/util/filter.do` lines 7–13.

### The `analysis-sample.do` Entrypoint

`lib/create/analysis-sample.do` is the Makefile target's recipe script. It accepts a single argument (the variation name), validates it against a local list, loads `temp/unfiltered.dta`, runs `lib/util/filter.do` with that variation, compresses, and saves to `temp/{variation}-analysis-sample.dta`.

```stata
args sample
confirm existence `sample'
local valid_samples full pre2000 post2000 size1 size2 size3 size4
assert strpos(" `valid_samples' ", " `sample' ") > 0
use "temp/unfiltered.dta", clear
do "lib/util/filter.do" `sample'
compress
save "temp/`sample'-analysis-sample.dta", replace
```

This file is the input to:
- `lib/create/edgelist.do` (firm-manager bipartite graph extraction) — only uses `full`
- `lib/estimate/manager_value.do` (manager fixed effects) — only uses `full`
- `lib/create/event_study_sample.do` (placebo generation) — all variations

The Makeline pattern rule `temp/%-analysis-sample.dta` maps any `ANALYSIS_VARIATIONS` value to this script.

## Layer 2: Event Study Sample Filters (`event_study_sample.do`)

**Entrypoint:** `lib/create/event_study_sample.do`
**Accepts:** Two positional arguments `variation` and `sample`
**Output:** `temp/{variation}_placebo_{sample}.dta`

This script loads a pre-built analysis sample (`temp/{variation}-analysis-sample.dta`), merges in person-level data and manager skill estimates, reshapes to spell-level format, then applies the event study sample filter as the final restriction before building placebo matches.

### Sample Definitions

Eleven named sample filters are defined as local macros at lines 6–17 of `lib/create/event_study_sample.do`:

| Sample | Condition | Description |
|--------|-----------|-------------|
| `full` | `1` | All transitions passing structural filters |
| `fnd2non` | `has_founder1 == 1 & has_founder2 == 0` | Founder CEO succeeded by non-founder |
| `non2non` | `has_founder1 == 0 & has_founder2 == 0` | Non-founder succeeded by non-founder |
| `small` | `max_size == 1` | Firms with ≤5 employees (lifetime max) |
| `large` | `max_size == 2` | Firms with >5 employees (lifetime max) |
| `one2one` | `n_ceo1 == 1 & n_ceo2 == 1` | Exactly one CEO in each spell (single CEO firms) |
| `twos` | `n_ceo1 == 2 \| n_ceo2 == 2` | At least one spell with co-CEOs (two CEOs) |
| `gap` | `n_ceo1 == 1 & n_ceo2 == 1` **and** `age_diff > 10` | Single-CEO spells with a large age gap between CEOs |
| `nogap` | `n_ceo1 == 1 & n_ceo2 == 1` **and** `age_diff <= 10` | Single-CEO spells with a small age gap |
| `gender` | `n_ceo_male1 != n_ceo_male2` | CEO gender changes between spells |
| `nogender` | `n_ceo_male1 == n_ceo_male2` | CEO gender does not change |

These conditions are applied at line 115 of the script:

```stata
display "Keeping `sample' sample: ``sample''"
keep if ``sample''
```

The double-quote local reference ` ``sample'' ` evaluates the macro named by `sample` — each sample name is itself a local macro holding the Stata condition.

### Structural Filters Applied Before Sample Condition

Before any sample-specific condition, `event_study_sample.do` applies structural quality filters:

1. **Person ID merge**: Joins `intervals.dta` to attach `person_id` to firm-years (lines 39–50)
2. **Manager skill merge**: Joins `manager_value.dta` for estimated manager skill (line 52)
3. **Max CEOs**: Keeps only firms with `max_n_ceo ≤ 2` (line 59)
4. **Clean transitions**: Keeps spells `ceo_spell ≤ max_ceo_spell` (line 62)
5. **Non-missing fixed effect**: Drops spells with missing ROA (line 63)
6. **Consecutive spells only**: Drops firms where spells are not consecutive, which also excludes single-spell firms (line 83)
7. **Non-missing skill**: Drops spells with missing manager skill (line 77)
8. **Minimum observations**: Requires `T ≥ 1` (line 78)
9. **Consecutive spell pairs**: After reshape, drops pairs where spells are not adjacent (ceo_spell1 != ceo_spell2 - 1) (line 107)

These ensure the event study sample only contains clean, consecutive CEO transitions with observable manager skill.

## Layer Interlock: The Makefile Cross-Product

The two layers meet in the Makefile's `GEN_PLACEBO` template:

```makefile
define GEN_PLACEBO
temp/$(1)_placebo_$(2).dta: lib/create/event_study_sample.do \
    temp/$(1)-analysis-sample.dta temp/manager_value.dta
    $$(STATA) $$< $(1) $(2)
endef
$(foreach variation, $(ANALYSIS_VARIATIONS), \
  $(foreach sample, $(SAMPLES), \
    $(eval $(call GEN_PLACEBO,$(variation),$(sample)))))
```

This generates 7 × 11 = 77 Makefile rules for the root project (7 analysis variations × 11 samples from `event_study_sample.do`). Each rule produces one `temp/{variation}_placebo_{sample}.dta` file.

The variables driving this cross-product live at the top of the root `Makefile`:

```makefile
ANALYSIS_VARIATIONS := full size1 size2 size3 size4 pre2000 post2000
SAMPLES := full one2one twos fnd2non non2non gender nogender gap nogap
```

Note that `SAMPLES` in the root Makefile does not include `small` and `large` (those are defined inside `event_study_sample.do` but not used in the root Makefile cross-product). The `SAMPLES` list in the root Makefile is a subset of the 11 available sample definitions.

### Paper Makefile Subsets

Each paper Makefile uses a different subset of the cross-product:

- **`papers/application/Makefile`**: Uses `SAMPLES := full fnd2non non2non post2004` (post2004 is a paper-specific sample not defined in the core library). Its event study targets are `data/{sample}_{outcome}.csv`. Only the `full` analysis variation is used; the Makefile references `../../temp/analysis-sample.dta` (singular), not the pattern rule.

- **`papers/econometrics/Makefile`**: Uses the full root `VARIATIONS` list and all 9 `SAMPLES` from the root Makefile. Its event study targets are `data/{variation}_{sample}_{outcome}-{fixed_effect}.csv`, keeping the full cross-product alive through estimation.

## Sample Lifecycle Summary

```
Raw Data → balance.dta, intervals.dta, ceo-panel.dta
    → unfiltered.dta
    → [analysis-sample.do + filter.do with {variation}]
        → temp/{variation}-analysis-sample.dta        (Layer 1: analysis variation applied)
            → [event_study_sample.do with {variation, sample}]
                → temp/{variation}_placebo_{sample}.dta  (Layer 2: sample filter & placebo)
                    → [event_study.do]
                        → data/{variation}_{sample}_{outcome}.csv
```

## Test Coverage

The placebo test script `lib/test/placebo.do` loads `output/test/placebo.dta` and performs basic validity checks. However, there is no dedicated unit test that validates sample counts or condition logic. Sample correctness is enforced by:

- **Assertions** in `analysis-sample.do` and `event_study_sample.do` that validate arguments against known lists
- **Tabulate calls** throughout `event_study_sample.do` that print sample composition to the log
- **Missing value assertions** (`assert !missing(MS1, MS2)`, `assert !missing(t0)`) that catch data integrity failures

## Configuration and Operations

The sample system is configured through:

| Parameter | Location | Default | Effect |
|-----------|----------|---------|--------|
| `ANALYSIS_VARIATIONS` | Root Makefile line 13 | full size1 size2 size3 size4 pre2000 post2000 | Build matrix rows |
| `SAMPLES` | Root Makefile line 14 | full one2one twos fnd2non non2non gender nogender gap nogap | Build matrix columns |
| `min_employment` | `filter.do` line 25 | 3 | Minimum firm size for analysis |
| `max_ceos_per_year` | `filter.do` line 21 | 2 | Maximum concurrent CEOs |
| `TARGET_N_CONTROL` | `event_study_sample.do` line 27 | 10 | Desired control:treated ratio |
| `SEED` | `event_study_sample.do` line 28 | 1391 | Random seed for placebo sampling |

To run only a subset of samples, modify the Makefile variables:

```bash
make temp/full_placebo_fnd2non.dta      # single cell
make -j4 $(foreach s,fnd2non non2non, temp/full_placebo_$(s).dta)   # subset
```

The `PRECIOUS` directive in the root Makefile (line 32) prevents `make` from deleting placebo intermediate files after building derived targets.
