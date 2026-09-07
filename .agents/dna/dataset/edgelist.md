---
type: Dataset
title: Bipartite firm-manager edge list
description: Unique firm-person pairs from the analysis sample, the base object for the co-employment network and leverage computation.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
sources:
  - id: eg_code
    resource: ../references/code/edgelist_do.md
    locator: Lines  1-15
  - id: logs
    resource: ../references/logs.md
    locator: edgelist.log (observed run matched 1,058,307 firm-person pairs
relations:
  - predicate: derived_from
    target: ../dataset/analysis_sample.md
    basis: declared
    evidence: [eg_code]
  - predicate: used_by
    target: ../dataset/large_component_managers.md
    basis: inferred
  - predicate: used_by
    target: ../dataset/edgelist_leverage.md
    basis: declared
---

# Bipartite firm-manager edge list

## Construction

`lib/create/edgelist.do` takes the set of firms in the [analysis sample](../dataset/analysis_sample.md) and saves unique `frame_id_numeric`, `person_id` pairs to `temp/edgelist.csv`. The current script text reads `temp/full-analysis-sample.dta`; the logged run produced `temp/analysis-sample.dta` afore variation-named convention was introduced.



## Uses

- Feeds [connected_component.jl](../references/code/connected_component_jl.md) which builds the firm-person co-employment component graph.
- Feeds [leverage.jl](../references/code/leverage_jl.md) which computes manager-switching leverage measures.


[^eg_code]: Edge list construction code - see [edgelist.do](../references/code/edgelist_do.md)
[^logs]: Stata execution logs - see [logs](../references/logs.md)