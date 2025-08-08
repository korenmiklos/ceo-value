# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an academic research project implementing a novel placebo-controlled event study design to estimate the causal effect of CEO quality on firm performance. Using comprehensive administrative data from Hungarian firms (1992-2022), the project separates true managerial effects from spurious correlations by comparing actual CEO transitions to carefully constructed placebo transitions. The analysis uses Stata for data processing and econometric estimation, Julia for network analysis, and LaTeX for paper compilation.

## Core Commands

### Build the entire project
```bash
make all
```
This runs all Stata scripts in dependency order and compiles the final PDF.

### Individual components
```bash
# Process balance sheet data
stata -b do code/create/balance.do

# Process CEO panel data  
stata -b do code/create/ceo-panel.do

# Create analysis sample
stata -b do code/create/analysis-sample.do

# Generate placebo CEO transitions
stata -b do code/create/placebo.do

# Extract firm-manager edgelist
stata -b do code/create/edgelist.do

# Find largest connected component of managers
julia --project=. code/create/connected_component.jl

# Run econometric analysis
stata -b do code/estimate/surplus.do

# Run placebo-controlled event study
stata -b do code/estimate/event_study.do

# Compile LaTeX document
cd output && pdflatex paper.tex && bibtex paper && pdflatex paper.tex && pdflatex paper.tex
```

### Manual execution (if Make unavailable)
```bash
stata -b do code/create/balance.do
stata -b do code/create/ceo-panel.do  
stata -b do code/create/analysis-sample.do
cd output && pdflatex paper.tex && pdflatex paper.tex
```

## Architecture

### Data Pipeline
1. **Raw Data** (`input/`): Proprietary Hungarian administrative datasets
   - `input/merleg-LTS-2023/balance/balance_sheet_80_22.dta`: Balance sheet data
   - `input/ceo-panel/ceo-panel.dta`: CEO registry data

2. **Processing** (`code/create/`): Stata scripts that clean and merge data
   - `balance.do`: Processes balance sheets (1992-2022), creates standardized variables
   - `ceo-panel.do`: Processes CEO registry, constructs firm-person-year structure  
   - `analysis-sample.do`: Merges datasets, applies industry classifications and sample restrictions
   - `placebo.do`: Generates placebo CEO transitions with same probability as actual changes but excluding actual transition periods
   - `edgelist.do`: Extracts firm-manager edgelist (frame_id_numeric, person_id) to CSV

3. **Utilities** (`code/util/`): Helper scripts called by main processing
   - `industry.do`: TEAOR08 industry sector classifications
   - `variables.do`: Derived variables (logs, tenure, age, firm characteristics)
   - `filter.do`: Final sample restrictions

4. **Analysis** (`code/estimate/`): Econometric estimation
   - `surplus.do`: Estimates revenue function and residualizes surplus for skill identification
   - `event_study.do`: Implements placebo-controlled event study design comparing actual vs placebo CEO transitions
   - `manager_value.do`: Estimates manager fixed effects and generates distribution plots

5. **Output** (`temp/`, `output/`): Intermediate data and final results
   - `temp/`: Processed Stata datasets, edgelist CSV, connected component results
   - `output/table/`: LaTeX tables for paper
   - `output/paper.pdf`: Final compiled document

### Network Analysis Component
`code/create/connected_component.jl` implements graph algorithms for CEO network analysis:
- Reads firm-manager edgelist from `temp/edgelist.csv`
- Projects bipartite graph to manager-manager network via shared firms
- Finds largest connected component of managers
- Outputs manager person_ids in largest component to `temp/largest_component_managers.csv`
- Uses modular functions with configurable column names for flexibility

## Key Dependencies

- **Stata 18.0**: All data processing and econometric analysis
- **Julia**: Graph algorithms (packages: CSV, DataFrames, Graphs, SparseArrays)
- **LaTeX**: Document compilation with standard packages (booktabs, graphicx, natbib, hyperref)
- **Make**: Build automation

## File Structure Notes

- All scripts must be run from project root directory
- Relative paths are used throughout
- Intermediate data saved to `temp/`
- Log files generated for all Stata operations
- Final analytical sample: 8,872,039 firm-year observations
- Event study sample: 51,736 firms with exactly one CEO change
- Placebo-controlled treatment effect: 6.8% (27% of raw correlation)

## Stata Coding Style

Beyond the CEU MicroData Stata Style Guide, this project follows additional conventions:

### Script Structure
- Start with `*!` version and description comments
- Use `clear all` for setup (not `set more off` or `cap log close`)
- Use section dividers with `* =============================================================================`
- End sections with descriptive `display` statements

### Variable Creation
- Use `generate byte` for binary variables when memory efficient
- Use `generate str` for string variables with explicit type
- Prefer `egen` functions with `by()` option over `bysort` + `generate`
- Use descriptive temporary variable names (e.g., `fmtag`, `max_n_managers`)

### Data Manipulation Patterns
- Use `keep if` early to reduce dataset size
- Use `drop` immediately after variables are no longer needed
- Use `preserve`/`restore` for temporary data operations
- Use `tempfile` and backtick notation for temporary datasets
- Use `collapse` with multiple statistics: `(mean) var1 (firstnm) var2`

### Advanced Techniques
- Use `egen tag()` for creating unique identifiers across groups
- Use `reshape wide` for pivoting data with string suffixes
- Use `merge ... using ..., keep(match) nogen` for clean merging
- Use `inrange()` function instead of `>= & <=` conditions
- Use `!missing()` instead of `~missing()` for clarity

### Comments and Documentation
- Use explanatory comments before complex operations
- Include verification steps with `count if` statements
- Add context for business logic (e.g., "switching years can be noisy")
- Use descriptive variable names that don't require comments

### Creating Exhibits and Tables
- Exhibit code lives in `code/exhibit/` directory
- Exhibits are named `table1.do`, `table2.do`, etc. (not `exhibit1.do`)
- Output files are named `output/table/table1.tex`, etc. (matching the .do filename)
- Use programmatic LaTeX generation with `file write` commands
- Include comprehensive table notes using `\begin{tablenotes}[flushleft]` and `\footnotesize`
- For long tables, show selected rows (e.g., every 5th year + first/last + totals)
- Use 9999 as indicator for total/summary rows when appending aggregated data
- Format numbers with thousand separators using `%12.0fc`
- Create summary statistics at the end of scripts for log file documentation
- In Makefile: exhibit dependencies include both data files and connected component CSV files

## Data Confidentiality

This project uses proprietary data that cannot be shared. Data files in `input/` are not included in repository and must be obtained separately from HUN-REN KRTK or Opten Zrt.

## Build and Development Notes

- **Make Timeout**: 
  * make takes long to run, adjust the timeout. 5 minutes is expected