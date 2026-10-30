\name{rr_recursive_residuals_lme}
\alias{rr_recursive_residuals_lme}
\title{Marginal Cholesky recursive residuals for nlme models}
\description{Computes marginal Cholesky recursive residuals for a linear mixed model fitted with \code{nlme::lme()}, including models with R-side correlation structures (e.g. \code{corAR1}, \code{corCAR1}) and variance functions. The fitted marginal covariance of each cluster is obtained from \code{nlme::getVarCov(type = "marginal")}. The within-cluster recursive ordering is the row order of the data, which should therefore be sorted by cluster and time.}
\usage{rr_recursive_residuals_lme(fit)}
\arguments{\item{fit}{A fitted \code{nlme::lme} object.}}
\value{A tibble containing the model data and a .rr column.}
\seealso{\code{\link{rr_recursive_residuals_lmer}}}
\keyword{models}
