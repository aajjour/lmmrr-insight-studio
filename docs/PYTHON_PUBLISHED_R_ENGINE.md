# Python access to the published `lmmRRdiag` engine

**Scientific reference:** [Indexed recursive residual processes for diagnostic assessment of linear mixed models](https://doi.org/10.1080/00949655.2026.2748404) — Ahmed Bani-Mustafa and Amjad D. Al-Nasser, *Journal of Statistical Computation and Simulation* (2026).

## Why this option

The package originally included a Python non-bootstrap **prototype** agreeing with a paired R prototype for 12 configurations. That parity does **not** imply equivalence with the original published recursive-residual algorithm. This bridge calls the published R function directly, from a Python program, so the published R calculations are used without inventing a native port. It is a Python-accessible **R-backed** implementation; it is **not** Python-only.

## Requirements

- Python 3.10+, the installed `lmmrr_crosslang` package.
- R executable `Rscript` in `PATH`, R packages `lme4` and `jsonlite`.
- Actual published R package source at `reference/published_r/lmmRRdiag/R/`. Its original MIT license accompanies the source.
- Only local CSV input is sent to R, via subprocess; no web service, shell interpolations or uploads.

## Inspect and run from Python

```bash
python3 -m lmmrr_crosslang.published_rr --inspect
python3 -m lmmrr_crosslang.published_rr \
  --data fixtures/sleepstudy.csv \
  --formula 'y ~ x + (1 | group)' \
  --output results/published_python_rr/sleepstudy_RI
```

Python usage:

```python
from lmmrr_crosslang.published_rr import inspect_published_rr, run_published_rr

print(inspect_published_rr()["signature"])
response = run_published_rr(
    data="fixtures/sleepstudy.csv",
    formula="y ~ x + (1 | group)",
    output_dir="results/published_python_rr/sleepstudy_RI",
)
print(response["numeric_csv"])
```

A `pandas.DataFrame` can replace the CSV path. Any additional arguments required by the **original R function** can be passed in `rr_options={...}`; inspect its signature first. Required arguments not exposed in this default example may need to be supplied explicitly. The bridge raises the original R error and displays its formal arguments rather than silently constructing a different algorithm.

## Outputs

- `published_rr_result.rds`: exact R output object, retained for audit.
- `published_rr_numeric_components.csv`: lossless finite scalar numeric components with **original object paths**, not reassigned model-diagnostic labels.
- `published_rr_structure.txt`: R object structure to guide downstream plotting.
- JSON response includes fitted coefficients, residual-return class, paths, and DOI.

The interface does not fabricate p-values, confidence envelopes, or automatic diagnosis. Bootstrap is not called, checked, or claimed. R source `bootstrap.R` remains included for researchers who intentionally choose to run it themselves.

## Publication gate

The Python API can be described as *R-backed Python access to the original published RR engine* **only after** `./run_python_rr_mac.sh` succeeds on the author's Mac. Until then the actual runtime integration is unverified, because the packaging environment has no R executable. This should not be described as a verified pure-Python port.
