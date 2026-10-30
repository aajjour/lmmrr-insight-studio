# 2 — API, data contract and S3 package blueprint

## Current runnable interface

`traces.csv` columns (1 row per index and process):

| Field | Meaning |
|---|---|
| `model` | Unique fitted-model identifier for matching and comparisons. |
| `process` | Named process, e.g. `mean_indexed`, `cluster_indexed`, `blup_indexed`, `serial_indexed`; custom values accepted but interpretation becomes generic. |
| `index` | Strictly increasing, finite numeric ordering coordinate (at least 20 rows per process). |
| `observed` | Indexed residual process computed by published backend — not raw residuals. |
| `lower`, `upper` | Supplied envelope, finite and `lower < upper` at each index. The UI cannot verify whether bounds are pointwise, simultaneous, or refit-calibrated. |

`evidence.csv` columns (exactly 1 row per model × process):

| Field | Required constraint |
|---|---|
| `model`, `process` | Exact match to trace keys. |
| `p_value` | Supplied *global process* p-value, blank if unavailable (never invented). |
| `calibration` | Literal `refit_parametric_bootstrap` to be eligible. |
| `scope` | Literal `global_process` to be eligible. |
| `b_refits` | Successful refits used, at least 99; valid p-value must respect minimum attainable `1/(B+1)` for plus-one Monte Carlo counts. |
| `origin` | Literal `user_supplied` to be eligible, or `synthetic_demo` for illustrative traces. |
| `family_id` | Stable identifier of a prespecified hypothesis family within one model. |
| `family_size` | Complete number of members of the family, all required for Holm inference. |
| `demo_signal` | `true` / `false`; ignored for actual data, visual synthetic demo only. |

**Critical:** These fields assert provenance; the UI does not scientifically authenticate that the backend truly refitted models, used the published ordering and calibrated the same statistic. That requires a separate numerical audit and immutable saved bootstrap metadata.

## Example R workflow

```r
source('R_bridge/rr_export.R')

# Replace with EXACT values returned by the published lmmRRdiag engine.
# No adapter can be finalized until the actual source/function signatures are inspected.
traces <- data.frame(
  model='LMM_1', process='mean_indexed', index=1:100,
  observed=NA_real_, lower=NA_real_, upper=NA_real_
)
# The above is only a schema template and must NOT be exported as findings.
# evidence must contain one row per test in the prespecified family.
# p_value may be blank when genuinely unavailable.

# rr_insight_export(actual_traces, actual_evidence, '/Users/me/RR_export')
```

Then `./run_mac.sh data /Users/me/RR_export`.

## Proposed final R interface (not implemented against native algorithm yet)

```r
# The names below describe the target API, not existing published lmmRRdiag functions.
diag <- lmmRRdiag::<actual_function>(fit, ...)
view <- rr_insight_bundle(traces = <mapped_trace_table>,
                          evidence = <mapped_process_level_tests>)
print(view)
summary(view)
plot(view, model='LMM_1', process='mean_indexed')
rr_insight_export(view, '/path/to/rr_export')
# In the standalone user-facing interface:
# ./run_mac.sh data /path/to/rr_export
```

Target S3 object (after actual integration):

```
rr_insight_bundle
  $model             fitting provenance and version
  $processes         observed indexed curves, index semantics, refit calibration
  $calibration       statistic, B, successful refits, seed, failure count, family
  $features          descriptive excursion metrics (not independent tests)
  $evidence          multiplicity adjusted process-level signals
  $interpretation    rule IDs, qualified text, follow-up action, limitations
  $plots             base/ggplot objects, accessible legends
  $comparison        matched-index differences and relevant caveats
```

## No hidden inference

A maximum observed envelope ratio is **not** a p-value. It is a screen summary only. A calibrated global process p-value is never reverse-engineered from the plotted bounds. Holm correction across the complete family is a conservative, transparent interim policy; determine whether the published simultaneous calibration already accounts for process multiplicity, to avoid unneeded double adjustment.

## Code locations

- Python validation/feature/adjustment engine: `app/engine.py`
- JavaScript UI: `app/app.js`, `app/index.html`, `app/style.css`
- HTML report: `app/report.py`
- R bridge: `R_bridge/rr_export.R`
- R package experiment: `R_package_candidate/lmmRRinsight/`
- Optional Shiny UI: `shiny_optional/app.R`
