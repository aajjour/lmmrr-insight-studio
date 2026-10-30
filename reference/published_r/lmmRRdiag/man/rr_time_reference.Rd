\name{rr_time_reference}
\alias{rr_time_reference}
\title{Closed-form first-order null reference for time-indexed processes}
\description{Computes pointwise null standard deviations of the unstandardised, variance-standardised and observation-weighted time-indexed processes of \code{\link{rr_time_cusum}} under the fitted model. With \eqn{\tilde X} the whitened fixed-effect design (rows \eqn{\hat L_i^{-1} X_i}) and \eqn{H = \tilde X(\tilde X^\top \tilde X)^{-1}\tilde X^\top}, the occasion sums of the recursive residuals have first-order null covariance \eqn{A^\top(I-H)A}, where \eqn{A} indicates the residuals observed at each occasion. Hence \eqn{\mathrm{Var}(\bar w_t) = (1-\kappa_t)/m_t} with \eqn{\kappa_t = a_t^\top H a_t / m_t}. Estimation of the covariance parameters does not contribute at first order to these linear processes. Pointwise (not simultaneous) bands are \eqn{\pm 1.96} times the returned standard deviations; simultaneous assessment uses a bootstrap-calibrated supremum (\code{\link{rr_bootstrap_pvalue}}).}
\usage{rr_time_reference(fit, time)}
\arguments{\item{fit}{A fitted \code{lme4::lmer} or \code{nlme::lme} model.} \item{time}{Occasion index aligned with the rows of the residual tibble.}}
\value{A data frame with columns time, m_t, kappa_t, sd_C_T, sd_C_T_std and sd_S_obs.}
\seealso{\code{\link{rr_time_cusum}}}
\keyword{models}
