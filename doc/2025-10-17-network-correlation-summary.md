# Network Correlation Analysis: CEO-Firm Sorting

**Date:** October 17, 2025  
**Status:** Completed and committed  
**Related commits:** 2d936bf, e646bac, c198834

## Overview

This analysis implements a variance-covariance decomposition method to quantify the strength of assortative matching between CEOs and firms in the Hungarian data (1992-2021). The approach uses only firm-level revenues and the topology of the CEO-firm mobility network to identify sorting parameters without requiring high-dimensional fixed effects estimation.

## Methodology

### Theoretical Framework

The method is based on a random-effects model where log revenue decomposes as:
```
y_im = a_i + z_m + ε_im
```
where:
- `a_i` = firm type (log firm effect)
- `z_m` = manager type (log manager effect)  
- `ε_im` = match-specific noise
- `Cov(a, z) = ρ·σ_a·σ_z` where ρ ∈ [-1, 1] measures sorting strength

### Key Innovation: Network Covariance Identification

Rather than estimating millions of fixed effects, the method exploits covariances across pairs at different distances in the firm-manager mobility network:

**2-step covariances** (direct neighbors):
- Manager-manager pairs sharing a firm: `Cov = σ_a² + 2ρσ_aσ_z + ρ²σ_z²`
- Firm-firm pairs sharing a manager: `Cov = σ_z² + 2ρσ_aσ_z + ρ²σ_a²`

**4-step covariances** (second neighbors):
- Connected through intermediate nodes, attenuated by `ρ²`

The ratio of 4-step to 2-step covariances directly identifies `ρ²`:
```
ρ² = Cov_4step / Cov_2step
```

### Implementation

**Data preparation** (`lib/create/sorting_windows.do`):
- Creates 10 non-overlapping 3-year windows (1992-1994, 1995-1997, ..., 2019-2021)
- Preserves firm-year-manager observations with log revenue
- Handles multiple CEOs per window by selecting primary CEO (longest tenure)
- Output: 3.1M observations across 985K firm-window-manager combinations

**Estimation** (`lib/estimate/sorting_moments.jl`):
- Builds bipartite firm-manager graphs and computes projections
- Calculates 2-step and 4-step network covariances using sparse matrix operations
- Estimates parameters via method-of-moments using excess variance equations:
  - V - C_mm2 = (1-ρ²)σ_z² + σ_ε²
  - V - C_ff2 = (1-ρ²)σ_a² + σ_ε²
- Grid search over σ_ε² to satisfy all moment conditions simultaneously
- Handles numerical stability when ρ approaches 1 by clamping ρ² to [0, 0.999]

## Key Technical Challenge Resolved

**Original issue:** Initial implementation used an incorrect formula for solving the system of moment equations, leading to σ_a ≈ 0 consistently.

**Solution:** Implemented proper root-finding based on excess variance equations. When ρ is very close to 1, the standard formula D = (C_ff2 - C_mm2)/(1-ρ²) becomes numerically unstable. The corrected approach:

1. Uses excess variance formulas directly
2. Grid searches over σ_ε² to find values of (σ_a, σ_z) that satisfy the sum constraint on 2-step covariances
3. Minimizes squared deviation between predicted and observed covariance sums

Full derivation documented in `doc/2025-10-17-sorting-derivation.md`.

## Results

### Estimated Parameters (1992-2021)

| Period | ρ (correlation) | σ_firm | σ_manager | σ_ε (noise) |
|--------|----------------|---------|-----------|-------------|
| 1992-1994 | 0.988 | 0.52 | 4.10 | 0.78 |
| 1995-1997 | 0.991 | 0.56 | 5.01 | 0.73 |
| 1998-2000 | 0.991 | 0.51 | 4.78 | 0.70 |
| 2001-2003 | 0.990 | 0.51 | 4.53 | 0.72 |
| 2004-2006 | 0.990 | 0.50 | 4.65 | 0.71 |
| 2007-2009 | 0.990 | 0.52 | 4.91 | 0.74 |
| 2010-2012 | 0.990 | 0.54 | 5.66 | 0.75 |
| 2013-2015 | 0.989 | 0.53 | 5.48 | 0.77 |
| 2016-2018 | 0.990 | 0.52 | 5.74 | 0.72 |
| 2019-2021 | 0.991 | 0.53 | 6.03 | 0.71 |

### Key Findings

1. **Extremely strong positive sorting**: ρ ≈ 0.99 throughout the entire 30-year period
   - Sorting strength is remarkably stable over time
   - No evidence of market efficiency improvements in matching

2. **Manager heterogeneity dominates**: σ_manager ≈ 4-6 vs σ_firm ≈ 0.5
   - Manager quality varies 8-10x more than firm quality
   - Suggests CEOs drive most of the variation in firm performance
   - Consistent with main placebo-controlled event study findings

3. **Moderate match-specific noise**: σ_ε ≈ 0.7
   - Match quality matters beyond CEO and firm types
   - Substantial idiosyncratic component to productivity

## Economic Interpretation

The near-perfect correlation (ρ ≈ 0.99) indicates that:
- The best managers systematically work at the best firms
- Very little "misallocation" of CEO talent across firms
- Matching frictions appear minimal in this labor market

Combined with the large manager variance relative to firm variance, this suggests:
- **Allocative efficiency is high** (managers well-sorted to firms)
- **CEO quality matters more than firm fundamentals** for performance
- The placebo-controlled causal effect (5.5%) operates through a highly efficient but talent-constrained matching process

## Methodological Contribution

This analysis demonstrates that:
1. Sorting parameters can be identified without estimating high-dimensional fixed effects
2. Network topology provides identifying variation through covariance attenuation
3. The method scales to massive administrative datasets (3M+ observations, 1M+ firms/managers)
4. Results are remarkably stable across 30 years of market evolution

## Integration with Main Analysis

The sorting results complement the placebo-controlled event study:
- **Event study finding**: True causal effect of CEO quality is 5.5% (25% of raw correlation)
- **Sorting finding**: This operates in a market with near-perfect positive sorting (ρ ≈ 0.99)
- **Interpretation**: Even with optimal allocation, CEO effects are modest (5.5%), suggesting limited scope for improving firm performance through better CEO-firm matching

The large manager variance (σ_z ≈ 5) relative to the causal effect (5.5%) suggests:
- Most manager heterogeneity reflects pre-match selection rather than causal impact
- Firms successfully identify high-quality CEOs ex-ante
- The sorting process works, but marginal returns to better matching are small

## Files Generated

**Code:**
- `lib/create/sorting_windows.do` - Window construction (Stata)
- `lib/estimate/sorting_moments.jl` - Moment computation and estimation (Julia)

**Output:**
- `output/sorting_estimates.csv` - Parameter estimates by window
- `output/sorting_moments.csv` - Network moments and sample statistics

**Documentation:**
- `doc/2025-10-17-sorting-derivation.md` - Full algebraic derivation

## Dependencies Added

- Julia package: `Roots.jl` (for numerical optimization)
- Updated `Project.toml` and `Manifest.toml`

## Makefile Integration

Added targets:
```makefile
temp/sorting_windows.csv: lib/create/sorting_windows.do temp/analysis-sample.dta
output/sorting_estimates.csv: lib/estimate/sorting_moments.jl temp/sorting_windows.csv
```

Integrated into:
- `data` target (adds `temp/sorting_windows.csv`)
- `analysis` target (adds `output/sorting_estimates.csv`)

## Future Extensions

1. **Bootstrap standard errors**: Add uncertainty quantification via block bootstrap
2. **Higher-order paths**: Use 6-step, 8-step covariances for overidentification tests
3. **Time-varying parameters**: Allow ρ, σ_a, σ_z to evolve smoothly over time
4. **Alternative outcomes**: Apply to value added, profits, or employment growth
5. **Heterogeneity analysis**: Estimate sorting by firm size, industry, or region

## Connection to Literature

This approach builds on:
- **Clark (2023)**: Using network path lengths to measure intergenerational correlation
- **Abowd, Kramarz, Margolis (1999)**: Firm-worker fixed effects decomposition
- **Graham (2008)**: Identifying social interactions through variance restrictions
- **Bonhomme et al. (2023)**: Bias corrections for two-way fixed effects with limited mobility

Our contribution: Showing that network covariance structure alone identifies sorting without requiring fixed effects estimation, making the method computationally tractable for massive datasets.

## Summary

The network correlation exercise successfully quantifies CEO-firm sorting strength in Hungarian administrative data, revealing near-perfect positive assortative matching throughout 1992-2021. Manager heterogeneity vastly exceeds firm heterogeneity, and the sorting process appears highly efficient. These findings provide crucial context for interpreting the modest causal effects identified in the placebo-controlled event study: not only are true CEO effects small (5.5%), but they operate in a market that has already achieved near-optimal matching.
