# Variance-Covariance Decomposition: Correct Derivation

**Date:** October 17, 2025  
**Issue:** Line 171 in `lib/estimate/sorting_moments.jl` has incorrect derivation of S_term

## Problem

The current implementation uses:
```julia
S_term = sum_cov2 - 4 * ρ * sqrt(max(0, D^2 / 4 + 1e-10))
```

This doesn't match the paper's derivation and produces incorrect estimates (σ_a = 0 consistently).

## Correct Algebraic Derivation

### Step 1: Factor out σ_z²

From the paper's equations (6) and (7):
- $C_{\text{mm},2} = \sigma_a^2 + 2\rho\sigma_a\sigma_z + \rho^2\sigma_z^2$
- $C_{\text{ff},2} = \sigma_z^2 + 2\rho\sigma_a\sigma_z + \rho^2\sigma_a^2$

Let $r = \sigma_a/\sigma_z$. Then:

$$C_{\text{mm},2} = \sigma_z^2(r^2 + 2\rho r + \rho^2)$$

$$C_{\text{ff},2} = \sigma_z^2(1 + 2\rho r + \rho^2 r^2)$$

### Step 2: Sum the covariances

$$C_{\text{mm},2} + C_{\text{ff},2} = \sigma_z^2[(1+\rho^2)(r^2 + 1) + 4\rho r]$$

### Step 3: Use known quantities

We know:
1. $\rho$ from 4-step/2-step ratio
2. $D = \sigma_z^2 - \sigma_a^2 = \sigma_z^2(1 - r^2)$ from difference equation
3. $\text{sum\_cov2} = C_{\text{mm},2} + C_{\text{ff},2}$ (observed)

### Step 4: Express r in terms of σ_z²

From $D = \sigma_z^2(1 - r^2)$:
$$r = \sqrt{1 - \frac{D}{\sigma_z^2}}$$

### Step 5: Root-finding equation

Substituting into the sum equation:
$$\text{sum\_cov2} = 2(1+\rho^2)\sigma_z^2 - (1+\rho^2)D + 4\rho\sqrt{\sigma_z^2(\sigma_z^2 - D)}$$

Define $f(x) = 0$ where $x = \sigma_z^2$:
$$f(x) = 2(1+\rho^2)x - (1+\rho^2)D + 4\rho\sqrt{x(x - D)} - \text{sum\_cov2}$$

Solve for $x$ in the interval $(D, V]$ where $V$ is the total variance.

## Implementation Plan

### 1. Compute known quantities
```julia
ρ2 = (C_mm4/C_mm2 + C_ff4/C_ff2) / 2  # Average of both estimates
ρ = sqrt(ρ2)
D = (C_ff2 - C_mm2) / (1 - ρ2)
sum_cov2 = C_mm2 + C_ff2
```

### 2. Define root-finding function
```julia
function solve_for_sigma_z2(ρ::Float64, D::Float64, sum_cov2::Float64, V::Float64)
    f(x) = 2*(1+ρ^2)*x - (1+ρ^2)*D + 4*ρ*sqrt(x*(x - D)) - sum_cov2
    
    # Search interval: (D + ε, V)
    lower = D + 1e-6
    upper = V
    
    # Use bisection or find_zero from Roots.jl
    σ_z2 = find_zero(f, (lower, upper), Bisection())
    
    return σ_z2
end
```

### 3. Recover all parameters
```julia
σ_z2 = solve_for_sigma_z2(ρ, D, sum_cov2, V)
σ_z = sqrt(σ_z2)
σ_a2 = σ_z2 - D
σ_a = sqrt(max(0, σ_a2))
σ_ε2 = max(0, V - σ_a2 - σ_z2 - 2*ρ*σ_a*σ_z)
σ_ε = sqrt(σ_ε2)
```

## Why This Works

1. **Algebraically rigorous:** Directly from the paper's moment equations
2. **Avoids approximations:** No ad-hoc formulas like the current `S_term`
3. **Numerically stable:** Root-finding on a well-behaved monotonic function
4. **Correct domain:** Ensures σ_z² > D (i.e., σ_a² > 0)

## Expected Results

With correct implementation:
- σ_a should be positive and meaningful (not zero)
- ρ ≈ 0.99 should remain (this part is correct)
- σ_z should adjust to satisfy all moment conditions
- All parameters should satisfy the variance decomposition: V = σ_a² + σ_z² + 2ρσ_aσ_z + σ_ε²

## Next Steps

1. Add `using Roots` to dependencies in Project.toml
2. Replace lines 167-172 in `lib/estimate/sorting_moments.jl` with root-finding approach
3. Test on one window to verify parameters are sensible
4. Rerun full analysis and compare results
