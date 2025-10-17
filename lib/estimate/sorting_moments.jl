using CSV, DataFrames
using SparseArrays, Statistics, LinearAlgebra
using Logging

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

function compute_network_covariance(D::SparseMatrixCSC, y::Vector{Float64}, step::Int=2)
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

function compute_window_moments(data::WindowData)::MomentEstimates
    V = var(data.log_revenue)
    D_firm, D_manager, _, _ = compute_bipartite_matrices(data)
    
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
    ρ2 = clamp(ρ2, 0.0, 1.0)
    
    ρ = sqrt(ρ2)
    if C_mm2 < 0 || C_ff2 < 0
        ρ = -ρ
    end
    
    D = (C_ff2 - C_mm2) / (1 - ρ2 + 1e-10)
    
    sum_cov2 = C_mm2 + C_ff2
    
    S_term = sum_cov2 - 4 * ρ * sqrt(max(0, D^2 / 4 + 1e-10))
    S = S_term / (1 + ρ2 + 1e-10)
    
    σ_a2 = max(0, (S - D) / 2)
    σ_z2 = max(0, (S + D) / 2)
    
    σ_a = sqrt(σ_a2)
    σ_z = sqrt(σ_z2)
    
    σ_ε2 = max(0, V - σ_a2 - σ_z2 - 2 * ρ * σ_a * σ_z)
    σ_ε = sqrt(σ_ε2)
    
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
        V = [m.V for m in moments],
        C_mm2 = [m.C_mm2 for m in moments],
        C_ff2 = [m.C_ff2 for m in moments],
        C_mm4 = [m.C_mm4 for m in moments],
        C_ff4 = [m.C_ff4 for m in moments],
        n_edges_mm2 = [m.n_edges_mm2 for m in moments],
        n_edges_ff2 = [m.n_edges_ff2 for m in moments],
        n_edges_mm4 = [m.n_edges_mm4 for m in moments],
        n_edges_ff4 = [m.n_edges_ff4 for m in moments]
    )
    CSV.write(path, df)
end

function save_estimates_csv(estimates::Vector{ParameterEstimates}, path::String)
    df = DataFrame(
        window_id = [e.window_id for e in estimates],
        year_min = [e.year_min for e in estimates],
        year_max = [e.year_max for e in estimates],
        σ_a = [e.σ_a for e in estimates],
        σ_z = [e.σ_z for e in estimates],
        ρ = [e.ρ for e in estimates],
        σ_ε = [e.σ_ε for e in estimates]
    )
    CSV.write(path, df)
end

function main()
    @info "Reading window data from temp/sorting_windows.csv"
    windows = read_window_data("temp/sorting_windows.csv")
    @info "Loaded $(length(windows)) windows"
    
    moments_vec = MomentEstimates[]
    estimates_vec = ParameterEstimates[]
    
    for window in windows
        year_min, year_max = minimum(window.years), maximum(window.years)
        @info "Processing window $(window.window_id) ($year_min-$year_max): $(length(window.log_revenue)) obs, $(length(unique(window.firm_ids))) firms, $(length(unique(window.manager_ids))) managers"
        
        moments = compute_window_moments(window)
        push!(moments_vec, moments)
        
        params = estimate_parameters_gmm(moments)
        push!(estimates_vec, params)
        
        @info "  ρ=$(round(params.ρ, digits=4)), σ_a=$(round(params.σ_a, digits=4)), σ_z=$(round(params.σ_z, digits=4))"
    end
    
    save_moments_csv(moments_vec, "output/sorting_moments.csv")
    save_estimates_csv(estimates_vec, "output/sorting_estimates.csv")
    @info "Results saved to output/sorting_moments.csv and output/sorting_estimates.csv"
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
