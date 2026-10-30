.align_vector <- function(x, n, name = "index") {
  if (is.null(x)) return(NULL)
  x <- as.vector(x)
  if (length(x) != n) {
    warning(name, " has length ", length(x),
            " but residual vector has length ", n,
            "; returning NA for this diagnostic.", call. = FALSE)
    return(NULL)
  }
  x
}

.safe_cor_abs <- function(x, y) {
  ok <- is.finite(x) & is.finite(y)
  if (sum(ok) < 3L || stats::sd(x[ok]) == 0 || stats::sd(y[ok]) == 0) {
    return(NA_real_)
  }
  abs(stats::cor(x[ok], y[ok]))
}

#' Ordered indexed recursive-residual process
#'
#' Orders the recursive residuals by a diagnostic index and forms the
#' cumulative process \eqn{S_z(r) = N^{-1/2}\sum_{j \le Nr} w_{\pi_z(j)}}.
#'
#' When the index has ties (for example a common measurement occasion), the
#' order of the tied residuals is arbitrary.  The column \code{block_end}
#' marks the last residual of each block of tied index values; scalar
#' summaries computed by \code{\link{rr_time_sup}} and \code{\link{rr_cvm}}
#' use only these block boundaries and are therefore invariant to the order
#' of tied observations.  For an index without ties every row is a block end.
#'
#' @param w Numeric vector of recursive residuals.
#' @param index Vector defining the diagnostic ordering.
#' @return A data frame with ordered index, residuals, r-grid, cumulative
#'   process \code{S}, and logical \code{block_end}.
#' @export
rr_indexed_process <- function(w, index) {
  empty <- data.frame(index = numeric(0), w = numeric(0), r = numeric(0),
                      S = numeric(0), block_end = logical(0))
  index <- .align_vector(index, length(w), "index")
  if (is.null(index)) return(empty)
  ok <- is.finite(w) & !is.na(index)
  if (sum(ok) == 0L) return(empty)
  w_ok <- as.numeric(w[ok])
  index_ok <- index[ok]
  o <- order(index_ok, seq_along(index_ok))
  n <- length(w_ok)
  idx_o <- index_ok[o]
  block_end <- if (n == 1L) TRUE else c(idx_o[-1L] != idx_o[-n], TRUE)
  data.frame(
    index = idx_o,
    w = w_ok[o],
    r = seq_len(n) / n,
    S = cumsum(w_ok[o]) / sqrt(n),
    block_end = block_end
  )
}

#' Supremum of an indexed recursive-residual CUSUM
#'
#' Computes \eqn{T_{z,\sup} = \max |S_z(r)|}, evaluated at the boundaries
#' between distinct index values so that the statistic does not depend on the
#' order of tied observations.  For a time index with \eqn{m_t} residuals at
#' occasion \eqn{t}, the boundary values are
#' \eqn{N^{-1/2}\sum_{s \le t} m_s \bar w_s}.
#'
#' @param w Numeric recursive residual vector.
#' @param index Diagnostic ordering index, e.g. time or fitted value.
#' @return Supremum absolute indexed CUSUM statistic.
#' @export
rr_time_sup <- function(w, index) {
  proc <- rr_indexed_process(w, index)
  if (nrow(proc) < 3L) return(NA_real_)
  max(abs(proc$S[proc$block_end]), na.rm = TRUE)
}

#' Integrated-square indexed recursive-residual statistic
#'
#' Computes a Cramer-von Mises-type statistic
#' \eqn{\int_0^1 S_z(r)^2 dr}, with the process evaluated at the boundaries
#' between distinct index values and weighted by block size.  Without ties this
#' equals the mean of \eqn{S_z(r_j)^2} over all residuals.
#'
#' @param w Numeric recursive residual vector.
#' @param index Diagnostic ordering index.
#' @return Cramer-von Mises-type integrated-square statistic.
#' @export
rr_cvm <- function(w, index) {
  proc <- rr_indexed_process(w, index)
  if (nrow(proc) < 3L) return(NA_real_)
  ends <- which(proc$block_end)
  sizes <- diff(c(0L, ends))
  sum(sizes * proc$S[ends]^2) / nrow(proc)
}

#' Time-indexed CUSUM processes, unstandardised and variance-standardised
#'
#' For residuals observed at ordered occasions \eqn{t = 1, \ldots, T}, returns
#' the occasion means \eqn{\bar w_t}, the numbers of contributing residuals
#' \eqn{m_t}, the unstandardised CUSUM \eqn{C_T(t) = \sum_{s \le t} \bar w_s},
#' the variance-standardised CUSUM
#' \eqn{C_T^*(t) = T^{-1/2}\sum_{s \le t} \sqrt{m_s}\,\bar w_s}, and the
#' observation-weighted process \eqn{S(t) = N^{-1/2}\sum_{s \le t} m_s \bar w_s}
#' used by \code{\link{rr_time_sup}}.  Ignoring parameter estimation,
#' \eqn{\mathrm{Var}(\bar w_t) \approx 1/m_t}; \eqn{C_T^*} removes this
#' \eqn{1/m_t} factor. The remaining first-order factor \eqn{1-\kappa_t} due
#' to fixed-effect estimation, and pointwise null standard deviations of all
#' three processes, are returned by \code{\link{rr_time_reference}}.
#'
#' @param w Numeric recursive residual vector.
#' @param time Occasion index (one residual per cluster and occasion).
#' @return A data frame with one row per occasion.
#' @export
rr_time_cusum <- function(w, time) {
  time <- .align_vector(time, length(w), "time")
  if (is.null(time)) return(NULL)
  ok <- is.finite(w) & !is.na(time)
  w <- w[ok]; time <- time[ok]
  occ  <- sort(unique(time))
  m_t  <- as.numeric(table(factor(time, levels = occ)))
  wbar <- as.numeric(tapply(w, factor(time, levels = occ), mean))
  data.frame(
    time = occ,
    m_t = m_t,
    wbar = wbar,
    C_T = cumsum(wbar),
    C_T_std = cumsum(sqrt(m_t) * wbar) / sqrt(length(occ)),
    S_obs = cumsum(m_t * wbar) / sqrt(length(w))
  )
}

#' Supremum of the variance-standardised time-indexed CUSUM
#'
#' @param w Numeric recursive residual vector.
#' @param time Occasion index.
#' @return \eqn{\max_t |C_T^*(t)|}; see \code{\link{rr_time_cusum}}.
#' @export
rr_time_sup_std <- function(w, time) {
  tc <- rr_time_cusum(w, time)
  if (is.null(tc) || nrow(tc) < 2L) return(NA_real_)
  max(abs(tc$C_T_std), na.rm = TRUE)
}

#' Group accumulation supremum
#'
#' @param w Numeric recursive residual vector.
#' @param group Grouping factor or vector.
#' @return Maximum absolute standardized group accumulation.
#' @export
rr_group_sup <- function(w, group) {
  group <- .align_vector(group, length(w), "group")
  if (is.null(group)) return(NA_real_)
  vals <- tapply(w, group, function(z) sum(z, na.rm = TRUE) / sqrt(length(z)))
  if (length(vals) == 0L || all(!is.finite(vals))) return(NA_real_)
  max(abs(vals), na.rm = TRUE)
}

#' Factor-level contrast supremum
#'
#' @param w Numeric recursive residual vector.
#' @param fac Factor defining diagnostic subgroups.
#' @return Maximum pairwise absolute standardized factor contrast.
#' @export
rr_factor_contrast_sup <- function(w, fac) {
  fac <- .align_vector(fac, length(w), "factor")
  if (is.null(fac)) return(NA_real_)
  fac <- as.factor(fac)
  levs <- levels(fac)
  if (length(levs) < 2L) return(NA_real_)
  vals <- sapply(levs, function(g) {
    idx <- which(fac == g)
    if (length(idx) == 0L) return(NA_real_)
    sum(w[idx], na.rm = TRUE) / sqrt(length(idx))
  })
  vals <- vals[is.finite(vals)]
  if (length(vals) < 2L) return(NA_real_)
  max(abs(as.vector(stats::dist(vals))), na.rm = TRUE)
}

#' Pooled absolute lag-one residual correlation
#'
#' Computes the absolute lag-one correlation by pooling adjacent within-cluster
#' recursive-residual pairs across clusters.
#'
#' @param w Numeric recursive residual vector.
#' @param group Cluster/group identifier.
#' @param time Optional within-cluster ordering variable. If omitted, the input
#'   order within each group is used.
#' @return Absolute pooled lag-one correlation.
#' @export
rr_acf1_pooled_abs <- function(w, group, time = NULL) {
  group <- .align_vector(group, length(w), "group")
  if (is.null(group)) return(NA_real_)
  if (is.null(time)) time <- ave(seq_along(w), group, FUN = seq_along)
  time <- .align_vector(time, length(w), "time")
  if (is.null(time)) return(NA_real_)
  dat <- data.frame(w = w, group = group, time = time)
  dat <- dat[order(dat$group, dat$time), , drop = FALSE]
  dat$w_lag <- ave(dat$w, dat$group, FUN = function(z) c(NA_real_, z[-length(z)]))
  .safe_cor_abs(dat$w, dat$w_lag)
}

# Internal helper: whitened fixed-effect design Xtilde = blockdiag(L_i^{-1}) X
# for an lme4 or nlme fit, in the row order of the residual tibble.
.whitened_design <- function(fit) {
  if (inherits(fit, "merMod")) {
    X <- as.matrix(lme4::getME(fit, "X"))
    Zt <- lme4::getME(fit, "Zt"); Lambda <- lme4::getME(fit, "Lambda")
    A <- Matrix::t(Zt) %*% Lambda
    V <- stats::sigma(fit)^2 * (as.matrix(Matrix::tcrossprod(A)) + diag(nrow(X)))
    return(forwardsolve(.chol_lower_safe(V), X))
  }
  if (inherits(fit, "lme")) {
    dat <- as.data.frame(nlme::getData(fit))
    X <- stats::model.matrix(stats::formula(fit), data = dat)
    if (ncol(X) != length(nlme::fixef(fit))) stop("could not rebuild the fixed-effect design matrix")
    grp <- as.character(fit$groups[[1L]]); ids <- unique(grp)
    Vlist <- .lme_marginal_covs(fit, ids)
    Xt <- matrix(NA_real_, nrow(X), ncol(X))
    for (id in ids) {
      idx <- which(grp == id)
      Xt[idx, ] <- forwardsolve(.chol_lower_safe(Vlist[[id]]), X[idx, , drop = FALSE])
    }
    return(Xt)
  }
  stop("fit must be an lme4::lmer or nlme::lme object")
}

#' First-order null reference for the time-indexed processes
#'
#' Computes pointwise null standard deviations of the time-indexed processes
#' returned by \code{\link{rr_time_cusum}} under the fitted model. Writing
#' \eqn{\tilde X = \mathrm{blockdiag}(\hat L_i^{-1})X} for the whitened
#' fixed-effect design and \eqn{H = \tilde X(\tilde X^\top \tilde X)^{-1}\tilde X^\top},
#' the occasion sums \eqn{u_t = \sum_{i} \hat w_{it}} have first-order null
#' covariance \eqn{A^\top (I - H) A}, where \eqn{A} is the residual-by-occasion
#' indicator matrix. Estimation of the fixed effects enters through \eqn{H};
#' estimation of the covariance parameters does not contribute at first order to
#' these linear processes. Hence
#' \eqn{\mathrm{Var}(\bar w_t) = m_t^{-1}(1-\kappa_t)} with
#' \eqn{\kappa_t = m_t^{-1} a_t^\top H a_t}. The returned standard deviations
#' give pointwise (not simultaneous) reference bands.
#'
#' @param fit A fitted \code{lme4::lmer} or \code{nlme::lme} model.
#' @param time Occasion index aligned with the rows of the residual tibble
#'   (e.g. \code{rr_recursive_residuals_lmer(fit)$Days}).
#' @return A data frame with one row per occasion: \code{time}, \code{m_t},
#'   \code{kappa_t}, and the pointwise null standard deviations \code{sd_C_T},
#'   \code{sd_C_T_std} and \code{sd_S_obs} of the processes in
#'   \code{\link{rr_time_cusum}}.
#' @export
rr_time_reference <- function(fit, time) {
  Xt <- .whitened_design(fit)
  time <- as.vector(time)
  if (length(time) != nrow(Xt)) stop("time must have one entry per residual")
  occ <- sort(unique(time))
  A <- sapply(occ, function(t) as.numeric(time == t))
  m_t <- colSums(A)
  AX <- crossprod(A, Xt)                                   # T x p
  covU <- diag(m_t, length(occ)) - AX %*% solve(crossprod(Xt), t(AX))
  N <- nrow(Xt); T_occ <- length(occ)
  lower <- lower.tri(diag(T_occ), diag = TRUE) * 1          # cumulative-sum operator
  sd_of <- function(wts) sqrt(pmax(diag(lower %*% (outer(wts, wts) * covU) %*% t(lower)), 0))
  data.frame(
    time = occ,
    m_t = m_t,
    kappa_t = 1 - diag(covU) / m_t,
    sd_C_T = sd_of(1 / m_t),
    sd_C_T_std = sd_of(1 / sqrt(m_t * T_occ)),
    sd_S_obs = sd_of(rep(1 / sqrt(N), T_occ))
  )
}
