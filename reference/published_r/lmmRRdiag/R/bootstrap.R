.p_value_ge <- function(obs, boot) {
  boot <- boot[is.finite(boot)]
  if (!is.finite(obs) || length(boot) == 0L) return(NA_real_)
  (1 + sum(boot >= obs)) / (length(boot) + 1)
}

# Internal helper: simulate one response vector from a fitted nlme::lme model
# under its fitted marginal Gaussian law, y* = X beta_hat + L_i z_i per cluster.
# (stats::simulate() cannot be used here: for "lme" objects it dispatches to
# nlme::simulate.lme, which returns simulated log-likelihoods, not responses.)
.simulate_lme_response <- function(fit) {
  mu  <- as.numeric(stats::fitted(fit, level = 0))
  grp <- as.character(fit$groups[[1L]])
  ids <- unique(grp)
  Vlist <- .lme_marginal_covs(fit, ids)
  y <- rep(NA_real_, length(mu))
  for (id in ids) {
    idx <- which(grp == id)
    Li  <- .chol_lower_safe(Vlist[[id]])
    y[idx] <- mu[idx] + as.numeric(Li %*% stats::rnorm(length(idx)))
  }
  y
}

# Internal helper: refit an nlme::lme model to a new data set.  The original
# call is re-evaluated in an environment whose parent is the environment of the
# model formula, so that objects referenced in the call (e.g. a control list
# defined inside a user function) are found.
.refit_lme <- function(fit, new_dat) {
  cl <- fit$call
  # nlme records the method name (e.g. lme.formula); call the exported generic
  cl[[1L]] <- quote(nlme::lme)
  cl$data <- quote(.rr_boot_data)
  env_parent <- environment(fit$terms)
  if (is.null(env_parent)) env_parent <- parent.frame()
  env <- new.env(parent = env_parent)
  assign(".rr_boot_data", new_dat, envir = env)
  eval(cl, env)
}

#' Parametric-bootstrap calibration for an indexed residual statistic
#'
#' Runs a refitting parametric bootstrap to calibrate an indexed
#' recursive-residual diagnostic statistic for either an \code{lme4::lmer} or
#' an \code{nlme::lme} model.
#'
#' For \code{lme4} models, responses are simulated with
#' \code{stats::simulate()} and the model is refitted with
#' \code{lme4::refit(fit, newresp = yb)}.  For \code{nlme} models, responses
#' are simulated from the fitted marginal Gaussian law of each cluster,
#' \eqn{y_i^* = X_i\hat\beta + \hat L_i z_i}, including any R-side correlation
#' structure and variance function, and the original \code{lme()} call is
#' re-evaluated on the simulated data.  In both cases the design, cluster
#' sizes and observation pattern are held fixed.
#'
#' @param fit A fitted \code{lme4::lmer} (\code{"merMod"}) or
#'   \code{nlme::lme} (\code{"lme"}) model.
#' @param statistic A function that accepts the tibble returned by
#'   \code{\link{rr_recursive_residuals_lmer}} or
#'   \code{\link{rr_recursive_residuals_lme}} and returns one numeric value.
#' @param B Number of parametric-bootstrap refits. Default 999.
#' @param seed Optional integer random seed passed to \code{set.seed()}.
#' @param label Optional character label printed in progress messages.
#' @param verbose Logical; if \code{TRUE} (default) print a progress message
#'   every 25 bootstrap replicates.
#' @return A one-row \code{\link[tibble]{tibble}} with columns:
#'   \code{statistic_observed}, \code{p_boot}, \code{B_target},
#'   \code{B_success}, \code{boot_mean}, \code{boot_q95}, \code{boot_q99}.
#' @export
rr_bootstrap_pvalue <- function(fit, statistic, B = 999, seed = NULL,
                                label = "bootstrap", verbose = TRUE) {
  is_lmer <- inherits(fit, "merMod")
  is_lme  <- inherits(fit, "lme")
  if (!is_lmer && !is_lme) {
    stop("fit must be an lme4::lmer ('merMod') or nlme::lme ('lme') object.")
  }

  if (!is.null(seed)) set.seed(seed)

  # Observed statistic
  obs_dat <- if (is_lmer) rr_recursive_residuals_lmer(fit)
             else         rr_recursive_residuals_lme(fit)
  T_obs <- statistic(obs_dat)

  # For nlme: identify response name and base data once
  if (is_lme) {
    resp_name <- all.vars(stats::formula(fit)[[2L]])[1L]
    base_dat  <- tryCatch(
      as.data.frame(nlme::getData(fit)),
      error = function(e) as.data.frame(fit$data)
    )
  }

  boot <- rep(NA_real_, B)
  ok   <- rep(FALSE,    B)

  for (b in seq_len(B)) {
    if (isTRUE(verbose) && b %% 25 == 0)
      message(label, ": bootstrap ", b, "/", B)

    if (is_lmer) {
      yb <- tryCatch(
        as.numeric(stats::simulate(fit, nsim = 1L)[[1L]]),
        error = function(e) NULL
      )
      if (is.null(yb)) next
      fit_b <- tryCatch(
        suppressWarnings(lme4::refit(fit, newresp = yb)),
        error = function(e) NULL
      )
      if (is.null(fit_b)) next
      dat_b <- tryCatch(rr_recursive_residuals_lmer(fit_b), error = function(e) NULL)
    } else {
      yb <- tryCatch(.simulate_lme_response(fit), error = function(e) NULL)
      if (is.null(yb)) next
      new_dat <- base_dat
      new_dat[[resp_name]] <- yb
      fit_b <- tryCatch(
        suppressWarnings(.refit_lme(fit, new_dat)),
        error = function(e) NULL
      )
      if (is.null(fit_b)) next
      dat_b <- tryCatch(rr_recursive_residuals_lme(fit_b), error = function(e) NULL)
    }

    if (is.null(dat_b)) next
    boot[b] <- tryCatch(statistic(dat_b), error = function(e) NA_real_)
    ok[b]   <- is.finite(boot[b])
  }

  tibble::tibble(
    statistic_observed = T_obs,
    p_boot             = .p_value_ge(T_obs, boot),
    B_target           = B,
    B_success          = sum(ok),
    boot_mean          = mean(boot[ok], na.rm = TRUE),
    boot_q95           = as.numeric(stats::quantile(boot[ok], 0.95, na.rm = TRUE)),
    boot_q99           = as.numeric(stats::quantile(boot[ok], 0.99, na.rm = TRUE))
  )
}

#' Family-wise parametric-bootstrap calibration for a declared set of diagnostics
#'
#' Evaluates a declared family of scalar diagnostics on the same refitting
#' parametric-bootstrap replicates and returns, for each diagnostic, the
#' marginal bootstrap p-value and the single-step min-p adjusted p-value
#' (Westfall and Young, 1993). The observed data and the \eqn{B} replicates are
#' treated as one pooled set of \eqn{B+1} values: each member of the pooled set
#' receives, for every diagnostic, the p-value \eqn{\#\{j : T_{jk} \ge T_{ik}\}/(B+1)},
#' and the adjusted p-value of diagnostic \eqn{k} is the proportion of the pooled
#' set whose smallest p-value over the family does not exceed the observed
#' p-value of diagnostic \eqn{k}. The selection of the most extreme member of
#' the family is thereby reproduced within every replicate. Under the
#' conditions of the parametric-bootstrap consistency result, the procedure
#' controls asymptotically the probability that any member of the declared
#' family is flagged when the fitted model is correctly specified (weak
#' family-wise control); attributing a departure to an individual member with
#' error control (strong control) would require subset pivotality.
#'
#' @param fit A fitted \code{lme4::lmer} or \code{nlme::lme} model.
#' @param statistics A named list of functions, each accepting the residual
#'   tibble returned by \code{\link{rr_recursive_residuals_lmer}} or
#'   \code{\link{rr_recursive_residuals_lme}} and returning one number.
#' @param B Number of bootstrap refits.
#' @param seed Optional random seed.
#' @param verbose Logical; print progress every 100 replicates.
#' @return A tibble with one row per diagnostic: \code{diagnostic},
#'   \code{statistic_observed}, \code{p_marginal}, \code{p_family_minp},
#'   \code{B_success}.
#' @references Westfall, P. H. and Young, S. S. (1993). \emph{Resampling-Based
#'   Multiple Testing}. Wiley, New York.
#' @export
rr_bootstrap_family <- function(fit, statistics, B = 999, seed = NULL, verbose = TRUE) {
  is_lmer <- inherits(fit, "merMod")
  is_lme  <- inherits(fit, "lme")
  if (!is_lmer && !is_lme) stop("fit must be an lme4::lmer or nlme::lme object.")
  if (!is.list(statistics) || is.null(names(statistics))) stop("statistics must be a named list of functions.")
  if (!is.null(seed)) set.seed(seed)
  eval_all <- function(d) vapply(statistics, function(f) tryCatch(as.numeric(f(d)), error = function(e) NA_real_), numeric(1))
  obs_dat <- if (is_lmer) rr_recursive_residuals_lmer(fit) else rr_recursive_residuals_lme(fit)
  T_obs <- eval_all(obs_dat)
  if (any(!is.finite(T_obs))) stop("an observed statistic is not finite")
  if (is_lme) {
    resp_name <- all.vars(stats::formula(fit)[[2L]])[1L]
    base_dat <- as.data.frame(nlme::getData(fit))
  }
  K <- length(statistics)
  boot <- matrix(NA_real_, B, K, dimnames = list(NULL, names(statistics)))
  for (b in seq_len(B)) {
    if (isTRUE(verbose) && b %% 100 == 0) message("family bootstrap ", b, "/", B)
    if (is_lmer) {
      yb <- tryCatch(as.numeric(stats::simulate(fit, nsim = 1L)[[1L]]), error = function(e) NULL)
      if (is.null(yb)) next
      fit_b <- tryCatch(suppressWarnings(lme4::refit(fit, newresp = yb)), error = function(e) NULL)
      if (is.null(fit_b)) next
      dat_b <- tryCatch(rr_recursive_residuals_lmer(fit_b), error = function(e) NULL)
    } else {
      yb <- tryCatch(.simulate_lme_response(fit), error = function(e) NULL)
      if (is.null(yb)) next
      new_dat <- base_dat; new_dat[[resp_name]] <- yb
      fit_b <- tryCatch(suppressWarnings(.refit_lme(fit, new_dat)), error = function(e) NULL)
      if (is.null(fit_b)) next
      dat_b <- tryCatch(rr_recursive_residuals_lme(fit_b), error = function(e) NULL)
    }
    if (is.null(dat_b)) next
    boot[b, ] <- eval_all(dat_b)
  }
  ok <- stats::complete.cases(boot)
  pooled <- rbind(T_obs, boot[ok, , drop = FALSE])          # row 1 = observed data
  n1 <- nrow(pooled)
  pmat <- apply(pooled, 2, function(x) vapply(x, function(v) sum(x >= v), numeric(1)) / n1)
  if (is.null(dim(pmat))) pmat <- matrix(pmat, nrow = n1)
  p_marg <- pmat[1, ]
  min_p <- apply(pmat, 1, min)
  p_adj <- vapply(p_marg, function(pk) sum(min_p <= pk) / n1, numeric(1))
  tibble::tibble(
    diagnostic = names(statistics),
    statistic_observed = as.numeric(T_obs),
    p_marginal = as.numeric(p_marg),
    p_family_minp = as.numeric(p_adj),
    B_success = n1 - 1L
  )
}
