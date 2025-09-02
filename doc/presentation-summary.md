# Estimating the Value of CEOs in Privately Held Businesses

**REFLEX Workshop, September 2, 2025**
Miklós Koren (with Krisztina Orbán, Bálint Szilágyi, Álmos Telegdy, András Vereckei)



## Motivation

* We ask: *What is the marginal product of a CEO?*
* Management clearly matters: consulting interventions, training programs, and event studies all show impact.
* But almost all the evidence comes from public firms in rich countries.
* We shift focus to **private firms**, where dynamics differ.



## What About Privately Held Firms?

* Private firms differ from public firms in three ways:

  1. **Data limitations**: scarce on compensation, decisions, financials.
  2. **Owner control**: owners often retain strong influence.
  3. **Noise**: small firms dominate, their data is messy.
* Our contribution is to tackle these issues directly in a large-scale, long-run dataset.



## This Paper

* Three contributions:

  1. A model of CEO effects that accounts for **owner-chosen inputs**.
  2. New data: over 1 million firms, 1 million CEOs, Hungary 1992–2022.
  3. A placebo-controlled event study to separate true CEO effects from noise.



## Preview of Results

* If you just compare firms: "good" vs "bad" CEOs appear to differ by **22.5%** in performance.
* Placebo test shows **17% is noise**.
* The *true causal CEO effect*: **5.5%**.
* So three-quarters of the apparent variation is spurious.



## Roadmap

1. Theoretical Framework
2. Data
3. Estimation
4. Results
5. Conclusion and Future Work



## Theoretical Framework

### Production Structure

* Start with a Cobb–Douglas production function:

  * Firm combines **fixed inputs** (capital, organizational capital) chosen by the owner.
  * **Variable inputs** (labor, materials) chosen by the CEO.
  * CEO skill $Z_m$ scales productivity.
  * Residual TFP captures everything we cannot measure.

<digression>  
I like to joke that this residual is our measure of ignorance: all the stuff we didn’t model.  
</digression>

### Optimization Problem

* The manager maximizes profit given the owner’s fixed inputs.
* First-order conditions determine optimal scale of the firm.
* Surplus goes partly to fixed factors.

### Surplus = Rent to Fixed Factors

* In Cobb–Douglas, surplus is a constant fraction of revenue.
* Chi (χ) is the surplus share, typically 10–20%.
* A 1% better CEO increases surplus by much more than 1% because inputs are scalable.

### Estimable Equation

* After taking logs and substitutions: revenue is linear in capital, CEO skill, firm FE, sector-time FE, and residual.
* Assumptions:

  1. Same prices in sector.
  2. Residual TFP uncorrelated with owner and manager choices.
  3. Owner and manager choices may be arbitrarily correlated.
* This makes estimation feasible with two-way fixed effects.



## Data

### Why Hungary?

* Rich administrative data:

  * All incorporated businesses.
  * Mandatory CEO registration.
  * 30+ years of coverage.
* Economic background:

  * Transition economy in the 1990s.
  * EU accession in 2004.
  * Mix of domestic and foreign firms.

<digression>  
When I first saw this dataset, I thought we were sitting on a goldmine. Even though it’s only 30 years, in this field it’s very rare to have universal coverage.  
</digression>

### Data Sources

* Firm registry: CEO appointments, ownership, complete since 1992.
* Balance sheet data: revenues, costs, assets, 1980–2022.
* About 10.2 million firm-years.

### Data Cleaning

* Defining a firm: legal entities tracked via tax IDs. Mostly stable, but sometimes IDs reused.
* Defining a CEO:

  * Before 2013 no numerical IDs. Used names, addresses, mother’s name, birthdate.
  * Entity resolution to merge records.
  * Managing director title sometimes missing → imputed.

<digression>  
Our data engineer once said: in this dataset, *everything and its opposite is true*. For example, tax IDs are unique—except when they’re not.  
</digression>

### Sample Construction

* Exclusions:

  * Firms with >2 CEOs per year or >6 over lifetime.
  * First-year firms (incomplete data).
  * State-owned firms.
  * Mining and finance (special balance sheets).
  * Firms that never reach 5 employees.

### CEO Characteristics

* 95% Hungarian names, 73% male.
* 69% are founders.
* 18% manage multiple firms.
* Large connected component: 26,000+ managers.

### Temporal Patterns

* From 1992 to 2022:

  * Over 1 million distinct firms.
  * 345,000+ CEOs.
  * Growth after transition, then plateau.

### Turnover Patterns

* 80% of firm-years have a single CEO.
* Most spells last 4+ years.
* Placebo spells mimic the length distribution well.



## Estimation

### Estimation Steps

1. Estimate χ (surplus share).
2. Estimate revenue function with rich FEs.
3. Estimate firm and manager fixed effects in the largest connected component.
4. Check dynamics via event study.

### Identification Challenges

* Residual TFP may correlate with manager changes (reverse causality).
* Firm and manager FEs only interpretable relative to a baseline group.
* Small-sample noise is severe.

### Placebo Control Solution

* Generate placebo CEO changes in firms with long CEO tenures.
* Hazard function estimated from real turnover (\~20% per year).
* Apply same estimation to placebo group → filters out noise.



## Results

### Manager Fixed Effects

* Wide dispersion in estimated CEO skills: 25th–75th percentile implies 24.6% productivity difference.
* But event study shows much of this is noise.

### Event Study

* Average TFP dips slightly before CEO change.
* Variance rises sharply after CEO change → consistent with real changes, not just noise.

### Raw vs Placebo-Controlled

* Without placebo: “good” CEOs raise TFP by \~22%, “bad” CEOs lower by \~−1%.
* With placebo: 75% of this evaporates. True effect \~5%.

### Correlations with Outcomes

* Better CEOs → higher sales, wage bills, material usage.
* Small effects on fixed assets and foreign ownership.
* Gradual growth in intangibles under good CEOs.
* Immediate spike in material usage under good CEOs.



## Guidance for Empirical Research

* Don’t trust raw manager fixed effects: mostly noise.
* Better practices:

  * Use observable CEO characteristics (education, work experience, foreign name, cohort selectiveness).
  * Put manager quality only on LHS (never RHS).
  * Always implement placebo checks.



## Conclusion

* Modeled CEO value in private firms.
* Used full Hungarian corporate universe.
* Developed placebo-controlled method.
* Found: 75% of apparent CEO effects are spurious.
* Better managers expand firms by immediately hiring/buying more, and gradually attract intangible assets.



## Appendix (Selected Points)

* Owners vs managers:

  * Owners control capital, industry, location, CEO hiring/firing.
  * Managers control labor, materials, daily operations.
* Industry breakdown: surplus shares vary, highest in finance (48%), lowest in wholesale/retail/transport (6.4%).
* Placebo spells match actual turnover quite well.



# Questions, Answers, and Promises to Follow Up

### Questions and Responses

* **How does timing affect causality?**

  * Pre-trends disappear after placebo control. The timing checks support causality.
* **What about EU accession or different periods?**

  * Suggested splitting sample pre- and post-2004 to check stability.
* **What about the first vs later CEOs?**

  * Mentioned descriptives: first→second CEO increases TFP \~12%, second→third \~10%, after that no difference.
* **Could owner decisions drive observed CEO effects?**

  * Possibly; cannot fully disentangle owner-CEO joint decisions. But timing evidence suggests CEOs drive immediate changes.
* **What about foreign CEOs?**

  * Previewed separate work: benefits of foreign acquisitions in Hungary come only when foreign CEOs replace domestic ones.

# Promises / Follow-Ups


## 1. Founders vs. Non-Founders

**What you said**: 69% of CEOs are founders (slide 19). In the transcript, you mentioned: *“Maybe we can do this first, second, third CEO without the founders and see what happens then.”*

**Issue framing**:

* Current results pool founder-CEOs and successor-CEOs together.
* Founders may differ systematically from hired successors in terms of skills, motivations, or owner overlap.
* The estimated CEO effects might be confounded if founder periods dominate the sample.
* **Issue**: Results need to be checked excluding founder CEOs to confirm that the measured 5% effect is not driven by founder dynamics.



## 2. Connected Component Representativeness

**What you said**: Slides (20) show \~26,000 managers in the largest connected component. Transcript: *“So we’re going to treat this as a kind of random subset of the sample. And actually, just looking at this table reminds me that we can actually check this. So we can do like balance tests and see whether this is a representative sample of the entire universe of firms.”*

**Issue framing**:

* Estimation relies on the largest connected component (Abowd-style TWFE).
* Not clear if this subset is representative of the universe of Hungarian firms.
* **Issue**: Must test balance between the connected component and the full sample to verify external validity of CEO effects.



## 3. Exclusion Thresholds for Many CEO Changes

**What you said**: Slide 17 excludes firms with >6 CEOs in their lifetime. Transcript: *“There are some companies that … have like 300 CEOs or 30. But I think we could experiment with different reasonable values, 10, 12, 2, and then see what happens.”*

**Issue framing**:

* Current cutoff is somewhat arbitrary.
* Noise from extreme firms may still bias results.
* **Issue**: Sensitivity analysis with alternative thresholds (e.g., 2, 10, 12 CEOs) needed to confirm robustness of findings.



## 4. Transition Years (1990s vs Post-EU Accession)

**What you said**: Slide 15 sets start in 1992. Transcript: *“One thing that we should, and I haven’t done yet, is to maybe start in after the EU accession, which we could think that kind of solidified as kind of a market economy before that … the 1990s was like the Wild West.”*

**Issue framing**:

* Hungary underwent structural change 1990–2004.
* CEO roles and measurement of productivity may differ across periods.
* **Issue**: Split sample into pre-2004 and post-2004 (or post-2010) to check robustness of CEO effect estimates.


## 5. Exclude Public Firms Explicitly

* Transcript: *“This reminds me that we should exclude public firms, but there are very few.”*
* You promised to make sure public companies (few hundred in Hungary) are fully excluded from the analysis.

## 6. Check First vs Second vs Third CEO More Carefully

* Transcript: *“One thing that we did see … the first, second, and third CEO, there’s a difference … we can look deeper into this, how you are doing in the CEO timeline.”*
* You said you would explore how effects vary across the CEO sequence beyond just average effects.

## 7. Experiment with Keeping vs Excluding Firms with Two CEOs

* Slide 17: exclusion criteria.
* Transcript: *“It’s quite often the case that they have two CEOs … we exclude those that have more. There are very few. We keep the two.”*
* You implied you may revisit whether keeping dual-CEO firms is appropriate.

## 8. Balance Tests for Noise Distribution in Placebo vs Actual Spells

* Slides (47) already show spell length distributions.
* Transcript: *“I think some of it can be tested, but for now, we’re just assuming it.”* (re placebo noise distribution)
* You said you should test the comparability of placebo vs actual turnover firms, not just assume it.

