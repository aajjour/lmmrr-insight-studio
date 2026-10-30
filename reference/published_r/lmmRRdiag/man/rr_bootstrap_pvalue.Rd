\name{rr_bootstrap_pvalue}
\alias{rr_bootstrap_pvalue}
\title{Bootstrap p-value calibration}
\description{Calibrates a scalar recursive-residual statistic by refitting parametric bootstrap under the fitted Gaussian LMM. For \code{lme4} fits, responses are simulated with \code{simulate()} and the model is refitted with \code{lme4::refit()}. For \code{nlme::lme} fits, responses are simulated from the fitted marginal Gaussian law of each cluster (including any R-side correlation structure and variance function) and the original \code{lme()} call is re-evaluated on the simulated data. The design, cluster sizes and observation pattern are held fixed.}
\usage{rr_bootstrap_pvalue(fit, statistic, B = 999, seed = NULL, label = "bootstrap", verbose = TRUE)}
\arguments{\item{fit}{A fitted \code{lme4::lmer} (merMod) or \code{nlme::lme} object.} \item{statistic}{Function of the residual tibble returning one number.} \item{B}{Number of bootstrap refits.} \item{seed}{Optional seed.} \item{label}{Progress label.} \item{verbose}{Print progress.}}
\value{A tibble with observed statistic, p-value, and bootstrap summaries.}
\keyword{models}
