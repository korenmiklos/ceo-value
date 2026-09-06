---
type: data source
title: Proprietary Hungarian Administrative Datasets (Mérleg LTS and Cégjegyzék LTS)
description: Documents the two proprietary Hungarian administrative datasets used in the CEO value research project—the Mérleg LTS balance sheet data and the Cégjegyzék LTS CEO panel—covering data provenance, schema, access procedures, confidentiality constraints, and placement requirements.
tags: [data-source, hungarian-administrative-data, merleg-lts, cegegyzek-lts, balance-sheet, ceo-panel, opten]
verified:
  - by: openwiki/0.5.0
    at: 2026-09-06T19:57:00.087Z
sources:
  - id: openwiki-source-e7c09a87bc4ebdf6e7d75b54
    resource: repo://input/merleg-LTS-2023/balance/README_v_20240912.txt
  - id: openwiki-source-cbbdea468bbabc80cdc25e89
    resource: repo://lib/create/balance.do
  - id: openwiki-source-4449fa522ff800d1a56ff655
    resource: repo://lib/create/ceo-panel.do
  - id: openwiki-source-b7cf126704af8528032e0799
    resource: repo://lib/create/intervals.do
  - id: openwiki-source-7d23136d63bcf19dc8ef8bd6
    resource: repo://lib/util/potholes.do
  - id: openwiki-source-23775c3de52f3ab95a13cb8b
    resource: repo://README.md
generated: { by: "openwiki/0.5.0", at: "2026-09-06T19:57:00.087Z" }
---

# Proprietary Hungarian Administrative Datasets

The CEO value project uses two proprietary Hungarian administrative datasets that together cover essentially all formally registered Hungarian firms from 1992 through 2022. Both datasets are distributed by **HUN-REN KRTK** and originally published by **Opten Zrt**. They cannot be redistributed due to strict confidentiality and redistribution restrictions in the data use agreements.

## Mérleg LTS Balance Sheet Data

### Provenance and Coverage

| Property | Value |
|----------|-------|
| Source file | `input/merleg-LTS-2023/balance/balance_sheet_80_22.dta` |
| Publisher | Opten Zrt, Budapest |
| Distributor | HUN-REN KRTK (2024) — "Mérleg LTS [data set]" |
| Period | 1980–2022 (analysis restricts to 1992–2022) |
| Observations | 10,545,843 firm-year records |
| Variables | 71 |
| Format | Stata `.dta` with full variable and value labels |
| License | Proprietary (annual fee ~€10,000 for commercial use) |

The Mérleg LTS dataset contains financial information for essentially all Hungarian firms required to file annual reports with Hungarian authorities. It covers the entire formal business sector except for the smallest individual entrepreneurs. The dataset is derived from a larger cleaned panel (`balance-sheet-1980-2022-panel-cleaned_20240913T091430885417+0200.zip`) and is updated annually. The version used is `v.5.7.0` (2024-09-12), which added year 2022 data, updated company form classifications to GFO'21, and incorporated Opten ownership data through 2022.

### Raw Schema (Inferred from Labels)

The following variables appear in the raw input and are preserved or renamed by `lib/create/balance.do`. All monetary values are in thousands of HUF (1000HUF) unless otherwise noted.

| Variable | Storage | Label |
|----------|---------|-------|
| `frame_id` | str15 | Frame_id identify one firm. Only_originalid if not valid |
| `originalid` | long | Given year Taxid. Minus if taxid not valid |
| `year` | int | Year 1980-2022 |
| `sales` | double | Sales 1000HUF |
| `sales_clean` | double | Sales cleaned 1000HUF |
| `sales22` | double | Sales in 2022 price 1000HUF |
| `emp` | double | Employment clean v8 |
| `tanass` | double | Tangible assets 1000HUF |
| `tanass_clean` | double | Tangible assets cleaned 1000HUF |
| `eszk` | double | Total assets 1000HUF |
| `export` | double | Export sales 1000HUF |
| `export22` | double | Export sales in 2022 price 1000HUF |
| `ranyag` | double | Sum of material type expenditures 1000HUF |
| `wbill` | double | Wage bill, Bérköltség 1000HUF |
| `wbill22` | double | Wage bill in 2022 price 1000HUF |
| `persexp` | double | Payments to personnel, Szemráf sum 1000HUF |
| `persexp_clean` | double | Payments to personnel cleaned 1000HUF |
| `persexp22` | double | Payments to personnel in 2022 price 1000HUF |
| `kecs` | double | Depreciation 1000HUF |
| `immat` | double | Intangible assets 1000HU |
| `immat_clean` | double | Intangible assets cleaned 1000HU |
| `so3_with_mo3` | byte | State and local government owned dummy with ultimate owners from Opten |
| `fo3` | byte | Foreign owned dummy with ultimate owners from Opten |
| `do3` | byte | Domestic owned dummy which is not so3 or fo3 |
| `mo3` | byte | Local government owned dummy which is not so3 |
| `teaor08_2d` | byte | 2 digit TEAOR08 |
| `teaor08_1d` | str1 | 1 digit TEAOR08 Letter |
| `foundyear` | int | Foundation year |
| `firmage` | int | The given year-foundation year |

Additional variables present in the raw input include: `hlk` (long-term liabilities), `rlk` (short-term liabilities), `egyebbev` (other revenues), `aktivalt` (capitalised own performance), `ranyag01`–`ranyag04` (subcomponents of material costs), `pretax` (net profit before taxation), `jetok`–`jetok06` (share capital by owner type), `satok` (equity), `ereduzem` (trading profit/loss), `gdp`/`gdp2` (gross value added), `tax` (tax paid), `county`, `region`, `VAT_group_id`, `gfo` (company form classification), and machine-related variables.

### Processing by `lib/create/balance.do`

The script located at `repo://lib/create/balance.do` transforms the raw input into `temp/balance.dta` with the following steps:

1. **Time filter**: Keeps years 1992–2023 (actual raw data goes through 2022, but script parameter `end_year = 2023`).
2. **ID cleaning**: Drops records where `frame_id == "only_originalid"` (firms without a valid frame identifier). Creates `frame_id_numeric` by parsing string IDs prefixed with `"ft"`.
3. **Variable selection**: Retains only the dimensions and facts used in analysis, then renames Hungarian variable names to English equivalents.
4. **Missingness screening**: Identifies firm-years missing any of six core variables (`sales`, `employment`, `tangible_assets`, `materials`, `personnel_expenses`, `assets`). For each firm, drops all observations before its first year with complete core data, then drops remaining incomplete years.
5. **Zero-fill and adjustment**: Uses `mvencode` to set remaining missing values to 0 for all financial variables. Adds 1 to employment and converts to integer.
6. **Derived variables**: Computes `EBITDA = sales - personnel_expenses - materials` and `capital` (lagged total assets with fallback to `assets - EBITDA` when lagged values are missing).
7. **Output**: `temp/balance.dta` — a clean firm-year panel with standardized variable names, no missing core data, and ready for merging.

## Cégjegyzék LTS CEO Panel Data

### Provenance and Coverage

| Property | Value |
|----------|-------|
| Source file | `input/manager-db-ceo-panel/ceo-panel.dta` (also referenced as `input/ceo-panel/ceo-panel.dta`) |
| Publisher | Opten Zrt, Budapest |
| Distributor | HUN-REN KRTK (2024) — "Cégjegyzék LTS [data set]" |
| Period | Firm registration history, linked to balance sheet years |
| Format | Stata `.dta` with full variable and value labels |
| License | Proprietary (same terms as Mérleg LTS) |

The Cégjegyzék LTS dataset contains firm registry information including registration dates, ownership structure, and executive appointments (CEOs). The raw input directory also contains auxiliary files:
- `ceo-spell-intervals.dta` (~43 MB)
- `ceo-spell-panel.dta` (~329 MB)
- `manager-id.dta` (~44 MB)
- `manager-panel.dta` (~984 MB)

These auxiliary files provide alternative representations of the same underlying appointment and person data.

### Raw Schema (Inferred from Processing Scripts)

The variables used from the raw CEO panel are extracted in `lib/create/manager-facts.do` and `lib/create/intervals.do`:

| Variable | Description |
|----------|-------------|
| `frame_id_numeric` | Numeric firm identifier (matching balance sheet data) |
| `person_id` | Unique CEO/person identifier |
| `year` | Calendar year of CEO-firm link |
| `male` | Binary: inferred gender from Hungarian name |
| `birth_year` | CEO birth year |
| `manager_category` | Categorical: type of manager (e.g., founder = 1) |
| `owner` | Binary: whether the manager is also an owner |

The raw data also contains a `hungarian_name` indicator inferred from the presence of gender information: `hungarian_name = !missing(male)` (`repo://lib/create/manager-facts.do#L4`).

### Processing Pipeline

The CEO panel undergoes a multi-stage processing chain before merging with balance sheet data:

1. **Manager-facts extraction** (`lib/create/manager-facts.do`): Creates two derived datasets:
   - `temp/manager-facts.dta`: Person-level data (gender, birth year, Hungarian name flag), collapsed by `person_id`.
   - `temp/manager-firm-facts.dta`: Firm-person level data (same variables minus gender and birth year) for linking.

2. **Interval cleaning** (`lib/create/intervals.do` + `lib/util/potholes.do`): Cleans raw annual appointments into non-overlapping tenure intervals:
   - **Pothole filling** (`repo://lib/util/potholes.do`): Fills gaps of 1 or 2 years in a CEO's continuous presence at a firm by expanding clone rows and adjusting years, so that brief interruptions in the raw data do not break a spell.
   - **Spell detection**: Identifies CEO spells at a firm, with the first observation of a CEO-firm pair starting a new spell; subsequent spells for the same person at the same firm are also tracked.
   - **Interval algebra** (`repo://lib/create/intervals.do#L39-L54`): Uses [Allen's interval algebra](https://en.wikipedia.org/wiki/Allen%27s_interval_algebra) to classify relationships between CEO intervals at the same firm (before, meets, overlaps, during, starts, finishes, equal, etc.).
   - **Short-interval cleanup**: Drops intervals ≤2 years that are nested inside longer ones; truncates overlapping intervals by ≤2 years.
   - **Filtering**: Limits to firms with ≤12 CEO spells (`max_ceo_spells` parameter).
   - **Output**: `temp/intervals.dta` — clean spell-level data with firm, person, and interval boundaries.

3. **CEO panel construction** (`lib/create/ceo-panel.do`): Expands intervals to firm-person-year, merges manager facts, collapses to firm-year level with CEO structure variables (`n_ceo`, `has_expat_ceo`, `has_founder`, `n_ceo_male`, `ceo_spell`).
   - **Output**: `temp/ceo-panel.dta` — firm-year panel ready for merging with balance sheet data.

## Data Placement Requirements

The raw data files must be placed in the following locations relative to the project root:

```bash
# Balance sheet data
input/merleg-LTS-2023/balance/balance_sheet_80_22.dta

# CEO panel data (at least the main file)
input/manager-db-ceo-panel/ceo-panel.dta
```

These paths are hardcoded in `lib/create/balance.do` (`repo://lib/create/balance.do#L7`) and `lib/create/intervals.do` (`repo://lib/create/intervals.do#L4`). All scripts must be run from the project root directory.

## Confidentiality and Access

### Why Data Cannot Be Shared

The datasets contain sensitive firm-level administrative information that is subject to strict confidentiality and redistribution restrictions under the original data use agreements with Opten Zrt and HUN-REN KRTK. The replication package therefore does **not** include any of the raw input data.

### How to Obtain Access

**For commercial use:** Contact Opten Zrt (opten.hu) to obtain a license. Annual license fees are approximately €10,000; expect contract negotiation and data access within 1–2 months.

**For academic/replication use:** Contact KRTK Adatbank at https://adatbank.krtk.mta.hu/.

### Citation Requirements

- HUN-REN KRTK (distributor). 2024. "Cégjegyzék LTS [data set]" Published by Opten Zrt, Budapest. Contributions by CEU MicroData.
- HUN-REN KRTK (distributor). 2024. "Mérleg LTS [data set]" Published by Opten Zrt, Budapest. Contributions by CEU MicroData.

### Confidential Data Extracts

Even the processed data extracts in `output/extract/` (2022 manager values, 2015 manager changes, connected component managers) are marked **confidential** and excluded from the repository via `.gitignore`. They contain firm-level manager skill estimates that retain sensitive characteristics of the underlying proprietary data.
