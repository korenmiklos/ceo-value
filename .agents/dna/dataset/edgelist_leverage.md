---type: Dataset
title: Leverage scores per firm-person edge
status: draft
description: "Numeric manager-switching leverage measures computed by Julia fromthe bipartite edge list, used as network-dependence controls, in the event study."
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
sources:
  - id: lev_code
    resource: ../references/code/leverage_jl.md
    locator: Lines   1-60
  - id: make_main
    resource: ../references/makefile_main.md
    locator: edgelist_leverage.csv rule dependency
relations:
  - predicate: derived_from
    target: ../dataset/edgelist.md
    basis: declared
    evidence: [lev_code]
  - predicate: used_by
    target: ../dataset/placebo_event_study_samples.md
    basis: inferred
    qualifiers: merged as leverage control variable
---

# Leverage scores per firm-person edge

## Construction

`lib/create/leverage.jl` reads `temp/edgelist.csv`, builds the bipartite firm-person co-employment graph, and computes per-edge leverage measures reflecting how much a manager's move changes the firm's network position, writing `temp/edgelist_leverage.csv`. Fields include edge identifiers and leverage scores per the [Julia code](../references/code/leverage_jl.md).



## Use

The root Makefile's `edgelist_leverage.csv` rule depends on `edgelist.csv` only, per [makefile_main](../references/makefile_main.md), wiring the measure into the event-study covariate set. Its role in the papers is as a network-dependence control in specification variants where treatment effects may differ by manager connectedness, inferred from the estimator code references.



[^lev_code]: Leverage Julia code - see [leverage.jl](../references/code/leverage_jl.md)
[^make_main]: Main Makefile - see [makefile_main](../references/makefile_main.md)