# Discussion: How to Handle Firm Fixed Effects in Notation

## Context: Comment 25

The email feedback points out that the current model omits firm fixed effects, but the empirical implementation uses TWFE (two-way fixed effects). The question is whether to:
1. Include firm FE in the model and show it cancels via the diff-in-diff contrast
2. Keep the model simple and note that TWFE is application-specific

## Analysis

**Current situation:**
- The model in equation (1) is: $y_{it} = z_{m(i,t)} + e_{it}$
- No firm fixed effect $\alpha_i$ is included
- The empirical implementation (lines 243-257) mentions TWFE but focuses on industry-year demeaning

**The key insight:** When using the $\mathbf{w}'$ contrast (with $\mathbf{w}'\mathbf{1}=0$), a firm fixed effect **would difference out**. This is the fundamental reason why the method works even if firm FE exists.

## Recommendation for Notation

**Option: Introduce $\alpha_i$ explicitly and show it differences out**

### Best approach:

1. **In Section 2 (The Econometric Problem), line 84-86**, write:
   ```
   y_{it} = \alpha_i + z_{m(i,t)} + e_{it}
   ```
   where $\alpha_i$ is a firm fixed effect.

2. **Immediately after** (around line 130), when introducing the contrast, add:
   ```
   For any linear contrast with weights w ∈ ℝ^T and w'1 = 0, define
   Δy_i = w'y_i = w'α_i·1 + w'z_i + w'e_i = w'z_i + w'e_i = Δz_i + ε_i
   
   where the firm fixed effect cancels because w'1 = 0.
   ```

3. **In the Appendix (line 365-367)**, update the model setup:
   ```
   y_i = α_i·1 + z_i + e_i
   ```
   And note that all contrasts satisfy $\mathbf{w}'\mathbf{1}=0$, eliminating $\alpha_i$.

### Why this is better than omitting firm FE:

1. **Addresses Comment 25 directly**: Shows awareness that TWFE is standard and that the method accommodates it
2. **Clarifies the empirical implementation**: The industry-year demeaning removes industry trends, but firm FE could still matter
3. **Matches the TWFE literature** (Andrews 2008, Kline 2020) while showing the contribution is orthogonal
4. **Elegant notation**: The $\mathbf{w}'\mathbf{1}=0$ condition serves double duty—it defines a pre-post difference AND eliminates firm FE

### Alternative (weaker):

Just add a footnote around line 86 saying: "We omit firm fixed effects $\alpha_i$ from the notation because all our contrasts satisfy $\mathbf{w}'\mathbf{1}=0$, which differences them out. The empirical implementation uses industry-year demeaning to control for common trends."

**Recommendation: Include $\alpha_i$ and show it cancels.** It's more transparent, aligns with TWFE literature, and the $\mathbf{w}'\mathbf{1}=0$ property becomes more meaningful (it's not arbitrary—it's the firm-FE differencing condition).

---

## The Two-Step LSDV Procedure (Refined Approach)

Following the user's insight about two-step LSDV estimation:

### Step 1: Firm demeaning
For firm $i$ observed over $T$ periods, define the within-firm demeaning matrix:
$$\mathbf{M}_i = \mathbf{I}_T - \frac{1}{T}\mathbf{1}\mathbf{1}'$$

This gives demeaned outcomes:
$$\tilde{y}_{it} = y_{it} - \bar{y}_i = (z_{m(i,t)} - \bar{z}_i) + (e_{it} - \bar{e}_i)$$

### Step 2: CEO FE estimation on demeaned data
$$\tilde{y}_{it} = \tilde{z}_{m(i,t)} + \tilde{e}_{it}$$

## Does the demeaning matrix satisfy $\mathbf{w}'\mathbf{1}=0$?

**Yes!** The key property of $\mathbf{M}_i$ is:
$$\mathbf{M}_i \mathbf{1} = \mathbf{1} - \frac{1}{T}\mathbf{1}\mathbf{1}'\mathbf{1} = \mathbf{1} - \mathbf{1} = \mathbf{0}$$

So for **any** row of $\mathbf{M}_i$, call it $\mathbf{w}'$, we have $\mathbf{w}'\mathbf{1}=0$.

Moreover, when you apply a contrast to the **already-demeaned** outcomes, you're composing two zero-sum operations.

## Unified Framework

You can now present **three equivalent interpretations** of $\mathbf{w}'\mathbf{1}=0$:

### Interpretation 1: Diff-in-diff (event study)
- Pre-post contrast: $w_t = +1$ for post-period, $w_t = -1$ for pre-period
- Removes firm FE: $\mathbf{w}'\alpha_i\mathbf{1} = \alpha_i(\mathbf{w}'\mathbf{1}) = 0$
- Preserves CEO effect change: $\mathbf{w}'(\mathbf{z}_i) = \Delta z_i$

### Interpretation 2: LSDV within-transformation
- The demeaning matrix $\mathbf{M}_i$ projects onto the space orthogonal to $\mathbf{1}$
- Every row satisfies $\mathbf{w}'\mathbf{1}=0$
- Applied to $y_{it} = \alpha_i + z_{m(i,t)} + e_{it}$ gives $\tilde{y}_{it} = \tilde{z}_{m(i,t)} + \tilde{e}_{it}$

### Interpretation 3: Spell means from demeaned data
- After firm-demeaning, estimate CEO effects via spell means: $\hat{z}_{is} = \frac{1}{T_{is}}\sum_{t\in s}\tilde{y}_{it}$
- The projection matrix $\mathbf{P}$ applied to demeaned data inherits $\mathbf{P}\mathbf{1}=\mathbf{1}$
- Any contrast of spell means has $\mathbf{w}'\mathbf{1}=0$ built in

## Recommended Exposition

### In Section 2 (around line 84-88):

> Let firm $i$ in year $t$ have outcome
> $$y_{it} = \alpha_i + z_{m(i,t)} + e_{it}, \qquad \mathbb{E}[e_{it}|\{\alpha_i, z_{is}\}_{s=1}^T]=0$$
> where $\alpha_i$ is a firm fixed effect, $z_{m(i,t)}$ is the CEO effect, and $e_{it}$ is a shock. We assume strict exogeneity: shocks are mean-independent of the firm effect and the entire CEO path.

### Then around line 130 (when introducing contrasts):

> Our method applies to any research design that differences out the firm fixed effect. This includes (i) event studies that contrast pre- and post-transition outcomes, and (ii) LSDV estimation that first demeans outcomes within firms. Both approaches can be represented by a linear contrast with weights $\mathbf{w}\in\mathbb{R}^T$ satisfying $\mathbf{w}'\mathbf{1}=0$. Under this condition,
> $$\Delta y_i = \mathbf{w}'(\alpha_i\mathbf{1} + \mathbf{z}_i + \mathbf{e}_i) = \mathbf{w}'\mathbf{z}_i + \mathbf{w}'\mathbf{e}_i = \Delta z_i + \varepsilon_i$$
> where the firm effect cancels because $\mathbf{w}'\mathbf{1}=0$. 

### In the Appendix (around line 365-367):

> The model is
> $$\mathbf{y}_i = \alpha_i\mathbf{1} + \mathbf{z}_i + \mathbf{e}_i$$
> In practice, firm effects are removed either by explicit within-transformation (LSDV) or by taking pre-post differences. Both correspond to applying a matrix $\mathbf{M}$ (either the demeaning matrix or a difference operator) satisfying $\mathbf{M}\mathbf{1}=\mathbf{0}$. After this transformation, the model becomes
> $$\mathbf{M}\mathbf{y}_i = \mathbf{M}\mathbf{z}_i + \mathbf{M}\mathbf{e}_i$$
> and all subsequent analysis applies to the transformed data. For notational simplicity, we write $\mathbf{y}_i = \mathbf{z}_i + \mathbf{e}_i$ with the understanding that these are firm-demeaned quantities.

## Advantage of This Approach

1. **Transparent**: Shows firm FE exists but is irrelevant for your method
2. **General**: Covers both TWFE estimation and event studies  
3. **Addresses Comment 25**: Makes clear the relationship to TWFE without requiring simulation of firm FE
4. **Elegant**: The $\mathbf{w}'\mathbf{1}=0$ condition is no longer arbitrary—it's the **defining feature** of firm-FE-robust contrasts

This is cleaner than introducing $\alpha_i$ only to "drop it afterwards"—instead, you show it's eliminated by design through the zero-sum property.
