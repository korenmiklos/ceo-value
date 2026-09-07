---
type: Reference
title: Econometrics paper text
description: Evidence excerpts from papers/econometrics/paper_july2026.tex, the methods paper.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
---

# Econometrics paper text

## Source

- Path: `papers/econometrics/paper_july2026.tex`
- SHA-256: `fa17227f2931d9f317ffdd32bd88203c08b765e265532cc99660c13395975c5d`
- Inspected: exact source slices below

## Excerpts

### Lines 93-117
```text
We apply the placebo-controlled debiasing method to the universe of Hungarian firms between 1992 and 2023, leveraging administrative data that link CEOs to firm balance sheets and income statements. The data cover the population of SMEs (472 thousand firms) and about 376,000 CEO transitions.\footnote{Perhaps the best alternative of our method is the leave-one-out method \citep{kline2020leave}. This method is based on the sample of firms which are connected by CEO movement with at least two paths. In our data, this contain XX firms only.}


\begin{comment}
\footnote{In these data, managerial mobility is the exception rather than the rule: only XX\% have CEOs who also served in another firm and XX\% of all CEOs led at least two firms. The connected component comprises XX\% of all firms. Had we applied the conventional methods in the literature, we would have used only XX\% of our sample.}

Number of unique firms in the data: 471K
    
Number of firms with a CEO who also served at another firms: 266K, or 56%

Gratest connected component: 110K firms. 

Number of CEO switches in the connected component:

Number of firms which would be used in with the leave-one-out method (leverage < 1)

Number of CEOs: 772K

CEOs who served in at least two firms: 158K or 20%

\end{comment}

We use CEO replacements to estimate changes in CEO quality measured along three dimensions: revenue growth, profitability, and labor productivity. We then study how these changes affect a range of firm outcomes, including revenue, employment, capital, productivity, profitability, and export participation. The framework allows us to quantify both the explanatory power of CEO changes and the channels through which managerial quality influences firm performance.

The empirical results show that conventional estimators substantially overstate the importance of CEOs. Naive estimates attribute 40–60 percent of revenue variation to CEO changes, whereas the debiased estimates imply a contribution of roughly 20–30 percent. We also find that event-study estimates based on conventional methods display pronounced pre-trends that disappear after debiasing, indicating that they are artifacts of small-sample bias rather than evidence against the identification strategy. Finally, the corrected estimates reveal immediate and persistent effects of CEO replacements on firm outcomes and show that CEOs who improve performance along one dimension also affect a broader set of firm decisions and outcomes.
```

### Lines 1032-1060
```text
\subsection{Results}
%%%%%%%%%%%%%%%%%%%%

The first question in the analysis of the value of the CEO (or the effect of CEO change) is the choice of the variable which is used to measure it. The firm's owners may have various objectives: they may want to raise revenue but also profits. From the society's point of view, productivity is arguably the most important firm attribute. Therefore, we carry out the analysis using these three variables as the metric of CEO value. The metric used can be thought of as the variable the decision maker of the company (the owner or the CEO) focuses on and comparing different metrics allow assessing the activity of various types of CEOs: depending on what the CEO maximizes, what firm outcomes increase?

Table \ref{tab:table_application} presents the naive and debiased estimated coefficients and the $R^2$ of the estimation for output (measured by log sales and an exporting dummy variable), inputs (log capital and labor) and financial and operating productivity (return on assets and labor productivity). The naive and debiased regression coefficients are typically very similar because both the covariance between the dependent and explanatory variables and the variance of the explanatory variable tend to be upwardly biased, causing much of the bias to cancel out in the coefficient estimate. We debias both statistics, and as a result, the change in the estimated regression coefficient is often small. Nonetheless, in some cases the naive and the debiased coefficients have different magnitudes. For example, the semi-elasticity of capital with respect to $\Delta Z$ (measured by ROA) is -0.027, suggesting that ROA-maximizing CEOs partially achieve their goal by shedding capital, but the debiased coefficient is only -0.005. Another example is the elasticity of labor with respect to $\Delta Z$ (measured by $lnRL$), which is zero with the naive estimation, but increases to 0.084 when we apply placebo-controlled debasing.

Contrary to the estimated coefficients, the $R^2$ of the estimation declines substantially in most of the cases. On average, the $R^2$ from the naive estimation is 2.8 times larger than from the debiased estimation (we did not take into account the $R^2$-s which are essentially zero). The difference between the two $R^2$s is also sizable: in those cases when the naive $R^2$ is at least 0.05, the naive estimate is smaller by 0.16 on average and in three cases the difference is close to 0.5.

Figures \ref{fig:application_lnR} to \ref{fig:application_lnYR} present the event-time estimations (the reference year is one year before the CEO transition). The red lines represent the coefficients from the naive estimation and the blue lines from the debiased estimation. As the Monte-Carlo estimation predicted, pre-trends largely diminish in the observational data when the placebo-controlled debiasing method is used. In 10 out of 18 cases, the pre-trend is considerably smaller than with the naive estimation, or it completely disappears. In only one case it becomes larger while in the remaining 7 cases the pre-trends are similar under the two methods. Needless to say, estimating unbiased pre-trends is crucial for any empirical analysis, as the reliability of the estimation is decided upon pre-trends. Our exercise demonstrates that the limited mobility bias may show up in ways which may make researchers reject well specified estimations.

The differences between the naive and corrected event-time estimations are smaller for the period subsequent to the CEO transition. Consistent with the average effects presented in Table \ref{tab:table_application}, the two lines mostly differ in their shape and not in magnitude. A good example for this behavior is the elasticity of labor with respect to $\Delta z$ measured by $lnR$: three years after the CEO replacement the two coefficients are identical, but the debiased coefficients reach this level in two years (including the year of CEO replacement), while the naive estimations increase gradually. 

In several cases, the debiased estimations lead to markedly different conclusions regarding firm behavior. For example, the naive estimates suggest that capital constantly decline when ROA is the measure of quality of CEO change, but the naive estimations reduce this to nothing. The elasticity of labor is also very different across the two specification when labor productivity is the metric: while the naive estimation suggests a dip in the first year under the new CEO and then some increase, the debiased estimates show a substantial increase which reaches 0.13 after 4 years.

This real-data exercise demonstrates that the primary value of the debiasing method does not lie in correcting the estimated relationship between $\Delta z$ and firm attributes. Rather, its importance lies first in obtaining an accurate measure of the explanatory power of $\Delta z$ for changes in firm attributes, as this explanatory power is substantially overstated in the naive estimates. Second, the pre-trends in event-time estimations are also upward biased in the naive estimates which leads to the rejection of well-identified estimates.

The comparison of the naive and debiased results demonstrate that there is nothing mechanical in our method in the sense that the difference between naive and debiased estimates vary widely depending on the metric and dependent variable. Sometimes they are very similar; sometimes only the pre-trend disappears, in some cases they have similar shape but the magnitude differs; and sometimes thy suggest completely different trajectories of the dependent variables.

The three metrics of CEO change enable us to draw conclusions about what can stakeholders expect from various CEO types? For example, what is the difference between a CEO who is good at increasing sales and one who boosts the profitability of the firm? Table \ref{tab:table_application} reveals that those CEOs who raise sales, raise every outcome we analyze. All the elasticities (semi-elasticities for ROA and Export) are large and statistically significant. The elasticity of labor with respect to $\Delta z$ is 0.23, of capital 0.33, of ROA 0.80 and of labor productivity 0.30. The semi-elasticities of ROA and exporting is also substantial (0.03 and 0.80). Relative to their average value, XXX.

CEOs who are good at increasing labor productivity are rather similar to those who increase revenue. They raise sales (with an elasticity of 0.50), exports (0.014), capital (0.33) but raise labor very little (0.08), and ROA (this latter is associated with a very large, but statistically insignificant coefficient). Contrary to these two similar types of CEOs, those who increase ROA do not raise the scale of production, BEÍRNI AZ EREDMÉNYEKET AMIKOR MEGVAN AZ ÁTLAGOS delta z. In conclusion, it seems that the best CEOs are those who concentrate on raising the volume of sales, as this raises both inputs and also productivity. 

The $R^2$ estimations suggest that CEO replacements explain less of the variance of the dependent variables as one would expect (REF EARLIER STUDIES). When the metric is the $lnR$, $R^2$ is larger than 0.10 only when it is estimated on the metric itself. For labor is it 0.09 and for all other dependent variables less than 0.04. When ROA is the metric, the $R^2$s are all close to zero (except for ROA, when it is 0.13). It seems, thus, that CEO change cannot explain itself changes taking place in the firm. (EZ VAJON IGAZ? ÉS HA IGEN, AKKOR MI LEHET AZ OKA? AZ, HOGY JÓ CÉGEKNEK JÓ CEO-JA VAN ÉS AKI LECSERÉLI, AZ IS JÓ? VAGYIS A DELTA Z NEM MAGAS? MEG KELLENE MUTASSUK A DELTA Z STATISZTIKÁIT)

WE MAY LOOK AT HETEROGENEITY AND TRY TO FIND SOMETHING INTERESTING. MAYBE LOOK ONLY AT R2
- CEO CHANGE 1-1, 1-2 ETC 
- FOUNDER-NONFOUNDER VS NONFOUNDER-NONFOUNDER CHANGES?
- POST COMMUNIST - CAPITALIST PERIOD (COMPETITTION WAS LOWER IN THE 90S, MAYBE MANAGERIAL TALENT WAS LESS IMPORTANT OR MANAGERIAL TALENT WAS MORE SCARCE IN THE EARLY PERIOD AND SO IT WAS MORE REWARDING)
```

### Lines 1069-1071
```text
Empirical analysis of 60,000 CEO transitions in Hungarian firms reveals that, after correction, CEO effects account for 20–30\% of revenue variance, about half of what naive estimates imply. CEO replacements have immediate and persistent effects on firm growth, with no spurious pre-trends. 
\clearpage 

```

## Notes

- The econometrics paper is titled "CEO Replacements and Firm Growth: Correcting for Small-Sample Bias in Fixed-Effect Estimates" (July 2026 draft; contains Hungarian-language drafting notes and placeholders like "XX", "ADD PROPORTION"  the text is a working draft, not a final manuscript.
- Numbers conflict within the paper: line 93 says "472 thousand firms", line  1016 says "471 thousand firms"; line  93 says "376,000 CEO transitions", line  1022 says "275 CEO switches" (likely 275 thousand, typo`, line   1069 says "60,000 CEO transitions"  three different transition counts. Recorded as internal disagreements.
