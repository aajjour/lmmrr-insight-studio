# 1 — Prioritized roadmap: lmmRRdiag v1 → interpretable v2

## Decision

**Go for an evidence-aware interpretation extension and visual interface; hold any claim that a rule engine identifies true misspecification types.** The current folder proves a user-experience concept, not improved statistical operating characteristics.

| Milestone | Scope | Acceptance criterion | Risk |
|---|---|---|---|
| R0 source audit | Reconcile published lmmRRdiag source/API, manuscripts, R package license, tests, data, results | Native processes, per-index ordering, envelope and globally calibrated p-values reproduced on 4 paper examples | Critical |
| R1 interpreter | Validated structured diagnostic object, Holm families, evidence provenance, no overclaims | Null and malformed-input gates, deterministic tests, provenance traceable to bootstrap output | High |
| R2 graphic reporting | Clear red/green/amber/neutral, annotated traces, location, cluster cues, HTML report | Accessible chart, no uncalibrated inferential language, PDF print path | Medium |
| R3 user workflows | Indexed process comparison and model-to-model descriptive changes | Diagnostics compared on matched data/indexing and prespecified model contrasts; no naive p-value ranking | Medium |
| R4 independent validation | Fresh null/misfit generators; error tables; blinded user study | Nominal global/familywise false alarm, classification confusion, stability, reproducibility and calibration precision quantified | Critical |
| R5 CRAN integration | Mature lmmRRdiag with optional `shiny` or self-contained companion | `R CMD check --as-cran` across OS, dependency and license checks, versioned artifacts | High |
| R6 publication & outreach | Tutorial, reproducibility DOI, software note if warranted | Reproducible quantitative gains in user comprehension and correct response, not merely appealing plots | Medium |

## Work packages and ownership

**Methodological/statistical (lead):** fix class taxonomy, freeze exact process-to-hypothesis claims, choose familywise error rule and prespecified alpha, assess invalid/missing bootstrap outputs, define independent true-category simulation audit, select appropriate comparison standards (conditional/studentized residual diagnostics, DHARMa/HLMdiag as applicable), measure false-specific-attribution risk.

**Engineering/software:** extract native lmmRRdiag outputs, ensure lossless round trips, restore reproducibility metadata (seed, B, fit provenance, software version), benchmark runtime/memory, establish cross-platform CI, implement UI and report exports, package documentation and secure local operation.

## Integration risk

The existing `lmmRRdiag` package appears within saved research packages but its actual native object schema is **not available to this build**. Neither a function name nor a numerical equivalence result should be fabricated. `run_mac.sh audit-master` is intentionally read-only. The integration gate cannot be marked passed until native outputs are supplied.

## Release versions (provisional)

- **Prototype 0.1:** This stand-alone insight studio, synthetic demo and CSV contract.
- **Experimental 0.2:** Native backend adapter, provenance, model comparisons, non-demo examples.
- **Candidate 0.5:** Validated inferential rules, independently generated-population audits, real user study.
- **Release 1.0 / 2.0 positioning:** Existing `lmmRRdiag` publication engine first; optional reporting UI added after tests. Version numbering belongs to the maintainer and should not be increased automatically.

## Suggested gates

1. Scientific novelty and method agreement.
2. Benchmark/data-integrity and objective simulation truth.
3. Statistical identifiability, calibration, false-signal and precision checks.
4. Reproducibility, portability, CRAN policy and documentation checks.

No release or publication inference may proceed on UI screenshots alone.
