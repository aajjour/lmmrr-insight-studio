\name{rr_recursive_residuals_lmer}
\alias{rr_recursive_residuals_lmer}
\title{Marginal Cholesky recursive residuals}
\description{Computes marginal Cholesky recursive residuals for an lme4 linear mixed model. The within-cluster recursive ordering is the row order of the data, which should therefore be sorted by cluster and time.}
\usage{rr_recursive_residuals_lmer(fit)}
\arguments{\item{fit}{A fitted lme4 merMod object.}}
\value{A tibble containing the model frame and a .rr column.}
\seealso{\code{\link{rr_recursive_residuals_lme}}}
\keyword{models}
