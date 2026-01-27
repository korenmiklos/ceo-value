# Research Meeting: Monte Carlo Simulation Parameter Exploration

**Date:** January 13, 2026  
**Participants:** Miklós Koren (PI), Geri (Research Assistant)  
**Topic:** Monte Carlo misspecification testing and parameter refinement

## Overview

This meeting focused on refining Monte Carlo simulation parameters to test the robustness of the placebo-controlled event study estimator under model misspecification. The discussion addressed both technical infrastructure issues and substantive econometric design decisions for testing the estimator's performance when key identifying assumptions are violated.

## Technical Infrastructure Discussion

### Repository Management
- Current state: 34+ active git branches requiring cleanup
- Decision: Work directly on main branch to avoid further branch proliferation
- Deleted experimental branches from August (outdated algorithm versions)
- Identified naming convention issues in legacy branches

### Data Pipeline Status
- Geri successfully ran full data pipeline from scratch
- Value-added variable definition relocated from `code/estimate/setup_event_study.do:28` to `code/util/variables.do`
- Improved code organization: variable definitions now in proper location in dependency chain
- Variables use truncation instead of winsorization for outlier treatment

### Environment Configuration
- Cross-platform deployment challenges: local (10 cores) vs server (100 cores)
- Stata binary naming inconsistency: `stata-mp` vs `stata`
- Discussed potential use of environment variables and phase.dev for secrets management
- Deferred infrastructure automation to focus on econometric analysis

## Monte Carlo Simulation Modifications

### Current Implementation
The existing Monte Carlo framework (located in `papers/econometrics/src/monte-carlo/`) tests the estimator under correctly specified models. The baseline "persistent" specification uses autocorrelation ρ = 0.9 for both treatment and control groups with equal variance.

### Proposed Misspecification Tests

#### Task 1: Heterogeneous Autocorrelation (Issue #53)
**Objective:** Test estimator performance when treatment and control groups have different autocorrelation structures.

**Implementation:**
- Modify `setup.do:58` to allow separate ρ parameters for treated and control groups
- Create analogous structure to existing `sigma_control_treated_ratio` parameter
- Test cases:
  - Control ρ = 0.9, Treatment ρ = 0.8
  - Control ρ = 0.8, Treatment ρ = 0.9

**Rationale:** The current estimator does not explicitly account for differential autocorrelation between groups. These scenarios test whether the estimator overcorrects or undercorrects when this assumption is violated.

#### Task 2: Realistic Excess Variance
**Objective:** Test estimator with empirically plausible variance differences between groups.

**Current specification:** Control variance = 0.5, Treatment variance = 1.0 (ratio: 2.0)

**New specification:**
- Control variance = 0.5
- Treatment variance = 0.7 (reduced from 1.0)
- Ratio = 1.4

**Rationale:** The 2.0 ratio is unrealistically large. Empirical analysis of the Hungarian data suggests variance ratios closer to 1.4, making this a more relevant robustness check.

**Location:** `papers/econometrics/src/monte-carlo/settings_excess_variance.do`

### Visualization Strategy

**Format:** Six-panel figure structure (similar to existing Figure MC)
- Focus on covariance panels (right-hand column)
- Comparison structure: correctly specified (baseline) vs. misspecified models
- Specific panels:
  1. Baseline: ρ = 0.9 for both groups
  2. Misspecified: Control ρ = 0.9, Treatment ρ = 0.8
  3. Misspecified: Control ρ = 0.8, Treatment ρ = 0.9
  4. Baseline: Equal variance
  5. Misspecified: Variance ratio = 1.4
  6. (Reserve for additional specification if needed)

**Output location:** `output/figure/` directory (PDF format)

**Expected results:** Because the current estimation code does not correct for excess variance or differential autocorrelation, Monte Carlo figures will show estimator bias under these misspecifications. The magnitude of bias is of substantive interest for understanding estimator limitations.

## Methodological Context

These Monte Carlo extensions directly address limitations identified in the manager effects literature:

1. **Limited mobility bias:** Even with the placebo control design, differential autocorrelation between movers and stayers could bias treatment effect estimates.

2. **Heterogeneous treatment effects:** If treatment effects have different variances than control outcomes, the two-way fixed effects estimator may not properly identify the average treatment effect.

3. **External validity:** Testing realistic parameter values (ρ ≈ 0.8-0.9, variance ratio ≈ 1.4) provides evidence about estimator performance in settings similar to the Hungarian administrative data.

## Action Items

1. **Geri:**
   - Implement Issue #53: Add separate ρ parameters for treatment and control groups
   - Modify excess variance parameters to realistic values (1.0 → 0.7)
   - Generate Monte Carlo exhibit figures with comparison structure
   - Push results to main branch
   - Share results with full team (not just Miklós) before Friday meeting

2. **Miklós:**
   - Review pull request for updated CEO panel and balance sheet data
   - Coordinate Friday meeting with Álmos and Krisztina (timezone: Melbourne)

3. **Team:**
   - Friday meeting to review Monte Carlo results and discuss next steps

## Technical Notes

- Monte Carlo scripts run quickly (not computationally intensive)
- All work proceeds directly on main branch
- Git history allows easy reversion if needed
- Full team communication preferred over bilateral updates

## References

The Monte Carlo design builds on theoretical work addressing identification challenges in two-way fixed effects models:
- Gaure (2014): Limited mobility bias in network models
- Bonhomme et al. (2023): Heterogeneous treatment effects with fixed effects
- Andrews et al. (2008): Variance decomposition in grouped data

These misspecification tests will validate whether the 5.5% causal CEO effect estimate (25% of the raw 22.5% correlation) remains robust when key homogeneity assumptions are relaxed.
