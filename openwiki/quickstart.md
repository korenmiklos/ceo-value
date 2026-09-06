---
type: entry-point
title: OpenWiki Quickstart
description: Entry point and task-routing map for the CEO Value Research Project wiki. Links to every wiki page organized by agent goal, with a concise project overview and a goal-to-page routing table.
tags: [entry-point, task-routing, quickstart, reference]
verified:
  - by: openwiki/0.5.0
    at: 2026-09-06T17:56:56.777Z
sources:
  - id: openwiki-source-a2371d6362e5db4bc834ad03
    resource: repo://CLAUDE.md
  - id: openwiki-source-012f2c78e3b1446dfc35803f
    resource: repo://Makefile
  - id: openwiki-source-23775c3de52f3ab95a13cb8b
    resource: repo://README.md
  - id: openwiki-source-d122eb20a9952e2f755cb685
    resource: repo://SUMMARIZE.md
  - id: openwiki-source-dcc9abf02abf0b020a0c918d
    resource: repo://WARP.md
generated: { by: "openwiki/0.5.0", at: "2026-09-06T17:56:56.777Z" }
---

# OpenWiki Quickstart

## Project Overview

This repository implements a **placebo-controlled event study design** to estimate the causal effect of CEO quality on firm performance. It uses comprehensive Hungarian administrative data (1992--2022) covering approximately 1M firms and 1M managers over 30 years.

**Key finding:** 75% of apparent CEO effects are spurious (noise rather than true skill differences). The true causal effect is 5.5% -- only 25% of the raw 22.5% correlation.

### Technology Stack

| Layer | Tool | Role |
|---|---|---|
| Data processing & estimation | Stata 18.0 | All `.do` scripts: cleaning, merging, econometrics (reghdfe, estout, xt2treatments, e2frame) |
| Network analysis | Julia 1.10.4 | Bipartite graph projection, connected components, edge leverage (`CSV`, `DataFrames`, `Graphs`, `SparseArrays`, `LeaveOut`) |
| Orchestration | Make | End-to-end dependency tracking (`make all`, incremental rebuilds) |
| Paper | LaTeX | `output/paper.pdf` with tables and figures |
| Evaluation harness | Python | AI agent evaluation on Stata code understanding (`eval/`) |

**Data:** Proprietary Hungarian administrative data (not included). See `README.md` for access instructions.

---

## Task-Routing Map

Use the table below to find the right page for your goal. Every page in this wiki is listed at least once.

| If you want to... | Start here |
|---|---|
| Run the full end-to-end build | [/openwiki/workflows/full-build.md](/openwiki/workflows/full-build.md) |
| Understand the core identification strategy | [/openwiki/concepts/placebo-controlled-event-study.md](/openwiki/concepts/placebo-controlled-event-study.md) |
| Modify the placebo construction logic | [/openwiki/workflows/placebo-construction.md](/openwiki/workflows/placebo-construction.md) |
| Understand how manager skill is estimated (AKM two-way FE) | [/openwiki/concepts/manager-skill-estimation.md](/openwiki/concepts/manager-skill-estimation.md) |
| Follow the end-to-end data flow (raw inputs to final outputs) | [/openwiki/architecture/data-pipeline.md](/openwiki/architecture/data-pipeline.md) |
| Modify econometric estimation (revenue function, event study, ATET, ANOVA) | [/openwiki/architecture/estimation-system.md](/openwiki/architecture/estimation-system.md) |
| Understand sampling filters (size, time, transition type) | [/openwiki/workflows/sampling-filtering.md](/openwiki/workflows/sampling-filtering.md) |
| Work with the Julia graph/network analysis | [/openwiki/integrations/julia-graph-analysis.md](/openwiki/integrations/julia-graph-analysis.md) |
| Understand connected components and why they matter for FE identification | [/openwiki/concepts/connected-network.md](/openwiki/concepts/connected-network.md) |
| Install Stata packages or understand Stata patterns | [/openwiki/integrations/stata-ecosystem.md](/openwiki/integrations/stata-ecosystem.md) |
| Tweak runtime parameters (filter thresholds, Monte Carlo settings) | [/openwiki/operations/runtime-parameters.md](/openwiki/operations/runtime-parameters.md) |
| Validate the event study design with Monte Carlo simulation | [/openwiki/testing/montecarlo-simulations.md](/openwiki/testing/montecarlo-simulations.md) |
| Add test cases or run the AI agent evaluation harness | [/openwiki/testing/evaluation-harness.md](/openwiki/testing/evaluation-harness.md) |
| Debug a build failure or understand Make targets | [/openwiki/workflows/full-build.md](/openwiki/workflows/full-build.md) |

---

## Page Index by Domain

### Architecture

- [Data Pipeline Architecture](/openwiki/architecture/data-pipeline.md) -- Maps the complete 10+ stage flow from raw inputs through intermediate datasets to final outputs, including script locations, file formats, and Makefile targets. Every stage is a `.PRECIOUS` artifact.
- [Estimation System](/openwiki/architecture/estimation-system.md) -- Documents all econometric estimation methods: AKM-style manager FE (two-way reghdfe), revenue function (six specifications), placebo-controlled event study via xt2denoise, ATET variant, variance decomposition of CEO skill, Monte Carlo simulation, and external KSS leave-out MATLAB routines.

### Concepts

- [Placebo-Controlled Event Study Design](/openwiki/concepts/placebo-controlled-event-study.md) -- The core causal identification strategy. Explains why standard event studies fail (dynamic endogeneity + measurement noise), the second-moment differencing logic (true variance = Var(treated) - Var(placebo)), and the three-step process (identify transitions, generate placebos via stratified matching, estimate via xt2denoise).
- [Manager Skill Estimation](/openwiki/concepts/manager-skill-estimation.md) -- How manager quality is decomposed into within-firm skill (relative to first CEO, winsorized to [-1, 1]) and between-firm skill (two-way FE on connected component). Includes person-year expansion logic.
- [Connected Component Network Analysis](/openwiki/concepts/connected-network.md) -- Bipartite firm-manager graph projection to manager-manager co-employment network, connected component detection (minimum component size 30), edge leverage computation, and why components are necessary for FE identification (effects are only identified up to a constant within each component).

### Integrations

- [Julia Graph Analysis Subsystem](/openwiki/integrations/julia-graph-analysis.md) -- The three Julia scripts (connected_component.jl, leverage.jl, test_network.jl), environment (Project.toml), data structures (BipartiteGraph, ProjectedGraph), and test harness.
- [Stata Ecosystem and Required Packages](/openwiki/integrations/stata-ecosystem.md) -- Stata 18.0 environment, required packages (reghdfe 6.12.3, estout 3.31, xt2treatments 0.9.0, e2frame 0.1.0), installation via `make install`, key patterns (reghdfe usage, estimate persistence via .ster files, log management).

### Operations

- [Runtime Parameters and Configuration](/openwiki/operations/runtime-parameters.md) -- Catalog of all configurable parameters organized by subsystem: Makefile build iterators (ANALYSIS_VARIATIONS, SAMPLES, OUTCOMES), balance sheet processing (start_year, end_year), filtering (max_ceos_per_year, max_ceo_spells, min_employment), event study sample construction, and Monte Carlo simulation parameters.

### Testing

- [Monte Carlo Simulation](/openwiki/testing/montecarlo-simulations.md) -- Two Monte Carlo implementations validating the event study design: a standalone generator (`lib/create/montecarlo.do`, 10,000 transitions, AR(1) TFP, known true effect ~0.0798), and a multi-scenario framework in `papers/econometrics/src/montecarlo/`. Documents how the same estimation code handles real and synthetic data.
- [AI Agent Evaluation Harness](/openwiki/testing/evaluation-harness.md) -- Python harness in `eval/` that tests AI coding agents on Stata code understanding. Two question types (true_false, numeric), opencode-based orchestration, per-test-case YAML question definitions, and JSON report output.

### Workflows

- [Full Build and Make Workflow](/openwiki/workflows/full-build.md) -- End-to-end build orchestration via two Makefiles (root + `papers/application/`). Phony targets (all, data, analysis, report), complete dependency chain from raw data to paper.pdf, and incremental build guidance.
- [Placebo Construction Workflow](/openwiki/workflows/placebo-construction.md) -- How placebo CEO transitions are constructed in `lib/create/event_study_sample.do`: stratified matching on cohort/sector/size, timing distribution alignment, sampling probability (10 controls per treated), weighting, and the 12 transition-type subsamples.
- [Sampling and Filtering Subsystem](/openwiki/workflows/sampling-filtering.md) -- Two-layer hierarchical sampling: Layer 1 (filter.do: universal quality filters + variation-specific subsample) and Layer 2 (event_study_sample.do: CEO transition-type restriction). The Makefile generates all 7 × 12 = 84 combinations automatically.

---

## Repository Map

```
input/                         # Proprietary data (not included)
├── merleg-LTS-2023/balance/   #   balance_sheet_80_22.dta
└── manager-db-ceo-panel/      #   ceo-panel.dta

lib/
├── create/                    # Data wrangling scripts
│   ├── balance.do             #   Stage 1: balance sheet processing
│   ├── ceo-panel.do           #   Stage 3: CEO panel construction
│   ├── intervals.do           #   Stage 2: CEO tenure cleaning
│   ├── manager-facts.do       #   Stage 3: manager demographics
│   ├── unfiltered.do          #   Stage 4: merged unfiltered dataset
│   ├── analysis-sample.do     #   Stage 5: filtered analysis sample
│   ├── event_study_sample.do  #   Stage 6: placebo transitions
│   ├── edgelist.do            #   Stage 7: firm-manager edgelist
│   ├── connected_component.jl #   Stage 8: Julia graph analysis
│   ├── leverage.jl            #   Stage 9: edge leverage
│   ├── network-sample.do      #   Helper: merge components
│   ├── montecarlo.do          #   Monte Carlo data generator
│   └── extract.do             #   Confidential data extracts
├── estimate/                  # Econometric estimation
│   ├── surplus.do             #   Revenue function residualization
│   ├── revenue_function.do    #   6 specification revenue models
│   ├── manager_value.do       #   Two-way FE manager skill
│   ├── event_study.do         #   Placebo-controlled event study
│   ├── setup_event_study.do   #   Event study setup helper
│   ├── anova.do               #   ANOVA decomposition
│   └── setup_anova.do         #   ANOVA setup helper
├── exhibit/                   # Tables and figures
│   ├── table1.do - table4.do #   Main paper tables
│   ├── tableA0.do, tableA1.do #   Appendix tables
│   ├── figure1.do - figure3.do #   Paper figures
│   └── event_study.do         #   Event study figure helper
├── test/                      # Tests
│   ├── test_network.jl        #   Julia graph test harness
│   └── placebo.do             #   Stata placebo test
└── util/                      # Utilities
    ├── install.do             #   Package installer
    ├── filter.do              #   Sample filter logic
    ├── variables.do           #   Variable construction
    ├── industry.do            #   Industry classification
    └── potholes.do            #   Gap-filling for CEO spells

temp/                          # Intermediate data (generated)
output/                        # Final artifacts
├── table/                     #   LaTeX tables
├── figure/                    #   Publication-ready figures
├── event_study/               #   Event study coefficients (CSV)
├── paper.pdf                  #   Final compiled paper
└── slides60.pdf               #   Presentation slides

eval/                          # AI agent evaluation harness
├── __main__.py                #   CLI entrypoint
├── schemas.py                 #   Pydantic data models
├── questions.py               #   YAML test case loader
├── server.py                  #   OpenCode server lifecycle
└── runner.py                  #   Evaluation orchestrator

papers/                        # LaTeX paper sources
├── application/               #   Main paper Makefile
└── econometrics/              #   Monte Carlo framework
```
