## Major Structural Issues

### 1. The Placebo Method Needs Earlier and Clearer Introduction

The paper buries its key innovation—the placebo-controlled approach—until Section 4.4. This is too late. Readers need to understand upfront that this is the paper's core methodological contribution.

Suggestion: Add a subsection in the Introduction (around page 3) briefly
explaining the placebo approach with a simple example. Something like: "To illustrate our approach, consider a firm with the same CEO from 2000-2010. We randomly assign a fake transition in 2005, creating two pseudo-CEOs. If estimated 'effects' for these pseudo-CEOs diverge substantially, this reveals the noise problem inherent in fixed effects estimation."

### 2. The Noise Problem Needs Quantification Earlier

The introduction mentions that three-quarters of effects are spurious but doesn't explain why this happens mechanically until Section 2.4.

Suggestion: Add a paragraph in Section 2.4 with the mathematical intuition: "When CEO $m$ manages firm $i$ for $T_{im}$ years, the estimated effect is $\hat{z}m = z_m + \frac{1}{T_{im}}\sum_t \epsilon_{it}$. With median tenure of 5 years and i.i.d. shocks, the noise-to-signal ratio is proportional to $1/\sqrt{T_{im}}$, making noise dominate for typical tenures."

### 3. Missing Literature Connection: Limited Mobility Bias

The paper doesn't sufficiently connect to the Andrews et al. (2008) limited mobility bias literature and Bonhomme et al. (2023) bias corrections.

Suggestion: Add a subsection 1.1 "Related Literature on Bias in Fixed Effects" that explicitly positions the placebo method as an alternative to existing bias-correction approaches when those methods fail due to extremely short panels.

### 4. The Division of Control Framework Needs Better Motivation

Section 2.1 introduces owner vs. manager control without explaining why this matters for identification.

Suggestion: Start Section 2 with: "Our model highlights a key institutional feature of private firms: the separation of strategic decisions (owner-controlled) from operational decisions (manager-controlled). This division allows us to validate our causal estimates by testing whether CEOs affect only variables under their control."

Also add a reference to Gandhi et al. (2020) who make a similar point: freely adjustable inputs are "bad controls", because they are determined by TFP, in our case manager skills.

### 5. Results Section Organization

The results jump between tables, figures, and different outcomes without a clear narrative flow.

Suggestion: Reorganize Section 5 as:

• 5.1 Production Function Estimates (establish basic parameters)
• 5.2 Raw Manager Effects and Their Distribution (show the problem)
• 5.3 The Placebo Test (reveal the noise)
• 5.4 True CEO Effects (main result)
• 5.5 Validation: Differential Effects on Manager vs Owner Variables (confirm causality)

### 6. Missing: Why Hungary?

The paper doesn't adequately explain why Hungarian data is ideal beyond completeness.

Suggestion: Add to Section 3: "Hungary provides three unique advantages: (1) mandatory registration of all directors, including CEOs, (2) no selection into coverage; all incorporated firms must report, and (3) a transition economy where CEO quality variation is likely larger than in mature markets, providing maximal statistical power."

### 7. Weak Connection Between Theory and Empirics

The model predicts $1/\chi$ amplification but this isn't well-connected to the empirical estimates.

Suggestion: Discuss the revenue, wagebill and material cost outcomes in light of the TFP increase (5.5 percent) and the estimated $\chi$ which causes magnification. Briefly mention again that we don't want to control for something that is caused by the CEO (Gandhi et al. 2020).

### 8. Missing Robustness Section

The paper mentions robustness checks but doesn't systematically present them.

Suggestion: Add an Appendix "Robustness" covering:

- Different outcome variables (log revenue, log wage bill, log materials)
- Sectoral differences in revenue function parameters
- Raw and placebo-controlled estimates in different subsamples: 
    1. after 2004
    2. including all firms with 2+ employees
    3. excluding founders and owners from event study
    4. only using giant components
    5. including all components incl very small ones

### 9. The Conclusion Undersells the Methodological Contribution

The conclusion emphasizes the substantive finding but should equally highlight the method.

Suggestion: Add a paragraph: "Our placebo-controlled approach offers a general solution for short-panel settings where traditional methods fail. This extends beyond CEOs to teachers, doctors, judges, or any setting where individual effects are estimated from limited observations. The method requires only the ability to construct credible placebo treatments."

### 10. Missing: Big-Picture Implications

The paper doesn't discuss the broader implications of the work. 

Suggestion: Add a final paragraph in the conclusion.

## Additional Edits from Krisztina's Patches

### 11. Change from Revenue to Surplus Notation Throughout

From krisztina1.patch: The theoretical framework should consistently use surplus ($s_{imst}$) rather than revenue ($r_{imst}$) notation, as surplus better captures the value creation we're measuring.

> Surplus is sometimes negative so, empirically, we always use revenue. I would stick to this notation. In the model, there is a constant share so I feel not much is lost and the flow is clearer. We may somewhere add that we ultimately care about the "value", which is driven by TFP. We already have language like

```latex
The surplus accruing to fixed factors—what owners and managers ultimately care about—equals revenue minus payments to variable inputs:
...

Manager value equals the skill difference scaled by $1/\chi$. This scaling reflects the leverage effect: a 1\% increase in manager skill generates a $(1/\chi)\%$ increase in revenue and, hence, surplus.
```
### 12. Make TFP Decomposition Explicit in Production Function

From krisztina1.patch: The production function should explicitly show how traditional TFP is decomposed into components.

> Great suggestion. I change the notation, $\Omega$ is TFP, residual TFP is the more noise-looking $\varepsilon$. 

```latex
Standard production function estimation combines the first three components into a single measure: $\Omega_{it} = A_i Z_m \varepsilon_{it}$, called total factor productivity (TFP). Our framework decomposes TFP into firm-specific advantages ($A_i$), manager-specific skill ($Z_m$), and residual productivity shocks ($\varepsilon_{it}$) to identify the manager's contribution.
```

### 13. Add Residualized Surplus Equation

From krisztina1.patch: The empirical strategy needs clearer exposition of the residualized surplus concept.

> My preferred interpretation is TFP. With the new notation, this is clearer. Once we multiply log revenue by $\chi$ and subtract contribution of fixed inputs, an estimate of $\omega$ remains.

```latex
After estimating the revenue function, we compute log total factor productivity by removing the contribution of capital from revenue:
\begin{equation}
\omega_{imst} = \hat{\chi} r_{imst} - \hat{\alpha} k_{it} - \hat{\mu}_{st} = z_m + a_i + \epsilon_{it}
\end{equation}

This measure of log TFP contains manager skill, firm effects, and residual productivity. In standard production function estimation, this entire term would be treated as a single TFP measure. Our decomposition separates the manager contribution from other sources of productivity.
```
### 14. Clarify Identification Assumption Mathematically

From krisztina1.patch: The identifying assumption should be stated more precisely using conditional expectation notation.

> Good idea but not quite sure how to do it with the fixed effects. $\lambda$ and $z$ are not variables, they are parameters.

### 15. Improve Event Study Pre-trend Description

From krisztina2.patch: The event study results section needs clearer description of pre-transition patterns and their interpretation.

> Our new Figure 1 shows this better: https://github.com/korenmiklos/ceo-value/blob/main/output/figure/event_study.pdf. All of the pretrends come from noise. But yes, we should explain this better.


---

## Suggested Edits to Address Identification Concerns

### 1. Section 4 (Estimation), around lines 204-207 - Clarify the identification assumption

Current text (lines 204-207):

> The key assumptions behind this estimating equation are: (1) all firms within a sector face the same prices, and (2) residual productivity $\tilde{\epsilon}_{it}$ is uncorrelated with owner and manager choices conditional on the fixed effects.

Suggested revision:

> The key assumptions behind this estimating equation are: (1) all firms within a sector face the same prices, and (2) for each manager, residual productivity $\tilde{\epsilon}_{it}$ has zero mean when averaged across all their firms and time periods: $E[\bar{\epsilon}m] = 0$ where $\bar{\epsilon}m = \frac{1}{N_m}\sum{i,t \in m} \tilde{\epsilon}{it}$ and the sum runs over all firm-year observations under manager $m$.
> 
> Crucially, we do not require random manager mobility or that residual productivity has zero mean at the point of CEO transition. Manager assignment can be endogenous: good managers may systematically move to firms experiencing positive shocks or be hired when firms anticipate improvements. We only require that these shocks average to zero over a manager's entire career. This is a weaker assumption than random assignment but still substantive: it rules out managers who systematically arrive at permanently improving (or declining) firms.


### 2. After line 217 - Add discussion of event study validation

Add new paragraph:

> The event study provides a diagnostic test for this identification assumption. Pre-trends in productivity before CEO transitions would suggest (though not prove) that the zero-mean assumption is violated. If productivity systematically rises before good CEOs arrive, we worry that the positive trend continues post-transition, violating $E[\bar{\epsilon}_m] = 0$. Conversely, the absence of pre-trends makes it harder to construct plausible endogeneity stories. While we cannot rule out contemporaneous shocks that coincide exactly with CEO changes (e.g., owners simultaneously firing the CEO and adopting new technology), such precise timing is less plausible than gradual changes that would manifest as pre-trends. Our event studies show no significant pre-trends, supporting but not proving our identification assumption.


---

## Notes and Placeholders to Address

### Krisztina's Comments to Address


### Additional Notes Throughout Paper

Lines 286-305: Figure description notes need to be converted to actual figure descriptions once figures are finalized.

Lines 307-309, 319-321: Notes about figure integration and interpretation need to be resolved.

Lines 377, 383-397: Appendix placeholders need actual content.

Lines 400-427: Robustness check placeholders need actual numbers from analysis.


### References to Complete

Line 68: Add citations for actual changes in investment, innovation from CEO event studies.

Line 70: Complete citations for Tervio (2008) and Gabaix & Landier (2008).

Line 76: Add two sentences about the Hungarian data.

Line 155: Add proper citation for Orban (2021).

### Table References

Line 161: Ensure table is properly referenced as `\ref{tab:sample}`

Line 182: Clean up reference to `\ref{tab:industry_stats}`

### General TODOs in Comments

Lines 51-63: These TODOs in comments should be removed or addressed before publication.

---
## Plan for Including Related Literature

### Papers to Add to Introduction (Section 1):

1. Quigley et al. (2022) - Add after discussing private vs public firms differences (around line
68-69):
 • They find CEO effects are 1.9× larger in private Swedish firms than public ones
 • Supports our focus on private firms where CEOs may have different impacts
2. Crossland & Hambrick (2011) - Could strengthen the institutional context discussion:
 • Shows how national institutions affect CEO discretion
 • Relevant for explaining Hungary's setting with limited CEO discretion in private firms


### Papers to Add to Literature Review Paragraph (lines 82-84):

3. Quigley & Hambrick (2015) - Add to show evolution of CEO effects:
 • Documents increasing CEO effects over time in US public firms
 • Contrasts with our finding that most variation is noise
4. Lippi & Schivardi (2014) - Very relevant for private firms:
 • Italian data showing family/government control reduces executive ability by ~10%
 • Directly relates to our owner-CEO division framework


### Papers to Reference in Model Section (Section 2):

5. Schulze & Zellweger (2021) - Add footnote around line 90:
 • Provides theoretical support for owner-manager division of control
 • Conceptual framework aligns with our model


### Papers to Reference in Results Discussion (Section 5):

6. Cornelli et al. (2013) - When discussing anticipation effects in event study:
 • Shows boards intervene more when performance deteriorates
 • Could explain pre-trends or lack thereof
7. Li et al. (2024) - When discussing gradual effects:
 • Shows CEO appointment timing affects performance
 • Explains why effects may build gradually


### Papers NOT to Include (avoid repetition):

• Bertrand & Schoar (2003) - Already cited extensively
• Bennedsen et al. (2007, 2020) - Already cited
• Abowd et al. (1999), Card et al. (2018) - Already cited
• Most other papers in the list are less directly relevant or would create redundancy

### Specific Integration Points:

1. Line 68-69: After discussing private firms, add:
This distinction is empirically important: \citet{quigley2022ceo} find CEO effects are nearly twice
as large in Swedish private firms compared to public ones, though our results suggest much of this
apparent effect is noise.

2. Line 84: Extend the methodology paragraph:
Recent work has documented apparently increasing CEO effects over time \citep{quigley2015has}, but
these studies do not account for the mechanical noise we identify. \citet{lippi2014corporate} find
that concentrated ownership in Italian firms distorts executive selection and reduces productivity
by 10%, providing additional motivation for our framework separating owner and CEO decisions.

3. Line 90 footnote: Add to existing footnote:
See also \citet{schulze2021property} for a theoretical framework on how property rights shape the
division between owner and manager value creation.

4. Around line 208 (event study discussion): Add:
The absence of strong pre-trends in our data contrasts with evidence from
\citet{cornelli2013monitoring} showing boards actively monitor and replace CEOs when performance
deteriorates, suggesting our transitions may be less performance-driven than in public firms.

5. Around line 333 (gradual effects discussion): Add:
The gradual buildup of effects aligns with \citet{li2024ceo} who show that CEO appointment timing
relative to fiscal cycles affects performance trajectories.