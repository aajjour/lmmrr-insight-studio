\name{rr_run_empirical_audit}
\alias{rr_run_empirical_audit}
\title{Run empirical audit}
\description{Runs the manuscript empirical bootstrap audit: BodyWeight (lme4 models M0 and M3; nlme CAR(1) model N1), sleepstudy (lme4 models RI and RS; nlme AR(1) models RI_AR1 and RS_AR1), and Pastes (P0--P3). The nlme cells are run after the lme4 cells so that the lme4 results do not depend on them.}
\usage{rr_run_empirical_audit(B = 999, seed = 20260622, include_produc = FALSE, verbose = TRUE)}
\arguments{\item{B}{Number of bootstrap refits.} \item{seed}{Random seed.} \item{include_produc}{Include optional Produc screen.} \item{verbose}{Print progress.}}
\value{A tibble of empirical audit results.}
\keyword{models}
