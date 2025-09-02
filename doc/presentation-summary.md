## Structured Summary of Talk: Estimating the Value of CEOs in Privately Held Businesses

### Motivation (Slides 3–5)

* Research question: what is the marginal product of a CEO in privately held firms?
* Existing evidence:

  * Management practices improve firm performance (Bloom et al., Giorcelli, etc.).
  * CEO changes in public firms show measurable effects (Bertrand & Schoar, Schoar & Zuo, etc.).
* Gap in literature:

  * Most studies cover public firms in the US and Europe.
  * Privately held firms are under-studied.
* Why private firms are different:

  * Limited reporting on CEO pay, decisions, and outcomes.
  * Owners retain strong control rights (unlike dispersed ownership in public firms).
  * Data availability is thinner and noisier.
* Goal: model and measure CEO effects in private firms with rich registry data.
* Contribution: bring together a theoretical model, long-run data for Hungary, and a placebo-controlled methodology.

### Theoretical Framework (Slides 9–13)

* Production structure: Cobb-Douglas function combining capital, labor, materials, organizational capital, and manager skill.
* Inputs:

  * Firm-specific: organizational capital (Ai), brand value, customer capital.
  * Manager-specific: CEO skill (Zm).
  * Owner-chosen: capital (Kit).
  * Manager-chosen: labor (L), materials (M).
* Omega (Ωit): residual productivity, treated as error term but important for econometrics.
* Surplus determination:

  * Firm revenue depends on both owner and manager decisions.
  * Surplus to fixed factors (owners, managers) is a constant share of revenue.
* Key insight: manager skill has a magnified impact due to surplus share χ < 1.

  * A 1% better CEO translates into >1% growth in surplus because inputs expand.
* Empirical strategy: log transformation, sector-time fixed effects, two-way fixed effects for firms and managers.
* <digression>In private firms, CEOs are closer to plant managers: they influence operations but not large-scale capital decisions like in superstar public companies.</digression>

### Data: Hungarian Corporate Registry (Slides 14–20)

* Context:

  * Hungary transitioned from socialism in 1990; corporate legal code normalized by 1992.
  * EU accession in 2004 marked stabilization of the market economy.
  * Dataset spans 1992–2022 (with some messy 1980s data).
* Sources:

  * Firm registry: mandatory CEO appointments/terminations.
  * Balance sheet and financial statements: 10.2 million firm-years.
* Coverage: essentially all incorporated businesses.
* Data cleaning challenges:

  * Defining the firm: stable identifiers but some inconsistencies (tax IDs reused \~2% of the time).
  * Defining the CEO:

    * No numerical IDs before 2013.
    * Used name, address, mother’s name (1999+), and birthdate (2010+) for entity resolution.
    * Managing director flag available only \~80% of time; imputed when missing.
  * CEO time spans: gaps or overlaps → manually closed.
  * Registry includes non-CEOs (accountants, attorneys) → filtered.
* Sample restrictions:

  * Exclude: firms with >2 CEOs/year, >6 total, state-owned, mining/finance sectors, micro firms with <5 employees.
  * Exclude first-year firms (incomplete data).
  * Keep: firms with at least some employment (to remove shell or tax-avoidance firms).
* Descriptives:

  * 1 million+ firms total; \~220k in analysis sample.
  * 95% Hungarian names, 73% male CEOs, 69% were founders.
  * 18% manage multiple firms.
  * Largest connected component: \~26,500 managers.
* Temporal patterns:

  * Explosive firm entry in the 1990s.
  * By 2010–2020, \~120k firms active per year with 120k CEOs.
  * CEO tenure distribution: 22% last 1 year, 15% 2 years, 51% 4+ years.
* CEO turnover:

  * 80% of firm-years have one CEO.
  * 17% have two, 2% have three, 1% more.
  * Early transitions (1st to 2nd CEO) show productivity jumps (\~12%), later transitions show little average effect.
* <digression>In Hungary many firms are incorporated for tax evasion or self-employment, not genuine businesses. Cleaning is essential to remove noise.</digression>

### Estimation Methodology (Slides 22–30)

* Step 1: Estimate surplus share χ from input revenue shares (Halpern et al., Gandhi et al.).

  * Typical χ ≈ 10–20%.
* Step 2: Estimate revenue function with rich fixed effects.

  * Coefficients relatively stable to control inclusion.
* Step 3: Estimate firm and manager fixed effects with TWFE.

  * Manager FE captures contribution beyond firm average.
  * Need large connected component for identification.
* Step 4: Event study to test dynamic assumptions.
* Identification challenges:

  * Reverse causality: booming firms may attract new CEOs rather than CEOs causing growth.
  * Baseline dependence: FE only interpretable within connected component.
  * Small-sample noise inflates FE dispersion.
* Placebo strategy:

  * Construct placebo CEO changes for firms with long tenures.
  * Match hazard function of CEO turnover (\~20% per year, declining over tenure).
  * Compare real vs placebo to measure and correct noise.

### Results (Slides 31–39)

* Manager fixed effect distribution:

  * Wide dispersion → 25% productivity difference across P25–P75.
  * But event study shows much of this dispersion is noise.
* Event study findings:

  * Pre-trends: slight dip in TFP before CEO change (<1%).
  * Post-change: variance in TFP rises, stabilizing after change.
  * Confirms real performance heterogeneity across CEOs.
* Good vs. bad CEOs:

  * Raw event study: 22% gap in TFP.
  * Placebo correction: only \~5% gap is true CEO effect, 17% is noise.
  * Good CEOs increase TFP, bad CEOs decrease.
* Firm outcomes:

  * Good CEOs → higher sales, wages, and materials.
  * Capital and intangibles weakly correlated; suggest owner retains control.
  * Intangibles build gradually with good CEOs.
  * Labor and materials respond immediately → consistent with manager control.
* <digression>Philosophical identification issue: when owner and CEO decide jointly, attributing causality solely to CEO is ambiguous.</digression>

### Conclusion and Future Work (Slides 40–42)

* Findings:

  * Raw CEO fixed effects mostly noise.
  * True CEO effect on TFP ≈ 5%.
  * Good managers expand firms immediately through operational inputs.
  * Longer-term, they gradually attract more resources (intangibles).
* Implications:

  * Don’t use raw manager FE (75% noise).
  * Include observable CEO characteristics (education, experience, foreign background, entry cohort).
  * Only use manager quality on LHS; otherwise attenuation bias.
  * Always implement placebo checks.
* Future directions:

  * Link CEO biographies and career histories to productivity.
  * Analyze foreign acquisitions: foreign CEOs drive post-acquisition improvements.
  * Macro-level selection into CEO markets across cohorts.

