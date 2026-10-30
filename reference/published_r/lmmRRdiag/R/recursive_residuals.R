# Internal helper: safe lower-triangular Cholesky factor
.chol_lower_safe <- function(V) {
  V <- as.matrix(V)
  storage.mode(V) <- "double"
  V <- (V + t(V)) / 2
  tryCatch(
    t(chol(V)),
    error = function(e) {
      V_pd <- as.matrix(Matrix::nearPD(V, corr = FALSE, keepDiag = TRUE)$mat)
      t(chol(V_pd + diag(1e-8, nrow(V_pd))))
    }
  )
}

# Internal helper: fitted marginal covariance matrices of an nlme::lme fit,
# one per outermost cluster, returned as a named list in the order of `ids`.
# nlme::getVarCov(type = "marginal") returns a *list* of matrices (class
# "VarCov"), so each element must be extracted with [[ ]], not as.matrix().
.lme_marginal_covs <- function(fit, ids) {
  V <- nlme::getVarCov(fit, type = "marginal", individuals = ids)
  if (!is.list(V)) V <- list(V)
  if (is.null(names(V))) names(V) <- ids
  lapply(V, as.matrix)
}

#' Marginal Cholesky recursive residuals for an lme4 LMM
#'
#' Computes the marginal-covariance-standardised recursive residuals for a
#' model fitted with \code{lme4::lmer()}.  The full marginal covariance matrix
#' \eqn{V = \sigma^2(Z\Lambda\Lambda^\top Z^\top + I)} is assembled from the
#' internal lme4 representation, a lower-triangular Cholesky factor \eqn{L}
#' is computed, and the whitened residual vector \eqn{w = L^{-1}r} is returned.
#'
#' @param fit A fitted \code{lme4::lmer} model (class \code{"merMod"}).
#' @return A \code{\link[tibble]{tibble}} containing the model frame columns
#'   and a \code{.rr} column of marginal Cholesky recursive residuals.
#' @details The recursive ordering within each cluster is the row order of the
#'   data, so the data should be sorted by cluster and by the within-cluster
#'   ordering variable (e.g. time) before fitting.  The implementation builds
#'   the full dense marginal covariance matrix and is suited for
#'   small-to-moderate datasets.  For models with R-side correlation
#'   structures (e.g.\ CAR(1)) or variance functions, use
#'   \code{\link{rr_recursive_residuals_lme}} instead.
#' @seealso \code{\link{rr_recursive_residuals_lme}} for \code{nlme::lme} models.
#' @export
rr_recursive_residuals_lmer <- function(fit) {
  if (!inherits(fit, "merMod")) {
    stop("fit must be an lme4 merMod object, e.g. from lme4::lmer().")
  }
  mf   <- stats::model.frame(fit)
  y    <- stats::model.response(mf)
  X    <- lme4::getME(fit, "X")
  beta <- lme4::fixef(fit)
  r    <- as.numeric(y - X %*% beta)

  Zt     <- lme4::getME(fit, "Zt")
  Lambda <- lme4::getME(fit, "Lambda")
  sig    <- stats::sigma(fit)
  n      <- length(r)

  A <- Matrix::t(Zt) %*% Lambda
  V <- sig^2 * (as.matrix(Matrix::tcrossprod(A)) + diag(n))
  L <- .chol_lower_safe(V)
  w <- as.numeric(forwardsolve(L, r))

  out      <- tibble::as_tibble(mf)
  out$.rr  <- w
  out
}


#' Marginal Cholesky recursive residuals for an nlme LMM
#'
#' Computes the marginal-covariance-standardised recursive residuals for a
#' model fitted with \code{nlme::lme()}.  The per-cluster marginal covariance
#' \eqn{V_i = Z_i D Z_i^\top + R_i} is obtained via
#' \code{nlme::getVarCov(fit, type = "marginal")}, a lower-triangular Cholesky
#' factor \eqn{L_i} is computed for each cluster, and the whitened residual
#' \eqn{w_i = L_i^{-1} r_i} is returned.
#'
#' This function supports R-side residual correlation structures such as
#' \code{nlme::corCAR1()}, \code{nlme::corAR1()}, \code{nlme::corExp()}, and
#' variance functions via \code{nlme::varFunc()}, which are not available in
#' \code{lme4}.
#'
#' @param fit A fitted \code{nlme::lme} model (class \code{"lme"}).
#' @return A \code{\link[tibble]{tibble}} containing the model data and a
#'   \code{.rr} column of marginal Cholesky recursive residuals, in the
#'   original observation order of the fitted object.
#' @details The recursive ordering within each cluster is the row order of the
#'   data, so the data should be sorted by cluster and by the within-cluster
#'   ordering variable before fitting.  Clusters whose fitted marginal
#'   covariance cannot be obtained receive \code{NA} residuals with a warning.
#' @seealso \code{\link{rr_recursive_residuals_lmer}} for \code{lme4} models.
#' @export
rr_recursive_residuals_lme <- function(fit) {
  if (!inherits(fit, "lme")) {
    stop("fit must be an nlme::lme object, e.g. from nlme::lme().")
  }
  if (!requireNamespace("nlme", quietly = TRUE)) {
    stop("Package 'nlme' is required. Install it with install.packages('nlme').")
  }

  # Population-level (marginal) residuals r_i = y_i - X_i beta_hat, in data order
  r <- as.numeric(stats::residuals(fit, level = 0))

  # Outermost grouping factor (rows of fit$groups follow the data order)
  grp <- as.character(fit$groups[[1L]])
  ids <- unique(grp)
  Vlist <- .lme_marginal_covs(fit, ids)

  w <- rep(NA_real_, length(r))
  failed <- character(0)
  for (id in ids) {
    idx <- which(grp == id)
    Vi  <- Vlist[[id]]
    if (is.null(Vi) || nrow(Vi) != length(idx)) {
      failed <- c(failed, id)
      next
    }
    w[idx] <- forwardsolve(.chol_lower_safe(Vi), r[idx])
  }
  if (length(failed) > 0L) {
    warning("Marginal covariance unavailable for ", length(failed),
            " cluster(s); their recursive residuals are NA.", call. = FALSE)
  }

  dat <- tryCatch(
    nlme::getData(fit),
    error = function(e) as.data.frame(fit$data)
  )
  out     <- tibble::as_tibble(dat)
  out$.rr <- w
  out
}
