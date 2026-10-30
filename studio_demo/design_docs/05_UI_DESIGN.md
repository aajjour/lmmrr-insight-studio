# 5 — Visual/interaction specification: research dashboard

## Implemented visual system

| Color role | Palette | Meaning |
|---|---|---|
| Red signal | `#B92F3E` (high contrast on soft rose) | Reported calibrated global process signal after Holm, **or explicitly labelled synthetic red demonstration** |
| Green non-signal | `#197B62` | Eligible adjusted p exceeds alpha; does not mean model correct |
| Amber uncertainty | `#B57B21` | No eligible/complete calibration, despite possible graphical crossing |
| Blue information | `#286AB1` | Observed indexed process, neutral navigation and typography |
| Slate background | `#F5F8FD`, `#132241` | Supporting neutral components and sidebar |

Never rely on color alone; every card includes a textual label, and the chart distinguishes observed/bounds/crossings by line and symbol.

## Screens, all included in the working local app

1. **Overview:** process counts, calibrated status, departure counts, provenance, process cards, guarded narrative and recommendations.
2. **Process explorer:** model/process selection, index-window focus, supplied envelope, observed curve, red crossing markers, hover values and descriptive features.
3. **Compare models:** per-process status matrix, adjusted p where eligible, exploratory metric, candidate follow-up map.
4. **Interpretation guide:** color contract, constraints, links to the 2026 journal paper.
5. **Report path:** self-contained HTML with embedded SVG graphs; browser Print → Save as PDF, and CSV summary export.

## Proposed next Shiny design (the optional starter is also included)

`shiny_optional/app.R` demonstrates the package-to-Shiny route. For a production UI, use a two-column `bslib` value-box layout with modular tabs, `plotly` hover for cluster metadata, a model comparator that checks comparability, filtered per-cluster diagnostics and downloadable `.html`, `.pdf`, `.csv` outputs. Put expensive bootstrap refits in a background job outside CRAN's routine check and expose progress/cancel states.

Before permitting click-through cluster records, evaluate privacy, leakage of identifiers, and minimum group-size disclosure; a dashboard for real clinical data must not silently publish patient-level records or send them to third-party services.

## User study metrics

- Correct identification of *a diagnostic signal*, not forced category selection.
- Correctly qualified source hypotheses and selection of meaningful follow-up.
- Correct understanding of red and green states and whether multiplicity was addressed.
- Task completion time, error rates, usability (SUS), comprehension in graduate and applied cohorts.
- Misplaced confidence (false-specificity and unwarranted reassurance) as critical harms.

## Responsive QA

The web interface uses system fonts (no bundled fonts), native controls, selectable CSS color roles, server-side input validation and accessible textual color legends. The primary app requires no Shiny/plotly dependencies, but an R-native front end may be preferable for CRAN-first distribution.
