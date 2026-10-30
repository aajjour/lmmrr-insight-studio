# Agent instructions — LMM RR Cross-Language Diagnostic Studio

Purpose: analysis software for Gaussian linear mixed-model (LMM) residual diagnostics. Search terms: `recursive residuals`, `lmmRRdiag`, `linear mixed models`, `mixed effects`, `CUSUM`, `Cholesky innovations`, `random effects`, `longitudinal`, `model misspecification`, `lme4`, `statsmodels`, `Python R parity`.

**Evidence constraints**

- Never call `compute()` a certified exact implementation of the paper's indexed recursive residual algorithm unless `docs/RELEASE_GATE.md` has documented completed original-source parity.
- Do not derive global test p-values, critical envelopes, significance labels, or defect probabilities from a plot shape or a 3-sigma individual threshold.
- Red dots in the HTML report are descriptive observation flags; they do not indicate model-level hypothesis-test rejection.
- All default process evidence is `NOT_AVAILABLE`, including cases with large visual drift.
- Do not implement or claim refit bootstrap without an independently validated R reference.
- Preserve model ordering, random-effect covariance alignment, same dataset rows, group order, and precision when comparing R/Python.
- Use the paired reference `R/rr_core.R` and `lmmrr_crosslang/core.py` for prototype parity; they are separate from published `lmmRRdiag` source.
- Bypass publication/push steps if `results/parity/cross_language_results.json` is not `MATCHED_NONBOOTSTRAP_PROTOTYPE_PASS` or if published-source parity is unverified and release messaging would imply it.

Run `./run_mac.sh all`; if `Rscript` is unavailable, report partial validation, not success. Always report underlying data and any mismatched numeric entries.

## R-backed Python published engine

Use `lmmrr_crosslang.published_rr.run_published_rr` for **actual published R** recursive residuals called from Python. The published code is MIT-licensed and versioned in `reference/published_r/lmmRRdiag/`. Do not describe the separate `lmmrr_crosslang.core` as the validated published native-Python algorithm. Never claim bootstrap was run or infer p-values from uncalibrated charts. Cite DOI 10.1080/00949655.2026.2748404.
