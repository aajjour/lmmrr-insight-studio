\name{rr_time_sup}
\alias{rr_time_sup}
\title{CUSUM supremum statistic}
\description{Computes the supremum absolute indexed recursive-residual CUSUM, \eqn{\max |S_z(r)|}. The process is evaluated at the boundaries between distinct index values, so the statistic does not depend on the order of tied observations (e.g. residuals sharing a measurement occasion). For a time index this equals \eqn{\max_t |N^{-1/2}\sum_{s \le t} m_s \bar w_s|}.}
\usage{rr_time_sup(w, index)}
\arguments{\item{w}{Numeric residual vector.} \item{index}{Ordering index.}}
\value{A numeric statistic.}
\seealso{\code{\link{rr_time_cusum}}, \code{\link{rr_time_sup_std}}}
\keyword{models}
