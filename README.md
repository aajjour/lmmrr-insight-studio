# LMM RR Insight Studio — R and Python


## Python API: the actual published recursive-residual engine (R-backed)

**Python users can now call the original published `lmmRRdiag` recursive-residual implementation** from Python, without rewriting the mathematics or manually using R. The bridge uses `Rscript`, `lme4`, and the original MIT-licensed R source included under `reference/published_r/lmmRRdiag/`. It is **R-backed**, not a pure-Python translation, and does not run bootstrap.

```python
from lmmrr_crosslang import inspect_published_rr, run_published_rr
print(inspect_published_rr()["signature"])
result = run_published_rr(
    "fixtures/sleepstudy.csv",
    "y ~ x + (1 | group)",
    output_dir="results/published_python_rr/sleepstudy_RI",
)
print(result["numeric_csv"])
print(result["numeric_html"])
```

To test the bridge on your Mac before publication, run `./run_python_rr_mac.sh`. This invokes the real published R recursive residuals and **no bootstrap**. See [Python published-R engine instructions](docs/PYTHON_PUBLISHED_R_ENGINE.md). Original algorithm citation: [DOI 10.1080/00949655.2026.2748404](https://doi.org/10.1080/00949655.2026.2748404). The earlier paired Python/R prototype remains independently labeled; it is not represented as a native port of the published algorithm.



## Cite the published methodology

**Bani-Mustafa, A., & Al-Nasser, A. D. (2026).**
*Indexed recursive residual processes for diagnostic assessment
of linear mixed models.*
Journal of Statistical Computation and Simulation.

**DOI:** https://doi.org/10.1080/00949655.2026.2748404

If you use this repository in research, please cite the
published methodological article.

The original R bootstrap source is included, but bootstrap
execution and independent Python bootstrap equivalence
are not established in this release.


**Research software source release with original published R bootstrap code.**

- R/Python non-bootstrap prototype: previously compared on sleepstudy and Orthodont.
- Published R bootstrap source: included without execution or numerical validation.
- Native Python equivalence to the complete published RR algorithm: not established.
- Red graphical markers: descriptive flags, not calibrated misspecification tests.

Publication: https://doi.org/10.1080/00949655.2026.2748404

## Published R implementation

The original source is preserved under
`reference/published_r/lmmRRdiag/`.

The complete scientific methodology and bootstrap calibration should be
cited through the published paper.

---

# LMM RR Cross-Language Diagnostic Studio — R + Python

**Pre-release candidate — non-bootstrap / non-inferential core. Not yet a verified Python port of the published `lmmRRdiag`.**

[![status](https://img.shields.io/badge/scientific%20status-pre--release-amber)](#scientific-status)
[![R](https://img.shields.io/badge/R-reference%20core-276DC3)](R/rr_core.R)
[![Python](https://img.shields.io/badge/Python-matched%20prototype-3776AB)](lmmrr_crosslang/core.py)

**Find this repository if you are looking for:** linear mixed-model diagnostics, multilevel model checking, mixed-effects residuals, recursive residuals, indexed residual processes, CUSUM, Cholesky innovations, random-intercept/random-slope models, longitudinal data, cluster dependence, residual visualization, misspecification exploration, R/Python model diagnostics, or comparison of `lme4` and `statsmodels`.

### What the software actually does

- Reads model parameters estimated by R `lme4` on **sleepstudy** and **Orthodont** (included real datasets; 4 RI/RS specifications).
- Computes clusterwise **marginal Cholesky innovation residuals** from exactly specified design matrices and fitted covariance parameters, with a matched formula in R and Python.
- Orders those innovations by scientific index (time/age, marginal fitted mean, or reverse time) and computes ordinary and centered indexed CUSUM traces.
- Exports numerical summaries and renders a locally viewable, responsive HTML evidence matrix and 12 SVG process charts, including descriptive individual extremes.
- Bundles the original **educational synthetic interactive demo** and optional Shiny example under `studio_demo/` to preserve the six design deliverables; this is distinct from the real-dataset numerical report.
- Runs numerical invariance tests and a separate **12-case R/Python consistency gate** on a Mac with R installed.

### What it does *not* do

- It does **not** yet establish identity to the published `lmmRRdiag` implementation; the original R reference source must be reviewed and numerical trajectories compared.
- It does **not** compute refit-bootstrap envelopes, global p-values, Holm adjustments, type-I-error rates, power, probabilities of specific defects, or automated model improvement.
- Red dots mark observations with **absolute marginal Cholesky innovation ≥ 3** (an exploratory numerical flag, *not* a model-level test). All model-level inference is amber/unavailable, including for small observed process excursions.
- It does **not** declare a missing random slope, variance misspecification or serial correlation solely from a process pattern.

### Scientific background

This is a companion exploratory implementation for the methods described in:

Ahmed Bani-Mustafa and Amjad D. Al-Nasser (2026). **Indexed recursive residual processes for diagnostic assessment of linear mixed models.** *Journal of Statistical Computation and Simulation*. DOI: [10.1080/00949655.2026.2748404](https://doi.org/10.1080/00949655.2026.2748404).

The published methodology uses model-dependent indexed residual processes and **refit parametric-bootstrap calibration**; this repository is *not* a substitute for that calibration.

## Mac installation and run

Download/unzip this repository; from Terminal:

```bash
cd ~/Downloads && \
unzip -qo LMM_RR_NonBootstrap_R_Python_Release_Candidate_2026-10-30.zip && \
cd LMM_RR_NonBootstrap_R_Python_Release_Candidate_2026-10-30 && \
python3 -m venv .venv && \
source .venv/bin/activate && \
python3 -m pip install -e . && \
chmod +x run_mac.sh && \
./run_mac.sh all
```

The R/Python check uses **base R only**, with R-fitted parameters already exported in `fixtures`. `Rscript` is required on Mac for `all` or `parity`.

For individual tasks:

```bash
./run_mac.sh selftest    # independent Python mathematical/unit tests
./run_mac.sh report      # results/nonbootstrap_report.html
./run_mac.sh parity      # regenerate R results and compare 12 cases, strict tolerance
./run_mac.sh source-audit # locate original published R sources, read only
./run_mac.sh studio       # synthetic interactive browser demo, no calibrated inference
```

Open results: `open results/nonbootstrap_report.html`.

## Python API example

```python
from lmmrr_crosslang import compute, get_input
x = get_input('fixtures', 'sleepstudy', 'RS', 'time')
result = compute(x)
print(result['features'])
print(result['inference']['global_alarm'])  # NOT_AVAILABLE
```

## R API example

```r
source('R/read_fixtures.R')
x <- rr_fixture_input('fixtures', 'sleepstudy', 'RS', 'time')
result <- do.call(rr_nonbootstrap_core, x)
print(result$features)
print(result$inference$global_alarm)  # NOT_AVAILABLE
```

## Scientific status

| Gate | Status | Evidence |
|---|---|---|
| Ordinary LMM parameter fit R vs Python | Previously passed on two datasets | See preceding independent audit; independent of this port |
| Python mathematical identity/invariance tests | Tested locally | Unit-test logs |
| This prototype's R vs Python numerical parity | **Requires Mac R execution** | `results/parity/cross_language_results.json` |
| Equivalence to published `lmmRRdiag` R algorithm | **Not tested; publication blocker for native-port claim** | `./run_mac.sh source-audit` |
| Refit bootstrap calibration | **Explicitly excluded** | Not implemented |
| Release to PyPI/CRAN as fully validated model diagnostic | **Not approved** | Needs source parity, calibration and software QA |

A matching code structure is not proof of cross-language equivalence. A passing R/Python result on fixtures is still not proof of identity with the published article's software.

## GitHub discoverability

This project includes `AGENTS.md`, `CITATION.cff`, `codemeta.json`, `.github/workflows`, `docs/RELEASE_GATE.md` and searchable topics. Proposed repository name: `lmmrr-insight-studio`. Do **not** tag this pre-release as a verified, calibrated Python implementation of the published diagnostic method.

## License and source limitations

New prototype source is supplied under MIT. Do not redistribute source from the published R package or its supplementary materials without independently checking its license and provenance. No original published R package code has been copied into this release candidate.

### Sending back validation results

After `./run_mac.sh all`, use:

```bash
./zip_results.sh
```

This creates `~/Downloads/LMM_RR_NonBootstrap_Parity_Mac_Results_2026-10-30.zip`, with the numerical R/Python comparison, report, and original-source inventory when available. Upload that ZIP to continue the original-package parity review.

**GitHub push is deliberately not executed in this package.** For eventual GitHub setup, see `docs/GITHUB_RELEASE.md` and `scripts/github_prepare.sh`; only a private exploratory repository is suggested at this stage.
