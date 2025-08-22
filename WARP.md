# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

Repository focus: academic research pipeline estimating the causal effect of CEO quality on firm performance using Hungarian administrative data (1992–2022). The stack combines Stata (data processing and econometrics), Julia (graph/network analysis), LaTeX (paper), and Make (orchestrates end-to-end builds). Proprietary inputs are not included; see README for data access and placement.

- Run all commands from the repository root
- Long-running: end-to-end builds may take hours; individual steps can be executed incrementally

Common commands
- Full build (data → analysis → figures/tables → paper):
  - make all
- Install runtime dependencies inside Stata (first run only):
  - stata -b do code/util/install.do
- Data pipeline (creates temp/*.dta and temp/edgelist.csv):
  - make data
  - or run individual steps:
    - stata -b do code/create/balance.do
    - stata -b do code/create/ceo-panel.do
    - stata -b do code/create/unfiltered.do
    - stata -b do code/create/analysis-sample.do
    - stata -b do code/create/placebo.do
    - stata -b do code/create/edgelist.do
    - julia --project=. code/create/connected_component.jl
- Econometric analysis:
  - make analysis
  - or:
    - stata -b do code/estimate/surplus.do
    - stata -b do code/estimate/manager_value.do
    - stata -b do code/estimate/event_study.do
    - stata -b do code/estimate/revenue_function.do
- Exhibits (tables/figures):
  - make output/table/table1.tex
  - make output/table/table2_panelA.tex output/table/table2_panelB.tex
  - make output/table/table3.tex
  - make output/table/table4a.tex
  - make output/table/tableA1.tex
  - make output/figure/event_study.pdf
- Compile the paper:
  - make report
  - or inside output/: pdflatex paper.tex && bibtex paper && pdflatex paper.tex && pdflatex paper.tex
- Optional confidential extracts:
  - make extract
- Clean intermediates and outputs (destructive):
  - make clean

Targeted runs and tests
- Julia network test harness (writes CSV paths report):
  - julia --project=. code/test/test_network.jl 1000 10
  - Outputs to output/test/test_paths.csv and logs connectivity stats
- Stata placebo test transform (after running event study that writes output/test/placebo.dta):
  - stata -b do code/test/placebo.do
- Re-run a single Stata program (example – event study):
  - stata -b do code/estimate/event_study.do
- Rebuild a specific exhibit from prerequisites (example – Figure 1):
  - make output/figure/event_study.pdf

Architecture overview
- Orchestration: Makefile is the single source of truth for dependencies across data creation, estimation, exhibits, and report compilation. Key phony targets: data, analysis, report, extract.
- Data layer (code/create/, Stata + Julia):
  - balance.do, ceo-panel.do, unfiltered.do, analysis-sample.do: construct the analysis dataset from proprietary inputs, standardize variables, apply filters.
  - placebo.do: generates placebo CEO transition series excluding actual transition periods.
  - edgelist.do: exports firm–manager pairs (frame_id_numeric, person_id) to temp/edgelist.csv.
  - connected_component.jl: Julia script reads edgelist, projects to a manager–manager graph, identifies the largest connected component, saves manager list to temp/large_component_managers.csv.
- Estimation layer (code/estimate/, Stata):
  - surplus.do: estimates revenue function and residualizes surplus for skill identification.
  - manager_value.do: estimates manager fixed effects, writes distribution figures and a regression table; also saves variance decomposition components to temp/within_firm.dta and temp/cross_section.dta.
  - event_study.do: implements placebo-controlled event study comparing actual vs. placebo transitions; produces panel datasets used by exhibits.
  - revenue_function.do: stores revenue model estimates in temp/revenue_models.ster used by exhibits.
- Exhibits layer (code/exhibit/, Stata):
  - table1.do, table2.do, table3.do, table4.do, tableA1.do produce LaTeX tables under output/table/.
  - figure1.do produces event_study.pdf under output/figure/.
- Outputs:
  - temp/: intermediates from creation and estimation phases.
  - output/table/ and output/figure/: final artifacts for the paper.
  - output/paper.pdf: compiled LaTeX report combining all exhibits.

Notes and constraints
- Proprietary inputs are required (see README sections “Data Availability and Provenance” and “Instructions to Replicators” for access and placement under input/). Without these, only limited steps (e.g., LaTeX compile if tables/figures are present) will work.
- All scripts assume paths relative to project root; do not change working directory when running commands.
- The Makefile encodes directories creation via mkdir -p where needed; artifacts under temp/ and output/ are safe to regenerate.
- Stata version last used: 18.0; Julia environment is pinned by Project.toml (CSV, DataFrames, Graphs, SparseArrays).
- Long-running targets: consider running make with specific leaf targets to iterate faster (e.g., output/table/table3.tex or temp/event_study_panel_a.dta).

Other agent guidance
- Import relevant context from README.md when assisting users with data placement, runtime expectations, and confidentiality constraints.
- When suggesting commands that use sensitive inputs, refer to paths like input/… without exposing any data.
- If Make is unavailable, replicate pipelines by invoking the listed Stata and Julia scripts in the sequence reflected above.

