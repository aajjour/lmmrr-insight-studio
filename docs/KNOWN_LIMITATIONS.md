# Known limitations

1. The baseline model parameters come from R `lme4` REML fits and are reused by both implementations. This deliberately controls optimizer and software version differences. It does not prove that independently refitted Python `statsmodels` produces precisely the same RR output in all models.
2. `Orthodont` and `sleepstudy` do not cover crossed or nested random effects beyond the single grouping factor, irregular observation covariance or arbitrary residual correlation structures.
3. The method deliberately does not implement BLUP-indexed, cluster-indexed or serial-dependence tests from the published package unless source-mapped and independently verified.
4. No confidence envelopes, global p-values, familywise adjustments, effect-type probabilities, validated cause identification or automatic model suggestions are supplied.
5. The index order is chosen by the analyst; different index orderings are not independent tests. They must not be combined as if independent.
6. Centering the descriptive process is not justified as a Brownian-bridge test. False-positive control remains unresolved without refit calibration.
7. Model-related diagnostics cannot be promoted merely from an unusually large residual. Red points are exploratory extreme-observation markers with no multiplicity-adjusted interpretation.
