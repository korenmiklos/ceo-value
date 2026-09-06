---
type: concept
title: Connected Component Network Analysis
description: Documents the bipartite firm-manager graph projection to manager-manager co-employment network, connected component detection, edge leverage computation, and why connected components are essential for manager fixed effect identification.
tags: [connected-components, network-analysis, bipartite-graph, manager-FE, identification]
verified:
  - by: openwiki/0.5.0
    at: 2026-09-06T17:56:56.777Z
sources:
  - id: openwiki-source-e6021cf24f8410c40aaf6ee1
    resource: repo://lib/create/connected_component.jl
  - id: openwiki-source-93335dee3bc8c938e1de8d74
    resource: repo://lib/create/edgelist.do
  - id: openwiki-source-0f02924f1a872fc0ce9e8336
    resource: repo://lib/create/leverage.jl
  - id: openwiki-source-f0ae5c512fbda36029c85f72
    resource: repo://lib/create/network-sample.do
  - id: openwiki-source-6c17ee820f3a743f1061bc3c
    resource: repo://lib/estimate/manager_value.do
  - id: openwiki-source-b521fd771647706983d15b22
    resource: repo://lib/test/test_network.jl
  - id: openwiki-source-012f2c78e3b1446dfc35803f
    resource: repo://Makefile
generated: { by: "openwiki/0.5.0", at: "2026-09-06T17:56:56.777Z" }
---

# Connected Component Network Analysis

## Overview

The CEO Value Research Project constructs a manager-manager co-employment network from the underlying bipartite firm-manager relationship to support identification of manager fixed effects in a two-way AKM-style regression. Because manager effects are only identified up to a constant within each connected component of the network, isolating components — especially the giant component — is a prerequisite for meaningful across-manager skill comparisons. Edge leverage scores are then computed to assess the influence of each firm-manager observation within the network.

This analysis spans three scripts and two intermediate data artifacts:

| Stage | Script | Output | Purpose |
|-------|--------|--------|---------|
| Edgelist extraction | [`lib/create/edgelist.do`](repo://lib/create/edgelist.do) | `temp/edgelist.csv` | Extract firm-person pairs for firms in the analysis sample |
| Component detection | [`lib/create/connected_component.jl`](repo://lib/create/connected_component.jl) | `temp/large_component_managers.csv` | Find managers in connected components of size >= 30 |
| Leverage computation | [`lib/create/leverage.jl`](repo://lib/create/leverage.jl) | `temp/edgelist_leverage.csv` | Compute edge leverage scores in the giant component |
| Sample integration | [`lib/create/network-sample.do`](repo://lib/create/network-sample.do) | (merged into analysis sample) | Merge component IDs into the estimation dataset |

---

## 1. Edgelist Extraction (`lib/create/edgelist.do`)

**Input:** `temp/full-analysis-sample.dta`, `temp/intervals.dta`  
**Output:** `temp/edgelist.csv`

This Stata script prepares the bipartite firm-manager relationship data:

1. Load the analysis sample, extract unique `frame_id_numeric` firm IDs, and save to a temporary file.
2. Load the cleaned CEO tenure intervals (`temp/intervals.dta`), keep unique `(frame_id_numeric, person_id)` pairs.
3. Merge to restrict to firms present in the analysis sample.
4. Export the resulting two-column CSV (`frame_id_numeric, person_id`).

The output `temp/edgelist.csv` is a bipartite edge list: each row represents a firm-manager employment relationship. The Makefile target is:

```makefile
temp/edgelist.csv: lib/create/edgelist.do temp/full-analysis-sample.dta
	$(STATA) $<
```

---

## 2. Bipartite Graph Projection and Connected Components (`lib/create/connected_component.jl`)

**Input:** `temp/edgelist.csv`  
**Output:** `temp/large_component_managers.csv`

### Architecture

The Julia script defines three core immutable types:

- **`BipartiteGraph`**: Holds parallel `sources` (firm IDs) and `targets` (manager IDs) vectors. Constructed from the edgelist CSV via `read_edgelist()`.
- **`ProjectedGraph`**: Stores a sparse adjacency matrix (`SparseMatrixCSC{Int, Int}`) and a dictionary mapping original manager IDs to matrix indices.

### Projection Algorithm

The projection from bipartite firm-manager graph to manager-manager network proceeds via the co-employment (or "shared-firm") matrix:

1. Build incidence matrix **B** of size `(n_firms x n_managers)`, where `B[f, m] = 1` if manager m works at firm f, using sparse matrix construction from the edgelist.
2. Compute **P = B' * B**, yielding a symmetric `(n_managers x n_managers)` matrix where `P[m1, m2]` counts the number of firms shared by managers `m1` and `m2`.
3. Remove self-loops: `P = P - diag(diag(P))`.

```julia
function project_bipartite_graph(bipartite::BipartiteGraph)::ProjectedGraph
    sources, targets = bipartite.sources, bipartite.targets
    uniq_sources = unique(sources)
    uniq_targets = unique(targets)
    source_idx = Dict(s => i for (i, s) in enumerate(uniq_sources))
    target_idx = Dict(t => i for (i, t) in enumerate(uniq_targets))

    rows = [source_idx[s] for s in sources]
    cols = [target_idx[t] for t in targets]
    B = sparse(rows, cols, ones(Bool, length(rows)), length(uniq_sources), length(uniq_targets))

    P = B' * B
    P = dropzeros!(P - spdiagm(0 => diag(P)))

    return ProjectedGraph(P, target_idx)
end
```

### Connected Component Detection

From the projected graph adjacency matrix, a `SimpleGraph` is constructed and `connected_components()` from the Graphs.jl library identifies all components:

```julia
G = SimpleGraph(graph.adjacency)
components = connected_components(G)
```

Components are then filtered by a minimum size threshold (`COMPONENT_SIZE_CUTOFF = 30`), sorted descending by size, and assigned sequential component IDs (1 = giant component, 2 = second largest, etc.). The `large_connected_components()` function returns three parallel vectors: `person_ids` (original manager IDs), `component_ids` (1-indexed by descending size), and `component_sizes`.

### Output Format

The results are written to `temp/large_component_managers.csv` with columns:

| Column | Description |
|--------|-------------|
| `person_id` | Original manager identifier |
| `component_id` | Component rank (1 = largest) |
| `component_size` | Number of managers in this component |

### Makefile Target

```makefile
temp/large_component_managers.csv: lib/create/connected_component.jl temp/edgelist.csv
	$(JULIA) $<
```

---

## 3. Edge Leverage Computation (`lib/create/leverage.jl`)

**Input:** `temp/edgelist.csv`  
**Output:** `temp/edgelist_leverage.csv`

### Purpose

Leverage scores measure how influential each firm-manager observation is in the network structure. In the context of the bipartite graph, high-leverage edges are those whose removal would substantially alter the network's spectral or geometric properties. These scores support robustness analysis and help identify influential observations in the manager value estimation.

### Method

1. Build a bipartite `SimpleGraph` where firm nodes and manager nodes are combined into a single graph (firms occupy indices 1..n_firms, managers occupy indices n_firms+1 .. n_firms+n_managers).
2. Extract connected components, select a specific component (default: component rank 1, the giant component) via the `COMPONENT_RANK` environment variable.
3. Construct the induced subgraph for the selected component.
4. Compute edge leverage scores using the `LeaveOut.jl` package, which implements the leave-one-out regression diagnostics for graph edges:
   ```julia
   d = Design(g_sub)
   p = prepare(d; verbose=true)
   h = p.h
   ```
5. Map leverage scores back to the original edgelist edges by matching firm and manager node indices.

The `COMPONENT_RANK` environment variable allows targeting any component (not just the giant one), enabling leverage analysis on second-largest or smaller components for robustness checks.

### Output

`temp/edgelist_leverage.csv` extends the original edgelist with a `leverage` column. Edges not in the selected component receive `missing` leverage values.

### Makefile Target

```makefile
temp/edgelist_leverage.csv: lib/create/leverage.jl temp/edgelist.csv
	$(JULIA) $<
```

---

## 4. Sample Integration (`lib/create/network-sample.do`)

**Input:** `temp/large_component_managers.csv` merged into the estimation sample  
**Output:** Component indicator variables added to the working dataset

This Stata do-file is included by [`lib/estimate/manager_value.do`](repo://lib/estimate/manager_value.do) at line 27:

```stata
do "lib/create/network-sample.do"
```

It performs three operations:

1. **Import** the component membership CSV and save as a temporary Stata file.
2. **Merge** component IDs onto the analysis sample by `person_id`. Managers not found in any large component receive `component_id = 0` and `component_size = 0`.
3. **Define indicator variables** reused across all tables and regressions:
   - `giant_component` = 1 if the manager belongs to the largest connected component (component_id == 1).
   - `connected_components` = 1 if the manager belongs to any component with size >= 30.

```stata
generate byte giant_component = (component_id == 1)
generate byte connected_components = (component_size >= 30)
```

---

## 5. Why Connected Components Matter for FE Identification

### The Identification Problem

In a two-way fixed effects model of the form:

```
Y_{fmt} = alpha_f + theta_m + epsilon_{fmt}
```

where `alpha_f` is a firm fixed effect and `theta_m` is a manager fixed effect, the parameters are identified only up to a constant within each **connected component** of the bipartite graph. This is the standard result from the Abowd-Kramarz-Margolis (AKM) literature:

- Two managers are comparable (their `theta_m` values have a well-defined relative ordering) if and only if there exists a path between them in the manager-manager co-employment network.
- Managers in different connected components have no shared-firm chain linking them, so their fixed effects can be shifted by arbitrary constants without changing the model fit.

### Application in the Project

The estimation in `manager_value.do` exploits this in two steps:

1. **Within-firm skill**: Managers are first compared within the same firm relative to the first observed CEO. This step does not require connected components.
2. **Between-firm skill**: `reghdfe` with absorb(frame_id_numeric person_id) estimates the full two-way FE model. The resulting manager effects are then normalized to have mean zero within the giant component (`giant_component == 1`):
   ```stata
   reghdfe `fixed_effect', absorb(firm_fixed_effect=frame_id_numeric manager_skill=person_id) keepsingletons
   summarize manager_skill if giant_component == 1, detail
   replace manager_skill = manager_skill - r(mean)
   ```

The `keepsingletons` option ensures singleton observations (managers observed at only one firm, or firms with only one manager) are retained — these contribute to within-firm skill but not to between-firm linkages.

### Component Size Threshold

The `COMPONENT_SIZE_CUTOFF = 30` threshold filters out tiny components that are unlikely to support meaningful between-manager comparisons. The giant component typically contains the vast majority of managers and is the primary vehicle for cross-firm manager skill estimation.

---

## 6. Network Tests (`lib/test/test_network.jl`)

The project includes a dedicated test script that validates connectivity properties of the bipartite network:

- **Connectivity test** (`test_connectivity`): Samples K1 (default 1000) random manager pairs from the giant component and verifies they are connected in the projected graph. Reports the fraction of connected pairs.
- **Path discovery** (`test_paths`): Samples K2 (default 10) random manager pairs and finds the shortest firm-level path connecting them via BFS in the bipartite graph. Writes path details (start manager, end manager, hop index, firm ID) to CSV for manual inspection.

These tests are run via command line:
```julia
julia lib/test/test_network.jl 1000 10
```

The test script uses the bipartite BFS path finder `find_bipartite_path_firms_fast()` which walks from manager to connected firms (alternating levels), enabling inspection of the actual firm-level connections that link any two managers.

---

## Dependency Relationships

```
temp/intervals.dta ──┐
                     ├──> temp/edgelist.csv ──> temp/large_component_managers.csv
temp/full-analysis-  │                          │
sample.dta ──────────┘                          │
                                                ├──> [merged into manager_value.dta via network-sample.do]
temp/edgelist.csv ───────────────────────────> temp/edgelist_leverage.csv
```

The connected component analysis sits between the analysis sample construction and the manager value estimation, providing the graph-theoretic infrastructure that justifies cross-firm manager skill comparisons.
