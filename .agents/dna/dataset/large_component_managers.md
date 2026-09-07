---
type: Dataset
title: Large connected component managers
description: Managers in co-employment components of at least 30 persons, identified by Julia graph analysis, used for manager-skill normalization and model-6 restriction.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
sources:
  - id: cc_code
    resource: ../references/code/connected_component_jl.md
    locator: Lines  109-121
  - id: ns_code
    resource: ../references/code/network_sample_do.md
    locator: Lines  1-19
relations:
  - predicate: derived_from
    target: ../dataset/edgelist.md
    basis: declared
    evidence: [cc_code]
  - predicate: used_by
    target: ../dataset/analysis_sample.md
    basis: inferred
    qualifiers: flags merged via network-sample.do
---

# Large connected component managers

## Construction

[connected_component.jl](../references/code/connected_component_jl.md) reads `temp/edgelist.csv`, builds the bipartite firm-person co-employment graph, and writes `temp/large_component_managers.csv` with `component_id` and `component_size` per person. The default minimum size is 1000 but the main call passes 30, so components with at least 30 members are listed.



## Flags

[network-sample.do](../references/code/network_sample_do.md) merges the component table onto panels and defines:

- `giant_component` if `component_id` equals 1.
- `connected_components` if `component_size` at least 30.
- `component_id` zero for managers outside listed components.



## Notes

- README states manager skill analysis identifies 189,108 managers in the large connected component, unverified in our logs.
- Revenue-function model 6 restricts to giant or connected components, per [revenue_function.do](../references/code/revenue_function_do.md)Ĉ



[^cc_code]: Connected component Julia code - see [connected_component.jl](../references/code/connected_component_jl.md)
[^ns_code]: Network sample helper - see [network_sample.do](../references/code/network_sample_do.md)