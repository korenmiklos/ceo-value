# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an academic research project analyzing the impact of CEOs on privately held Hungarian businesses from 1992-2022. The project processes proprietary administrative data using Stata, Julia, and LaTeX to generate tables and figures for an economics paper.

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

# Extract firm-manager edgelist
stata -b do code/create/edgelist.do

# Find largest connected component of managers
julia --project=. code/create/connected_component.jl

# Run econometric analysis
stata -b do code/estimate/surplus.do

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
   - `edgelist.do`: Extracts firm-manager edgelist (frame_id_numeric, person_id) to CSV

3. **Utilities** (`code/util/`): Helper scripts called by main processing
   - `industry.do`: TEAOR08 industry sector classifications
   - `variables.do`: Derived variables (logs, tenure, age, firm characteristics)
   - `filter.do`: Final sample restrictions

4. **Analysis** (`code/estimate/`): Econometric estimation
   - `surplus.do`: Generates regression tables for paper

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

## Data Confidentiality

This project uses proprietary data that cannot be shared. Data files in `input/` are not included in repository and must be obtained separately from HUN-REN KRTK or Opten Zrt.