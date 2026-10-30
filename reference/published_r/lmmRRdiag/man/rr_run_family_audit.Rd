\name{rr_run_family_audit}
\alias{rr_run_family_audit}
\title{Family-wise calibration of the empirical diagnostics}
\description{Runs \code{\link{rr_bootstrap_family}} for every model of the manuscript's empirical audit, with the declared families BodyWeight \{lag-one ACF, time CUSUM, diet contrast\}, sleepstudy \{lag-one ACF, subject accumulation, time CUSUM\} and Pastes \{batch:cask, batch, and cask-label accumulation\}.}
\usage{rr_run_family_audit(B = 999, seed = 20260930, verbose = TRUE)}
\arguments{\item{B}{Number of bootstrap refits per model.} \item{seed}{Random seed.} \item{verbose}{Print progress.}}
\value{A tibble with one row per model and diagnostic.}
\keyword{models}
