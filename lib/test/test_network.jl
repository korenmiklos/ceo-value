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

# --- Helper functions --- #

function find_bipartite_path_firms(manager1::Int, manager2::Int, bipartite::BipartiteGraph)::Vector{Int}
    """Find shortest path between two managers in bipartite graph and return connecting firms"""
    
    # Create bipartite graph representation
    # Sources are firms, targets are managers
    firms = unique(bipartite.sources)
    managers = unique(bipartite.targets)
    
    # Create adjacency lists
    firm_to_managers = Dict{Int, Set{Int}}()
    manager_to_firms = Dict{Int, Set{Int}}()
    
    for (firm, manager) in zip(bipartite.sources, bipartite.targets)
        if !haskey(firm_to_managers, firm)
            firm_to_managers[firm] = Set{Int}()
        end
        if !haskey(manager_to_firms, manager)
            manager_to_firms[manager] = Set{Int}()
        end
        push!(firm_to_managers[firm], manager)
        push!(manager_to_firms[manager], firm)
    end
    
    # Check if both managers exist
    if !haskey(manager_to_firms, manager1) || !haskey(manager_to_firms, manager2)
        return Int[]
    end
    
    # BFS in bipartite graph (alternating between managers and firms)
    queue = [(manager1, Int[], true)]  # (current_node, path_firms, is_manager)
    visited_managers = Set{Int}([manager1])  
    visited_firms = Set{Int}()
    
    while !isempty(queue)
        current, path_firms, is_manager = popfirst!(queue)
        
        if is_manager && current == manager2 && !isempty(path_firms)
            return path_firms
        end
        
        if is_manager
            # From manager, go to connected firms
            if haskey(manager_to_firms, current)
                for firm in manager_to_firms[current]
                    if firm ∉ visited_firms
                        push!(visited_firms, firm)
                        new_path = copy(path_firms)
                        push!(new_path, firm)
                        push!(queue, (firm, new_path, false))
                    end
                end
            end
        else
            # From firm, go to connected managers  
            if haskey(firm_to_managers, current)
                for manager in firm_to_managers[current]
                    if manager ∉ visited_managers
                        push!(visited_managers, manager)
                        push!(queue, (manager, path_firms, true))
                    end
                end
            end
        end
    end
    
    return Int[]  # No path found
end

function find_bipartite_path_firms_fast(manager1::Int, manager2::Int, firm_to_managers::Dict{Int, Set{Int}}, manager_to_firms::Dict{Int, Set{Int}})::Vector{Int}
    """Fast version using prebuilt adjacency lists"""
    
    # Check if both managers exist
    if !haskey(manager_to_firms, manager1) || !haskey(manager_to_firms, manager2)
        return Int[]
    end
    
    # BFS in bipartite graph (alternating between managers and firms)
    queue = [(manager1, Int[], true)]  # (current_node, path_firms, is_manager)
    visited_managers = Set{Int}([manager1])  
    visited_firms = Set{Int}()
    
    while !isempty(queue)
        current, path_firms, is_manager = popfirst!(queue)
        
        if is_manager && current == manager2 && !isempty(path_firms)
            return path_firms
        end
        
        if is_manager
            # From manager, go to connected firms
            if haskey(manager_to_firms, current)
                for firm in manager_to_firms[current]
                    if firm ∉ visited_firms
                        push!(visited_firms, firm)
                        new_path = copy(path_firms)
                        push!(new_path, firm)
                        push!(queue, (firm, new_path, false))
                    end
                end
            end
        else
            # From firm, go to connected managers  
            if haskey(firm_to_managers, current)
                for manager in firm_to_managers[current]
                    if manager ∉ visited_managers
                        push!(visited_managers, manager)
                        push!(queue, (manager, path_firms, true))
                    end
                end
            end
        end
    end
    
    return Int[]  # No path found
end

# --- Test Functions --- #

function test_connectivity(bipartite::BipartiteGraph, managers::Vector{Int}, K1::Int, seed::Int=12345)
    """Test K1 random pairs for connectivity using projected graph for speed"""
    Random.seed!(seed)
    
    # Use projected graph for fast connectivity testing
    println("Projecting bipartite graph for connectivity testing...")
    graph = project_bipartite_graph(bipartite)
    
    # Filter managers to those in the projected graph
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
        
        # Convert to graph indices and check connectivity
        idx1 = graph.node_idx[manager1]
        idx2 = graph.node_idx[manager2]
        
        if has_path(G, idx1, idx2)
            connected_count += 1
        else
            println("WARNING: No path found between managers $manager1 and $manager2")
        end
    end
    
    println("Connectivity test: $connected_count/$K1 pairs are connected")
end

function test_paths(bipartite::BipartiteGraph, managers::Vector{Int}, K2::Int, output_path::String, seed::Int=12345)
    """Test K2 random pairs and write paths to CSV"""
    Random.seed!(seed)
    
    # Build adjacency lists once for efficiency
    println("Building bipartite adjacency lists...")
    firm_to_managers = Dict{Int, Set{Int}}()
    manager_to_firms = Dict{Int, Set{Int}}()
    
    for (firm, manager) in zip(bipartite.sources, bipartite.targets)
        if !haskey(firm_to_managers, firm)
            firm_to_managers[firm] = Set{Int}()
        end
        if !haskey(manager_to_firms, manager)
            manager_to_firms[manager] = Set{Int}()
        end
        push!(firm_to_managers[firm], manager)
        push!(manager_to_firms[manager], firm)
    end
    
    # Filter managers to those that exist in bipartite graph
    valid_managers = filter(m -> haskey(manager_to_firms, m), managers)
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
        hop=Int[],
        firm=Union{Int,Missing}[]
    )
    
    for i in 1:K2
        # Use pairs from sampled indices
        manager1 = valid_managers[indices[2*i-1]]
        manager2 = valid_managers[indices[2*i]]
        
        # Find firm path in bipartite graph using prebuilt adjacency lists
        path_firms = find_bipartite_path_firms_fast(manager1, manager2, firm_to_managers, manager_to_firms)
        
        if !isempty(path_firms)
            println("Path from manager $manager1 to $manager2: $(length(path_firms)) firm hops")
            for (hop_idx, firm) in enumerate(path_firms)
                push!(results, (manager1, manager2, hop_idx, firm))
            end
        else
            println("WARNING: No bipartite path found between managers $manager1 and $manager2")
            # Still record the pair with missing firm data
            push!(results, (manager1, manager2, 1, missing))
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
    
    # Run tests on bipartite graph
    println("\n=== Test 1: Connectivity ===")
    test_connectivity(bipartite, managers, K1)
    
    println("\n=== Test 2: Path Details ===")
    test_paths(bipartite, managers, K2, "output/test/test_paths.csv")
    
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