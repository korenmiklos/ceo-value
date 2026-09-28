# Dataset – Core Inputs

## Raw balance sheet panel
- Path: `input/merleg-LTS-2023/balance/balance_sheet_80_22.dta`
- Subset years 1992‑2023, drop non‑original IDs, keep variables: `frame_id_numeric`, `sales`, `employment`, `tangible_assets`, `materials`, `personnel_expenses`, `assets`.
- Cleaning: compute missing‑flag, keep rows with at least one year of full observability per firm `first_clean_year`.
## CEO panel definition
- Path: `input/manager-db-ceo-panel/ceo-panel.dta`
- Parsed into yearly observations via `lib/create/ceo-panel.do`.

---

Created files:
- `temp/balance.dta`
- `temp/ceo-panel.dta`
