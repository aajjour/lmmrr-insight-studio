\name{rr_bootstrap_family}
\alias{rr_bootstrap_family}
\title{Family-wise (single-step min-p) bootstrap calibration}
\description{Evaluates a declared family of scalar recursive-residual diagnostics on common refitting parametric-bootstrap replicates and returns, for each diagnostic, the marginal bootstrap p-value and the single-step min-p adjusted p-value of Westfall and Young (1993). The observed data and the replicates form one pooled set of \eqn{B+1} values; each member receives, for every diagnostic, the p-value \eqn{\#\{j: T_{jk} \ge T_{ik}\}/(B+1)}, and the adjusted p-value of diagnostic \eqn{k} is the proportion of the pooled set whose smallest p-value over the family does not exceed the observed p-value of diagnostic \eqn{k}. The selection of the most extreme member is thereby reproduced within every replicate. Under the conditions of parametric-bootstrap consistency this controls asymptotically the probability that any member of the declared family is flagged when the fitted model is correctly specified (weak family-wise control); error-controlled attribution to an individual member (strong control) would require subset pivotality.}
\usage{rr_bootstrap_family(fit, statistics, B = 999, seed = NULL, verbose = TRUE)}
\arguments{\item{fit}{A fitted \code{lme4::lmer} or \code{nlme::lme} model.} \item{statistics}{A named list of functions of the residual tibble, each returning one number.} \item{B}{Number of bootstrap refits.} \item{seed}{Optional seed.} \item{verbose}{Print progress.}}
\value{A tibble with columns diagnostic, statistic_observed, p_marginal, p_family_minp and B_success.}
\references{Westfall, P. H. and Young, S. S. (1993). \emph{Resampling-Based Multiple Testing: Examples and Methods for p-Value Adjustment}. Wiley, New York.}
\keyword{models}
