---
type: "Reference"
title: "Julia Graph Analysis Subsystem"
openwiki_generated: true
verified:
  - by: openwiki/0.5.0
    at: 2026-09-06T17:56:56.777Z
sources:
  - id: openwiki-source-e6021cf24f8410c40aaf6ee1
    resource: repo://lib/create/connected_component.jl
  - id: openwiki-source-0f02924f1a872fc0ce9e8336
    resource: repo://lib/create/leverage.jl
  - id: openwiki-source-f0ae5c512fbda36029c85f72
    resource: repo://lib/create/network-sample.do
  - id: openwiki-source-b521fd771647706983d15b22
    resource: repo://lib/test/test_network.jl
  - id: openwiki-source-012f2c78e3b1446dfc35803f
    resource: repo://Makefile
  - id: openwiki-source-5a45efb32d540f177b4fa9fc
    resource: repo://Manifest.toml
  - id: openwiki-source-0f3c6735bbc40f4951ad2578
    resource: repo://Project.toml
generated: { by: "openwiki/0.5.0", at: "2026-09-06T17:56:56.777Z" }
---


# Julia Graph Analysis Subsystem

## Overview

The Julia graph analysis subsystem transforms a bipartite firm-manager edge list into a manager-manager co-employment network, detects connected components for manager fixed-effect identification, computes edge leverage scores, and provides a test harness for path-finding verification. It comprises three Julia scripts and a shared Julia environment defined by `Project.toml` and `Manifest.toml`.

| Script | Purpose | Input | Output |
|--------|---------|-------|--------|
| `lib/create/connected_component.jl` | Bipartite projection, connected component detection, component filtering | `temp/edgelist.csv` | `temp/large_component_managers.csv` |
| `lib/create/leverage.jl` | Edge leverage computation via LeaveOut.jl inside a selected component | `temp/edgelist.csv` | `temp/edgelist_leverage.csv` |
| `lib/test/test_network.jl` | Path-finding and connectivity test harness | `temp/edgelist.csv`, `temp/large_component_managers.csv` | `output/test/test_paths.csv` |

## Julia Environment

The project runs on **Julia 1.10.4** (per `Manifest.toml`). The `Project.toml` declares these dependencies:

| Package | UUID | Role |
|---------|------|------|
| `CSV` | `336ed68f-0bac-5ca0-87d4-7b16caf5d00b` | Read and write CSV edge lists and component output |
| `DataFrames` | `a93c6f00-e57d-5684-b7b6-d8193f3e46c0` | Tabular data manipulation for component and path data |
| `Graphs` | `86223c79-3864-5bf0-83f7-82e725a168b6` | Graph data structures: `SimpleGraph`, `connected_components`, `has_path` |
| `SparseArrays` | `2f01184e-e22b-5df5-ae63-d93ebab69eaf` | Sparse incidence and adjacency matrix construction |
| `LeaveOut` | `b3d5e7a1-4c62-4f8a-9e11-2a7c9f0d6e34` | Edge leverage computation (GitHub: `codedthinking/LeaveOut.jl`) |
| `Random` | `9a3f8284-a2c9-5f02-9a11-845980a1fd5c` | Seeded random sampling for test harness |

Scripts are invoked by the Makefile with the project-local Julia environment:

```makefile
JULIA := julia --project=.

temp/large_component_managers.csv: lib/create/connected_component.jl temp/edgelist.csv
	$(JULIA) $<

temp/edgelist_leverage.csv: lib/create/leverage.jl temp/edgelist.csv
	$(JULIA) $<
```

## Data Structures

### `BipartiteGraph` (defined in `connected_component.jl`)

A lightweight container holding two parallel vectors representing the bipartite firm-manager edge list:

```julia
struct BipartiteGraph
    sources::Vector{Int}    # firm IDs (frame_id_numeric)
    targets::Vector{Int}    # manager IDs (person_id)
end
```

A convenience constructor accepts `Vector{Tuple{Int, Int}}`. The `read_edgelist()` function parses `temp/edgelist.csv` (two-column CSV with `frame_id_numeric` and `person_id`) and drops rows with missing `person_id`.

### `ProjectedGraph` (defined in `connected_component.jl`)

The result of projecting the bipartite graph onto a manager-manager network:

```julia
struct ProjectedGraph
    adjacency::SparseMatrixCSC{Int, Int}  # manager × manager co-employment matrix
    node_idx::Dict{Int, Int}              # original manager ID → matrix column index
end
```

The sparse adjacency matrix `P` is symmetric, with `P[m1, m2]` counting the number of firms shared by managers `m1` and `m2`. Self-loops are removed.

## Core Pipeline

### Stage 1: Connected Component Detection (`lib/create/connected_component.jl`)

This script performs the bipartite-to-manager projection and identifies large connected components.

**Algorithm — Bipartite Projection:**

1. Read the firm-manager edge list into a `BipartiteGraph`.
2. Map unique firm IDs and manager IDs to contiguous integer indices.
3. Build the sparse incidence matrix **B** of size `(n_firms × n_managers)` where `B[f, m] = 1` if manager `m` works at firm `f`:

   ```julia
   B = sparse(rows, cols, ones(Bool, length(rows)), length(uniq_sources), length(uniq_targets))
   ```

4. Compute the co-employment (shared-firm) matrix **P = Bᵀ × B** — a symmetric sparse matrix where each entry `P[m1, m2]` counts the number of firms managers `m1` and `m2` have jointly worked at.
5. Remove self-loops: `P = dropzeros!(P - spdiagm(0 => diag(P)))`.

The resulting `ProjectedGraph` is a weighted manager-manager network. Any two managers with `P[m1, m2] > 0` are directly connected via at least one shared firm.

**Algorithm — Connected Components:**

1. Construct a `SimpleGraph` from the projected adjacency matrix (Graphs.jl treats any non-zero entry as an edge).
2. Call `connected_components(G)` to obtain all connected components.
3. Filter by a minimum size threshold (`COMPONENT_SIZE_CUTOFF = 30`), sorting in descending order by component size.
4. Assign sequential component IDs (1 = largest/giant component, 2 = second largest, etc.).
5. Write output to `temp/large_component_managers.csv` with columns:

   | Column | Description |
   |--------|-------------|
   | `person_id` | Original manager identifier |
   | `component_id` | Component rank (1 = largest) |
   | `component_size` | Total managers in this component |

The component membership is later merged into the Stata estimation sample by `lib/create/network-sample.do`, which defines indicator variables `giant_component` (`component_id == 1`) and `connected_components` (`component_size >= 30`).

### Stage 2: Edge Leverage Computation (`lib/create/leverage.jl`)

**Purpose:** Compute leverage scores for each firm-manager edge in a selected component of the bipartite graph. Leverage measures how influential each observation is in the network structure — edges whose removal would substantially alter the graph's spectral or geometric properties receive high leverage scores.

**Algorithm:**

1. **Build a unified bipartite graph.** Firm nodes occupy indices `1 … n_firms` and manager nodes occupy indices `n_firms+1 … n_firms+n_managers` within a single `SimpleGraph`. The graph has `n_firms + n_managers` nodes total.
2. **Select a component** via the `COMPONENT_RANK` environment variable (default `"1"`, the giant component). Components are sorted by size in descending order; `COMPONENT_RANK=2` selects the second-largest component, etc. Raises an error if the requested rank exceeds the number of existing components.
3. **Build the induced subgraph** for the selected component, mapping original node IDs to a contiguous index range.
4. **Compute leverages** using the `LeaveOut.jl` package:

   ```julia
   d = Design(g_sub)
   p = prepare(d; verbose=true)
   h = p.h
   ```

   `LeaveOut.jl` implements leave-one-out regression diagnostics for graph edges. The `Design` object wraps the graph adjacency, and `prepare()` computes the hat values (leverage scores) for every edge. The resulting vector `h` has one entry per edge, in the canonical edge order `d.edges`.

5. **Map leverages back** to the original bipartite edge list by matching firm and manager node indices. Edges not in the selected component receive `missing` leverage values.

**Output:** `temp/edgelist_leverage.csv` — identical to the input edge list but with an added `leverage` column (`Float64` or `missing`).

**Makefile target:**

```makefile
temp/edgelist_leverage.csv: lib/create/leverage.jl temp/edgelist.csv
	$(JULIA) $<
```

## Test Harness (`lib/test/test_network.jl`)

The test harness validates the graph analysis by checking connectivity between managers and computing explicit firm-level paths. It is invoked manually (not part of the main Makefile pipeline) and accepts optional command-line arguments `K1` (connectivity pairs, default 1000) and `K2` (path-writing pairs, default 10).

**Architecture:**

- Imports all data structures and functions from `connected_component.jl` via `include("../create/connected_component.jl")`.
- Reads the edgelist and the precomputed component manager list.

**Test 1 — Connectivity (`test_connectivity`):**

1. Projects the bipartite graph to a manager-manager network (reusing `project_bipartite_graph`).
2. Samples `2 × K1` managers from the giant component without replacement, forming `K1` random pairs.
3. For each pair, checks connectivity using `has_path(G, idx1, idx2)` on the projected `SimpleGraph`.
4. Reports the fraction of connected pairs.

**Test 2 — Path Details (`test_paths`):**

1. Builds adjacency dictionaries `firm_to_managers` and `manager_to_firms` from the bipartite edge list.
2. Samples `K2` random manager pairs from the giant component.
3. For each pair, runs a **bidirectional BFS** in the bipartite graph (alternating between manager and firm nodes) via `find_bipartite_path_firms_fast()` to find the shortest path of firms connecting the two managers.
4. Records each hop (firm ID) along the path.
5. Writes results to `output/test/test_paths.csv` with columns `start_manager`, `end_manager`, `hop`, `firm`.

Two path-finding implementations exist:
- `find_bipartite_path_firms()` — generic version that builds adjacency dicts on every call.
- `find_bipartite_path_firms_fast()` — optimized version accepting pre-built adjacency dicts; used by `test_paths()`.

## Connection to Manager FE Identification

The connected component analysis directly supports the AKM-style two-way fixed effects model:

```
Y_{fmt} = α_f + θ_m + ε_{fmt}
```

where `α_f` is a firm fixed effect and `θ_m` is a manager fixed effect. Parameters are identified only up to a constant within each connected component of the manager-manager co-employment network. Managers in different components have no shared-firm chain linking them, so their fixed effects can be shifted by arbitrary constants without changing model fit.

The pipeline thus ensures that manager fixed effects are comparable at least within the giant component — the largest set of managers connected through shared firms. The leverage scores identify influential firm-manager edges whose removal could change component structure or manager rankings.

## Invariants and Failure Modes

- **Missing manager IDs**: `read_edgelist()` drops rows with missing `person_id`. If all rows are dropped, the graph will be empty; `connected_components()` returns an empty list, and `large_connected_components()` writes an empty CSV.
- **Singleton components**: Components smaller than `COMPONENT_SIZE_CUTOFF` (30) are excluded from the output. If no component meets the threshold, the output CSV is empty, and the Stata merge assigns `component_id=0` to all managers.
- **COMPONENT_RANK out of bounds**: `leverage.jl` raises an error if `COMPONENT_RANK` exceeds the number of existing components.
- **Synthetic data generator**: `connected_component.jl` includes a `generate_edgelist(n_left, n_right, edges_per_right)` function for testing, which produces a random bipartite graph with uniform edge assignment.

## Key Configuration

| Parameter | Location | Default | Description |
|-----------|----------|---------|-------------|
| `COMPONENT_SIZE_CUTOFF` | `connected_component.jl` | `30` | Minimum component size for output inclusion |
| `COMPONENT_RANK` | Environment variable (`leverage.jl`) | `"1"` | Component rank to analyze (1 = giant component) |
| `K1`, `K2` | Command-line args (`test_network.jl`) | `1000`, `10` | Number of test pairs for connectivity and path tests |
