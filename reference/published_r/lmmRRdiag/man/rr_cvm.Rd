\name{rr_cvm}
\alias{rr_cvm}
\title{Integrated-square statistic}
\description{Computes a Cramer-von Mises-type indexed residual statistic \eqn{\int_0^1 S_z(r)^2 dr}, evaluated at the boundaries between distinct index values and weighted by block size, so that it is invariant to the order of tied observations.}
\usage{rr_cvm(w, index)}
\arguments{\item{w}{Numeric residual vector.} \item{index}{Ordering index.}}
\value{A numeric statistic.}
\keyword{models}
