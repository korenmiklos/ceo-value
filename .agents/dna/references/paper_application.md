---
type: Reference
title: Application paper text
description: Evidence excerpts from papers/application/paper.tex, the application paper results.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
---

# Application paper text

## Source

- Path: `papers/application/paper.tex`
- SHA-256: `a5372fe4a2fa85b8ec76bea70e79f3deb740d53e4764ee64cf6efda53a303951`
- Inspected: exact source slices below

## Excerpts

### Lines 268-299
```text
\section{Results}
%%%%%%%%%%%%%%%%%

\paragraph{Production Function Estimates.} Table \ref{tab:industry_stats} in the Appendix reports our estimates of the surplus share $\chi$ by industry. The estimates range from 0.06 to 0.19 across included sectors, with wholesale, retail, and transport showing the lowest values and professional services the highest. These estimates imply that a 1\% increase in TFP increases revenue by 5 to 16 percent through the leverage effect of scaling variable inputs.

%Table \ref{tab:surplus} presents the revenue function estimates. We include controls for log capital, firm age, presence of intangible assets, and foreign ownership, along with firm-CEO and sector-year fixed effects. The capital coefficient is precisely estimated at 0.333 (standard error 0.001), consistent with capital's limited but significant role in private businesses. 

\input{table/table2} 
%elég 3 tizedesjegy, nem vagyok mink atom fizikusok
%a nobs nem jó, mert három különböző kell a három sorba

\paragraph{CEO Transitions and Productivity Change.} Table \ref{tab:placeholder} shows the average effect of CEO transition on productivity as estimated by the naive OLS regression, the placebo effect and the corrected regression estimate.\footnote{The naive and the pseudo outcome regression are estimated on the treated and placebo samples, respectively. The controls are the not-yet-treated firm years. The corrected regressions are estimated on the merged samples and we use the two-way treatment method discussed in Section \ref{sec:est}.} To start with the effect on the whole sample, TFP increases by 0.5\% around the CEO change. The placebo regression produces precisely measured zeros.\footnote{This is reasonable because here we do not have a reason to believe the estimated effect by simple OLS regression is biased as we do not select on unobservables correlated with productivity.} That is, even without a CEO change, TFP changes somewhat. The placebo controlled estimate equals 0.3\%. 

As most of our firms are family-owned, we look into an interesting CEO transition: when founders relinquish control. For comparison, we also run a separate regression on other CEO changes. When founders are the departing CEO, the estimated effect is 1\%. For the other CEO changes we do not find any change in TFP. This is also a test of our method: when similar CEOs replace each other, the effect is zero, at least on average. On the contrary, when we measure the TFP change between two distinctly different CEOs, we do find an economically and statistically significant effect.\footnote{The reason for a positive effect of founder replacement may be the timing of the change. Founders usually give up their central role in the firm when they find they no longer have enough energy to run the firm.} 

\begin{figure}[htbp]
\centering
\includegraphics[width=\textwidth]{figure/figure1.pdf}
\caption{Placebo-Controlled Event Studies of CEO Transitions}
\label{fig:event_study_main}
\end{figure}

Finally, we analyze perhaps the most interesting question: how the productivity reacts to the arrival of a better or worse CEO than the incumbent? For this, we split the sample into two types of CEO transitions: when the incoming CEO has a higher or lower quality (as measured by the associated fixed effect) than the incumbent CEO. We also split the placebo sample into firms which experience an increase/decline of their TFP around the pseudo CEO change. The estimated coefficients are presented in the last two columns of Table \ref{tab:placeholder} and demonstrate the importance of CEOs and also show how the placebo correction works. Better CEOs than the incumbent increase TFP by 6\% while worse CEOs decrease it by 5\%. This large effect, however, is upward biased, as the placebo regressions demonstrate. The pseudo CEO change also produces a sizable effect of $\pm$2.5\%. Thus, the corrected effect is much smaller: better CEOs increase TFP by 2.7\% while worse CEOs decrease it by 1.8\%. Thus, the difference between a good and a bad CEO is 4.5\%. 

Figure \ref{fig:event_study_main} visualizes the evolution of TFP around the CEO change for four samples: all changes, when the incumbent is the founder of the firm, all other incumbents, and for the period of mature market economy (2004 -- 2022).\footnote{The latter sample is used to make our results more comparable to mature market economies. In the 1990s the economy was changing rapidly as it underwent rapid economic liberalization, transition to market economy, foreign direct investment inflows and large scale privatization. We conduct this robustness check by restricting the sample to post-2004 data following Hungary's EU accession.} On each figure we present the event time regression estimates for the whole sample (black line) and for better and worse CEO replacements (blue and red lines). The estimations leave little pre-trend and we find large swings in TFP. If the incoming CEO is better than the incumbent, TFP increases by 3 -- 4\% while worse CEOs decrease it by about 2\%. New CEOs have an effect immediately on the firm and this proves to be quite stable, as the estimated coefficients do not change much.  

\begin{figure}[htbp]
\centering
\includegraphics[width=\textwidth]{figure/figure2.pdf}
\caption{Placebo-Controlled Event Studies of CEO Transitions. Effects on Firm Inputs}
\label{fig:event_study_input}
\end{figure}
```

### Lines 300-331
```text

\paragraph{Model Validation: Differential Effects on Short- and Long-Term Inputs.} Our model predicts that CEOs should primarily affect outcomes they control (labor, materials) rather than those controlled by owners (capital, organizational structure). Figure \ref{fig:event_study_input} presents event studies for owner-controlled inputs (fixed assets and intangibles) and manager-controlled inputs (employment and materials).

Good CEOs have immediate and substantial effects on manager-controlled inputs. Material costs increase by 30\% and the wage bill by 13 percent (all effects highly significant). Firms under bad managers experience the opposite: a decline in material and employment costs by about 20\%. These effects appear immediately in the year of CEO transition and persist throughout the post-period, consistent with new CEOs quickly adjusting operational scale.

In contrast, owner-controlled variables show different patterns. Fixed assets exhibit a gradual change under good CEOs and little or no change under bad CEOs. The proportion of firms with intangible assets does not change at all around the CEO transition.

\paragraph{Contribution of CEOs to Firm Productivity.} To assess how important CEOs are for firm performance, we conduct the variance decomposition. As we describe at the end of Section \ref{sec:est}, we face two challenges. The variance is biased and it also depends on firm age. The outcome of our method is presented in Figure \ref{fig:variance_decomp} for TFP in the top row and log revenue in the bottom row. The blue line shows the within-firm change in variance relative to the second year after firm foundation. The blue line on panels A and C show the evolution of this variance around the CEO transition. Before the CEO transition, the variance grows continuously. The transition increases the variance abruptly; in later years it stays relatively stable for TFP and continues growing for revenue. Part of this growth, however, is due to limited mobility bias, and part arises mechanically: as time passes, the chance of receiving shocks increases. To control for these biases, we estimate the same variance on the pseudo transition sample. As the red line shows, this also increases in time. Panels B and D of the figure show the evolution of the estimated variance in the two samples by firm age. 

Our estimate of the contribution of CEO change to the total variance of TFP is the difference between the two estimates, and we quantify it in Appendix Table \ref{tab:var_share}. The table presents the total variance, the unadjusted contribution of CEO change and the adjusted contribution. We analyze only one CEO change, and the contribution depends on the length of the period measured (the longer the period, the more the variance increases for reasons unrelated to CEO change). In the first 10 years of existence, the uncorrelated share of CEO change in the variance is 62\%. Our correction decreases this number to 29\%.


\begin{figure}[htbp]
\centering
\includegraphics[width=\textwidth]{figure/figure3.pdf}
\label{fig:variance_decomp}
\begin{minipage}{15cm}
\caption{Decomposition of the Variance}
\vspace{.2cm}
\footnotesize Notes: Dependent variable: TFP (panels A and B), Log Revenue (panels C and D). Panels A and C present the variance growth relative to the year after firm foundation for firms with a CEO transition (blue line) and with a pseudo transition (red line). Panels B and D show the evolution of the variance in treated and pseudo-treated firms by firm age. 
\end{minipage}
\end{figure}

%%%%%%%%%%%%%%%%%%%%
\section{Conclusion}
%%%%%%%%%%%%%%%%%%%%

This paper estimates the contribution of CEOs to firm productivity by exploiting a unique administrative dataset covering the entire population of Hungarian private firms and their CEOs from 1992 to 2022. The novelty of the data lies in its unprecedented scope and completeness, allowing the study of CEO effects not only in large firms but crucially in small and medium-sized enterprises that dominate every economy. The combination of the dataset with a theoretically grounded model that distinguishes owner-controlled capital decisions from CEO-controlled operational inputs allows for a more precise attribution of productivity effects. 

The paper develops a new placebo-controlled event study design that overcomes limited mobility bias, which contaminates studies using two fixed effects.  By creating matched placebo CEO transitions in firms without actual leadership changes, the method effectively separates true CEO skill effects on productivity from mechanical noise. Empirically, the findings reveal that the true causal effect of CEO quality on firm productivity is economically meaningful but notably smaller than raw correlations suggest, explaining about 7–8 percent of productivity variation. 

An alternative way to deal with the noise problem is to use observable manager characteristics as measures of skill. Observable characteristics such as education and work experience \citep{DePirro2025}, foreign name as a proxy for international exposure \citep{Koren2023expat}, and the selectiveness of entry cohorts \citep{koren2024managers} offer more reliable, though narrower, measures of specific dimensions of managerial quality. These observables capture only partial aspects of CEO ability but avoid the mechanical noise that contaminates fixed effects estimates.
```

### Lines 332-342
```text

\clearpage
\bibliographystyle{apalike}
\bibliography{../../lib/references}

\clearpage
\appendix
\section{Online Appendix: Additional Tables and Figures}
\renewcommand{\thefigure}{A\arabic{figure}}
\renewcommand{\thetable}{A\arabic{table}}
\setcounter{figure}{0}
```

## Notes

- The application paper uses `TFP` as the main outcome and reports ATET comparisons (Table 2} and variance decomposition (Table A4}.
- No explicit code anchors exist in the paper for these numbers beyond the make references to `table/table2.tex` and `table/tableA4.tex`.
