---
type: "Reference"
title: "Placebo Construction Workflow"
openwiki_generated: true
verified:
  - by: openwiki/0.5.0
    at: 2026-09-06T17:56:56.777Z
sources:
  - id: openwiki-source-f85faafafeb554812fa0eed3
    resource: repo://lib/create/event_study_sample.do
generated: { by: "openwiki/0.5.0", at: "2026-09-06T17:56:56.777Z" }
---


# Placebo Construction Workflow

## Purpose

The placebo construction workflow builds the counterfactual dataset for the placebo-controlled event study design. It creates **fake CEO transitions** — placebo change years assigned to real firms that experienced no actual CEO change during the event window — by matching control firms to treated firms on observable characteristics and replicating the timing distribution of real transitions. The output is a unified dataset of actual and placebo transitions used by the [`xt2denoise`](/openwiki/concepts/placebo-controlled-event-study.md) estimator to debias second moments.

## Entry Point

The workflow is implemented entirely in [`/lib/create/event_study_sample.do`](repo://lib/create/event_study_sample.do) (lines 1–247). It is invoked with two arguments:

```
do event_study_sample.do <variation> <sample>
```

| Argument | Domain | Example | Source |
|----------|--------|---------|--------|
| `variation` | Sample restriction from the analysis-sample stage: `full`, `size1`–`size4`, `pre2000`, `post2000` | `full` | [`lib/util/filter.do`](repo://lib/util/filter.do) |
| `sample` | CEO transition filter: `full`, `fnd2non`, `non2non`, `small`, `large`, `one2one`, `twos`, `gap`, `nogap`, `gender`, `nogender` | `one2one` | [`lib/create/event_study_sample.do`](repo://lib/create/event_study_sample.do#L5-L17) |

Output: `temp/<variation>_placebo_<sample>.dta`.

---

## Identification Logic

Placebo firms are **real firms with actual CEO transitions shifted to a different year**. Because the same firm serves as its own control (with a counterfactual change year), firm-specific trends and time-invariant unobservables are absorbed. The design difference between treated and placebo moments isolates the causal contribution of CEO quality from noise and mechanical reversion.

Formally:

> **True variance** = Var(outcome | treated) − Var(outcome | placebo)
>
> **Debiased coefficient** = (Cov(dy, dz | treated) − Cov(dy, dz | placebo)) / (Var(dz | treated) − Var(dz | placebo))

See the [Placebo-Controlled Event Study Design](/openwiki/concepts/placebo-controlled-event-study.md) concept page for the full identification argument.

---

## Workflow Steps

### 1. Data Preparation and Spell Construction

The script loads `temp/<variation>-analysis-sample.dta` (analysis sample with the requested variation filter already applied) and merges three additional sources:

1. **CEO person-year panel** — built from `temp/intervals.dta` by expanding each CEO spell into year-level rows (lines 39–50).
2. **Manager skill estimates** — merged from `temp/manager_value.dta` (lines 52).
3. **Manager demographic facts** — merged from `temp/manager-facts.dta` (lines 53).

**Firm-level restrictions** (lines 57–79):
- Keep only firms with ≤ 2 CEOs (`max_n_ceo <= ${max_n_ceo}` where `max_n_ceo = 2`).
- Keep only firm-years where `ceo_spell` ≤ `max_ceo_spell`.
- Drop observations with missing ROA (the fixed-effect outcome).
- Collapse to spell-level: mean manager skill (`MS`), observation count (`T`), first change year, max window end, CEO age, first values of exact match variables (`cohort`, `sector`, `max_size`), CEO counts.
- Drop spells with missing manager skill or insufficient observations (`T < min_T = 1`).

**Consecutive spell requirement** (lines 80–84):
- Drop firms where the current spell has no lag or lead — this excludes single-spell firms and ensures only firms with a clean succession are retained.

**Intermediate spell duplication** (lines 87–100):
- Firms with more than two spells get each intermediate spell duplicated (once as "spell 1" from the before-transition perspective, once as "spell 2" from the after-transition perspective), so every transition appears as a separate observation.
- The data is reshaped wide: spell characteristics for the pre-transition CEO (`*1`) and post-transition CEO (`*2`) sit side-by-side.

### 2. Sample Filter Application

Lines 112–115 apply the requested `sample` condition:

```stata
display "Keeping `sample' sample: ``sample''"
keep if ``sample''
```

The valid samples are defined at lines 5–17:

| Sample | Condition | Meaning |
|--------|-----------|---------|
| `full` | none | All clean transitions |
| `fnd2non` | `has_founder1 == 1 & has_founder2 == 0` | Founder → non-founder |
| `non2non` | `has_founder1 == 0 & has_founder2 == 0` | Non-founder → non-founder |
| `small` | `max_size == 1` | Small firms |
| `large` | `max_size == 2` | Large firms |
| `one2one` | `n_ceo1 == 1 & n_ceo2 == 1` | Single CEO each spell |
| `twos` | `n_ceo1 == 2 \| n_ceo2 == 2` | Multi-CEO spell |
| `gap` | `n_ceo1 == 1 & n_ceo2 == 1 & age_diff > 10` | Large age gap |
| `nogap` | `n_ceo1 == 1 & n_ceo2 == 1 & age_diff <= 10` | Small age gap |
| `gender` | `n_ceo_male1 != n_ceo_male2` | Gender change |
| `nogender` | `n_ceo_male1 == n_ceo_male2` | No gender change |

### 3. Treated Firm Registration

Lines 119–130 record the treated firms:

- Collapse to unique treated transitions: one row per `(frame_id_numeric, spell_id)`.
- Generate a unique `fake_id` per treated firm-spell (`fake_id = group(frame_id_numeric ceo_spell)`).
- Count treated firms (`N_TREATED = r(max)`).
- Label `placebo = 0` and `weight = 1`.

### 4. Control Pool Matching and Sampling

Lines 132–206 implement the stratified matching design:

#### 4.1 Exact Matching Strata

The global `exact_match_on` (line 33) specifies the variables that define matching strata:

```stata
global exact_match_on cohort sector max_size
```

- **`cohort`** — 3-year founding-year bins (derived from firm age in the analysis sample).
- **`sector`** — Industry classification (Agriculture, Mining, Manufacturing, Wholesale/Retail/Transport, Telecom/Business Services, Construction, Nontradable Services).
- **`max_size`** — Firm size category (based on employment).

Every control firm must match a treated firm on all three dimensions simultaneously.

#### 4.2 Window Compatibility

Control firms must have a CEO spell window (`window_start1` to `window_end1`) that is **weakly larger** than the treatment event window (`window_start` to `window_end`). Line 171:

```stata
keep if window_start1 <= window_start & window_end1 >= window_end
```

This ensures the control firm has sufficient pre- and post-period data to support the same event-time structure.

#### 4.3 Target Ratio: 10 Controls per Treated

The target control-to-treated ratio is set at line 27:

```stata
local TARGET_N_CONTROL 10
```

The ratio is implemented through a **probability-proportional-to-target** sampling scheme.

#### 4.4 Sampling Probability Computation

Lines 134–148 compute the sampling parameters:

1. Collapse treated firms by `(exact_match_on, window_start, window_end, t0)` where `t0 = change_year - window_start` measures the position of the change year within the event window (line 132).
2. Reshape to wide: one column per distinct `t0` value, with count of treated firms in that bucket.
3. Compute `N_treated` = total treated firms per stratum-window (row total of all `n_treated*` columns).
4. Compute `MEAN` = mean of `N_treated` across all strata (line 146).
5. Compute `MULTIPLE = TARGET_N_CONTROL / MEAN` (line 147).

This `MULTIPLE` ensures that the expected number of sampled controls across all strata equals `TARGET_N_CONTROL` per treated firm.

#### 4.5 Random Seed

Line 28 sets the random seed for reproducibility:

```stata
local SEED 1391
```

#### 4.6 Loop Over Cohorts and Sampling

Lines 162–206 process each cohort independently:

1. **Join controls to treated strata** (line 169):
   ```stata
   joinby $exact_match_on using "`treated_groups'"
   ```

2. **Restrict window compatibility** (line 171).

3. **Count controls per stratum** (line 176):
   ```stata
   egen n_control = total(1), by($exact_match_on window_start window_end)
   ```

4. **Compute sampling probability** (line 178):
   ```stata
   generate p = MULTIPLE * N_treated / n_control
   ```

5. **Sample controls** (line 180):
   ```stata
   keep if uniform() < p
   ```
   Each candidate control firm is included with probability `p`, which is proportional to the target 10:1 ratio divided by the actual control pool size.

6. **Compute sampling weight** (line 184):
   ```stata
   generate weight = N_treated / n_control
   ```
   The weight ensures that in analyses, each placebo observation represents the correct share of the treated population.

### 5. Placebo Change Year Assignment

Lines 187–200 assign the placebo change year by replicating the empirical `t0` distribution of treated firms within the same stratum:

1. Initialize `t0 = .` (missing).
2. Loop over the `t` position columns (`n_treated1`, `n_treated2`, ..., `n_treatedT`).
3. For each position `t`, compute the conditional probability:
   ```stata
   replace p = cond(missing(t0), n_treated`t' / N_treated, 0)
   ```
   This is the share of treated firms that had their change at position `t`.
4. Assign `t0 = t` with probability `p` (line 194):
   ```stata
   replace t0 = `t' if missing(t0) & uniform() <= p
   ```
5. Decrement `N_treated` by `n_treated` to normalize remaining probabilities (line 195).
6. Compute `change_year = window_start + t0` (line 200).

This ensures the distribution of placebo change years within each matched stratum matches the empirical timing of actual transitions.

### 6. Final Assembly and Balance Checks

Lines 209–247 assemble the final dataset:

1. **Append** placebo observations to treated firms (line 228).
2. **Unique fake_ids**: Placebo `fake_id` values start after `N_TREATED` (line 220):
   ```stata
   replace fake_id = fake_id + N_TREATED
   ```
3. **Balance checks** (lines 231–240):
   - Tabulate `placebo` (unweighted and weighted) to verify the ratio of control to treated.
   - Tabulate `change_year` by `placebo`.
   - Tabulate `T1` (pre-period length = `change_year - window_start`) and `T2` (post-period length = `window_end - change_year + 1`) by `placebo`.

4. **Output variables** (lines 242–247):
   ```
   fake_id placebo frame_id_numeric window_start change_year ceo_spell window_end weight
   ```

Saved to `temp/<variation>_placebo_<sample>.dta`.

---

## Key Parameters

| Parameter | Value | Role | Source |
|-----------|-------|------|--------|
| `TARGET_N_CONTROL` | 10 | Target controls per treated firm | line 27 |
| `SEED` | 1391 | Random seed for reproducibility | line 28 |
| `min_obs_threshold` | 1 | Minimum observations before/after transition | line 29 |
| `min_T` | 1 | Minimum observations for fixed-effect estimation | line 30 |
| `max_n_ceo` | 2 | Maximum CEOs per firm in event study | line 32 |
| `exact_match_on` | `cohort sector max_size` | Exact matching variables for strata | line 33 |

---

## Sample Variations

The workflow produces multiple placebo datasets that are consumed by downstream estimation scripts. Each combination of `variation` and `sample` yields a distinct file:

```
temp/full_placebo_full.dta       # Full sample, all transitions
temp/full_placebo_one2one.dta    # Full sample, single-CEO spells only
temp/full_placebo_twos.dta       # Full sample, multi-CEO spells
temp/full_placebo_fnd2non.dta    # Full sample, founder→non-founder
temp/full_placebo_non2non.dta    # Full sample, non-founder→non-founder
temp/size1_placebo_full.dta      # Small firms (≤5 emp), all transitions
...
```

The estimation pipeline (see [Data Pipeline Architecture](/openwiki/architecture/data-pipeline.md)) consumes these files via `setup_event_study.do` and `event_study.do`.

---

## Balance Verification

After assembly, the script performs informal balance checks by tabulating:

- **Unweighted counts** of treated vs. placebo firms — should show roughly a 10:1 ratio if sampling was successful.
- **Weighted counts** — ensures the weight adjustment corrects for unequal control availability.
- **Change year distribution** — placebo years should mirror the treated distribution.
- **Pre/post window lengths** (`T1`, `T2`) — ensure control firms have comparable event window coverage.

A more rigorous balance assessment (covariate balance across treated and placebo groups within each stratum) is assumed to be performed in the downstream analysis step.

---

## Related Pages

- [/openwiki/architecture/data-pipeline.md](/openwiki/architecture/data-pipeline.md) — End-to-end data flow; Stage 10 documents the same workflow at the pipeline level.
- [/openwiki/concepts/placebo-controlled-event-study.md](/openwiki/concepts/placebo-controlled-event-study.md) — Identification logic and estimation structure that consumes the placebo datasets.
- [/openwiki/workflows/sampling-filtering.md](/openwiki/workflows/sampling-filtering.md) — The analysis-sample filtering stage that produces the input dataset.
- [repo://lib/create/event_study_sample.do](repo://lib/create/event_study_sample.do) — The complete source script (247 lines).
- [repo://lib/util/filter.do](repo://lib/util/filter.do) — Variation filter definitions used in `event_study_sample.do`.
