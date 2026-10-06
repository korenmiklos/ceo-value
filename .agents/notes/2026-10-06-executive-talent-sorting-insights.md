---
id: 3
type: note
created: 2026-10-06
related:
  - id: 2
    type: note
    title: Domain expert interview
---

# Executive talent sorting insights

Brown bag seminar presentation by Speaker C (with Christina, Miklos as co-authors; multiple discussants). Presented the GMRF approach to identifying whether better executives work at better firms, measuring the sorting correlation from mobility networks.

## Research question and motivation

Core question: do better executives work at better firms, and how strong is the relationship? Measured as the correlation between log persistent firm productivity and log persistent executive talent. Firm productivity and managerial skill are complementary; sorting affects aggregate output.

Firm productivity is an interpretation of a persistent firm fixed effect; executive talent is a persistent manager fixed effect. Neither is directly observable; both are latent.

## Data

Hungarian corporate court records, 1990-2022. Universe of Hungarian firms with annual revenue and employment. Approximately 1 million firms, 1.3 million executives, 1.9 million unique firm-executive links. About 75% of executives are observed at only a single firm -- mobility is very sparse.

In the largest connected component, 81.8% of edges are bridges. KSS trimming reduces 1.7 million outcome pairs to about 265,000, then to about 10% after leave-out block selection. The literal KSS algorithm leaves only about 54 pairs -- essentially unusable on this data.

## Identification strategy: GMRF

Instead of estimating millions of fixed effects (AKM/KSS), the approach models the joint distribution of latent effects directly on the bipartite firm-executive network. Four parameters are estimated rather than 2.3 million fixed effects.

Latent effects are modeled as a Gaussian Markov Random Field (GMRF) on the network. The precision matrix Q encodes network structure: non-zero entries only for observed links. The Markov assumption states that conditional on a manager's latent effect, firm effects at connected firms are independent.

Quote: "Selection occurs through latent effects only. If you know the A of the firm that you're interviewing for and the firm knows your Z, your skill when they are interviewing you, there's no other information that's necessary to form a link."

## Identification of rho from covariance decay

The covariance of outcomes decays with network distance. Distance-2 covariance alone cannot isolate rho, but the ratio of distance-4 to distance-2 covariance gives rho-squared. Odd-distance covariances identify the sign of rho. Cycles in the network complicate the tree-based analytic strategy, but GMRF inversion accounts for all paths.

Covariance decay was confirmed empirically across firm, mixed, and executive endpoint pairs. Estimation is via maximum likelihood; a Julia package was developed for sparse matrix computation.

## Key assumptions and challenges

- Markov assumption: correlation travels only through direct network links, not through space or industry shocks. Tested empirically: not exactly true, but decay visually consistent with constant-rate decay up to distance 7.
- Spatial proximity is a plausible alternative explanation for decay; same-city dummies were proposed as a robustness check.
- Homoscedastic, uncorrelated match disturbances assumed in baseline; preferred specification uses AR(1) within-firm serial correlation.
- Symmetry constraint: a single rho parameter captures the full covariance pattern. Richer heterogeneous rho structures (by sector, education) were discussed as extensions.
- Learning and dynamic manager effects are not modeled; tenure covariates could be added.

## Results

Preferred estimate (AR(1) shocks): sorting correlation = 0.541. Independent shocks specification: 0.374. Firm-average specification: similar point estimate.

Variance decomposition of demeaned log real revenue:
- Firm productivity: 23.2%
- Executive talent: 0.7%
- Sorting covariance (x2): 4.5%
- Match-specific disturbance: 71.6% (comparable to Fenizia 2022 at about 66%)

The no-sorting counterfactual implies 8.9% lower average output. KSS on a comparable subsample: positive correlation but smaller than the GMRF estimate.

Prior literature range: Gabaix-Landier assumes perfect sorting (rho=1); empirical estimates span -0.85 to +0.95.

Quote: "I started with 'better executives work at better firms.' I will also close with 'better executives work at better firms.' That's it."