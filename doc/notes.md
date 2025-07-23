# 2025-07-17
## Measuring surplus

EBITDA = revenue minus material cost and labor cost

## What is entrepreneur compensated for?

Ownership of physical capital, intangible assets, like brand value, location of company, existing market position.
## Research design

### Sample
- firms that have changed outside manager some time 2014-2015
- no ownership change within +/- 2 years of the ceo change

### Measurement
- wage: base salary, bonuses cumulated for year $=W$
- surplus: EBITDA $=S$

### Regression
Given a CEO change in year $t$, define medium-run change as
$$
\Delta y_{it} = \frac13\sum_{s=1}^3 y_{i,t+s} - \frac13\sum_{s=1}^3 y_{i,t-s}.
$$
Regression:
$$
\Delta W_{it} = \phi \Delta S_{it} + \varepsilon_{it}
$$
with controls,
$$
\Delta W_{it} = \phi \Delta S_{it} + \beta \Delta X_{it} + \varepsilon_{it}
$$

> Figure out what to control and not control for.

### Mini model

$$
Q_{imt} = \Omega_{it}A_i^\chi K_{it}^\alpha Z_{m}^\nu L_{imt}^{1-\alpha-\nu-\chi} 
$$
Here $\chi$ is the elasticity wrt organizational capital and fixed immaterial assets (like location and brand value), $\alpha$ is the elasticity wrt physical capital, $\nu$ is the elasticity wrt manager skill. These are all fixed assets that are compensated from rents. The remaining variable inputs (here only labor, but in the data labor and material) are chosen optimally in each time period, holding the value of fixed assets fixed.

The term $\Omega_{it}$ is residual TFP, after controlling for manager skill and organization capital, and we assume it to be uncorrelated with these. (This can be relaxed with more sophisticated estimation methods.)

We assume that the manager only has control over the variable inputs, the fixed inputs are chosen by the owner.

Output price in sector $s$ is $P_{st}$.

FOC wrt labor:
$$
(1-\alpha-\nu-\chi)P_{st}\Omega_{it}A_i^\chi K_{it}^\alpha Z_{m}^\nu L_{imt}^{-\alpha-\nu-\chi} = W_t
$$
$$
L_{imt} = (1-\alpha-\nu-\chi)^{1/(\alpha+\nu+\chi)}(P_{st}\Omega_{it})^{1/(\alpha+\nu+\chi)} A_i^{\chi/(\alpha+\nu+\chi)} K_{it}^{\alpha/(\alpha+\nu+\chi)} Z_{m}^{\nu/(\alpha+\nu+\chi)} W_t^{-1/(\alpha+\nu+\chi)}
$$
so that revenue is
$$
R_{imst} = (P_{st}\Omega_{it})^{1/(\alpha+\nu+\chi)}A_i^{\chi/(\alpha+\nu+\chi)}
K_{it}^{\alpha/(\alpha+\nu+\chi)}
Z_{m}^{\nu/(\alpha+\nu+\chi)}
W_t^{-(1-\alpha-\nu-\chi)/(\alpha+\nu+\chi)}
(1-\alpha-\nu-\chi)^{(1-\alpha-\nu-\chi)/(\alpha+\nu+\chi)} \tag{1}
$$

Surplus is $\alpha + \nu+\chi$ share of revenue:
$$
S_{imst} = (\alpha+\nu+\chi) R_{imst},
$$
of which $\nu R_{imst}$ should go to managers, but only $\phi\nu R_{imst}$ actually does:
$$
W_{imst} = \phi\nu R_{imst}
$$

In logs,
$$
s_{imst} = \text{const} 
+ \frac{1}{\alpha+\nu+\chi}p_{st}
+ \frac{\chi}{\alpha+\nu+\chi}a_i
+ \frac{\alpha}{\alpha+\nu+\chi}k_{it}
+ \tilde z_{m}
- \frac{1-\alpha-\nu-\chi}{\alpha+\nu+\chi}w_t
+ \tilde\omega_{it}
$$
where $\tilde z_m = \frac{\nu}{\alpha+\nu+\chi}z_{m}$ and $\tilde\omega_{it} = \ln\Omega_{it}/(\alpha+\nu+\chi)$. Adding firm and industry-time fixed effects,
$$
s_{imst} =  
\frac{\alpha}{\alpha+\nu+\chi} k_{it}
+ \tilde z_{m}
+ \lambda_i
+\mu_{st} 
+ \tilde\omega_{it}
\tag{2}
$$
The firm fixed effect $\lambda_i$ removes the contribution of $a_i$ (time invariant organizational capital and immaterial assets) to the surplus. The industry-time fixed effect $\mu_{st}$ removes the variation in prices and wages.

We assume that $\tilde\omega_{it}$ is orthogonal to physical capital and manager skill. Note that organizational capital can be arbitrarily correlated with these.

The surplus function can be estimated with fixed-effects OLS (`reghdfe`) with manager fixed effects capturing $\tilde z_m$. 


> Problem: $\Delta k$ may be correlated with $\Delta z$ if smarter managers invest more, likely overestimating $\alpha$. But: if we already know $\alpha$ and $\nu$

$$
\Delta s_{imst} -
\frac{\alpha}{\alpha+\nu+\chi}\Delta k_{it}
= \Delta \tilde z_{mt}
+\mu_{st}
+\tilde\omega_{it}
$$

Time fixed effect can be estimated off firms that do not change a manager.

Then, for every manager-changing firm, we have $\Delta \tilde z$. 

Given a starting level of surplus, $S_{it-1}$, we can create a counterfactual new surplus, that comes only from the new manager skill can be computed from log-differentiating (1)
$$
\hat S_{i,t+1} = S_{i,t-1} e^{\Delta \tilde z_{mt}}.
$$
The counterfactual surplus change is
$$
\hat S_{i,t+1} - S_{i,t-1} = S_{i,t-1}\left[e^{\Delta \tilde z_{mt}}-1\right] \approx 
S_{i,t-1}\Delta \tilde z_{mt}.
$$
We can contrast it to the change in wages, 
$$
\text E\Delta W_{it} = \phi (\hat S_{i,t+1} - S_{i,t-1})
\approx 
\phi
S_{i,t-1}\Delta \tilde z_{mt} \tag{3}
$$
$$
\frac{\text E\Delta W_{it}}{S_{i,t-1}} 
\approx 
\phi
\Delta \tilde z_{mt} 
$$


## Things to check in the data
- [ ] access to ADMIN4
- [ ] are wages also top-coded in ADMIN4
- [ ] capital: fixed assets (not financial assets), tangible assets 
- [ ] EBITDA
- [ ] CEO wage, inclusive of taxes
- [ ] compute annual tax rates