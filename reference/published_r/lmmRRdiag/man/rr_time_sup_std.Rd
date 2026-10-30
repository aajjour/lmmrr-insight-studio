\name{rr_time_sup_std}
\alias{rr_time_sup_std}
\title{Supremum of the variance-standardised time-indexed CUSUM}
\description{Computes \eqn{\max_t |C_T^*(t)|} for the variance-standardised time-indexed process of \code{\link{rr_time_cusum}}. It can be calibrated with \code{\link{rr_bootstrap_pvalue}}.}
\usage{rr_time_sup_std(w, time)}
\arguments{\item{w}{Numeric residual vector.} \item{time}{Occasion index.}}
\value{A numeric statistic.}
\keyword{models}
