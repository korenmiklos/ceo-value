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

function read_edgelist(path::String, source_col::String, target_col::String)::BipartiteGraph
    df = CSV.read(path, DataFrame; header=true)
    return BipartiteGraph(Vector{Int}(df[!, source_col]), Vector{Int}(df[!, target_col]))
end

function write_edgelist_csv(path::String, sources::Vector{Int}, targets::Vector{Int})
    open(path, "w") do io
        for (s, t) in zip(sources, targets)
            println(io, "$s,$t")
        end
    end
end

function write_component_csv(path::String, person_ids::Vector{Int})
    df = DataFrame(person_id=person_ids)
    CSV.write(path, df)
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
    _, largest_idx = findmax(length, components)
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

# --- Main Analysis --- #

# Read firm-manager edgelist from Stata output
bipartite = read_edgelist("temp/edgelist.csv", "frame_id_numeric", "person_id")
println("Read ", length(bipartite.sources), " edges")

# Project to manager-manager network and find largest connected component
graph = project_bipartite_graph(bipartite)
largest_component_managers = largest_connected_component(graph)
println("Size of largest component: ", length(largest_component_managers))

# Write manager person_ids in largest component to CSV
write_component_csv("temp/largest_component_managers.csv", largest_component_managers)
