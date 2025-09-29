# ANOVA Methodology for CEO Effects on Firm Performance

## Overview

The ANOVA approach decomposes the variance of firm performance growth to quantify how much CEO transitions contribute to long-term performance differences. This extends the placebo-controlled event study from mean effects to second moments (variance).

## Theoretical Framework

### Cumulative TFP Growth Model

For firms, the cumulative TFP growth from birth year $b$ to year $t$ is:

**Control firms (no CEO change):**
$$\Delta_0 \omega_{it} = \sum_{a=1}^{t-b}\Delta\omega_{i,b+a} = \sum_{a=1}^{t-b}\Delta\epsilon_{i,b+a}$$

**Treated firms (CEO change):**
$$\Delta_0 \omega_{it} = \sum_{a=1}^{t-b}\Delta\omega_{i,b+a} = z_{mit} - z_{mi0}+\sum_{a=1}^{t-b}\Delta\epsilon_{i,b+a}$$

where:
- $\omega_{it}$ = TFP of firm $i$ at time $t$
- $\Delta\epsilon_{i,b+a}$ = residual TFP shocks
- $z_{mit} - z_{mi0}$ = change in manager quality

### Variance Decomposition Under Unit Root

Assuming $\Delta z$ is orthogonal to $\Delta \epsilon$ and the latter is iid over time:

**Control firms:**
$$\text{Var}(\Delta_0 \omega_{it}|D_{it}=0) = (t-b)\sigma^2_0$$

**Treated firms:**
$$\text{Var}(\Delta_0 \omega_{it}|D_{it}=1) = \text{Var}(\Delta z)+(t-b)\sigma^2_1$$

The object of interest is **$\text{Var}(\Delta z)$** - the contribution of manager change to long-run growth variance.

## Empirical Implementation

### Parallel Trends in Second Moments

**Key assumption:** Variance of error terms depends only on firm age and treatment status, not timing of treatment:

$$\text{Var}(\Delta_0 \epsilon_{it}|D_i=1,t=b_i+a) = \text{Var}(\Delta_0 \epsilon_{it}|D_{it}=0,D_i=1,t=b_i+a)$$

This allows age-specific variance controls: $\sigma^2_{a0}$ (control) and $\sigma^2_{a1}$ (not-yet-treated).

### Parametric Model

For firms with $k_{it}$ CEO changes by year $t$:

$$\text{Var}(\Delta_0 \omega_{it}|D_i=1,t=b_i+a) = k_{it}\Phi + \sigma^2_1\eta_a$$

where:
- $\Phi = \text{Var}(z_m - z_{m'})$ = variance of manager quality differences
- $\eta_a$ = age-specific variance profile
- $k_{it}$ = number of CEO changes (observed in data)

### Estimation Strategy

1. **Estimate placebo-controlled variance effects** for single CEO transitions
2. **Extract components:** $\hat{\Phi}$, $\hat{\sigma}^2_1$, and $\hat{\eta}_a$ 
3. **Compute predicted variance:** $k_{it}\hat{\Phi} + \hat{\sigma}_1^2\hat{\eta}_a$
4. **Calculate manager contribution:** $\frac{k_{it}\hat{\Phi}}{k_{it}\hat{\Phi} + \hat{\sigma}_1^2\hat{\eta}_a}$

### Average Treatment Effect on Treated (ATET)

The variance-weighted average effect across all treated firms:

$$\text{ATET} = \sum_{it:k_{it}>0}w_{it}\frac{k_{it} \hat{\Phi}}{k_{it} \hat{\Phi} + \hat{\sigma}_1^2\eta_a}$$

where $w_{it}$ are appropriate sample weights.

## Key Methodological Innovations

1. **Placebo controls for variance:** Uses same placebo design as mean effects but applied to $(\Delta \text{TFP})^2$
2. **Age-specific corrections:** Controls for systematic variance changes with firm age using $\eta_a$ profile
3. **Multiple transitions:** Back-of-envelope calculation scales single-transition estimates by number of changes $k_{it}$
4. **Within-firm identification:** Firm fixed effects remove cross-sectional variance differences

## Results Interpretation

The methodology yields the share of long-term firm performance variance attributable to CEO quality differences, addressing the fundamental question: **"How much do CEOs matter for firm performance differences?"**

This represents a significant advance over naive R² decompositions by properly controlling for selection, timing, and age effects through the placebo-controlled design.

## Discussion Summary from 2025-09-25

The team discussed several key implementation details:

### Event Study Framework
- The approach extends the placebo-controlled event study to second moments
- Pre-trends in variance are observed and corrected using age-specific controls
- The treatment effect manifests as increased variance after CEO transitions

### Sample Construction
- Focus on firms with exactly one CEO change in the analysis window
- Use unbalanced panels with careful placebo matching on birth cohort, sector, and event window
- Each CEO transition gets 9 placebo controls to ensure precise estimation

### Variance Decomposition Results
- Preliminary findings suggest CEOs contribute ~27% to long-term TFP growth variance
- This is substantially lower than naive R² estimates (~50-60%)
- Results are robust across different outcome measures (TFP, revenue, inputs)

### Technical Challenges
- Age-specific variance profiles require sophisticated modeling
- Multiple CEO transitions need back-of-envelope scaling
- Firm fixed effects essential for within-firm identification

### Paper Structure
The methodology will be presented across multiple exhibits:
- Figure 1: Placebo validation showing treatment vs. control variance paths
- Figure 2-3: Event study results for mean and variance effects  
- Table: Variance decomposition results with age corrections
- Additional robustness checks in appendix