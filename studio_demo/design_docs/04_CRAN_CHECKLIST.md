# 4 — CRAN-readiness / release dossier

The included `R_package_candidate/lmmRRinsight` is a deliberately limited reporting skeleton. It has NOT been submitted to CRAN and was NOT run in an R environment during its initial build. It should NOT be presented as `lmmRRdiag` 2.0 without author validation and source integration.

## Release gates

- [ ] Review original package source in preserved 76 MB master and confirm author ownership/license; avoid republishing unlicensed data or private patient records.
- [ ] Resolve name with CRAN, avoid collisions; decide extension vs integrated `lmmRRdiag` package based on user-facing usability and maintenance costs.
- [ ] Preserve published numerical algorithm identically unless separately validated; regression-reference bootstrap test outputs from all four empirical examples.
- [ ] Establish R unit tests for null, true signal, wrong indexing, invalid envelopes, seed reproducibility, missing family member, bootstrap fit failure, and character escaping.
- [ ] Add end-to-end CI across current R on macOS, Windows, Linux; run `R CMD check --as-cran` on build tarball with 0 ERROR, 0 WARNING and justified NOTE review.
- [ ] Provide `DESCRIPTION`, `NAMESPACE`, full `.Rd`, `inst/CITATION`, tested vignettes and return-value examples. Check package size (aim ≤10MB), light tests, no external network needed during checks.
- [ ] Keep parallelism at ≤2 simultaneous cores during CRAN checks; large B=999 runs belong outside the routine tests and package tarball.
- [ ] Load the Shiny interface lazily through `Suggests`; avoid launching browser during R package examples/tests.
- [ ] Verify citation to published paper DOI `10.1080/00949655.2026.2748404`; test `citation('lmmRRinsight')` and `citation('lmmRRdiag')` after eventual integration.
- [ ] Document the distinction between descriptive feature thresholds and calibrated hypothesis tests prominently in user-facing outputs.
- [ ] Obtain final copyright, license and authorship clearance for actual published implementation and any supplementary datasets.
- [ ] Create release tags, checksums, changelog, reproducibility DOI, GitHub issue templates and maintenance policy.

## Commands on a Mac with R installed

```bash
./run_mac.sh cran-check
# Or explicitly:
cd R_package_candidate
R CMD build lmmRRinsight
R CMD check --as-cran lmmRRinsight_0.1.0.tar.gz
```

**Do not submit if the `R CMD check` fails**; even a clean check is necessary but insufficient for a scientific release.

## Positioning

The novelty is the rigorously calibrated, indexed recursive residual diagnostic method reported in the paper. A visually attractive wrapper alone is a software interface enhancement, not a new statistical inferential result. A second methods paper requires independent validation of interpretation accuracy and error rates, not merely a dashboard.

## Official references

- CRAN Policy: https://cran.r-project.org/web/packages/policies.html
- Writing R Extensions: https://cran.r-project.org/doc/manuals/r-devel/R-exts.html
- Shiny getting started: https://shiny.posit.co/r/getstarted/shiny-basics/lesson1/
