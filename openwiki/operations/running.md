---
type: operations
title: Build and Execution
description: Documents all Makefile targets (all, data, analysis, report, install, clean) across root, application paper, and econometrics paper builds; individual Stata and Julia script invocations; parameterized builds via variation/sample/outcome cross products; and LaTeX paper compilation procedures.
tags: [build, execution, Makefile, Stata, Julia, LaTeX, paper-compilation, parameterized-builds]
verified:
  - by: openwiki/0.5.0
    at: 2026-09-06T19:57:00.087Z
sources:
  - id: openwiki-source-012f2c78e3b1446dfc35803f
    resource: repo://Makefile
  - id: openwiki-source-668d3dee65423484e813acea
    resource: repo://papers/application/Makefile
  - id: openwiki-source-59f2f40c6cfbe469fc787915
    resource: repo://papers/econometrics/Makefile
generated: { by: "openwiki/0.5.0", at: "2026-09-06T19:57:00.087Z" }
---

# Build and Execution

## Overview

The project uses **GNU Make** as the single orchestration layer across three Makefiles: the root `/Makefile` drives the data pipeline, `/papers/application/Makefile` builds the main application paper, and `/papers/econometrics/Makefile` builds the econometric methods paper (including Monte Carlo simulations). All three Makefiles share the same underlying `lib/` script library but define independent target trees, phony targets, and parameterization variables.

Three build parameters are cross-joined to generate the full matrix of intermediate files:

| Parameter | Values (Root) | Values (Application) | Values (Econometrics) |
|-----------|---------------|----------------------|-----------------------|
| `ANALYSIS_VARIATIONS` | `full size1 size2 size3 size4 pre2000 post2000` | (uses root's intermediates) | `full size1 size2 size3 size4 pre2000 post2000` |
| `SAMPLES` | `full one2one twos fnd2non non2non gender nogender gap nogap` | `full fnd2non non2non post2004` | `full one2one twos fnd2non non2non gender nogender gap nogap` |
| `OUTCOMES` | `lnK lnWL lnM has_intangible` | `TFP lnK lnWL lnM has_intangible` | `lnR lnL lnK ROA lnRL` |

Tool definitions in each Makefile:

| Tool | Root | Application | Econometrics |
|------|------|-------------|--------------|
| **Stata** | `stata-mp -b do` | `stata -b do` | `stata-mp` |
| **Julia** | `julia --project=.` | `julia --project=../..` | (inherits root) |
| **LaTeX** | `pdflatex` | `pdflatex` | (not used) |

All commands must be run from the repository root (for the root Makefile) or from the paper subdirectory (for paper Makefiles). The application and econometrics Makefiles use `cd ../..` to run Stata/Julia from the project root.

---

## Common Makefile Targets

### Root Makefile (`/Makefile`)

```console
# Full data pipeline: processed samples, manager value estimates, placebo files
make data

# Install Stata packages (first run only)
make install
```

**Target details:**

| Target | Responsibility | Prerequisites |
|--------|---------------|---------------|
| `data` | Build `temp/manager_value.dta` and the full cross product of `temp/{variation}_placebo_{sample}.dta` (7 × 10 = 70 placebo files) | All data-wrangling intermediates: `balance.dta`, `ceo-panel.dta`, `unfiltered.dta`, analysis samples, edgelist, giant component |
| `install` | Run `lib/util/install.do` to install required Stata packages | `lib/util/install.do` |

The root Makefile has no `all`, `analysis`, `report`, or `clean` phony targets. Data-wrangling is its sole responsibility. Intermediate files are marked `.PRECIOUS` to prevent Make from deleting them after intermediate builds.

### Application Paper Makefile (`papers/application/Makefile`)

```console
# Complete workflow (data → analysis → report)
make all

# Data pipeline only
make data

# Estimation and exhibits
make analysis

# Compile the paper PDF and generate all figures
make report

# Install Stata packages
make install

# Confidential data extracts
make extract

# Event study figures by sample and outcome
make event_study
```

**Target details:**

| Target | Responsibility | Phony |
|--------|---------------|-------|
| `all` | Depends on `report` — runs the full build end to end | Yes |
| `data` | Build `temp/unfiltered.dta`, `temp/analysis-sample.dta`, `temp/placebo.dta`, `temp/large_component_managers.csv` | Yes |
| `analysis` | Build `temp/surplus.dta`, `temp/manager_value.dta`, event study panel datasets (`event_study_panel_a`, `event_study_panel_b`, `event_study_moments`), `temp/revenue_models.ster`, Bloom autonomy analysis log, and ATET tables | Yes |
| `report` | Build `paper.pdf`, three figures (`figure1.pdf`–`figure3.pdf`) and `figure/manager_skill_{within,connected}.pdf` | Yes |
| `install` | Run `lib/util/install.do` | Yes |
| `extract` | Build `../../output/extract/manager_changes_2015.dta` and `connected_managers.dta` | Yes |
| `event_study` | Build `data/{sample}_{outcome}.csv` for all 4 samples × 5 outcomes | Yes |

### Econometrics Paper Makefile (`papers/econometrics/Makefile`)

```console
# Full build: outcomes figures, descriptive tables, debiased R²s, spell distributions
make all

# Monte Carlo simulation build
make montecarlo

# Clean intermediates
make clean
```

**Target details:**

| Target | Responsibility | Phony |
|--------|---------------|-------|
| `all` | Build all standard exhibits: outcomes PDFs per sample, descriptive tables (firm, firm-year, switch, industry), debiased R² tables per variation, CEO spell distributions, tenure snapshots, combined outcomes figure | Yes |
| `montecarlo` | Build Monte Carlo simulation figure (`figure/figuremc.pdf`) and ATET table | Yes |
| `clean` | Remove generated files (no recipe shown in the Makefile, but declared phony) | Yes |

---

## Individual Script Invocations

When a Makefile is unavailable or you need to run a single step incrementally, invoke the scripts directly from the repository root. The order matters — each script depends on outputs from prior steps.

### Data Wrangling Layer (`lib/create/`)

```bash
# 1. Process raw balance sheet data
stata-mp -b do lib/create/balance.do

# 2. Create manager facts lookup tables
stata-mp -b do lib/create/manager-facts.do

# 3. Create cleaned CEO tenure intervals
stata-mp -b do lib/create/intervals.do

# 4. Process CEO panel data (depends on balance, manager-facts, intervals)
stata-mp -b do lib/create/ceo-panel.do

# 5. Merge balance + CEO panel into unfiltered dataset
stata-mp -b do lib/create/unfiltered.do

# 6. Create analysis sample (parameterized by variation)
stata-mp -b do lib/create/analysis-sample.do full

# 7. Extract firm-manager edgelist (uses full sample)
stata-mp -b do lib/create/edgelist.do

# 8. Find largest connected component of managers
julia --project=. lib/create/connected_component.jl

# 9. Compute leverage of each firm-manager edge (optional)
julia --project=. lib/create/leverage.jl

# 10. Generate placebo CEO transitions (parameterized by variation + sample)
stata-mp -b do lib/create/event_study_sample.do full full
```

### Estimation Layer (`lib/estimate/`)

```bash
# 1. Estimate revenue function and residualize surplus
stata-mp -b do lib/estimate/surplus.do

# 2. Estimate manager fixed effects and variance decomposition
stata-mp -b do lib/estimate/manager_value.do

# 3. Run event study (parameterized by variation, sample, outcome, controls)
stata-mp -b do lib/estimate/event_study.do full full lnR no lnR excessvariance

# 4. ATET variant of event study
stata-mp -b do lib/estimate/event_study_atet.do full full lnR no lnR excessvariance

# 5. Revenue function estimation
stata-mp -b do lib/estimate/revenue_function.do

# 6. Balance estimation (alternative analysis)
stata-mp -b do lib/estimate/balance.do

# 7. Bloom et al. autonomy analysis
stata-mp -b do lib/estimate/bloom_autonomy_analysis.do
```

### Exhibit Layer (`lib/exhibit/` or paper-specific `src/exhibit/`)

```bash
# Root-level tables
stata-mp -b do lib/exhibit/table1.do
stata-mp -b do lib/exhibit/table3.do
stata-mp -b do lib/exhibit/tableA0.do
stata-mp -b do lib/exhibit/tableA1.do

# Application paper figures (run from papers/application/)
stata -b do src/exhibit/figure1.do
stata -b do src/exhibit/figure2.do
stata -b do src/exhibit/figure3.do

# Econometrics paper exhibits (run from papers/econometrics/)
stata-mp -b do src/exhibit/outcomes.do full
stata-mp -b do src/exhibit/final_outcomes.do
stata-mp -b do src/exhibit/application_r2s.do
stata-mp -b do src/exhibit/debiased_r2s.do full
stata-mp -b do src/exhibit/atets.do
stata-mp -b do src/exhibit/firm-descriptives.do
stata-mp -b do src/exhibit/switch-descriptives.do
stata-mp -b do src/exhibit/industry-descriptives.do
```

### Test Layer (`lib/test/`)

```bash
# Network analysis test harness
julia --project=. lib/test/test_network.jl 1000 10

# Placebo test (after event study has written output/test/placebo.dta)
stata-mp -b do lib/test/placebo.do
```

---

## Parameterized Builds

The Makefiles use GNU Make's `foreach` and `eval` to generate pattern rules over cross products of build parameters, avoiding repetitive rule definitions.

### Analysis Variations

The pattern rule `temp/%-analysis-sample.dta` maps any valid variation name to `lib/create/analysis-sample.do`:

```makefile
temp/%-analysis-sample.dta: lib/create/analysis-sample.do temp/unfiltered.dta lib/util/filter.do
	$(STATA) $< $*
```

The stem `%` captures the variation (e.g., `pre2000`, `size3`). The script receives it as position argument and applies the corresponding `filter.do` condition. Seven variations produce seven analysis samples.

### Placebo Generation Cross Product

The `GEN_PLACEBO` template generates one build rule per variation–sample pair:

```makefile
define GEN_PLACEBO
temp/$(1)_placebo_$(2).dta: lib/create/event_study_sample.do temp/$(1)-analysis-sample.dta temp/manager_value.dta
	$$(STATA) $$< $(1) $(2)
endef
$(foreach variation, $(ANALYSIS_VARIATIONS), $(foreach sample, $(SAMPLES), $(eval $(call GEN_PLACEBO,$(variation),$(sample)))))
```

The root Makefile produces 7 × 10 = 70 placebo files. The econometrics paper replicates this with its own `VARIATIONS` and `SAMPLES`.

### Event Study Effects Cross Product (Econometrics Paper)

The `effects_RULE` template produces a three-level nested cross product (variation × sample × outcome):

```makefile
define effects_RULE
data/$(1)_$(2)_$(3)-$(3).csv: $$(CODELIB) $$(DATALIB) data/$(1)_placebo_$(2).dta
	mkdir -p data
	$$(STATA) -b do "../../lib/estimate/event_study.do" $(1) $(2) $(3) no $(3) excessvariance
endef
$(foreach variation, $(VARIATIONS),$(foreach sample,$(SAMPLES),$(foreach outcome, $(OUTCOMES), $(eval $(call effects_RULE,$(variation),$(sample),$(outcome))))))
```

This pattern generates 7 × 10 × 5 = 350 build rules in the econometrics paper's Makefile.

### ATET Cross Product and Debiased R² Tables

The `atets_RULE` template mirrors `effects_RULE` but invokes `event_study_atet.do` instead. The `debiased_rule` template then aggregates ATET CSVs across all samples and outcomes for a single variation to build a debiased R² table.

### Monte Carlo Scenarios

The econometrics paper defines `MC_SCENARIOS` with 7 DGP specifications (`baseline`, `persistent`, `excessvariance`, `excessvariance_corr`, `all`, `trend`, `longpanel`). The `GEN_MC` template generates event study data and ATET data for each scenario using Monte Carlo placebo files built from scenario-specific DGP scripts.

---

## Paper Compilation Procedures

### Application Paper

Compile from `papers/application/`:

```console
# Automatic (via Make)
make report

# Manual LaTeX compilation
cd output && \
  pdflatex paper.tex && \
  bibtex paper && \
  pdflatex paper.tex && \
  pdflatex paper.tex
```

The Make target `paper.pdf` lists all prerequisite tables and figures explicitly as dependencies, ensuring every exhibit is current before compilation:

```makefile
paper.pdf: paper.tex ../../lib/references.bib \
    table/table1_panelAB.tex table/table2_panelA.tex table/table2_panelB.tex \
    table/table3.tex table/tableA0.tex table/tableA1.tex table/tableA3.tex \
    table/tableA4.tex \
    figure/manager_skill_within.pdf figure/manager_skill_connected.pdf \
    figure/figure1.pdf figure/figure2.pdf figure/figure3.pdf
	$(LATEX) paper.tex && bibtex paper && $(LATEX) paper.tex && $(LATEX) paper.tex
```

Three `pdflatex` passes are required: the first writes auxiliary files, BibTeX resolves citations, and subsequent passes resolve cross-references.

### Econometrics Paper

The econometrics paper does not include a LaTeX compilation target. Its Makefile produces standalone tables and figures under `table/` and `figure/` for inclusion in a separate manuscript. Compile that manuscript manually.

---

## Execution Order and Dependencies

The end-to-end build must respect the following dependency chain:

```
Raw data (balance sheets, CEO registry)
  → balance.dta, intervals.dta, manager-facts.dta
    → ceo-panel.dta
      → unfiltered.dta
        → analysis-sample.dta         (7 variations)
          → edgelist.csv
            → large_component_managers.csv
          → surplus.dta
            → manager_value.dta
              → placebo files          (variation × sample cross product)
                → event study CSVs     (variation × sample × outcome)
                  → tables and figures
                    → paper PDF
```

The Makefiles encode these dependencies in prerequisite lists. Running `make all` from either paper directory will transitively resolve all upstream dependencies in the correct order.

---

## Notes and Constraints

- **Proprietary inputs** are required under `input/`. Without them, only limited steps (e.g., LaTeX compilation from pre-generated tables/figures) will succeed.
- **Stata version** last used: 18.0 (MP). The root Makefile uses `stata-mp -b do`; the application paper uses `stata -b do`.
- **Julia environment** is pinned by `Project.toml` (requires modules: CSV, DataFrames, Graphs, SparseArrays).
- **Long-running builds**: the end-to-end build may take hours. Use specific leaf targets (e.g., `output/figure/event_study.pdf` or `temp/event_study_panel_a.dta`) to iterate faster.
- **Running from the correct directory** is essential: all scripts expect paths relative to project root. Application paper Makefile targets use `cd ../..` before each command.
- **File system permissions**: the Makefiles create `temp/`, `output/`, `figure/`, `table/`, and `data/` directories via `mkdir -p` as needed.
- **Preserving intermediates**: `.PRECIOUS` targets prevent Make from deleting costly intermediate files (placebo DTAs, manager value estimates) after partial builds.
- **Parallel execution**: the Makefiles are not explicitly parallel-safe. Avoid `make -j` unless you understand the Stata file-locking behavior.
