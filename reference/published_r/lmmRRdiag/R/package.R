#' lmmRRdiag: indexed recursive residual diagnostics for Gaussian LMMs
#'
#' Research-companion package for computing marginal Cholesky recursive residuals,
#' indexed residual processes, scalar diagnostic statistics, and parametric
#' bootstrap p-values for Gaussian linear mixed models fitted with lme4 or nlme.
#'
#' @keywords internal
"_PACKAGE"

# Column names used in dplyr::mutate() within .format_empirical_results()
utils::globalVariables(c("p_boot", "statistic_observed", "boot_q95", "boot_q99"))
