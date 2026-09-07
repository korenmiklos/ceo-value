---
type: Reference
title: Edge leverage Julia code
description: Evidence excerpt from lib/create/leverage.jl, leave-one-out leverage computation.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
---

# Edge leverage Julia code

## Source

- Path: `lib/create/leverage.jl`
- SHA-256: `c4897b73789990417acefb01a0699e51b5713a68e820ba38496647c426abc8a1`
- Inspected: exact source slices below

## Excerpts

### Lines 26-52
```text
# Find connected components, select by COMPONENT_RANK env var (1=giant, 2=second largest, etc.)
comps = connected_components(g)
comp_order = sortperm(length.(comps), rev=true)
comp_rank = parse(Int, get(ENV, "COMPONENT_RANK", "1"))
comp_rank <= length(comps) || error("COMPONENT_RANK=$comp_rank but only $(length(comps)) components exist")
chosen = comps[comp_order[comp_rank]]
println("Component rank $comp_rank: $(length(chosen)) nodes (largest: $(length(comps[comp_order[1]])) nodes, $(length(comps)) components total)")
giant_set = Set(chosen)

# Build subgraph for selected component
node_subset = sort(collect(giant_set))
node_to_sub = Dict(v => i for (i, v) in enumerate(node_subset))
g_sub = SimpleGraph(length(node_subset))
for e in edges(g)
    u, v = src(e), dst(e)
    if u in giant_set && v in giant_set
        add_edge!(g_sub, node_to_sub[u], node_to_sub[v])
    end
end
println("Subgraph: $(nv(g_sub)) nodes, $(ne(g_sub)) edges")

# Compute leverages via LeaveOut.jl
d = Design(g_sub)
println("Computing leverages...")
p = prepare(d; verbose=true)
h = p.h
println("Leverages computed: $(length(h)) edges, mean=$(round(mean(h), digits=4))")
```

### Lines 79-81
```text
# Write output
CSV.write("temp/edgelist_leverage.csv", df)
println("Wrote temp/edgelist_leverage.csv with leverage column")
```

## Notes

- Uses `LeaveOut.jl` to compute leverage of each firm-manager edge in the selected connected component (rank 1 = giant, 2 = second largest, etc.; env var `COMPONENT_RANK`].
- `temp/edgelist_leverage.csv` was produced in this checkout (present in temp listing), but the main Makefile rule depends on `temp/edgelist.csv` (present; observed edgelist.log run).
