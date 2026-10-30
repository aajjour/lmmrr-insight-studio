\name{rr_time_cusum}
\alias{rr_time_cusum}
\title{Unstandardised and variance-standardised time-indexed CUSUM}
\description{For residuals observed at ordered occasions, returns one row per occasion with the number of contributing residuals \eqn{m_t}, the occasion mean \eqn{\bar w_t}, the unstandardised CUSUM \eqn{C_T(t)=\sum_{s\le t}\bar w_s}, the variance-standardised CUSUM \eqn{C_T^*(t)=T^{-1/2}\sum_{s\le t}\sqrt{m_s}\,\bar w_s}, and the observation-weighted process \eqn{N^{-1/2}\sum_{s\le t} m_s\bar w_s} used by \code{\link{rr_time_sup}}. Ignoring parameter estimation, \eqn{\mathrm{Var}(\bar w_t)\approx 1/m_t}; \eqn{C_T^*} removes this \eqn{1/m_t} factor. The remaining first-order factor due to fixed-effect estimation, and pointwise null standard deviations of all three processes, are given by \code{\link{rr_time_reference}}.}
\usage{rr_time_cusum(w, time)}
\arguments{\item{w}{Numeric residual vector.} \item{time}{Occasion index (one residual per cluster and occasion).}}
\value{A data frame with columns time, m_t, wbar, C_T, C_T_std, and S_obs.}
\seealso{\code{\link{rr_time_reference}}, \code{\link{rr_time_sup_std}}, \code{\link{rr_time_sup}}}
\keyword{models}
