# Optional synthetic demonstration studio

This folder contains the earlier educational Insight Studio browser interface, synthetic demo data, and an optional R Shiny prototype.

**Its synthetic envelopes and apparent red signals are not real model-level inferential findings.** It does not automatically ingest the non-bootstrap Cholesky innovation series from the parent package, and it does not run refit-bootstrap calibration. Use `../results/nonbootstrap_report.html` to inspect actual two-dataset numeric diagnostics.

From the parent directory: `./run_mac.sh studio` (the browser app). Exit with Ctrl+C. To run the optional Shiny demo, run `Rscript -e 'shiny::runApp("studio_demo/shiny_optional")'` after installing Shiny.
