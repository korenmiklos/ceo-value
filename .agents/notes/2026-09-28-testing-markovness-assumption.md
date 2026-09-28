---
id: 1
type: note
created: 2026-09-28
related: []
---

# Testing Markovness assumption and alternative network mechanisms with Ulrich and Krisztina

Participants: Miklos, Ulrich Wohak, Krisztina Orban. Discussion of the Markov property in the firm-manager network model, the Madrid presentation reception, and next steps for the paper.

## Madrid presentation takeaways

The Madrid talk went well overall. Hoppenheimer and others responded positively. The DGP framing resonated particularly with the macro audience. Presenting the GMRF as an approximation of the DGP rather than the DGP itself was the key reframe.

The DGP does not lead to a GMRF, but it can be approximated by a GMRF.

This framing opens a natural discussion of pruning: if we get closer to a tree, the approximation improves. The Markov property slide worked well -- the AR(1) autocorrelation and partial autocorrelation figure validated the model intuitively, with partial autocorrelation dropping to near-zero after lag 1 as expected under Markovness.

## Markov assumption: framing and testability

Markovness is a model assumption but is testable in the data. Residual correlation after AR(1) could indicate non-Markovness. An alternative story: firms are correlated in latent space (industry, location) even without mobility links, which would produce higher-order partial autocorrelations and slower unconditional correlation decay.

The preferred test is 3-step covariance along a firm-manager-firm-manager path with no shared shocks. This is the "smoking gun" covariance -- correlation here implies network-driven correlation, not common shocks. The proposal is to compute this covariance within-industry vs. cross-industry and same vs. different location. The focus should be on economic magnitude, not just statistical significance, since millions of observations will reject anything.

Ulrich will send results on within- vs. cross-industry 3-hop covariance tomorrow (29th September).

## H-matrix score test

Ulrich presented results from the score test that adds artificial connections (H matrix) to Q and checks whether the likelihood slope improves significantly. Three H specifications were tested: firm distance-2, manager distance-2, and within-industry firms. The null hypothesis is gamma = 0 (no additional correlation through H). The score distribution is simulated under the null with network fixed and outcomes redrawn.

Within-industry H produces a very large score, well outside the simulated distribution. Firm and manager distance specs are also outside the 97th percentile but less extreme. Industry fixed effects have not yet been removed from the data; Ulrich will try adding them.

A concern was raised that with millions of observations, even tiny economic differences will be statistically significant. The scores need to be translated into interpretable covariance or correlation units. The preferred path is to compute the 3-step empirical covariance, split by industry and location, and assess the gap size.

## Likelihood approximation and GMRF framing

The true likelihood consists of three parts: prior, links, and non-links. Current estimation ignores the non-links term. Two approximations are used: the link probability is approximately exponential, and the non-link term is approximately constant (valid for sparse networks and trees). For trees and sparse networks, the non-link term is provably flat, and pruning pushes the network toward this regime.

The fact that I am not the CEO of Apple is not particularly informative, neither about Apple nor about myself.

The preferred framing going forward is "DGP approximated by GMRF" rather than "model is a GMRF." This is more defensible for econometrics audiences and honest about the approximation. For science/PNAS audiences, a rougher framing is still acceptable -- every model is wrong.

## Pruning justification

Current results show the GMRF is a good approximation for trees but breaks down for dense cycles. There is no formal theorem yet specifying exactly when to prune and how. In Madrid, pruning was presented informally: if not a tree, remove edges to get closer to one. There was no pushback from Hoppenheimer or Matt Jackson, though pruning was not covered in depth.

An open question is whether a tighter theorem would require a different pruning rule.

## KSS comparison and contribution

KSS leaves out bridges, destroying network connectivity. It can reduce usable data to around 59 observations or 5-15% of the sample, even before further exclusions.

The key argument is that excluding bridges gains nothing for variance decomposition, while zero-weighting preserves connectivity while ignoring the outcome on the bridge.

Currently at around 93% confidence this is correct; the goal is 99.99% with a formal argument. The AR(1) epsilon version (correlated within-firm shocks) needs a corresponding pruning graph, and the KSS comparison for this case is unresolved. Once results are finalized, everything should be recomputed afresh from a clean slate.

## Publication strategy and broader framing

Matt Jackson's advice: pitch to top-5 or general-interest journals by showing the method works across 5+ sparse-network domains. Candidate applications include CEO labor markets, buyer-supplier networks (Hungary), patent/inventor data (Oppenheimer), procurement, and trade.

Two framing options were discussed. The first is misallocation framing: efficiency of CEO markets, strength of sorting, welfare, with rho as the central parameter. The second is general measurement framing: how to measure competitiveness or sorting in any sparse bipartite network, with variance decomposition as the output.

We're standing on the shoulders of giants, extending their brilliant work to sparse networks.

Current preference is the misallocation / CEO market framing as primary, with generalizability mentioned in the abstract with 2-3 examples. The peer-effects network literature has related ideas (Brian Graham, a French author whose name Krisztina will look up) that are different enough but worth citing.

## CEU brown bag prep (next Tuesday, 12:30)

Ulrich will present the Geomagic paper at the CEU brown bag. Krisztina may join via Zoom. The audience will be a mix of labor economists and economic relations people (Adam, Andrea, Robbie).

The presentation strategy is: open with the general question, briefly note AKM/KSS limitations (data loss, unrepresentativeness), lead with what the method does and why it works with prominent DGP framing, keep the KSS critique to roughly 25% or less (it will come up in Q&A anyway), do not spend heavy time bashing KSS, and deliver results first.

How soon does Adam get annoyed?

Ulrich will send draft slides by Friday; comments requested by Monday.

## Next steps

- Compute 3-step covariance split by industry and location (Ulrich by 29th September)
- Re-estimate H-matrix model with industry fixed effects removed (Ulrich)
- Send draft brown bag slides by Friday 2nd October (Ulrich); Miklos and Krisztina to comment by Monday
- Update and post working paper draft to website by Wednesday 30th September (Miklos); needed for October 30th grant report
- Share remaining reviewer comments from the draft (Krisztina); other reviewers' comments were saved as drafts and not yet visible to the team
- Recompute all results afresh once paper content is finalized (Ulrich); ensures clean provenance for every estimate before submission