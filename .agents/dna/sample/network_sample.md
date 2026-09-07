---
type: Sample
title: Network sample
description: Managers in co-employment connected components of at least 30 persons, used for skill normalization and the revenue-function model 6 restriction.
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
  - predicate: selected_from
    target: ../dataset/large_component_managers.md
    basis: declared
    evidence: [cc_code, ns_code]
  - predicate: used_by
    target: ../result/revenue_function_estimation.md
    basis: inferred
---

# Network sample

## Definition

The set of managers whose firm-person co-employment component has at least 30 members, `connected_components` flag, plus the giant component flag. Produced by [connected_component.jl](../references/code/connected_component_jl.md) from the [edgelist](../dataset/edgelist.md) and merged onto panels by [network-sample.do](../references/code/network_sample_do.md).

## Uses

- Normalization of manager skill to giant-component mean in manager_value.do.
- Revenue-function model 6 restricts to giant or connected components.

[^cc_code]: [Connected component Julia code](../references/code/connected_component_jl.md).
[^ns_code]: [Network sample helper code](../references/code/network_sample_do.md).