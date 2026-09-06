---
type: test specification
title: Monte Carlo Simulation
description: Documents the Monte Carlo simulation framework for validating the placebo-controlled event study design, including data generation parameters, scenario definitions, expected true effects, and integration with the estimation pipeline.
tags: [monte-carlo, simulation, validation, event-study, placebo, xt2denoise, testing]
verified:
  - by: openwiki/0.5.0
    at: 2026-09-06T17:56:56.777Z
sources:
  - id: openwiki-source-2a84a273bb200e9b22c6ecfa
    resource: repo://lib/create/montecarlo.do
  - id: openwiki-source-f626faeec630004c3392a141
    resource: repo://lib/estimate/event_study.do
  - id: openwiki-source-e9e02b9d834f8e298693cb09
    resource: repo://lib/estimate/setup_event_study.do
  - id: openwiki-source-59f2f40c6cfbe469fc787915
    resource: repo://papers/econometrics/Makefile
  - id: openwiki-source-5f635c38839469a5fde329f9
    resource: repo://papers/econometrics/src/figuremc.do
  - id: openwiki-source-35c304bef36c8402dd8bd06d
    resource: repo://papers/econometrics/src/montecarlo/all.do
  - id: openwiki-source-9af45458db5f1e04d3336cf4
    resource: repo://papers/econometrics/src/montecarlo/baseline.do
  - id: openwiki-source-c162d2b054530666f57956ad
    resource: repo://papers/econometrics/src/montecarlo/excessvariance_corr.do
  - id: openwiki-source-8252de3c8a3c606c27b03f0b
    resource: repo://papers/econometrics/src/montecarlo/excessvariance.do
  - id: openwiki-source-a21494b920e69daf20baadce
    resource: repo://papers/econometrics/src/montecarlo/longpanel.do
  - id: openwiki-source-408912ea85ae805db243a5a5
    resource: repo://papers/econometrics/src/montecarlo/params.do
  - id: openwiki-source-0bb8f0fc81eeab3447be0b36
    resource: repo://papers/econometrics/src/montecarlo/persistent.do
  - id: openwiki-source-5752147336be4a495058cc0f
    resource: repo://papers/econometrics/src/montecarlo/run.do
  - id: openwiki-source-6073ded41ad6b665180106e7
    resource: repo://papers/econometrics/src/montecarlo/setup.do
  - id: openwiki-source-8d65e71b0070a825a56566e0
    resource: repo://papers/econometrics/src/montecarlo/trend.do
generated: { by: "openwiki/0.5.0", at: "2026-09-06T17:56:56.777Z" }
---

# Monte Carlo Simulation

## Overview

The Monte Carlo simulation validates that the **placebo-controlled event study design** (xt2denoise) correctly recovers the true causal effect of CEO quality on firm performance. It generates synthetic panel data with known parameters, runs the full estimation pipeline, and compares estimated coefficients against the known true effect.

There are two Monte Carlo implementations:

1. **Standalone generator** [`/lib/create/montecarlo.do`](repo://lib/create/montecarlo.do) -- A self-contained Stata script that builds a synthetic panel with CEO transitions, placebo controls, and an autoregressive TFP outcome. It was used for initial validation and also serves as a template for the variable contract expected by the event study pipeline.

2. **Multi-scenario framework** [`/papers/econometrics/src/montecarlo/`](repo://papers/econometrics/src/montecarlo/) -- A parameterized Monte Carlo with separate scenario `.do` files (`baseline`, `persistent`, `excessvariance`, `excessvariance_corr`, `all`, `trend`, `longpanel`), run via [`run.do`](repo://papers/econometrics/src/montecarlo/run.do) and orchestrated by the `montecarlo` Makefile target in `/papers/econometrics/Makefile`.

The same estimation code (`/lib/estimate/event_study.do`) processes both real data and Monte Carlo data. When invoked with the `montecarlo` argument, it skips the merge with real manager-value data and industry-year demeaning, operating purely on synthetic variables.

## Data Generation: `/lib/create/montecarlo.do`

The standalone script generates a synthetic dataset that mirrors the structure of the real event-study dataset. It is the earlier implementation and documents the variable contract.

### Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| `N_changes` | 10,000 | Number of independent CEO transitions simulated |
| `hazard` | 0.2 | Hazard rate of CEO change per period |
| `sigma_z` | 0.1 | Standard deviation of CEO ability (`sqrt(0.01)`) |
| `half_normal` | 0.797885 | Expected absolute value of a standard normal (`sqrt(2/pi)`) |
| `true_effect` | `half_normal * sigma_z` | Expected absolute CEO effect on TFP |
| `sigma_epsilon0` | 0.05 | TFP noise standard deviation (control firms) |
| `sigma_epsilon1` | 0.06 | TFP noise standard deviation (treated firms) -- excess variance |
| `rho` | 0.97 | Autoregressive coefficient for TFP |
| `control_treated_ratio` | 9 | Number of placebo controls per treated firm |
| `T_max` | 20 | Maximum CEO spell duration (periods) |

### Generation Steps

1. **CEO spell durations**: `T1` (spell 1) and `T2` (spell 2) are drawn from exponential distributions with rate `1/hazard`, then ceiling-rounded and capped at `T_max`. Only observations with `T1 <= T_max & T2 <= T_max` are kept.

2. **Placebo structure**: Each treated firm is expanded by `1 + control_treated_ratio` copies. The first copy (`placebo == 0`) is the actual transition; the remaining copies (`placebo == 1`) are placebo transitions. Each copy gets a unique `fake_id` via `group(frame_id_numeric index)`.

3. **Time dimension**: Each firm-year panel is expanded to `T1 + T2` periods. CEO spells are assigned: `ceo_spell = 1` for `year <= T1`, `ceo_spell = 2` thereafter. The `change_year` is `T1 + 1`.

4. **Outcome (TFP) generation**: Innovations `dTFP` are drawn from `N(0, sigma_epsilon0)` for controls and `N(0, sigma_epsilon1)` for treated. The outcome follows an AR(1) process: `TFP_t = rho * TFP_{t-1} + dTFP_t`, initialized at 0.

5. **CEO ability shock**: A single `dz` is drawn from `N(0, sigma_z)` per treated firm. The mean ability `z` is computed at `change_year` for treated firms. The outcome is then adjusted: `TFP = TFP + z` for treated firms in post-transition periods.

6. **Manager skill proxy**: `manager_skill` is computed as the CEO-spell mean of TFP, then demeaned.

### Expected True Effect

The true effect is the expected absolute CEO ability draw:

```
true_effect = half_normal * sigma_z
```
where `half_normal = E[|Z|]` for `Z ~ N(0,1)` = `sqrt(2/pi) ≈ 0.797885`.

With `sigma_z = 0.1`, the true effect is approximately **0.0798** TFP log points.

The simulation verifies that:
- The **mean** ATET should be zero (CEO ability is mean-zero, and an equal fraction of better/worse CEOs enter).
- The **variance** of outcomes should increase after treated CEO changes by `true_effect²`.
- The placebo-controlled debiased estimator should recover this variance effect, while the naive estimator is biased upward.

The script runs two diagnostic regressions to confirm this:
```
reghdfe TFP treatment, absorb(fake_id year)
reghdfe TFP2 treatment, absorb(fake_id year)
```

The first should show zero mean ATET; the second should show a variance increase matching `true_effect²`.

### Generated Dataset

Saved to `temp/placebo_montecarlo.dta` with the following variable contract:

| Variable | Description |
|----------|-------------|
| `frame_id_numeric` | Firm identifier |
| `year` | Time variable |
| `TFP` | Outcome variable (non-missing) |
| `ceo_spell` | CEO tenure spell (1 or 2) |
| `manager_skill` | Demeaned CEO-spell mean of TFP |
| `change_year` | Year of CEO transition |
| `placebo` | Binary: 0 = actual, 1 = placebo |
| `fake_id` | Synthetic firm identifier |

## Multi-Scenario Framework: `/papers/econometrics/src/montecarlo/`

This is the production Monte Carlo framework used to validate the method across multiple data-generating processes. It lives inside the `papers/econometrics/` directory and is invoked via the `montecarlo` Makefile target.

### Architecture

```
papers/econometrics/src/montecarlo/
├── run.do           # Entry point: includes params.do + scenario.do + setup.do
├── params.do        # Default parameter values (N=50000, sigma_z=1.0, etc.)
├── setup.do         # Generic data generation engine (reads scenario-specific params)
├── baseline.do      # Baseline: no persistence, balanced panel, no excess variance
├── persistent.do    # rho0=0.8, rho1=0.9 (persistent shocks, different for treated)
├── excessvariance.do # sigma_epsilon1 = 1.2 * sqrt(0.5) (treated firms more volatile)
├── excessvariance_corr.do # Same as excessvariance; correction applied at estimation
├── all.do           # Combines persistent + excessvariance + hazard=0.2
├── trend.do         # gamma=0.1 (ability correlated with past TFP)
└── longpanel.do     # T_max=20 (longer CEO spells)
```

**Setup flow:**
1. `run.do <scenario>` is called with the scenario name.
2. It `include`s `params.do` to set default parameters.
3. It `include`s `<scenario>.do` which overrides specific parameters.
4. It `include`s `setup.do` which runs the full simulation using the active parameter locals.
5. Output is saved to `data/placebo_<scenario>.dta`.

### Default Parameters (`params.do`)

| Parameter | Value | Description |
|-----------|-------|-------------|
| `N_changes` | 50,000 | Number of CEO transitions |
| `sigma_z` | 1.0 | Standard deviation of CEO ability |
| `control_treated_ratio` | 1 | Number of placebos per treated firm |
| `rho0` | 0.9 | AR(1) coefficient for control firms |
| `rho1` | 0.9 | AR(1) coefficient for treated firms |
| `sigma_epsilon0` | `sqrt(0.5)` | TFP noise SD for control firms |
| `sigma_epsilon1` | `sqrt(0.5)` | TFP noise SD for treated firms |
| `hazard` | 0.2 | Hazard rate of CEO change |
| `T_max` | 5 | Maximum spell duration |
| `gamma` | 0 | Coefficient linking TFP to ability (trend) |
| `half_normal` | 0.797885 | E[\|Z\|] for standard normal |
| `true_effect` | `half_normal * sigma_z` | Effect = 0.7979 |

### Scenario Descriptions

| Scenario | Parameters Changed | Purpose |
|----------|-------------------|---------|
| `baseline` | None (uses defaults) | Validates method under ideal conditions: balanced panel, no persistence differences, equal noise, no correlation between ability and pre-trends |
| `persistent` | `rho0=0.8, rho1=0.9` | Tests robustness when treated and control firms have different shock persistence |
| `excessvariance` | `sigma_epsilon1=1.2*sqrt(0.5)` | Tests robustness when treated firms have higher outcome variance than controls |
| `excessvariance_corr` | Same as excessvariance | Tests the excess-variance correction feature of xt2denoise (enables `excessvariance` option) |
| `all` | `rho1=0.8, rho0=0.9, hazard=0.2, sigma_epsilon1=1.2*sqrt(0.5)` | Torts the method with all features simultaneously |
| `trend` | `gamma=0.1` | Tests robustness when past TFP partially determines ability (pretrend) |
| `longpanel` | `T_max=20` | Tests with longer CEO spells (more pre/post observations per firm) |

### Setup Engine (`setup.do`)

The setup script (`/papers/econometrics/src/montecarlo/setup.do`) validates the input parameters and executes:

1. **Parameter validation**: Asserts each parameter exists and lies in valid ranges (`rho in [0,1)`, `sigma_epsilon > 0`, `hazard >= 0`, `N_changes` is integer, etc.).

2. **CEO spell generation**: If `hazard > 0`, durations are drawn from exponential distributions with rate `1/hazard`, ceiling-rounded and capped at `T_max`. If `hazard == 0`, spells are fixed at `T_max` (balanced panel).

3. **Placebo construction**: Expands each treated firm by `1 + control_treated_ratio` copies, creating an equal number of treated and placebo firms when `ratio = 1`.

4. **Outcome generation**: The outcome variable is `lnR` (log revenue), generated as an AR(1) process with separate persistence `rho0` (control) and `rho1` (treated):
   - `dlnR ~ N(0, sigma_epsilon0)` for placebo firms
   - `dlnR ~ N(0, sigma_epsilon1)` for treated firms
   - `lnR_t = rho * lnR_{t-1} + dlnR_t` (separate `rho` per group)

5. **Ability generation**: `dz = gamma * lnR + N(0, sigma_z)`. When `gamma > 0`, this creates a pretrend (ability partially reflects pre-treatment performance). The ability `z` is the mean of `dz` at the change year for treated firms only.

6. **Post-transition effect**: `lnR = lnR + z` for treated firms after `change_year`.

7. **Manager skill proxy**: Computed as CEO-spell mean of `lnR`, then demeaned.

8. **Variable contract**: Output has the same required variables as the standalone generator, using `lnR` as the outcome instead of `TFP`.

## Running Monte Carlo Simulations

### Via Make

```bash
# Run all scenarios and produce the comparison figure
cd papers/econometrics
make montecarlo
```

This target (defined in `/papers/econometrics/Makefile`) executes:

1. Generate each Monte Carlo scenario dataset:
   ```
   stata -b do src/montecarlo/run.do baseline
   stata -b do src/montecarlo/run.do persistent
   stata -b do src/montecarlo/run.do excessvariance
   stata -b do src/montecarlo/run.do excessvariance_corr
   stata -b do src/montecarlo/run.do all
   stata -b do src/montecarlo/run.do trend
   ```

2. Run the estimation pipeline for each scenario:
   ```
   stata -b do ../../lib/estimate/event_study.do <scenario> lnR montecarlo lnR
   ```
   For `excessvariance_corr`, the `excessvariance` option is appended to enable the correction feature.

3. Run the ATET variant:
   ```
   stata -b do ../../lib/estimate/event_study_atet.do <scenario> lnR montecarlo lnR
   ```

4. Produce the comparison figure (`figure/figuremc.pdf`) via `src/figuremc.do`, which calls `src/exhibit/event_study2.do` or `src/exhibit/event_study3.do` for each scenario.

### Direct Execution (Standalone)

```bash
# Run the standalone generator
stata -b do lib/create/montecarlo.do

# Run a single Monte Carlo scenario directly
cd papers/econometrics
stata -b do src/montecarlo/run.do baseline
```

### Running Through the Estimation Pipeline Manually

The estimation script accepts the `montecarlo` argument:

```
stata -b do lib/estimate/event_study.do <variation> <sample> <outcome> montecarlo
```

When `montecarlo` is passed:
- `setup_event_study.do` loads `data/<variation>_placebo_<sample>.dta` directly (skipping the merge with real manager-value data and the industry-year demeaning step).
- The estimation proceeds with synthetic variables (`lnR`, `manager_skill`, `change_year`, `placebo`, `fake_id`).

## Interpreting Results

### Expected vs. Estimated Effects

For each scenario, the simulation compares two estimators:

| Estimator | Description | Expected Behavior |
|-----------|-------------|-------------------|
| **Naive (OLS)** | Uses only treated firms, no placebo differencing | Overestimates the true effect due to finite-sample bias and noise accumulation |
| **Debiased (xt2denoise)** | Subtracts placebo-group moments from treated-group moments | Recovers the true effect `true_effect = half_normal * sigma_z` |

### Diagnostic Checks

The framework validates that:

1. **Mean ATET ≈ 0**: Since CEO ability is mean-zero and drawn symmetrically, the average treatment effect of a CEO change on the outcome mean should be near zero.
2. **Variance ATET ≈ true_effect²**: The variance of outcomes increases after a CEO change, and the placebo-controlled estimator recovers this.
3. **Debiased coefficient ≈ true effect**: The beta coefficient from xt2denoise should converge to the true effect as `N_changes → ∞`.
4. **Pretrend detection**: When `gamma > 0` (the `trend` scenario), the method should still recover the true effect after controlling for pre-existing trends.
5. **Excess variance correction**: When `sigma_epsilon1 > sigma_epsilon0` (the `excessvariance` scenario), the correction feature scales control-group moments to match the treated-group noise variance.

### Output Artifacts

| Artifact | Description |
|----------|-------------|
| `papers/econometrics/figure/figuremc.pdf` | Six-panel figure comparing naive vs. debiased estimates across scenarios |
| `papers/econometrics/data/placebo_<scenario>.dta` | Generated synthetic panel for each scenario |
| `papers/econometrics/data/<scenario>_lnR-lnR.csv` | Estimation results (event-time path of betas) |
| `papers/econometrics/data/atet_<scenario>_lnR-lnR.csv` | ATET results |
| `papers/econometrics/table/atets.tex` | Aggregate ATET table across scenarios |
| `papers/econometrics/montecarlo.log` | Full Stata log from the simulation run |

### Typical Results

Under the **baseline** scenario (`sigma_z = 1.0`):
- **True effect** = 0.7979
- **Naive estimator** typically overestimates (upward bias from measurement noise, often ~0.9-1.1)
- **Debiased estimator** converges to ~0.80 (within sampling error of true effect)

Under **excessvariance** (treated firms have 20% more noise variance):
- The naive estimator is further inflated.
- Without correction, the debiased estimator partially corrects the bias.
- With the excess-variance correction (`excessvariance_corr`), the debiased estimator fully recovers the true effect.

Under **persistent** (different AR coefficients):
- The method remains robust; the debiased estimator continues to recover the true effect.

## Integration with the Estimation Pipeline

<!-- openwiki: mermaid parse failed and this diagram was converted to a text fence so it does not break rendering. Fix the diagram source and restore the mermaid fence. Parser error: Heuristic: an unescaped angle bracket inside a label breaks rendering; rephrase the label. -->
```text
flowchart LR
    subgraph Generation
        A[lib/create/montecarlo.do] -->|synthetic data| B[temp/placebo_montecarlo.dta]
        C[papers/econometrics/src/montecarlo/run.do] -->|params + scenario + setup| D[data/placebo_<scenario>.dta]
    end

    subgraph Estimation
        E[lib/estimate/event_study.do] -->|montecarlo argument| F[setup_event_study.do]
        F -->|skips real data merge| G[xt2denoise]
    end

    subgraph Results
        H[figure/figuremc.pdf]
        I[ATET tables]
    end

    B --> E
    D --> E
    G --> H
    G --> I
```

## Scenario Make Targets

From `/papers/econometrics/Makefile`:

```makefile
# Generate scenario datasets
data/placebo_%.dta: src/montecarlo/%.do src/montecarlo/params.do src/montecarlo/setup.do
    $(STATA) -b do src/montecarlo/run.do $*

# Run estimation for each scenario
data/$(1)_lnR-lnR.csv: $$(CODELIB) data/placebo_$$(if $$(filter excessvariance%,$(1)),excessvariance,$(1)).dta
    $$(STATA) -b do ../../lib/estimate/event_study.do $(1) lnR montecarlo lnR $$(if $$(findstring _corr,$(1)),excessvariance,)

# Full Monte Carlo target
montecarlo: figure/figuremc.pdf table/atets.tex
```

The pattern `$(if $(findstring _corr,$(1)),excessvariance,)` ensures that the `excessvariance_corr` scenario sources its data from the `excessvariance` dataset (they share the same DGP) but appends the `excessvariance` correction option to the estimation call.
