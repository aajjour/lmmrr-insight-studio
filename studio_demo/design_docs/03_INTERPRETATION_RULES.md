# 3 — Interpretation rulebook: defensible defaults

## Fundamental inference separation

The observed process, descriptive shape, local excursion and supplied bounds are *visual information*. A global process-wide test is *inferential evidence* only when the null distribution of the selected process-wide statistic is calibrated using appropriate model refitting and the multiplicity family is valid.

The rule engine currently uses only **reported** refit-parametric-bootstrap p-values; it cannot audit the simulation/refit computation independently. The example patterns are synthetic and not evidence.

## Decision status

1. Complete eligible global-process family: use `p.adjust(p, method='holm')` within model/family; red if adjusted p ≤ prespecified alpha, green otherwise.
2. Incomplete family or uncalibrated p-values: amber **unverified**, even if many observed points cross an envelope.
3. Synthetic demo: explicit **DEMO** flag; never use words like 'statistically significant' in demo interpretations.
4. Red never means 'the true defect is X'; it means evidence of a departure for an indexed diagnostic process.

## Diagnostic leads (not validated classifier)

| Process / cue | What a signal can suggest reviewing | Competing explanations / caution |
|---|---|---|
| `mean_indexed`: sustained directional drift | nonlinear mean, omitted trend, time-dependent fixed effect | grouping and covariance defects can generate analogous patterns |
| `cluster_indexed`: cluster-linked excursions | grouping, heterogeneous cluster means, influential clusters, contextual covariates | clusters may be influential due to mean/variance misspecification |
| `blup_indexed`: BLUP-related departure | random intercept/slope specification, random-effect distribution sensitivity | BLUP shrinkage and cluster size may alter the pattern |
| `serial_indexed`: ordered within-cluster departures | AR-type dependence, omitted time structure, measurement artifacts | mean misspecification and irregular follow-up produce confounding |
| `scale_indexed`: scale-specific departure if **separately implemented and calibrated** | variance structure/heteroscedasticity | do not infer from generic RR amplitude alone |
| isolated high excursions | influential observation/cluster, transcription issue | small anomalous periods might arise by chance |

**Do not rank the above as posterior probabilities.** Statements such as “85% probability of heteroscedasticity” require a separately validated probabilistic classifier and well-defined prior truth prevalence, which this product does not have.

## Descriptive features

- `max_ratio`: maximum absolute deviation from envelope midline divided by envelope half-width. This is **not** a standardized residual, p-value, or likelihood ratio.
- `excursion_fraction`: proportion of index positions where observed trace falls outside the supplied envelope. **Not** a calibrated percentage of bad data points.
- `longest_excursion`: longest contiguous run of positions outside the supplied envelope. **Not** an independent test.
- `peak_index`, `region`: location of the maximum ratio, relative to the meaningful ordering.

Current descriptive labels use `longest_excursion ≥ 6` as an **interface-only heuristic** for sustained patterns. This threshold has not been scientifically calibrated and has **no inferential standing**. Real process-specific thresholds, ordering invariance, and simultaneous error control require independent validation.

## Statistical validation requirements before claiming auto-interpretation accuracy

1. Freeze 16 paper misspecification scenarios and correctly specified baseline, plus harder unseen DGPs not used for rules.
2. Prespecify random seeds, independent data populations, cluster counts, imbalance, sample sizes, covariance models, and 999+ refits where feasible.
3. Use an independently generated test bank; ensure training and test simulation seeds, generator code paths and data do not overlap.
4. Record `true_category` vs `suggested_category` with multi-label ambiguity and an explicit 'indeterminate' option; report confusion tables, sensitivity/specificity, wrong-specific-signal rate and no-signal rate.
5. Quantify nominal per-process and familywise type-I error with binomial confidence intervals; capture fit failures and failed bootstrap refits.
6. Report uncertainty of detection rates and realistic simultaneous envelopes; calculate precision planning against prespecified margin (e.g. worst-case Wilson half-width targets).
7. Compare standard diagnostics: conventional residual plots/tests, HLMdiag, DHARMa where appropriate, and domain-specific covariance diagnostics. Avoid claiming universal superiority.
8. User study: blinded tasks, correct follow-up choice, time to diagnosis, excessive-specificity errors, calibration comprehension; preregister outcomes.
9. Evaluate selective/unknown out-of-taxonomy defects. A robust interface should explicitly say 'unidentified' rather than confidently forcing a label.

## Language templates

**Defensible:** “The indexed mean process shows a reported refit-calibrated global signal after Holm adjustment. This is consistent with several possible deficiencies; investigate the mean functional form and competing covariance explanations.”

**Defensible:** “The process exhibits an out-of-envelope excursion, but no eligible global bootstrap p-value was provided; no inferential conclusion is made.”

**Not defensible:** “The model is heteroscedastic with 94% confidence because the line is red.”

**Not defensible:** “No red signal proves the fitted model is correctly specified.”
