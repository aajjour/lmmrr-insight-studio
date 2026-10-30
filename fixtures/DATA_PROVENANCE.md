# Reference datasets and fitted parameter provenance

`fixtures/sleepstudy.csv` and `fixtures/Orthodont.csv` were exported on the user's Mac from the R packages `lme4` and `nlme`, respectively, as part of the earlier actual R-versus-Python fit comparisons. `r_metrics.csv` contains the corresponding four `lme4::lmer` REML parameter exports. `r_session_info.txt` preserves the R session package/version information.

The files are **benchmark data and fit outputs**, not patient records. They are included here for numerical repeatability, but their original upstream license and attribution requirements must be reviewed before a public distribution. The MIT license on the new prototype source does not override third-party data or package licenses.

These source files are not the published `lmmRRdiag` numerical outputs. This release candidate only checks a deliberately specified cross-language non-bootstrap innovation/CUSUM implementation.
