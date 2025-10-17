using CSV, DataFrames
using SparseArrays, Statistics, LinearAlgebra
using Logging
using Roots
using Graphs

struct WindowData
    window_id::Int
    years::Vector{Int}
    firm_ids::Vector{Int}
    manager_ids::Vector{Int}
    log_revenue::Vector{Float64}
end

struct MomentEstimates
    window_id::Int
    year_min::Int
    year_max::Int
    n_obs::Int
    n_firms::Int
    n_managers::Int
    V::Float64
    C_mm2::Float64
    C_ff2::Float64
    C_mm4::Float64
    C_ff4::Float64
    n_edges_mm2::Int
    n_edges_ff2::Int
    n_edges_mm4::Int
    n_edges_ff4::Int
end

struct ParameterEstimates
    window_id::Int
    year_min::Int
    year_max::Int
    σ_a::Float64
    σ_z::Float64
    ρ::Float64
    σ_ε::Float64
end

function read_window_data(path::String)::Vector{WindowData}
    df = CSV.read(path, DataFrame)
    
    windows = WindowData[]
    for window_id in sort(unique(df.window_id))
        window_df = df[df.window_id .== window_id, :]
        
        push!(windows, WindowData(
            window_id,
            Vector{Int}(window_df.year),
            Vector{Int}(window_df.frame_id_numeric),
            Vector{Int}(window_df.person_id),
            Vector{Float64}(window_df.lnR)
        ))
    end
    
    return windows
end

function compute_bipartite_matrices(data::WindowData)
    firms = data.firm_ids
    managers = data.manager_ids
    
    unique_firms = sort(unique(firms))
    unique_managers = sort(unique(managers))
    
    firm_idx = Dict(f => i for (i, f) in enumerate(unique_firms))
    manager_idx = Dict(m => i for (i, m) in enumerate(unique_managers))
    
    n_firms = length(unique_firms)
    n_managers = length(unique_managers)
    n_obs = length(firms)
    
    rows_fm = [i for i in 1:n_obs]
    cols_firm = [firm_idx[f] for f in firms]
    cols_manager = [manager_idx[m] for m in managers]
    
    D_firm = sparse(rows_fm, cols_firm, ones(n_obs), n_obs, n_firms)
    D_manager = sparse(rows_fm, cols_manager, ones(n_obs), n_obs, n_managers)
    
    return D_firm, D_manager, firm_idx, manager_idx
end

function find_largest_component_entities(D::SparseMatrixCSC)::Vector{Int}
    # D is n_obs × n_entities
    # Project to entity-entity network: D' * D
    P = D' * D
    P_clean = P - spdiagm(0 => diag(P))
    dropzeros!(P_clean)
    
    # Find connected components in entity space
    G = SimpleGraph(P_clean)
    components = connected_components(G)
    
    # Return largest component entity indices
    largest_idx = argmax([length(c) for c in components])
    return sort(components[largest_idx])
end

function compute_network_covariance(D::SparseMatrixCSC, y::Vector{Float64}, step::Int=2, valid_nodes::Union{Nothing,Vector{Int}}=nothing)
    # Use only valid nodes if specified
    if valid_nodes !== nothing
        D = D[valid_nodes, :]
        y = y[valid_nodes]
    end
    
    y_centered = y .- mean(y)
    
    P = D * D'
    P_clean = P - spdiagm(0 => diag(P))
    dropzeros!(P_clean)
    
    if step == 2
        W = P_clean
    elseif step == 4
        W = P_clean^2
        W = W - spdiagm(0 => diag(W))
        dropzeros!(W)
    else
        error("Only step=2 or step=4 supported")
    end
    
    n_edges = nnz(W) ÷ 2
    
    if n_edges == 0
        return 0.0, 0
    end
    
    cov_sum = 0.0
    rows = rowvals(W)
    for col in 1:size(W, 2)
        for j in nzrange(W, col)
            row = rows[j]
            if row > col
                cov_sum += y_centered[row] * y_centered[col]
            end
        end
    end
    
    return cov_sum / n_edges, n_edges
end

function find_nodes_with_both_neighbors(D::SparseMatrixCSC)::Vector{Int}
    # Find nodes that have both 2-step AND 4-step neighbors
    P = D * D'
    P_clean = P - spdiagm(0 => diag(P))
    dropzeros!(P_clean)
    
    # Nodes with 2-step neighbors
    has_2step = vec(sum(P_clean, dims=2) .> 0)
    
    # Nodes with 4-step neighbors
    P4 = P_clean^2
    P4 = P4 - spdiagm(0 => diag(P4))
    dropzeros!(P4)
    has_4step = vec(sum(P4, dims=2) .> 0)
    
    # Return indices where both conditions hold
    return findall(has_2step .& has_4step)
end

function compute_window_moments(data::WindowData)::MomentEstimates
    D_firm, D_manager, _, _ = compute_bipartite_matrices(data)
    
    # Use all observations - network covariances will use available edges
    V = var(data.log_revenue)
    
    C_ff2, n_ff2 = compute_network_covariance(D_firm, data.log_revenue, 2)
    C_mm2, n_mm2 = compute_network_covariance(D_manager, data.log_revenue, 2)
    
    C_ff4, n_ff4 = compute_network_covariance(D_firm, data.log_revenue, 4)
    C_mm4, n_mm4 = compute_network_covariance(D_manager, data.log_revenue, 4)
    
    n_firms = length(unique(data.firm_ids))
    n_managers = length(unique(data.manager_ids))
    
    return MomentEstimates(
        data.window_id, minimum(data.years), maximum(data.years),
        length(data.log_revenue), n_firms, n_managers,
        V, C_mm2, C_ff2, C_mm4, C_ff4,
        n_mm2, n_ff2, n_mm4, n_ff4
    )
end

function estimate_parameters_gmm(moments::MomentEstimates)::ParameterEstimates
    V = moments.V
    C_mm2 = moments.C_mm2
    C_ff2 = moments.C_ff2
    C_mm4 = moments.C_mm4
    C_ff4 = moments.C_ff4
    
    if C_mm2 <= 0 || C_ff2 <= 0
        return ParameterEstimates(
            moments.window_id, moments.year_min, moments.year_max,
            NaN, NaN, NaN, NaN
        )
    end
    
    ρ2_mm = C_mm4 / C_mm2
    ρ2_ff = C_ff4 / C_ff2
    
    ρ2 = (ρ2_mm + ρ2_ff) / 2
    ρ2 = clamp(ρ2, 0.0, 0.999)
    
    ρ = sqrt(ρ2)
    if C_mm2 < 0 || C_ff2 < 0
        ρ = -ρ
    end
    
    excess_mm = V - C_mm2
    excess_ff = V - C_ff2
    sum_cov2 = C_mm2 + C_ff2
    
    function objective(σ_ε2)
        if σ_ε2 < 0 || σ_ε2 >= min(excess_mm, excess_ff)
            return 1e10
        end
        
        σ_z2 = (excess_mm - σ_ε2) / (1 - ρ2 + 1e-10)
        σ_a2 = (excess_ff - σ_ε2) / (1 - ρ2 + 1e-10)
        
        if σ_z2 <= 0 || σ_a2 <= 0
            return 1e10
        end
        
        σ_z = sqrt(σ_z2)
        σ_a = sqrt(σ_a2)
        
        predicted_sum = (1 + ρ2) * (σ_a2 + σ_z2) + 4 * ρ * σ_a * σ_z
        
        return (predicted_sum - sum_cov2)^2
    end
    
    σ_ε2_candidates = range(0.0, min(excess_mm, excess_ff) * 0.99, length=1000)
    objectives = [objective(σ_ε2) for σ_ε2 in σ_ε2_candidates]
    best_idx = argmin(objectives)
    σ_ε2_opt = σ_ε2_candidates[best_idx]
    
    σ_z2 = (excess_mm - σ_ε2_opt) / (1 - ρ2 + 1e-10)
    σ_a2 = (excess_ff - σ_ε2_opt) / (1 - ρ2 + 1e-10)
    
    σ_z = sqrt(max(0, σ_z2))
    σ_a = sqrt(max(0, σ_a2))
    σ_ε = sqrt(max(0, σ_ε2_opt))
    
    return ParameterEstimates(
        moments.window_id, moments.year_min, moments.year_max,
        σ_a, σ_z, ρ, σ_ε
    )
end

function save_moments_csv(moments::Vector{MomentEstimates}, path::String)
    df = DataFrame(
        window_id = [m.window_id for m in moments],
        year_min = [m.year_min for m in moments],
        year_max = [m.year_max for m in moments],
        n_obs = [m.n_obs for m in moments],
        n_firms = [m.n_firms for m in moments],
        n_managers = [m.n_managers for m in moments],
        variance = [round(m.V, digits=5) for m in moments],
        cov_mm_2step = [round(m.C_mm2, digits=5) for m in moments],
        cov_ff_2step = [round(m.C_ff2, digits=5) for m in moments],
        cov_mm_4step = [round(m.C_mm4, digits=5) for m in moments],
        cov_ff_4step = [round(m.C_ff4, digits=5) for m in moments],
        n_edges_mm_2step = [m.n_edges_mm2 for m in moments],
        n_edges_ff_2step = [m.n_edges_ff2 for m in moments],
        n_edges_mm_4step = [m.n_edges_mm4 for m in moments],
        n_edges_ff_4step = [m.n_edges_ff4 for m in moments]
    )
    CSV.write(path, df)
end

function save_estimates_csv(estimates::Vector{ParameterEstimates}, path::String)
    df = DataFrame(
        window_id = [e.window_id for e in estimates],
        year_min = [e.year_min for e in estimates],
        year_max = [e.year_max for e in estimates],
        sigma_a = [round(e.σ_a, digits=5) for e in estimates],
        sigma_z = [round(e.σ_z, digits=5) for e in estimates],
        rho = [round(e.ρ, digits=5) for e in estimates],
        sigma_epsilon = [round(e.σ_ε, digits=5) for e in estimates]
    )
    CSV.write(path, df)
end

function main()
    @info "Variance-covariance decomposition for CEO-firm sorting"
    
    windows = read_window_data("temp/sorting_windows.csv")
    @info "Loaded $(length(windows)) windows spanning 1992-2021"
    
    moments_vec = MomentEstimates[]
    estimates_vec = ParameterEstimates[]
    
    for window in windows
        year_min, year_max = minimum(window.years), maximum(window.years)
        
        moments = compute_window_moments(window)
        push!(moments_vec, moments)
        
        @info "Window $year_min-$year_max: n=$(moments.n_obs), V=$(round(moments.V, digits=2)), C_mm2=$(round(moments.C_mm2, digits=2)), C_ff2=$(round(moments.C_ff2, digits=2))"
        
        params = estimate_parameters_gmm(moments)
        push!(estimates_vec, params)
        
        @info "Window $year_min-$year_max: ρ=$(round(params.ρ, sigdigits=4)), σ_firm=$(round(params.σ_a, sigdigits=3)), σ_manager=$(round(params.σ_z, sigdigits=3))"
    end
    
    save_moments_csv(moments_vec, "output/sorting_moments.csv")
    save_estimates_csv(estimates_vec, "output/sorting_estimates.csv")
    
    @info "Results saved to output/"
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
