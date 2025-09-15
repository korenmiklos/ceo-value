identification assumption for z_m

When estimating a fixed effect parameter, the exact moment condition is that the residual has zero mean in each group in which the dummy takes the value 1. Nothing more, nothing less.

So our assumption is that 

> For each manager, residual TFP is mean zero, when averaged across all their firms and time periods.

Things we allow for:
 1. nonrandom mobility - maybe I am being pedantic here, but nowhere do we need to assume that managers move randomly
 2. time-varying residual TFP - it is fine for epsilon to be low initially during a manager's tenure and increasing thereafter. This we can check in the event study, no need to assume anything.
 3. different residual TFP for the same manager at different firms, as long as they average to zero
 4. The mean of all other variables can depend on the manager: good managers can go to good firms (or bad), can receive more capital, etc. Again, correlations can be checked, no need to assume.

 
> > "nonrandom mobility - maybe I am being pedantic here, but nowhere do we need to assume that managers move randomly"
> ---> idk about this one, if the error term is correlated with manager change, than the manager effect we recover from the nonplacebo regs is not the theoretical manager effect but a biased version of it? and not just biased because of the extra noise that's present in the placebo transitions, but above and beyond that there is bias, no?
> 

Helpful question because forces us to rethink identification. We do NOT need random mobility. We do NOT need eps(change - 1) to have zero mean, nor eps(change + 1) to have zero mean. Only that the average eps is zero for all managers. The is the condition the estimator enforces. The rest is not enforced, which is exactly why we can check the event study. 

A pre-trend on the event study would be problematic because it would SUGGEST that the mean assumption is also violated. If pretrends are positive, the new manager is likely to have a higher mean epsilon than the old one. This is not proof of the identification being violated, just a suggestion: if you see epsilon increasing for three years, you become worried that maybe it is an increasing trend and keeps going. 

Similarly, the lack of pretrend does not prove we are right. We cannot rule out a contemporary increase in epsilon at the exact same time as the good manager arrives. This is fundamentally untestable. (For example, the owner reads a cool article about AI in Wired, decides to fire the current CEO and adopt ChatGPT the same morning.) 

But it is much harder to to come up with endogeneity stories that kick in exactly when the CEO changes and are not caused by the CEO. (My story above is quite esoteric.) A more general worry that "improving firms have the budget to hire better CEOs" or "worsening firms are more likely to fire their CEO" are captured by the pretrend: we expect productivity to change BEFORE the change of CEO, not at the same time.

---
It may be a matter of semantics but I think we should be precise.

Random mobility is sufficient but not necessary for identification. (Demanding randomness from everyone is a very unfortunate byproduct of the RCT revolution.) Random mobility would imply that Zm is uncorrelated with everything: observables like lnK and all time periods of the unobservable epsilon. None of these are necessary. The exact moment condition for estimating Zm is 

> for each manager, residual productivity $\tilde{\epsilon}_{it}$ has zero mean when averaged across all their firms and time periods: $E[\bar{\epsilon}_m] = 0$ where $\bar{\epsilon}_m = \frac{1}{N_m}\sum_{i,t \in m} \tilde{\epsilon}_{it}$ and the sum runs over all firm-year observations under manager $m$.

This is a much weaker condition than random mobility.


On Mon, Sep 15, 2025, at 9:45 AM, Telegdy Álmos wrote:
> Yes, we do need random mobility. But we do not seem to have this problem, as shown by the pre-trends, as you also write below. I am actually very surprised of this, as I would expect CEO turnover to be correlated with TFP. If everything goes ok, firms do not change the CEO.

Remember, these are private firms. Many of the CEO changes can be quite idiosyncratic like death or divorce or friends arguing or people moving to a different city. Not a board deciding to fire the CEO. 

The mean of TFP does fall in the two years before CEO change, just by very small amounts, less than 1%. You can also see it in the good vs bad event study, https://github.com/korenmiklos/ceo-value/blob/main/output/figure/event_study.pdf but small relative to the effects.



>  
> Maybe we can do a simple regression looking at 2 or 3 year changes in TFP before CEO turnover relative to periods without CEO change. We can add industryxyear FEs to the regression.  If this turns up to be insignificant, that’s good for us. If not, we can argue that our more complex regression does a good job elmininating the effects of random mobility. But we can show some simple descriptive information about when mobility happens.

This should be visible on the event study graph.

>  
> Long time ago I talked to Abowd, who was revising a paper and he complained that the main concern of the referee was random mobility.
> 

We should explain it clearer. I don't see how any paper could survive the random mobility critique. Clearly, managers don't go to random firms, nor should they.