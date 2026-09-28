# Sample Restrictions – Filtering

## Core constraints enforced in `lib/create/analysis-sample.do`
1. **Firm‑size**: retain only years where `employment >= 2`.
2. **Spell length**: keep spells with duration `T >= 1` year (computed in `ceo-panel.do`).
3. **Connected component**: only observations whose `frame_id_numeric` appear in `temp/large_component_managers.csv` (produced from `connected_component.jl`).

All filters are applied after the yearly panel expansion and before the `temp/%-analysis-sample.dta` output is written.
