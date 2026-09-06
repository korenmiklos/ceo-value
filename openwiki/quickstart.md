---
type: entry point
title: CEO Value Research Project Quickstart
description: Entry point for the wiki. Routes readers to architecture, concepts, operations, testing, and integration pages based on what they need to understand, replicate, or modify in this placebo-controlled CEO event study pipeline.
tags: [quickstart, entry-point, CEO-value, placebo-design, research-pipeline, documentation-map]
verified:
  - by: openwiki/0.5.0
    at: 2026-09-06T19:57:00.087Z
sources:
  - id: openwiki-source-a2371d6362e5db4bc834ad03
    resource: repo://CLAUDE.md
  - id: openwiki-source-668d3dee65423484e813acea
    resource: repo://papers/application/Makefile
  - id: openwiki-source-59f2f40c6cfbe469fc787915
    resource: repo://papers/econometrics/Makefile
  - id: openwiki-source-23775c3de52f3ab95a13cb8b
    resource: repo://README.md
generated: { by: "openwiki/0.5.0", at: "2026-09-06T19:57:00.087Z" }
---

# CEO Value Research Project Quickstart

## Project Overview

This repository implements a **placebo-controlled event study design** that estimates the causal effect of CEO quality on firm performance. Using comprehensive Hungarian administrative data (1992–2022, ~1M firms, ~1M managers), the method constructs *fake* CEO transitions — called placebo transitions — in firms that undergo no actual CEO change. Because placebo firms have no true treatment effect, their measured moments nonparametrically estimate the bias components. Subtracting placebo moments from treated moments yields debiased causal estimates of CEO impact. The headline finding: **77% of apparent CEO effects are spurious; the true causal impact is 5.5%**.

The codebase integrates three languages under GNU Make orchestration:

| Layer | Language | Responsibility |
|-------|----------|---------------|
| Data preparation | Stata (`.do`) | Cleaning, merging, sample construction |
| Network analysis | Julia (`.jl`) | Bipartite graph projection, connected component identification |
| Econometric estimation | Stata (`.do`) | Manager fixed effects, event studies, ANOVA |
| Paper compilation | LaTeX (`.tex`) | Tables, figures, final PDF |

Two papers share the same `lib/` library: an **application paper** (`papers/application/`) reporting the main results, and an **econometrics paper** (`papers/econometrics/`) with methodological derivations and Monte Carlo simulations.

---

## What Do You Want to Do?

### Understand the Architecture

| If you want to... | Read this page |
|-------------------|---------------|
| See how data flows from raw input through estimation to exhibits | [Data and Analysis Pipeline](/openwiki/architecture/pipeline.md) — Documents Makefile dependencies, the three Stata layers (create, estimate, exhibit), Julia graph analysis, and the `code/` → `lib/` naming convention |
| Understand the econometric estimation scripts and their ordering | [Econometric Estimation Subsystem](/openwiki/architecture/estimation.md) — Covers surplus share estimation, revenue function, manager fixed effects, event study, variance decomposition, and ANOVA |

### Grasp the Core Concepts

| If you want to... | Read this page |
|-------------------|---------------|
| Learn how placebo CEO transitions are constructed, matched, and used for bias correction | [Placebo-Controlled Event Study Design](/openwiki/concepts/placebo-design.md) — The methodological core: matching logic, bias decomposition, debiased second moments, and Monte Carlo validation |
| See what data sources we use and how to get access | [Input Data Sources](/openwiki/concepts/data-sources.md) — Mérleg LTS balance sheets and Cégjegyzék LTS CEO panel: provenance, schema, placement, and confidentiality |
| Understand the two-layer sample architecture | [Analysis Samples](/openwiki/concepts/samples.md) — Analysis variations (`full`, `size1`–`size4`, `pre2000`, `post2000`) and event study sample filters (`fnd2non`, `non2non`, `gap`, `nogap`, `gender`, `nogender`, etc.) |

### Set Up and Run the Pipeline

| If you want to... | Read this page |
|-------------------|---------------|
| Install dependencies (Stata packages, Julia environment, Python) and place the proprietary data | [Setup and Dependencies](/openwiki/operations/setup.md) — Environment requirements, package installation, data placement, first-run checklist |
| Execute builds and run individual scripts | [Build and Execution](/openwiki/operations/running.md) — All Makefile targets, parameterized builds via variation/sample/outcome cross products, paper compilation |

### Test and Validate

| If you want to... | Read this page |
|-------------------|---------------|
| Add test cases or run the agent evaluation harness | [Agent Eval Harness](/openwiki/testing/eval-harness.md) — The Python-based `eval/` framework that tests AI agents on Stata do-file comprehension |

### Learn About External Tools

| If you want to... | Read this page |
|-------------------|---------------|
| Understand which Stata packages, Julia libraries, and LaTeX toolchain are required | [External Tools and Packages](/openwiki/integrations/external-tools.md) — `reghdfe`, `estout`, `xt2treatments`, `e2frame`, Julia dependencies (CSV, DataFrames, Graphs, LeaveOut, SparseArrays), KSS estimators |

---

## Quick Start (Minimal Setup)

```bash
# 1. Install Stata packages (one-time)
make install
# or: stata -b do lib/util/install.do

# 2. Place proprietary data (if you have access):
#    input/merleg-LTS-2023/balance/balance_sheet_80_22.dta
#    input/ceo-panel/ceo-panel.dta

# 3. Run the full data pipeline
make data

# 4. Build the application paper (from papers/application/)
cd papers/application && make all
```

**Important:** All commands must be run from the project root unless stated otherwise. Relative file paths are used throughout.

---

## Key Results at a Glance

| Finding | Value |
|---------|-------|
| Raw correlation (naive comparison) | 25.3% |
| Spurious effect from placebo transitions | 19.7% |
| **True causal effect** | **5.5%** |
| Variance decomposition: within-firm (p25→p75) | 9.6% |
| Variance decomposition: cross-firm connected component (p25→p75) | 24.6% |
| Share of apparent CEO effects that is spurious | 77% |
| Event study window | −4 to +3 years (baseline: year −1) |
| Final analytical sample | 8,872,039 firm-year observations, 891,631 unique firms |
| Managers in largest connected component | 189,108 |

---

## Repository Map

```
/                           Root directory — run all Stata/Julia commands from here
├── lib/                    Shared script library (the old code/ directory)
│   ├── create/             Data wrangling: balance.do, ceo-panel.do, event_study_sample.do, etc.
│   ├── estimate/           Econometric estimation: surplus.do, manager_value.do, event_study.do, etc.
│   ├── util/               Utility includes: filter.do, variables.do, industry.do, install.do
│   ├── test/               Unit/integration tests
│   ├── KSS/                KSS methodology (Koren-Szilagyi-Szoke) code
│   └── references.bib      Shared bibliography
├── input/                  Proprietary data (not included in repository)
├── temp/                   Intermediate datasets generated by the pipeline
├── output/                 Final artifacts: tables, figures, compiled paper PDF
├── papers/
│   ├── application/        Main application paper
│   └── econometrics/       Econometric methods paper + Monte Carlo simulations
├── eval/                   Agent eval harness (Python)
├── Makefile                Root build orchestration
└── openwiki/               Wiki documentation (this page and all pages linked above)
```

---

## Related Pages

- [/openwiki/architecture/pipeline.md](/openwiki/architecture/pipeline.md) — End-to-end data flow, Makefile dependency graph, script ordering
- [/openwiki/architecture/estimation.md](/openwiki/architecture/estimation.md) — Econometric estimation subsystem
- [/openwiki/concepts/placebo-design.md](/openwiki/concepts/placebo-design.md) — Placebo-controlled event study design
- [/openwiki/concepts/data-sources.md](/openwiki/concepts/data-sources.md) — Proprietary Hungarian administrative datasets
- [/openwiki/concepts/samples.md](/openwiki/concepts/samples.md) — Analysis samples catalogue
- [/openwiki/operations/setup.md](/openwiki/operations/setup.md) — Setup and dependencies
- [/openwiki/operations/running.md](/openwiki/operations/running.md) — Build and execution
- [/openwiki/testing/eval-harness.md](/openwiki/testing/eval-harness.md) — Agent eval harness
- [/openwiki/integrations/external-tools.md](/openwiki/integrations/external-tools.md) — External tools and packages
