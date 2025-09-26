# Topic Summaries from ceo-value-almos.txt

## 1) Outcome variable and theory
We debated the appropriate left-hand-side outcome—revenue, EBITDA, operating surplus (“short-term profit”), and rent—anchored in a Cobb–Douglas production framework. The core point is that with certain inputs treated as fixed and others variable, the firm’s operating surplus equals revenue minus variable input payments (wage bill and materials). Under Cobb–Douglas with standard assumptions and log specification, surplus and revenue are proportional up to a constant that reflects income shares and markups, implying that empirical specifications using revenue or surplus should be closely related aside from the constant term. In practice, EBITDA can be negative and thus complicates transformations and subtraction-based constructions; this motivated preferring revenue as the main empirical outcome, with robustness checks that rotate among revenue, EBITDA, wage bill, and materials to demonstrate consistency of results and similar correlation structures. Conceptually, the question can be framed as the marginal product of managerial skill, with managerial capability modeled as Hicks-neutral (X-neutral) productivity shifters in the production function. We explicitly bracket corporate finance division issues (how the surplus is allocated across claimants) because they are not required for the production-side identification and because, under Cobb–Douglas, shares follow from elasticities. We also noted that observation coverage differs across outcomes (e.g., wage bill or EBITDA may be missing more often), further recommending revenue as the primary outcome for sample size and comparability. Finally, the conversation referenced table placement (e.g., “Table 3”) where alternative outcomes are shown to behave similarly, supporting the theoretical claim that, controlling for fixed inputs (fixed assets, intangibles, foreign ownership), rotations of the LHS produce highly similar estimates except for intercept shifts consistent with the proportionality logic.

## 2) Fixed vs variable inputs, model assumptions
We clarified what is held fixed versus variable in the model and estimation. Variable inputs (labor L and materials M) are the choice variables that solve a static profit-maximization problem conditional on prices (P), residual demand or markups, Hicks-neutral productivity (A, Z where Z is managerial capability), capital stock (K), and other fixed characteristics (firm FE, industry-year FE). Thus L and M are functions of prices and state variables: L = L(P, Ω, A, Z, K) and M = M(P, Ω, A, Z, K). Under Cobb–Douglas, several proportionalities follow (e.g., common dependence on the same composite surplus S), yielding that revenue and surplus differ by a multiplicative constant. Managerial capability Z is treated as X-neutral (Hicks-neutral) in the production block; we acknowledged this is an assumption that could be relaxed but is standard and convenient. The residual Ω is reserved for remaining shocks and factors not otherwise modeled; we discussed what plausibly remains in Ω after rich fixed effects and controls—measurement error and non-systematic shocks dominate in our data. In the empirical implementation, we condition on fixed assets and other fixed inputs, and we offload dynamic capital adjustment to governance/strategy rather than operations, making clear why capital is not modeled as an outcome of the CEO within the short-run production block. This separation aligns with the identification target (short-run operational effect of managerial skill holding slow-moving inputs fixed) and with institutional details (in concentrated ownership settings, owners often control capital budgeting, whereas CEOs manage operations). Finally, we emphasized that while the Cobb–Douglas-based proportionalities need not hold exactly in reality, they are a useful first-order organizing device and are empirically well supported in our rotations.

## 3) Practical estimation choices
We chose revenue as the primary outcome because EBITDA can be negative (log transformations and subtracting inputs become problematic), and wage-bill/material measures are not universally available across firms/years, shrinking samples. The theoretical link between revenue and surplus under Cobb–Douglas permits interpreting revenue-based estimates as scaled versions of surplus-based ones (up to constants and markups). We include controls for fixed inputs and characteristics—fixed assets, intangibles (dummy), and foreign ownership (dummy)—so that differences across LHS variants should manifest primarily in constant terms, not slope heterogeneity. We also flagged observation coverage differences: in practice, “revenue is often available” whereas wage bill or EBITDA may be missing, motivating revenue for statistical power and comparability. The discussion stressed placing variants (revenue, EBITDA, wage bill, materials) in a main table to illustrate overlapping estimates and near-identical correlation structures across specifications; this supports the claim that results are robust to outcome definition. We also discussed constant-term interpretation across these rotations and why they must differ. On the right-hand side, we maintain a parsimonious, theory-consistent structure (capital, manager FE, firm FE, industry-year FE as appropriate) rather than stacking ad hoc regressors that blur production versus finance. Finally, we explicitly downplay corporate finance allocation questions in the estimation stage (e.g., how rents are split across claimants) to avoid conflating identification of production-side manager effects with distributional choices. In summary, the design prioritizes: (i) revenue as LHS for coverage and stability, (ii) rotations to demonstrate robustness, (iii) fixed-input controls and fixed effects to align the empirical model with the short-run production logic, and (iv) clean interpretation of constants and coefficients across alternative LHS choices.

## 4) Estimable equation and identification
We settled on an estimable revenue equation that includes capital and fixed effects for firms and managers, consistent with a Cobb–Douglas production function in logs with Hicks-neutral manager effects. In the “Equation (6)” discussion, the LHS is revenue (not surplus), which better matches data realities and the Gandhi et al. guidance that revenue-based estimation with markup adjustments is appropriate when output quantities are not observed. Identification of the capital elasticity and the composite non-capital share relies on material shares (and, if needed, markup corrections). We noted that Gandhi et al. (the cited year to be checked) derive that, under certain conditions, the material expenditure share—appropriately adjusted for markups—identifies a key share parameter in revenue-based production functions. With firm and manager fixed effects included, identification of manager effects uses mobility across firms plus within-firm switches over time. Industry-year effects and other time-varying common shocks can be included to absorb macro/sectoral movements. The residual Ω captures remaining shocks orthogonal to controls; for causal interpretation of manager FE, we need that Ω be mean-independent of manager assignments conditional on the fixed effects, i.e., that only timing (dynamic endogeneity) remains as a threat, which we address with the event-study/placebo design. We emphasized ensuring that LaTeX/formula sections align with the implemented regression (revenue on the LHS) and cleaning up the notation so that alpha, gamma, and the implied non-capital share are consistently mapped from theory to estimation. Lastly, we discussed extracting and using the estimated fixed effects downstream (e.g., distributions, within-firm changes) and aligning these with the event-time analyses.

## 5) Noise and endogenous mobility
Two central threats were highlighted: (i) dynamic endogeneity/timing of manager changes and (ii) measurement noise. Because manager FE are commonly estimated from few observations (e.g., 3 years), noise is large, and noise propagates along mobility chains when building two-way FE networks. We emphasized that much of the raw correlation between manager and firm effects in two-way FE frameworks can be mechanical in the presence of high noise (akin to AKM worker–firm issues), and standard shrinkage corrections used in labor contexts may be insufficient when manager spells are short and chains are long. We clarified that the main endogeneity concern is event-time timing—firms tend to change CEOs in periods of declining performance or during coincident shocks (e.g., acquisitions, capital changes). The focus is not that “good managers go to good firms” per se (sorting is allowed in levels and absorbed by fixed effects) but that the switch timing may be correlated with transitory shocks. Hence, even after firm and manager FE, we may detect spurious pre-trends or attributed effects coming from Ω. We described how short spells and unbalanced panels aggravate these issues, and why we avoid certain cross-sectional correlational diagnostics (e.g., simple FE–FE correlations) which are dominated by noise. To isolate true managerial effects from noise/timing, we proposed a placebo-controlled event study that matches the empirical distribution of spell lengths and assigns pseudo-switches in non-switching windows, thereby quantifying the contribution of noise to observed event-time patterns. Our experience suggests a very large portion (on the order of ~80%) of the naïve effect disappears under placebo control, consistent with measurement noise and timing bias being first-order concerns.

## 6) Placebo-controlled event study
We designed an event-study where “treated” are real manager switches classified ex post as better/worse using FE-based ranks, and “controls” are placebo switches in firms that do not switch within a defined dry spell (e.g., 7 years). For the placebo, we randomly draw switch times to match the empirical distribution of spell lengths (including multiple placebo spells per firm as needed) and classify pseudo “better/worse” based on local averages, so the placebo treatment captures only noise and transitory Ω movements. Comparing real treated vs placebo-treated firms reveals two patterns: (1) pre-trends visible in naïve event studies largely vanish after placebo control (indicating timing/noise confounding), and (2) the post-switch effect magnitude drops substantially—our discussion mentions an order-of-magnitude reduction around 80%, though precise re-estimation is ongoing. The method removes mechanical selection on noise induced by conditioning on observed improvements. We also emphasized a second-moment diagnostic: the variance of revenue changes relative to an anchor date (e.g., t = −3) should exhibit a jump at the true switch if manager quality (ΔZ) changes, while placebo paths should not display such a structural break beyond noise accumulation. Implementation details include: ensuring the same event-time window for treated and placebo, respecting spell-length distributions, excluding real-switch windows from placebo sampling, and classifying better/worse consistently across real and pseudo events. The approach directly addresses dynamic endogeneity (timing) and noise, without relying on strong exclusion restrictions; it complements the FE-based identification from connected components by validating dynamic patterns and removing spurious anticipatory movements.

## 7) Measuring manager quality
We use two complementary constructions. First, from the two-way FE regression, we extract manager fixed effects (relative to a chosen normalization) and use within-firm changes to label a given switch as “better” or “worse” in event-time. This leverages information from an entire mobility network (connected component) so that a manager’s quality is informed by multiple firm–periods (not just a single firm’s episode). Second, for cases outside the giant component or where FE estimates are too noisy, we considered within-firm rankings based on local averages (before/after means), acknowledging higher susceptibility to noise. We discussed leave-one-out variants to avoid “using the same firm” to both define and evaluate manager quality, but computational feasibility is a challenge in large, sparse networks because removing a link can fragment components. We also considered weighting schemes that downweight path segments/switches with limited information (e.g., few paths or extremely short spells) to reduce noise propagation along chains. Importantly, we clarified that labeling “better” based on ex post performance mixes true quality with noise if not corrected by placebo; hence, the placebo-controlled event study is used to purge this mechanical selection. We also noted that using external observables (e.g., source firm size or multinational status) as proxies can complement FE-based measures but should be treated as separate specifications to avoid conflating constructs. The guiding principle is to triangulate manager quality using FE where credible, within-firm changes where FE are unavailable, and placebo calibration to quantify the extent of noise-induced misclassification.

## 8) Network and two-way fixed effects
We estimate manager and firm fixed effects on a bipartite mobility network and highlighted why connected components matter. Within a connected component, all managers and firms are comparable up to a normalization; across components, fixed effects are not comparable (distinct normalizations). We compute the largest ("giant") component using a Julia routine over the firm–manager edge list (CSV I/O) and validated connectivity with path-length checks (typical shortest paths ~6–12 steps; multiple disjoint paths exist). This network perspective clarifies how FE estimates aggregate “pairwise comparisons” along chains of switches: noisy comparisons can propagate, and short or singleton spells can inject substantial noise. We discussed the idea of downweighting paths with few or tenuous links and the practical observation that many managers have short spells (2–3 years), which exacerbates measurement error. Although the giant component provides the richest comparability, we emphasized that within-firm event-time analysis remains valid for firms outside the giant component, because it relies on within-firm dynamics rather than cross-component FE comparisons. We flagged the need for consistent use of FE-based labels across the sample: using FE labels for the giant component and within-firm labels elsewhere is convenient but inconsistent; better is to unify (e.g., within-firm labels for event-study classification everywhere, FE used for descriptive distributions), or implement feasible leave-one-out approximations that avoid contamination. Finally, we stressed reporting and inference: dependence along chains implies that standard errors need careful clustering or alternative dependence-robust approaches; naïvely treating observations as independent will understate uncertainty.

## 9) Within-firm vs cross-firm views
We distinguished two complementary identification lenses. The within-firm view uses changes around a CEO switch in the same firm (with firm FE netting out levels), focusing on dynamics and timing. This is well-suited for event-study plots and is applicable even for firms not in the giant component; it also enables uniform classification by normalizing the first observed CEO to zero within the firm and evaluating subsequent changes. The cross-firm (network) view uses two-way FE leveraging mobility chains to compare managers across different firms, enabling statements about manager quality distributions and broader rankings, but it is more sensitive to noise propagation and component-specific normalizations. Practically, we recommended: (i) implement event-study dynamics within firms (mitigating timing via placebo), and (ii) use network FE for descriptive distributions and cross-firm comparisons within the giant component, reporting precision caveats that depend on path counts and spell lengths. We discussed the pitfalls of mixing methods (e.g., using FE labels in the giant component but local labels elsewhere) and suggested either unifying the labeling rule or clearly bifurcating analyses. We also noted that singleton or very small components cannot support reliable cross-firm comparisons; however, they can still contribute to within-firm dynamics. Finally, we highlighted that interpreting cross-firm FE correlations can be misleading in the presence of heavy noise; thus, we deprioritize such diagnostics in favor of event-time placebo validation.

## 10) Governance and decision rights
We articulated why capital and other long-run strategic choices should be treated as largely outside the CEO’s short-run operational margin in concentrated ownership settings. Owners (especially in private, family, or closely held firms) retain authority over investment, product introductions, and marketing to varying degrees, while local plant/production managers (and sometimes CEOs) have clearer authority over hiring and day-to-day operations. We referenced Bloom et al.-style survey evidence indicating that family-owned firms systematically grant less local authority (e.g., −36% investment amounts, −20% marketing decision probability, −34% product introduction decision probability; hiring often remains local). This motivates separating “operations” (short-run, CEO-influenced) from “strategy” (long-run, owner-dominated), aligning our empirical model: treat capital and brand as predetermined fixed inputs in the short run, while allowing CEO skill to shift operations (Hicks-neutral Z). We acknowledged edge cases (e.g., dispersed public ownership where CEOs wield broad discretion; CEO-owner unification in small firms) but argued that our short-run framing remains coherent: even when the same person is owner and CEO, the identification target is the operational response conditional on capital being set. We further discussed that some CEO skill may include the ability to convince owners to allocate capital; we treat that as a distinct (long-run) channel deliberately excluded from the short-run event-study focus, to avoid conflating governance bargaining with operational productivity. The upshot is a clean partition: short-run production effects identifiable via within-firm dynamics vs long-run governance effects that are acknowledged but bracketed.

## 11) Lifecycle and composition
We explored firm and manager lifecycle dynamics as potential confounders and controls. A stylized story: founder-CEOs (e.g., “Géza”) run a firm for ~20 years; as they age, operational intensity declines, prompting either a manager change or exit. Such patterns can generate pre-trends unrelated to manager quality per se. We suggested controlling for firm age and its square (included in current specs), and we experimented with manager lifecycle profiles (e.g., tenure/age controls), though we avoid using them directly in the event study to prevent mechanical effects when a new manager’s tenure resets to one. We recognized that many small Hungarian firms have CEO-owners, resulting in fewer CEO switches; therefore, the switching sample likely over-represents firms where CEO and owner are distinct, which should be transparently documented. We proposed moving some composition-heavy descriptive tables to the appendix while highlighting more informative distributions/plots (e.g., histograms of firm size classes, shares of owner-CEOs) in the main text. The lifecycle discussion also relates to robustness: some results could be sensitive to firm age distributions; hence, stratified analyses (e.g., by size/age bins) and explicit controls help. Finally, we reiterated that our identification aims at short-run operational changes around switches; lifecycle-induced long-run drifts are handled as controls or shown to be orthogonal in placebo-adjusted dynamics.

## 12) Presentation and robustness
We emphasized clear table/figure organization: place the main outcome rotations (revenue, EBITDA, wage bill, materials) together to demonstrate similarity, move highly compositional tables to the appendix, and foreground event-study figures with both naïve and placebo-controlled panels showing the disappearance of pre-trends and the attenuation of post effects. For Table 4-type correlation panels (e.g., manager FE vs inputs), emphasize economically interpretable correlations and de-emphasize those dominated by noise. We proposed second-moment diagnostics (variance jumps at switch) as complementary evidence of ΔZ beyond mean comparisons. On inference, we cautioned about dependence along network chains and within firms; cluster choices (e.g., firm, manager, component) and possibly multi-way clustering should be considered, noting that standard practice often under-reports such complexities. We also discussed constant-term differences across LHS rotations and how to interpret them (consistent with Cobb–Douglas proportionality). Robustness includes: rotating outcomes, stratifying by firm size/industry, and documenting coverage differences (why revenue yields the largest usable sample). Finally, we flagged LaTeX/notation hygiene (ensure the estimable equation uses revenue on LHS; fix references/dates like Gandhi et al.), and we recommended presenting both within-firm distributions (e.g., average improvement of second CEO vs first) and network-level FE distributions, with clear caveats where cross-component comparability does not hold.

## 13) Project management and extensions
We concluded with practical to-dos and potential extensions. Immediate tasks: (i) make the LaTeX consistent with the implemented revenue-based estimation (Equation 6 LHS), (ii) unify the use of manager quality labels across samples (avoid mixing giant-component FE labels with local labels elsewhere, or clearly separate analyses), (iii) finalize the placebo event-study implementation (spell-length matching, exclusion of true switch windows, multiple placebo spells, consistent better/worse classification), (iv) re-check key citations (e.g., Gandhi et al. year), and (v) plan inference (clustering strategy acknowledging network dependence). Scope-wise, the paper is unlikely to fit into a short note; careful writing and figure/table curation are needed. As a related project, we sketched a privatization (SOE→private) event design leveraging existing code, classifying incoming managers as internal promotions, transfers from other SOEs, or external hires (incl. private/foreign), and running parallel tables/figures analogous to the export design. Timeline-wise, we proposed finishing the core tables/figures first, then iterating on model intuition and notation. The overarching message to the reader: most naïve manager effects are spurious due to noise/timing; after placebo control, a smaller but meaningful causal manager effect remains, consistent with theory and external quasi-experimental benchmarks.

---

# Summary of Research Meeting: CEO Value Project (September 17, 2025)

## Research Question and Context

The team discussed a project estimating the causal effect of CEO quality on firm performance using a novel placebo-controlled event study design. The core research question focuses on identifying true managerial effects versus spurious correlations in CEO transitions. The project uses comprehensive Hungarian administrative data covering 1992-2022 with approximately 1M firms and 1M managers.

## Literature Positioning and Data Scope

### Expanding Beyond Existing Literature
The team agreed their key contribution is extending CEO effect analysis to the entire universe of firms, not just large public companies:
- Traditional studies (Strategic Management Journal, business literature) focus on public firms with average sizes of 700-800 employees
- Their dataset covers all firms, with average firm size around 5 employees after applying the minimum threshold
- Connected component requirement doesn't undermine this contribution since it still captures orders of magnitude more firms than previous studies

### Private vs. Public Firm Distinction
The team decided against emphasizing private vs. public ownership as a key distinction:
- Most firms globally, including public ones, have concentrated ownership
- The civil law vs. common law distinction is more relevant
- Hungary has only ~30 public firms versus hundreds of thousands of private firms
- The "universe of firms" framing is more compelling than ownership structure

## Identification Strategy and Econometric Methods

### Production Function Estimation
The team discussed combining steps 2 and 3 of their estimation procedure:
- Step 2: Estimate production function coefficients (α, β) controlling for capital, labor, materials
- Step 3: Estimate manager and firm fixed effects on residualized TFP
- **Decision**: Combine these steps for presentation clarity while maintaining same numerical results

### Control Variables and Specification
Debate over including additional controls (foreign ownership, state ownership, intangible assets):
- **Revenue function estimation**: Include all relevant controls to precisely estimate capital coefficient α
- **Fixed effects regression**: Question whether to maintain these controls in TFP analysis
- **Resolution**: Default specification excludes additional controls in TFP regression (cleaner "TFP" interpretation), with robustness check including them

### Connected Component Analysis
**Current approach**: Focus on largest connected component of managers
**Alternative considered**: Include all firms with sufficient mobility
- Pros of universal approach: More generalizable, aligns with "universe of firms" narrative
- Cons: Potentially noisier estimates due to limited mobility
- **Decision**: Test universal approach; if results are reasonable, use as main specification

## Random Mobility and Identification Assumptions

### Theoretical Foundation
The team clarified what "random mobility" means in the AKM framework:
- Not that managers move randomly, but that error terms are orthogonal to mobility patterns
- Equivalent to standard OLS exogeneity assumption: E[ε|manager transitions] = 0
- This is a strong assumption requiring errors to be orthogonal across all time periods

### Event Study as Test
The event study serves as a test of the random mobility assumption:
- Pre-trends would indicate violations of exogeneity
- Flat post-trends support the identification strategy
- **Key insight**: "We cannot reject random mobility" rather than "we assume random mobility"

### The Small Sample Bias Problem
Critical methodological insight emerged about why placebo control is necessary:

**The Problem**: When estimating manager fixed effects with limited observations per manager, the estimated fixed effect ẑᵢ contains both:
- True manager skill (zᵢ)  
- Average error term over manager's tenure (ε̄ᵢ)

**Mathematical Expression**: ẑᵢ = zᵢ + ε̄ᵢ

**Bias Mechanism**: When analyzing TFP changes around CEO transitions:
- Left-hand side (TFP): Contains error term εᵢₜ
- Right-hand side (manager quality): Contains ε̄ᵢ from fixed effect estimation
- These create spurious correlation even without true managerial effects

**Solution**: Placebo transitions experience identical data generating process (same firms, same error structure) but without true managerial changes, allowing isolation of bias component.

## Empirical Results and Interpretation

### Event Study Findings
The placebo-controlled design reveals:
- Raw CEO effect: ~22.5% revenue impact
- Placebo effect: ~17% (measuring pure bias/noise)
- **True causal effect**: 5.5% (25% of raw correlation)
- 75% of apparent CEO effects are spurious

### Pre-trends in Results
The team discussed why pre-trends appear in both actual and placebo transitions:

**Actual transitions**: Pre-trends arise because:
1. Conditioning on TFP growth creates mechanical correlation
2. Variable spell lengths create apparent trends when only short-term changes observed
3. Persistence in error terms

**Placebo transitions**: Similar pre-trends validate the identification strategy by showing same bias mechanisms operate

### Capital and Input Responses
Event study shows minimal capital adjustment around CEO transitions:
- Supports assumption of limited managerial discretion over capital
- Justifies treating capital as "slowly moving" input
- Provides conservative lower bound on true managerial effects

## Methodological Contributions

### Placebo-Controlled Design
**Innovation**: Adapting medical trial methodology to CEO analysis
- Traditional approaches: Show placebo has no effect (rejoice)
- Their approach: Placebo has effect (bias), use it to control for noise
- **Key advantage**: Same data generating process ensures proper bias correction

### Connection to Labor Economics Literature
The team identified their contribution relative to matched employer-employee studies:
- **Similar problems**: Limited mobility bias, small sample bias
- **Greater severity**: Only one manager per firm (vs. multiple workers per firm)
- **Different focus**: Manager effects on productivity (vs. wage inequality)
- **Methodological advance**: Placebo control addresses bias that labor literature acknowledges but doesn't correct

## Sample Restrictions and Data Decisions

### Employment Threshold
**Current**: Firms must reach 5+ employees at some point
**Rationale**: Excludes pure "non-employer" businesses while retaining economically meaningful small firms

### State-Owned and Large Firms
**Decision**: Reintroduce both categories with appropriate controls
- Maintains larger connected component
- Include state ownership dummy variable
- Enables broader generalizability claims

### Industry and Time Variation
**Capital coefficients**: Estimated separately by industry (TEAOR08 classification)
**Time stability**: Considered but rejected time-varying coefficients
- Post-2004 sample shows similar results with cleaner patterns
- Maintains power from full 30-year panel

## Variance Analysis and Second Moments

The team noted their analysis captures both mean and variance effects:
- Post-transition variance increase indicates heterogeneous firm responses
- Aligns with theoretical predictions about manager-firm matching
- Provides richer understanding than pure mean effects

## Writing and Presentation Strategy

### Key Messages to Emphasize
1. **Universe of firms**: Comprehensive coverage beyond typical large-firm samples
2. **Methodological rigor**: Careful treatment of capital vs. managerial decisions  
3. **Placebo innovation**: Novel bias correction approach
4. **Practical magnitude**: True CEO effects are much smaller than commonly believed

### Paper Organization
**Target length**: 6000 words
**Structure priority**: 
- Clear exposition of identification strategy
- Intuitive explanation of placebo methodology
- Robust empirical results supporting key claims

## Technical Next Steps Identified

1. **Run analysis on full sample** (excluding only singletons) to test generalizability
2. **Create consistent figure formatting** with unified scales and color schemes
3. **Estimate specifications with/without additional controls** for robustness
4. **Compute standard errors** for event study coefficients
5. **Prepare industry-level analysis** for appendix tables

## Timeline and Project Management

**Deadline pressure**: September 30 target for three papers including this one
**Coordination approach**: 
- Weekly check-ins
- Clear task division to avoid conflicts
- Focus on completing analysis before refining presentation

The discussion revealed sophisticated understanding of both the methodological challenges in CEO effect estimation and innovative solutions through placebo-controlled design. The team demonstrated strong grasp of identification assumptions and their testable implications while positioning their work as a significant advance in both scope and methodology relative to existing literature.

---

# Research Progress Discussion (September 25, 2025)

## Event Study Pattern Analysis

### Pre-trends Across Different Transition Types
The team examined event study results across multiple transition types and consistently found pre-trends in firm performance before CEO changes. This pattern appears in:
- **Founder-to-non-founder transitions**: Pre-trends of approximately 11-13%
- **Non-founder-to-non-founder transitions**: Similar patterns observed
- **Material/input outcomes**: Consistent pre-trending across different outcome variables

**Key insight**: The presence of pre-trends in both actual and placebo transitions validates the identification strategy by showing that the same bias mechanisms operate in both cases. This is not evidence against random mobility but rather confirms that timing-related selection bias is captured and corrected by the placebo design.

### Robustness Across Outcome Variables
Event study patterns show remarkable consistency across different outcome measures:
- **TFP (Total Factor Productivity)**: Shows clear CEO transition effects
- **Material inputs**: Similar response patterns to CEO changes
- **Wage bill**: Consistent with productivity-driven input adjustments
- **Revenue**: Aligns with theoretical predictions about scale effects

This consistency supports the theoretical framework where better managers increase productivity, leading firms to optimally scale up all inputs proportionally.

## Variance Decomposition Methodology

### Theoretical Foundation
The team developed a sophisticated approach to measure how much CEO transitions contribute to firm performance variance over time. The key innovation is extending the placebo control method to second moments (variance) rather than just first moments (means).

**Core formula**: The variance of cumulative TFP growth from firm age 2 to age A equals:
- Base variance accumulation: σ²ₑ × η(A) [where η(A) captures age-specific variance growth]
- Plus CEO transition effects: K × σ²ᵧ [where K = number of CEO transitions, σ²ᵧ = variance contribution per transition]

### Methodological Innovation
**Age-specific controls**: Unlike naive ANOVA approaches, this method controls for the natural tendency of firm performance variance to increase with age due to accumulated shocks. The placebo design ensures that treatment and control groups have identical variance evolution absent true CEO effects.

**Event-time validation**: The method shows a clear structural break in variance at the time of CEO transition (year 0), with variance jumping from ~0.015 at year -1 to ~0.030 at year 0, while counterfactual variance grows smoothly.

### Empirical Findings
**Naive ANOVA overstatement**: Traditional within-firm R-squared analysis suggests managers explain 54-62% of performance variance. After placebo adjustment, this drops to 39-46%, with the corrected share declining as firms age (since early CEO impacts are relatively more important).

**Quantitative contribution**: At firm age 10, CEO transitions explain approximately 27% of total TFP variance - a substantial but not overwhelming contribution that is much smaller than naive estimates suggest.

## Back-of-the-Envelope Calculations

### Multiple CEO Transitions
The team discussed how to extend the analysis beyond the clean single-transition event study to firms with multiple CEO changes. The proposed approach:
- Estimate per-transition variance contribution (φ) from single-transition sample
- Apply multiplicatively: Total CEO contribution = K × φ, where K = number of transitions
- Use age profiles η(A) estimated from control firms to capture baseline variance growth

**Methodological note**: This requires assuming that CEO transition effects are approximately constant across transitions and additive in variance space - simplifications that enable quantification but may miss heterogeneous effects of second vs. third transitions.

### Practical Implementation
The back-of-the-envelope calculation allows translating the event study estimates (which focus on single, clean transitions) to statements about the broader population of firms with varying numbers of CEO changes over their lifecycle.

## Technical Methodological Details

### Placebo Matching Process
The placebo construction maintains exact matching on:
- **Birth cohort**: Control firms born in same year as treatment firms  
- **Event window length**: Identical observation periods (-2 to +3 years, etc.)
- **Sample composition**: 9:1 ratio of control to treatment observations for statistical precision
- **Exclusion criteria**: Placebo firms cannot have actual CEO changes during their placebo window

### Sample Construction and Balance
**Unbalanced panel handling**: The analysis accommodates firms with different observation lengths rather than requiring balanced panels, which would exclude many smaller firms with shorter lifespans. The placebo design ensures that any bias from unbalanced observation is identical between treatment and control groups.

**Multiple event windows**: Firms with multiple CEO transitions appear multiple times in the sample with separate firm fixed effects for each event window, allowing identification of distinct transition effects while properly clustering standard errors by firm.

### Standard Error Considerations
**Network dependence**: The team acknowledges but does not fully resolve the challenge that standard errors should account for dependence along manager mobility chains in the two-way fixed effects network. This remains an area for methodological development.

## Paper Organization and Exhibit Planning

### Target Exhibit Structure
**5 exhibits maximum**, each fitting on one page:
1. **Table 1**: Descriptive statistics of CEO transitions (timing, frequency, spell lengths) 
2. **Figure 1**: Placebo-controlled event study showing bias correction (4 panels)
3. **Figure 2**: Event study results across different transition types and samples (4 panels)  
4. **Figure 3**: Variance decomposition showing age profiles and CEO contributions (2+ panels)
5. **Remaining exhibit**: Additional robustness or methodological validation

### Writing Strategy
**Target length**: 6,000 words requiring careful prioritization
**Key messages**: 
- Comprehensive coverage beyond typical large-firm studies
- Methodological innovation through placebo-controlled design  
- Quantitative finding that true CEO effects are much smaller than commonly believed (75% of apparent effects are spurious)

**Presentation philosophy**: Write comprehensively first, then edit down rather than trying to write concisely from the start. This ensures important technical details are not lost in the editing process.

## Project Management and Timeline

### Task Allocation
**Immediate priorities**:
- **Model section**: Continue refining theoretical exposition and connection to empirical specification
- **Methodology section**: Document placebo construction and variance decomposition procedures  
- **Results organization**: Finalize which specific estimates to highlight as main findings
- **Figure preparation**: Convert analysis code outputs into publication-ready exhibits

### Coordination Approach
**Daily check-ins** during intensive writing period, with clear division of labor to avoid editing conflicts. The team emphasized finishing the analytical work completely before focusing on presentation refinements.

---

## Variance Decomposition Analysis

### Empirical Implementation

The ANOVA analysis uses a placebo-controlled approach similar to the mean effect analysis:

**Sample Construction**: The analysis focuses on firms transitioning between founder and non-founder CEOs, tracking TFP growth relative to firm age 2 as the baseline. This normalizes for initial conditions while allowing variance to evolve naturally with firm age.

**Placebo Control**: Placebo transitions are assigned to non-switching firms, matching the empirical distribution of CEO spell lengths. This creates a control group experiencing identical data generating processes except for actual managerial changes.

**Variance Estimation Process**:
1. Calculate TFP growth since age 2 for all firms
2. Estimate mean effects (ATET) for actual versus placebo transitions
3. Compute squared deviations after removing mean effects to isolate variance changes
4. Adjust for age-specific pre-trends in variance between treatment and control groups
5. Decompose total variance into counterfactual and treatment-induced components

### Key Methodological Innovations

**Second-Order Treatment Effects**: The analysis estimates not just first-order effects on levels but second-order effects on squared outcomes. The additional variance from treatment equals the second-order average treatment effect minus the squared first-order effect.

**Age-Specific Adjustments**: Since variance naturally grows with firm age due to accumulated shocks, the analysis controls for age-specific variance patterns. Pre-treatment differences in variance growth rates between eventually-treated and control firms are netted out to isolate treatment-induced variance changes.

**Parallel Trends in Second Moments**: The identification requires parallel trends not just in levels but also in variances. The analysis tests whether, absent treatment, the variance evolution would be similar between treatment and control groups. Finding similar pre-trends in both actual and placebo samples validates this assumption.

### Empirical Findings

The variance decomposition reveals several key patterns:

**Variance by Firm Age**: Total variance of TFP growth increases substantially with firm age, from zero at age 2 (by construction) to approximately 0.035 by age 12. The counterfactual variance (without CEO changes) follows a similar but consistently lower trajectory, reaching about 0.022 at age 12.

**Treatment-Induced Variance**: CEO transitions add meaningful variance beyond natural accumulation. At age 4, the total variance is 0.024 while counterfactual variance is about 0.013. By age 12, total variance reaches 0.035 compared to counterfactual variance of 0.022, indicating persistent additional variance from managerial heterogeneity.

**Event-Time Dynamics**: Panel B shows a dramatic structural break at CEO transition timing (year 0). Pre-transition variance evolves smoothly from about 0.010 at year -5 to 0.015 at year -1. At transition, total variance jumps sharply to 0.030 and remains elevated through year +5 (around 0.032), while counterfactual variance grows gradually to only 0.020, confirming heterogeneous managerial impacts.

**Comparison with Naive ANOVA**: Traditional ANOVA approaches substantially overstate managerial contributions. The naive within-firm R-squared suggests managers explain 54-62% of variance (0.544 at age 4, rising to 0.620-0.625 at ages 8-12). After placebo adjustment, the true contribution drops to 39-46% (0.464 at age 4, declining to 0.391-0.397 at ages 8-12). The adjusted share decreases with firm age, suggesting early-stage CEO impacts are relatively more important.


---
