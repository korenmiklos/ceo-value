using CSV, DataFrames
using SparseArrays, Graphs, Random
using LinearAlgebra

# --- Data Structures --- #

struct BipartiteGraph
    sources::Vector{Int}
    targets::Vector{Int}
end

BipartiteGraph(edges::Vector{Tuple{Int, Int}}) = BipartiteGraph([e[1] for e in edges], [e[2] for e in edges])

struct ProjectedGraph
    adjacency::SparseMatrixCSC{Int, Int}
    node_idx::Dict{Int, Int}  # maps original ID to index
end

# --- I/O --- #

function read_edgelist(path::String)::BipartiteGraph
    df = CSV.read(path, DataFrame; header=false, rename=["source", "target"])
    return BipartiteGraph(Vector{Int}(df.source), Vector{Int}(df.target))
end

function write_edgelist_csv(path::String, sources::Vector{Int}, targets::Vector{Int})
    open(path, "w") do io
        for (s, t) in zip(sources, targets)
            println(io, "$s,$t")
        end
    end
end

# --- Core Logic --- #

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
    P = dropzeros!(P - spdiagm(0 => diag(P)))  # remove self-loops

    return ProjectedGraph(P, target_idx)
end

function largest_connected_component(graph::ProjectedGraph)::Vector{Int}
    G = SimpleGraph(graph.adjacency)
    components = connected_components(G)
    println("Number of components: ", length(components))
    println("Component sizes: ", [length(c) for c in components])
    _, largest_idx = findmax(length, components)
    println("Largest component index: ", largest_idx)
    largest_component = components[largest_idx]
    idx_to_id = Dict(v => k for (k, v) in graph.node_idx)
    return [idx_to_id[i] for i in largest_component]
end

# --- Synthetic Data Generator --- #

function generate_edgelist(n_left::Int, n_right::Int, edges_per_right::Int)::BipartiteGraph
    sources = Int[]
    targets = Int[]
    for t in 1:n_right
        selected_sources = rand(1:n_left, edges_per_right)
        append!(sources, selected_sources)
        append!(targets, fill(t, edges_per_right))
    end
    return BipartiteGraph(sources, targets)
end

# --- Example Usage --- #

# Generate synthetic data
bipartite = generate_edgelist(500_000, 1_000_000, 3)
# write_edgelist_csv("test.csv", bipartite.sources, bipartite.targets)

# Read from CSV and compute largest component
# bipartite = read_edgelist("test.csv")
graph = project_bipartite_graph(bipartite)
largest = largest_connected_component(graph)
println("Size of largest component: ", length(largest))
