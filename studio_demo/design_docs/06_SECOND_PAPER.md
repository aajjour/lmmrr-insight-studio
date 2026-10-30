# 6 — Potential scientific software/methods paper (PROPOSAL, not a completed validation)

## Provisional title

**Evidence-Calibrated Interpretation and Interactive Reporting of Indexed Recursive-Residual Diagnostics for Linear Mixed Models**

## Positioning

Distinguish the published 2026 *indexed RR theoretical framework* from the new, independently studied question: can transparent process-level evidence synthesis improve diagnostic decisions without increasing false attribution or overconfidence? User experience alone is not a sufficient new methodology contribution.

## Specific research questions

- **RQ1 (calibration):** Does the reporting layer preserve nominal process/global and familywise false-signal rates when it reports calibrated evidence? Are missing/incomplete refit results handled without false significance?
- **RQ2 (decision utility):** Does structured reporting improve selection of correct follow-up analyses (and reduce unjustified diagnostic claims) over ordinary RR plots and conventional residual diagnostics?
- **RQ3 (identifiability):** Which defects can reliably be differentiated from indexed process patterns, and which remain observationally confounded?
- **RQ4 (robustness):** Does performance generalize to independent generators, variable group sizes and follow-up imbalance, correlated random effects, and unseen defects?

## Candidate paper outline

1. Introduction — gap between calibrated RR tests and human diagnostic interpretation.
2. Related work — graphical model criticism, residual tooling, decision-support constraints, visual diagnostics.
3. Existing indexed RR methodology — cite 2026 article, avoid repeating its proof as new work.
4. Interpretation and provenance contract — traces, process family, Holm, feature map, uncertainty qualification, abstention rules.
5. Interactive design — annotated panels, comparison, audit-friendly reports, accessibility.
6. Prospective independent validation — generator, true labels, fixed algorithm, thresholds, methods, simulation budget and power.
7. Results — process-level FWER, incorrect-specificity, sensitivity/precision, class confusion, CPU/memory and user study.
8. Application — BodyWeight / sleepstudy / Pastes / Produc with a separate heldout application if possible.
9. Limitations — non-identifiability, multi-causal departures, uncertainty from refit failure, risk of false confidence.
10. Reproducibility, package links, dataset provenance and conclusion.

## Minimum prospective design

Prespecify 16 published alternatives plus correct specification and independent novel alternatives, each at multiple cluster counts and imbalance regimes. Separately define **model-diagnostic flag correctness** and **true-category classification correctness**. For each scenario record the true generating defects, all process decisions, all reported descriptive leads, abstentions, and exact simulation success/failed-fit counts.

- Main performance: per-process and familywise false-positive rates under null, power by defect and design, incorrect defect-specific signal probabilities, precision of false-alarm estimates.
- Attribution accuracy: multi-label confusion matrices (true mechanism × suggested category) with unidentifiable and abstain cells, micro/macro F1 only if defined meaningfully for the multilabel task.
- Numerical quality: bootstrap resolution, repeated-seed coverage, refit failures, correspondence of old/new outputs, independent implementations where possible.
- Reader study: stratified statistician/graduate/applied users, randomized chart-only versus evidence-aware UI, prespecified primary outcome and uncertainty measures, paired analysis avoiding pseudoreplication.
- Forecasting: run-time planning forecasts for B refits with heldout comparison and precision margin; do not promise a runtime based on one Mac.

## No-go statements

Do not call the rulebook a validated classifier until an independently generated test population demonstrates type-level error control. A visually appealing red alert may increase misinterpretation unless paired with explicit epistemic limitations and training.

## Target venues

A strong scientific-software article could eventually be evaluated for **The R Journal** or **Journal of Statistical Software** if mature software and externally validated scientific contribution exist. These are *prospective options*, not claims of current acceptance probability or submission eligibility.
