using CSV, DataFrames
using SparseArrays, Graphs, Random
using LinearAlgebra

# Import existing data structures and functions
include("../create/connected_component.jl")

# --- Additional I/O for tests --- #

function read_component_managers(path::String)::Vector{Int}
    df = CSV.read(path, DataFrame; header=true)
    # Filter to largest component (component_id == 1)
    largest_component = filter(row -> row.component_id == 1, df)
    return Vector{Int}(largest_component.person_id)
end

# --- Helper function to add reverse mapping --- #

function add_idx_to_id_mapping(graph::ProjectedGraph)
    idx_to_id = Dict(v => k for (k, v) in graph.node_idx)
    return graph.adjacency, graph.node_idx, idx_to_id
end

function get_manager_firms(manager::Int, bipartite::BipartiteGraph)::Set{Int}
    """Get all firms connected to a manager"""
    firms = Set{Int}()
    for (i, target) in enumerate(bipartite.targets)
        if target == manager
            push!(firms, bipartite.sources[i])
        end
    end
    return firms
end

function find_firm_path_hops(manager1::Int, manager2::Int, bipartite::BipartiteGraph, adjacency::SparseMatrixCSC{Int, Int}, node_idx::Dict{Int, Int}, idx_to_id::Dict{Int, Int})::Vector{Tuple{Int, Int}}
    """Find the shortest path between two managers and return firm-to-firm hops"""
    
    # Convert to graph indices
    if !haskey(node_idx, manager1) || !haskey(node_idx, manager2)
        return Tuple{Int, Int}[]
    end
    
    idx1 = node_idx[manager1]
    idx2 = node_idx[manager2]
    
    # Find shortest path in the projected graph
    G = SimpleGraph(adjacency)
    
    # Use dijkstra to find shortest path
    dijk_result = dijkstra_shortest_paths(G, idx1)
    
    # Check if path exists
    if dijk_result.dists[idx2] == Inf
        return Tuple{Int, Int}[]
    end
    
    # Reconstruct path backwards from target to source
    path_indices = Int[]
    current = idx2
    while current != idx1
        pushfirst!(path_indices, current)
        current = dijk_result.parents[current]
    end
    pushfirst!(path_indices, idx1)
    
    # Convert indices back to manager IDs
    path_managers = [idx_to_id[idx] for idx in path_indices]
    
    # Convert manager path to firm-to-firm hops
    hops = Tuple{Int, Int}[]
    
    for i in 1:(length(path_managers) - 1)
        current_manager = path_managers[i]
        next_manager = path_managers[i + 1]
        
        # Find firms that connect these two managers
        current_firms = get_manager_firms(current_manager, bipartite)
        next_firms = get_manager_firms(next_manager, bipartite)
        
        # Find a shared firm (there must be at least one for them to be adjacent)
        shared_firms = intersect(current_firms, next_firms)
        if !isempty(shared_firms)
            shared_firm = first(shared_firms)
            push!(hops, (shared_firm, shared_firm))
        else
            # This shouldn't happen in a properly constructed graph, but handle it
            println("WARNING: No shared firm found between adjacent managers $current_manager and $next_manager")
            push!(hops, (-1, -1))  # Placeholder for missing connection
        end
    end
    
    return hops
end

# --- Test Functions --- #

function test_connectivity(bipartite::BipartiteGraph, graph::ProjectedGraph, managers::Vector{Int}, K1::Int, seed::Int=12345)
    """Test K1 random pairs for connectivity"""
    Random.seed!(seed)
    
    # Filter managers to those in the graph
    valid_managers = filter(m -> haskey(graph.node_idx, m), managers)
    println("Testing connectivity with $(length(valid_managers)) valid managers")
    
    if length(valid_managers) < 2 * K1
        println("ERROR: Not enough valid managers for connectivity test (need $(2*K1), have $(length(valid_managers)))")
        return
    end
    
    # Sample 2*K1 random indices without replacement
    indices = randperm(length(valid_managers))[1:2*K1]
    
    connected_count = 0
    G = SimpleGraph(graph.adjacency)
    
    for i in 1:K1
        # Use pairs from sampled indices
        manager1 = valid_managers[indices[2*i-1]]
        manager2 = valid_managers[indices[2*i]]
        
        # Convert to graph indices
        idx1 = graph.node_idx[manager1]
        idx2 = graph.node_idx[manager2]
        
        # Check if connected
        if has_path(G, idx1, idx2)
            connected_count += 1
        else
            println("WARNING: No path found between managers $manager1 and $manager2")
        end
    end
    
    println("Connectivity test: $connected_count/$K1 pairs are connected")
end

function test_paths(bipartite::BipartiteGraph, graph::ProjectedGraph, managers::Vector{Int}, K2::Int, output_path::String, seed::Int=12345)
    """Test K2 random pairs and write paths to CSV"""
    Random.seed!(seed)
    
    # Filter managers to those in the graph
    valid_managers = filter(m -> haskey(graph.node_idx, m), managers)
    println("Testing paths with $(length(valid_managers)) valid managers")
    
    if length(valid_managers) < 2 * K2
        println("ERROR: Not enough valid managers for path test (need $(2*K2), have $(length(valid_managers)))")
        return
    end
    
    # Sample 2*K2 random indices without replacement
    indices = randperm(length(valid_managers))[1:2*K2]
    
    results = DataFrame(
        start_manager=Int[],
        end_manager=Int[],
        firm1=Union{Int,Missing}[],
        firm2=Union{Int,Missing}[]
    )
    
    for i in 1:K2
        # Use pairs from sampled indices
        manager1 = valid_managers[indices[2*i-1]]
        manager2 = valid_managers[indices[2*i]]
        
        # Find firm path hops  
        adjacency, node_idx, idx_to_id = add_idx_to_id_mapping(graph)
        hops = find_firm_path_hops(manager1, manager2, bipartite, adjacency, node_idx, idx_to_id)
        
        if !isempty(hops)
            println("Path from manager $manager1 to $manager2: $(length(hops)) hops")
            for (hop_idx, (firm1, firm2)) in enumerate(hops)
                push!(results, (manager1, manager2, firm1, firm2))
            end
        else
            println("WARNING: No path found between managers $manager1 and $manager2")
            # Still record the pair with missing firm data
            push!(results, (manager1, manager2, missing, missing))
        end
    end
    
    CSV.write(output_path, results)
    println("Path test results written to $output_path")
end

# --- Main Analysis --- #

function main(K1::Int=1000, K2::Int=10)
    println("Starting network connectivity tests with K1=$K1, K2=$K2")
    
    # Read data
    println("Reading edgelist...")
    bipartite = read_edgelist("temp/edgelist.csv", "frame_id_numeric", "person_id")
    println("Read $(length(bipartite.sources)) edges")
    
    println("Reading largest component managers...")
    managers = read_component_managers("temp/large_component_managers.csv")
    println("Read $(length(managers)) managers in largest component")
    
    # Project to manager-manager network
    println("Projecting bipartite graph...")
    graph = project_bipartite_graph(bipartite)
    println("Projected graph has $(size(graph.adjacency, 1)) nodes")
    
    # Run tests
    println("\n=== Test 1: Connectivity ===")
    test_connectivity(bipartite, graph, managers, K1)
    
    println("\n=== Test 2: Path Details ===")
    test_paths(bipartite, graph, managers, K2, "output/test/test_paths.csv")
    
    println("\nNetwork tests completed!")
end

# Parse command line arguments
if length(ARGS) >= 2
    K1 = parse(Int, ARGS[1])
    K2 = parse(Int, ARGS[2])
    main(K1, K2)
else
    main()  # Use defaults
end