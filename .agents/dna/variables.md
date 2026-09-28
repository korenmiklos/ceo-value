# Variable Definitions

The variables below are generated in the `lib/util/variables.do` script applied to the cleaned panel `temp/unfiltered.dta`.

| Variable | Code generating it | Description |
|----------|--------------------|-------------|
| `export` | input variable | Export volume (sales exports) |
| `employment` | input variable | Number of employees |
| `tangible_assets` | `cond()` | Strength of tangible assets | 
| `materials` | `cond()` | Materials expenses |
| `wagebill` | `cond()` | Wage bill |
| `personnel_expenses` | `cond()` | Personnel expenses |
| `intang` | input | Intangible assets |
| `assets` | `cond()` | Tied‑together assets variable |
| `EBITDA` | `generate EBITDA = sales - personnel_expenses - materials` | Earnings before interest tax depreciation & amortisation |
| `dfunc` | ... | **skip** |

## Log‑transformed variables
| Symbol | Variable | Formula |
|--------|----------|---------|
| `lnK` | `ln(tangible_assets)` | log of tangible assets |
| `lnA` | `ln(assets)` | log of total assets |
| `lnR` | `ln(sales)` | log of sales |
| `lnEBITDA` | `ln(EBITDA)` | log of EBITDA |
| `lnL` | `ln(employment)` | log of labor |
| `lnM` | `ln(materials)` | log of materials |
| `lnWL` | `ln(wagebill) - lnL` | log avg wage per worker |
| `lnKL` | `lnK - lnL` | log capital–labor ratio |
| `lnRL` | `lnR - lnL` | log sales–labor ratio |
| `lnMR` | `lnM - lnR` | log materials–sales ratio |
| `lnYL` | `ln(sales - materials) - lnL` | log sales minus materials per worker |

## Shares and indicators
| Symbol | Variable | Formula |
|--------|----------|---------|
| `exportshare` | `export / sales` | share of sales that are exports, winsorized 0–1 |
| `intang` | `intang_assets / (tangible_assets + intangible_assets)` | intangible_assets share |
| `has_intangible` | `intang_assets > 0` | binary flag for presence of intangible assets |
| `exporter` | `export > 0` | binary exporter indicator |
| `ROA` | `EBITDA/(L.tangible_assets + tangible_assets) * 2` | Return on assets, winsorized between 1st and 99th percentile |

## Structural and auxiliary variables
| Variable | Description |
|----------|-------------|
| `frame_id_numeric` | numeric firm identifier |
| `foundyear` | year of foundation |
| `year` | panel year |
| `ceo_spell` | count of CEO spell for a record |
| `n_ceo` | number of CEOs in the firm in a year |
| `min_firm_age` | computed age `year - foundyear` |
| `cohort` | 3‑year cohort based on `foundyear` |
| `firm_age_sq` | squared firm age |
| `max_size`, `early_size` | categorical size indicator (1 small ≤9 ; 2 large ≥10) |
| `seller` | not official.

*Full list of labels is shown in the comments section of `variables.do` (lines 67–115).*