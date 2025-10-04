# Makefile Migration to Monorepo Structure

## Changes Made

### 1. Makefile Location
- **Old**: `/ceo-value/Makefile`  
- **New**: `/ceo-value/papers/application/Makefile`

### 2. Key Path Updates

#### Code References
- `code/` → `../../lib/` (shared library code)
- `code/exhibit/` → `papers/application/src/exhibit/` (paper-specific exhibits)
- `code/util/` → `../../lib/util/`
- `code/create/` → `../../lib/create/`
- `code/estimate/` → `../../lib/estimate/`

#### Data Paths  
- `temp/` → `../../temp/` (shared temp directory)
- `input/` → `../../input/` (shared input directory)
- `output/` → `../../output/` (for shared outputs)

#### Paper-Specific Outputs
- `output/table/` → `papers/application/table/`
- `output/figure/` → `papers/application/figure/`

### 3. Exhibit Script Updates

All scripts in `papers/application/src/exhibit/` were updated:

- **table1.do**: Output path updated to `papers/application/table/table1_panelAB.tex`
- **table2.do**: Output paths updated to `papers/application/table/table2_panel[A|B].tex`
- **table3.do**: 
  - Changed `code/create/network-sample.do` → `lib/create/network-sample.do`
  - Output path → `papers/application/table/table3.tex`
- **tableA0.do**: Output path → `papers/application/table/tableA0.tex`
- **tableA1.do**: Output path → `papers/application/table/tableA1.tex`
- **figure1.do**: Output path → `papers/application/figure/figure1.pdf`
- **figure2.do**: 
  - `code/exhibit/event_study.do` → `papers/application/src/exhibit/event_study.do`
  - Output path → `papers/application/figure/figure2.pdf`
- **figure3.do**: 
  - `code/exhibit/event_study.do` → `papers/application/src/exhibit/event_study.do`
  - Output path → `papers/application/figure/figure3.pdf`
- **figuremc.do**: Similar updates to figure2/3

### 4. Working Directory Strategy

All Stata/Julia commands run from project root using `cd ../..`:
```make
../../temp/balance.dta: ../../lib/create/balance.do
	cd ../.. && $(STATA) lib/create/balance.do
```

This ensures:
- Scripts can use relative paths like `temp/balance.dta` 
- Shared library code remains accessible
- Paper-specific outputs go to correct locations

### 5. Julia Project Path

Updated Julia invocation:
```make
JULIA := julia --project=../..
```

### 6. Directory Cleanup

- Flattened `papers/application/table/table/` → `papers/application/table/`
- Flattened `papers/application/figure/figure/` → `papers/application/figure/`

## Running the Build

From the paper directory:
```bash
cd papers/application
make all          # Full build
make data         # Data wrangling only
make analysis     # Analysis only  
make paper.pdf    # Compile paper
```

## Testing

Dry run test passed:
```bash
cd papers/application && make -n paper.pdf
```

All paths resolved correctly with proper execution from root directory.

## Update: Event Study Data Files

### Changes Made (2024-10-04)

Event study CSV files have been moved from the shared `output/event_study/` directory to the paper-specific `papers/application/data/` directory.

#### Files Moved
- All event study CSV files: `{sample}_{outcome}.csv` where:
  - Samples: `full`, `fnd2non`, `non2non`, `post2004`, `fnd2fnd`, `non2fnd`, `montecarlo`
  - Outcomes: `TFP`, `lnK`, `lnWL`, `lnM`, `has_intangible`

#### Code Changes

**Makefile Updates:**
- Event study rule output path: `../../output/event_study/` → `data/`
- Figure dependencies updated to reference `data/*.csv`

**Library Script Updates:**
- `lib/estimate/event_study.do`: Auto-detects paper context and writes to `papers/application/data/` when run from application paper

**Exhibit Script Updates:**
- `src/exhibit/figure2.do`: Import from `papers/application/data/`
- `src/exhibit/figure3.do`: Import from `papers/application/data/`
- `src/exhibit/figuremc.do`: Import from `papers/application/data/`

This change isolates paper-specific intermediate data files, making the monorepo structure cleaner and enabling multiple papers to have their own event study data without conflicts.

## Update: Bibliography File Location

### Changes Made (2024-10-04)

The shared bibliography file has been moved from `output/references.bib` to `lib/references.bib`.

#### Rationale
- The bibliography is a shared resource used across multiple papers in the monorepo
- Placing it in `lib/` (the shared library directory) makes more sense than `output/`
- This aligns with the monorepo structure where `lib/` contains shared code and resources

#### Code Changes

**File Move:**
- `output/references.bib` → `lib/references.bib` (using `git mv`)

**paper.tex Update:**
```latex
\bibliography{../../lib/references}
```

**Makefile Update:**
- Added `../../lib/references.bib` as a dependency for `paper.pdf` target
- Ensures paper rebuilds when bibliography is updated

#### Verification

Compilation tested successfully:
```bash
cd papers/application
pdflatex paper.tex && bibtex paper && pdflatex paper.tex && pdflatex paper.tex
# Output: 23 pages, 651KB (includes references)
```

Make target tested:
```bash
make paper.pdf  # ✓ Works correctly
```
