---
type: reference
title: External Tools and Packages
description: Documents the external software dependencies and their roles across Stata, Julia, Matlab, and LaTeX toolchains used in the firm-manager fixed-effect bias-correction pipeline.
tags: [stata, julia, matlab, latex, dependencies, bias-correction, kss]
verified:
  - by: openwiki/0.5.0
    at: 2026-09-06T19:57:00.087Z
sources:
  - id: openwiki-source-e6021cf24f8410c40aaf6ee1
    resource: repo://lib/create/connected_component.jl
  - id: openwiki-source-0f02924f1a872fc0ce9e8336
    resource: repo://lib/create/leverage.jl
  - id: openwiki-source-48d46b9352692a1c5ba81912
    resource: repo://lib/estimate/bloom_autonomy_analysis.do
  - id: openwiki-source-f626faeec630004c3392a141
    resource: repo://lib/estimate/event_study.do
  - id: openwiki-source-6c17ee820f3a743f1061bc3c
    resource: repo://lib/estimate/manager_value.do
  - id: openwiki-source-f4654182fa577f7165a11860
    resource: repo://lib/estimate/revenue_function.do
  - id: openwiki-source-e9e02b9d834f8e298693cb09
    resource: repo://lib/estimate/setup_event_study.do
  - id: openwiki-source-3ce4cfc25b9848c4c80a32e6
    resource: repo://lib/estimate/xt2var.do
  - id: openwiki-source-063a17dbfdd0b7095e6bed88
    resource: repo://lib/KSS/leave_out_COMPLETE.m
  - id: openwiki-source-b3e5daa694b07791f2a69ca2
    resource: repo://lib/KSS/leave_out_FD.m
  - id: openwiki-source-66c48298d2bb89eaacbf17c3
    resource: repo://lib/KSS/leave_out_KSS.m
  - id: openwiki-source-0b4443606c794d02e5f3fdc1
    resource: repo://lib/util/install.do
  - id: openwiki-source-f1257e562ca22f6474d4863c
    resource: repo://papers/econometrics/paper.tex
  - id: openwiki-source-0f3c6735bbc40f4951ad2578
    resource: repo://Project.toml
generated: { by: "openwiki/0.5.0", at: "2026-09-06T19:57:00.087Z" }
---

# External Tools and Packages

This page inventories the third-party software dependencies that the bias-correction pipeline relies on. These are installed separately from the project's own code and are enumerated here to support setup, debugging, and reproducibility reviews.

## Stata Packages

The Stata components of the pipeline use four community-contributed packages. The canonical installation script is `lib/util/install.do`, which installs `xt2treatments` and `e2frame` from GitHub and `reghdfe` and `estout` from the SSC archive.

### reghdfe

**Role:** High-dimensional fixed-effects linear regression.

**Source:** SSC (`ssc install reghdfe`).

**Usage:** Called throughout `lib/estimate/` for absorbing firm and manager fixed effects (and other high-dimensional categorical variables) with clustered standard errors. Key call sites include:

- `lib/estimate/manager_value.do` — absorbs `frame_id_numeric` (firm) and `person_id` (manager) effects.
- `lib/estimate/revenue_function.do` — estimates revenue, EBITDA, wage, and material regressions with firm-manager fixed effects and firm-level clustering.
- `lib/estimate/bloom_autonomy_analysis.do` — firm-level cross-sectional HLM-style regressions with high-dimensional controls.
- `lib/estimate/xt2var.do` — difference-in-differences regressions with two-way fixed effects.

**Entrypoint:** Called via Stata's `reghdfe` command, e.g.:

```stata
reghdfe lnR `controls', absorb(frame_id_numeric person_id) vce(cluster frame_id_numeric)
```

**Failure modes:** Installation incompatibility (requires Stata 14+ and a Java runtime on some platforms). Singular absorbed effects produce a warning but do not stop estimation.

### estout (esttab / eststo)

**Role:** Regression table export to LaTeX.

**Source:** SSC (`ssc install estout`).

**Usage:** `eststo` stores estimation results, `esttab` formats them as LaTeX tables with significance stars, standard errors, and model labels. Used primarily in `lib/estimate/revenue_function.do`.

**Relationship:** The project's LaTeX documents define `\newcommand{\sym}[1]{{#1}}` to render the significance stars that `esttab` emits, ensuring mechanical compatibility.

### xt2treatments

**Role:** Staggered difference-in-differences estimation with two-way fixed effects and clustering.

**Source:** GitHub (`net install xt2treatments, from(https://raw.githubusercontent.com/codedthinking/xt2treatments/main/)`).

**Usage:** Called in `lib/estimate/xt2var.do` for event-study regressions where treatment timing varies across units. The pipeline requires version 0.9 or higher for correct clustering (`lib/estimate/setup_event_study.do` checks `which xt2treatments`).

**Failure modes:** Older versions miscompute standard errors with clustering. The setup script guards against this by verifying the installed version.

### e2frame

**Role:** Extract estimation results (coefficients, covariance matrices) into Stata frames for programmatic manipulation.

**Source:** GitHub (`net install e2frame, from(https://raw.githubusercontent.com/codedthinking/e2frame/main/)`).

**Usage:** Captures `e(b)`, `e(V)`, and related matrices from fitted models into named frames for post-estimation bias corrections. Used in:

- `lib/estimate/event_study.do` — extracts coefficient vectors and covariance matrices for placebo-corrected difference-in-differences.
- `lib/estimate/xt2var.do` — captures covariance and variance components for debiasing.

## Julia Packages

The Julia code lives under `lib/create/` and `lib/test/` and depends on the packages declared in `Project.toml`.

| Package          | UUID                                   | Role in pipeline                                                         |
|------------------|----------------------------------------|--------------------------------------------------------------------------|
| `CSV`            | `336ed68f-0bac-5ca0-87d4-7b16caf5d00b` | Read/write edgelists and component membership tables (CSV format).       |
| `DataFrames`     | `a93c6f00-e57d-5684-b7b6-d8193f3e46c0` | Tabular data manipulation for edgelist and component output.             |
| `Graphs`         | `86223c79-3864-5bf0-83f7-82e725a168b6` | Connected-components analysis of bipartite firm–manager graphs.          |
| `LeaveOut`       | `b3d5e7a1-4c62-4f8a-9e11-2a7c9f0d6e34` | Compute edge leverages (hat values) for the bipartite graph's incidence matrix. |
| `Random`         | `9a3f8284-a2c9-5f02-9a11-845980a1fd5c` | Random sampling for synthetic data generation and connectivity tests.    |
| `SparseArrays`   | `2f01184e-e22b-5df5-ae63-d93ebab69eaf` | Sparse matrix construction for bipartite projection and graph adjacency. |

### Key call sites

- **`lib/create/connected_component.jl`** — Reads a firm–manager edgelist (produced by Stata), projects the bipartite graph to a manager–manager graph via `B' * B`, finds connected components using `Graphs.connected_components`, and writes component membership to CSV. Entrypoint for the Julia pipeline.
- **`lib/create/leverage.jl`** — Reads the same edgelist, constructs a `Graphs.SimpleGraph` bipartite structure, selects a connected component by rank, and calls `LeaveOut.prepare`/`LeaveOut.Design` to compute edge leverages. Writes the leverages back to the edgelist CSV.
- **`lib/test/test_network.jl`** — Connectivity and path-finding tests using `Graphs.has_path` and BFS-based path extraction.

### Failure modes

- Missing `Project.toml` or `Manifest.toml` prevents package resolution. The environment should be instantiated with `julia --project=. -e 'using Pkg; Pkg.instantiate()'`.
- `LeaveOut` is a new, small-registry package (UUID `b3d5e7a1-...`); it may not resolve on older Julia versions (< 1.8).
- Memory: `SparseArrays` with a full `B' * B` product on graphs with > 10⁵ nodes can exhaust RAM. The code relies on `dropzeros!` to mitigate.

## Matlab KSS Leave-Out Estimators

Three functions in `lib/KSS/` implement the Kline–Saggio–Solomon (KSS) leave-out variance correction for two-way fixed-effects models. These are standalone Matlab functions (no additional dependencies beyond base Matlab and the optional Combinatorial Multi-Grid solver for large datasets).

### leave_out_COMPLETE.m

**Role:** Full leave-out estimation of firm-effect and worker-effect variances in the AKM model (levels specification).

**Signature:**

```matlab
[sigma2_psi, sigma_psi_alpha, sigma2_alpha, SE_sigma2_psi, SE_sigma_psi_alpha, SE_sigma2_alpha] = ...
    leave_out_COMPLETE(y, id, firmid, leave_out_level, year, controls, ...)
```

**Capabilities:**

- Exact or Johnson–Lindenstrauss (JL) approximation of the leverage (`P_ii`, `B_ii`) matrices.
- Leave-one-out at the observation level or the worker-history level.
- Inference robust to serial correlation (requires a year variable).
- Optional CMG (Combinatorial Multi-Grid) solver for the Laplacian linear system when controls are absent or residualized (version 1.5+).

**Extension points:** The `scale` (exact version) or `epsilon` (JL version) parameters trade speed for bias in leverage approximation. The `type_of_algorithm` flag toggles between `'exact'` and `'JLL'`.

### leave_out_FD.m

**Role:** Leave-out variance of firm effects in the first-differenced (FD) or pooled first-differenced (PFD) specification.

**Signature:**

```matlab
[sigma2_psi, V] = leave_out_FD(y, id, firmid, leave_out_level, leave_2_out, controls, ...)
```

**Capabilities:**

- Supports `max(T_i) = 2` (simple FD) and `max(T_i) > 2` (PFD weighting by `T_i`).
- Leave-two-out connected set option (`leave_2_out`) for inference on variance estimates.
- Monte Carlo exercise for finite-sample diagnostics.
- Standard errors that account for within-worker serial correlation (version 2.0+).

### leave_out_KSS.m

**Role:** A simplified wrapper of `leave_out_COMPLETE.m` that replaces the JL `epsilon` parameter with a direct simulation-count parameter (`scale`).

**Signature:**

```matlab
[sigma2_psi, sigma_psi_alpha, sigma2_alpha, SE_sigma2_psi, SE_sigma_psi_alpha, SE_sigma2_alpha] = ...
    leave_out_KSS(y, id, firmid, leave_out_level, year, controls, ...)
```

**Usage:** Called with `type_of_algorithm='JLL'` and a `scale` value that directly controls the number of JL simulation draws rather than the epsilon precision target.

### Invariants and failure modes

- All three functions require input sorted by worker ID and year (`xtset id year` in Stata terms).
- If `leave_out_level` is not `'obs'` and `restrict_movers=0`, person-effect variance (`sigma2_alpha`) is set to `NaN` because stayers do not identify it under multi-observation leave-out.
- The JLL algorithm cannot run on a non-Laplacian design matrix; the code errors if `resid_controls=0` with controls present and `type_of_algorithm='JLL'`.
- Large datasets without the CMG toolbox may be extremely slow for exact leverage computation.

## LaTeX Toolchain

The project produces two academic papers and one slide deck. Their LaTeX documents draw on the following packages (beyond a standard TeX Live distribution):

### Econometrics paper (`papers/econometrics/paper.tex`)

| Package             | Purpose                                              |
|---------------------|------------------------------------------------------|
| `amsmath`, `amssymb`| Mathematical notation for variance, covariance operators. |
| `apacite` / `natbib`| Citations and bibliography (APA style).             |
| `graphicx`          | Figure inclusion.                                    |
| `booktabs`          | Publication-quality table rules.                     |
| `threeparttable`    | Tables with notes.                                   |
| `hyperref`          | Internal and external hyperlinks.                    |
| `setspace`          | Double-spacing for draft.                            |
| `comment`           | Conditional blocks.                                  |
| `outlines`          | Multi-level lists.                                   |
| `geometry`          | Page margins (2.5 cm).                                |

The `\sym` command is defined locally to match the significance-star convention emitted by `estout`/`esttab`.

### Slides (`output/preamble-slides.tex`)

Beamer presentation with:

| Package             | Purpose                                              |
|---------------------|------------------------------------------------------|
| `pgfpages`          | Handout/full-frame output.                           |
| `microtype`         | Improved justification.                              |
| `tikz`              | Custom diagrams, positioning, graphs library.        |
| `dcolumn`           | Decimal-aligned columns in tables.                   |
| `booktabs`, `threeparttable` | Table formatting.                            |
| `ragged2e`          | Full justification in blocks.                        |
| `textpos`           | Absolute-position overlays for exhibit placement.    |

### Table fragments (`papers/econometrics/table/*.tex`)

These are standalone LaTeX table snippets generated by `esttab` and included via `\input{}`. They depend only on `booktabs` and `threeparttable` being available in the parent document's preamble.

## Dependency Summary by Pipeline Stage

| Stage | Language | Core Dependencies |
|-------|----------|-------------------|
| Data extraction / sample construction | Stata | — |
| Two-way fixed-effects estimation | Stata | `reghdfe` |
| Bias correction (variance decomposition) | Matlab | `leave_out_COMPLETE.m`, `leave_out_FD.m` |
| Graph component analysis | Julia | `CSV`, `DataFrames`, `Graphs`, `SparseArrays` |
| Edge leverage computation | Julia | `LeaveOut`, `Graphs` |
| Difference-in-differences | Stata | `xt2treatments`, `e2frame` |
| Table export to LaTeX | Stata → LaTeX | `estout`, LaTeX `booktabs` + `threeparttable` |
| Paper / slide compilation | LaTeX | See package tables above |
