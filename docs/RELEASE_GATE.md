# Validation contract and release gate

## Non-bootstrap prototype parity

- Primary examples: `sleepstudy` (n=180, 18 subjects) and `Orthodont` (n=108, 27 subjects).
- Model structures: random intercept (RI) and correlated intercept/random slope (RS), 4 fitted specifications.
- Index orderings: original time/age, marginal fitted mean, reverse time; 12 configurations.
- Input parameters: fixed effects, random effects marginal covariance, residual variance from the R `lme4` REML fits exported earlier. Reuse identical inputs for R and Python to isolate innovation algorithm differences.
- Compare row ID, group ID, index, every innovation, CUSUM and centered CUSUM entry, and all scalar features.
- Acceptance tolerance: max absolute difference ≤ 3×10⁻⁸ in each numeric cell. This is a numerical engineering tolerance, not statistical significance.
- Verify model covariance reconstruction, deterministic ties, permutation invariance, missing values, small clusters, zero innovations, and positive definiteness.
- `results/parity/cross_language_results.json` must explicitly report a successful comparison; absence blocks a release claim.

## Full original published method parity — mandatory before calling Python a port of `lmmRRdiag`

1. Locate `recursive_residuals.R`, `statistics.R`, package public function definitions and their tests inside the **protected published master**.
2. Map the exact R innovation transformation, indexing, any weighting and centering, normalization, test statistic(s), random-effect/BLUP processes and estimator conventions, including treatment of unbalanced clusters, missingness and ties.
3. Translate these functions into Python without altering the published definitions; compare not just this independent prototype's formulas, but actual package outputs.
4. Independently check vectors and final statistics for both datasets and relevant misspecification simulations, with error tolerance and failure report.
5. Bootstrap refit-calibration parity is out-of-scope for *this* release; all model-level p-values must remain unavailable.
6. Public GitHub may describe this as an **experimental non-bootstrap visualization / numerical prototype** after basic parity; PyPI/CRAN release as a validated method waits for original-source mapping and broader reproducibility.

**Hard policy:** Never mark an uncalibrated CUSUM as a rejected test based on universal Brownian-bridge critical values; the article's null is model-specific and requires refit calibration.

## Original source retrieval boundary

The prior original R sources remain on the user's Mac under the published master. They were not uploaded with the latest validation ZIP. This build environment cannot verify the exact published R code. Any claim of published-source parity is thus blocked until those actual files are inspected and tested. The `source-audit` command only locates files; it does not perform port verification.
