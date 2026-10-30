.add_result <- function(results, example, model, diagnostic, target, stat_tbl) {
  dplyr::bind_rows(
    results,
    dplyr::bind_cols(
      tibble::tibble(
        example = example,
        model = model,
        diagnostic = diagnostic,
        target = target
      ),
      stat_tbl
    )
  )
}

.format_empirical_results <- function(results) {
  dplyr::mutate(
    results,
    p_boot_fmt = ifelse(is.na(p_boot), NA_character_, sprintf("%.4f", p_boot)),
    statistic_observed_fmt = ifelse(is.na(statistic_observed), NA_character_, sprintf("%.4f", statistic_observed)),
    boot_q95_fmt = ifelse(is.na(boot_q95), NA_character_, sprintf("%.4f", boot_q95)),
    boot_q99_fmt = ifelse(is.na(boot_q99), NA_character_, sprintf("%.4f", boot_q99))
  )
}

#' Run the manuscript empirical bootstrap p-value audit
#'
#' @param B Number of bootstrap refits. The manuscript run used `B = 999`.
#' @param seed Random seed. The manuscript run used `20260622`.
#' @param include_produc Logical. Produc is off by default because it is treated
#'   as a boundary screening example in the manuscript, not a reported calibrated
#'   p-value benchmark.
#' @param verbose Logical; print progress.
#' @return A tibble containing audit statistics for BodyWeight (lme4 models
#'   M0 and M3; nlme CAR(1) model N1), sleepstudy (lme4 models RI and RS;
#'   nlme AR(1) models RI_AR1 and RS_AR1), Pastes, and optionally Produc.
#' @export
rr_run_empirical_audit <- function(B = 999, seed = 20260622,
                                   include_produc = FALSE, verbose = TRUE) {
  if (!requireNamespace("nlme", quietly = TRUE)) {
    stop("Package 'nlme' is required for the BodyWeight dataset.")
  }
  if (!requireNamespace("lme4", quietly = TRUE)) {
    stop("Package 'lme4' is required.")
  }
  set.seed(seed)
  ctrl_lmer <- lme4::lmerControl(
    optimizer = "bobyqa",
    optCtrl = list(maxfun = 100000),
    check.conv.singular = "ignore"
  )
  results <- tibble::tibble()

  if (isTRUE(verbose)) message("Fitting BodyWeight models...")
  utils::data("BodyWeight", package = "nlme")
  BodyWeight <- as.data.frame(BodyWeight)
  BodyWeight$Rat <- factor(BodyWeight$Rat)
  BodyWeight$Diet <- factor(BodyWeight$Diet)
  BW_models <- list(
    M0_linear = lme4::lmer(
      weight ~ Time + Diet + (Time | Rat),
      data = BodyWeight, REML = FALSE, control = ctrl_lmer
    ),
    M3_quadratic_interaction = lme4::lmer(
      weight ~ (Time + I(Time^2)) * Diet + (Time | Rat),
      data = BodyWeight, REML = FALSE, control = ctrl_lmer
    )
  )
  for (nm in names(BW_models)) {
    fit <- BW_models[[nm]]
    results <- .add_result(
      results, "BodyWeight", nm, "absolute pooled lag-one RR ACF", "serial dependence",
      rr_bootstrap_pvalue(
        fit,
        function(d) rr_acf1_pooled_abs(d$.rr, d$Rat, d$Time),
        B = B, label = paste0("BodyWeight ", nm, " ACF1"), verbose = verbose
      )
    )
    results <- .add_result(
      results, "BodyWeight", nm, "time-indexed RR CUSUM supremum", "mean trajectory drift",
      rr_bootstrap_pvalue(
        fit,
        function(d) rr_time_sup(d$.rr, d$Time),
        B = B, label = paste0("BodyWeight ", nm, " time CUSUM"), verbose = verbose
      )
    )
    results <- .add_result(
      results, "BodyWeight", nm, "diet-indexed RR contrast", "diet/subgroup imbalance",
      rr_bootstrap_pvalue(
        fit,
        function(d) rr_factor_contrast_sup(d$.rr, d$Diet),
        B = B, label = paste0("BodyWeight ", nm, " diet contrast"), verbose = verbose
      )
    )
  }

  if (isTRUE(verbose)) message("Fitting sleepstudy models...")
  utils::data("sleepstudy", package = "lme4")
  sleepstudy <- as.data.frame(sleepstudy)
  sleepstudy$Subject <- factor(sleepstudy$Subject)
  SS_models <- list(
    RI = lme4::lmer(Reaction ~ Days + (1 | Subject), data = sleepstudy, REML = FALSE, control = ctrl_lmer),
    RS = lme4::lmer(Reaction ~ Days + (Days | Subject), data = sleepstudy, REML = FALSE, control = ctrl_lmer)
  )
  for (nm in names(SS_models)) {
    fit <- SS_models[[nm]]
    results <- .add_result(
      results, "sleepstudy", nm, "absolute pooled lag-one RR ACF", "within-subject residual serial pattern",
      rr_bootstrap_pvalue(
        fit,
        function(d) rr_acf1_pooled_abs(d$.rr, d$Subject, d$Days),
        B = B, label = paste0("sleepstudy ", nm, " ACF1"), verbose = verbose
      )
    )
    results <- .add_result(
      results, "sleepstudy", nm, "subject accumulation supremum", "omitted subject-specific structure",
      rr_bootstrap_pvalue(
        fit,
        function(d) rr_group_sup(d$.rr, d$Subject),
        B = B, label = paste0("sleepstudy ", nm, " subject accumulation"), verbose = verbose
      )
    )
    results <- .add_result(
      results, "sleepstudy", nm, "time-indexed RR CUSUM supremum", "mean trajectory drift",
      rr_bootstrap_pvalue(
        fit,
        function(d) rr_time_sup(d$.rr, d$Days),
        B = B, label = paste0("sleepstudy ", nm, " time CUSUM"), verbose = verbose
      )
    )
  }

  if (isTRUE(verbose)) message("Fitting Pastes models...")
  utils::data("Pastes", package = "lme4")
  Pastes <- as.data.frame(Pastes)
  Pastes$batch <- factor(Pastes$batch)
  Pastes$cask <- factor(Pastes$cask)
  Pastes$batch_cask <- interaction(Pastes$batch, Pastes$cask, drop = TRUE)
  P_batch <- Pastes$batch
  P_batch_cask <- Pastes$batch_cask
  P_models <- list(
    P0 = lme4::lmer(strength ~ 1 + (1 | batch), data = Pastes, REML = FALSE, control = ctrl_lmer),
    P1 = lme4::lmer(strength ~ 1 + (1 | batch) + (1 | cask), data = Pastes, REML = FALSE, control = ctrl_lmer),
    P2 = lme4::lmer(strength ~ 1 + (1 | batch) + (1 | batch_cask), data = Pastes, REML = FALSE, control = ctrl_lmer),
    P3 = lme4::lmer(strength ~ 1 + (1 | batch_cask), data = Pastes, REML = FALSE, control = ctrl_lmer)
  )
  for (nm in names(P_models)) {
    fit <- P_models[[nm]]
    results <- .add_result(
      results, "Pastes", nm, "batch:cask factor accumulation supremum", "nested grouping structure",
      rr_bootstrap_pvalue(
        fit,
        function(d) rr_group_sup(d$.rr, P_batch_cask),
        B = B, label = paste0("Pastes ", nm, " batch:cask"), verbose = verbose
      )
    )
    results <- .add_result(
      results, "Pastes", nm, "batch factor accumulation supremum", "batch grouping structure",
      rr_bootstrap_pvalue(
        fit,
        function(d) rr_group_sup(d$.rr, P_batch),
        B = B, label = paste0("Pastes ", nm, " batch"), verbose = verbose
      )
    )
  }

  # ---------------------------------------------------------------------------
  # Residual-covariance refinements fitted with nlme (R-side correlation).
  # These cells are appended after the lme4 cells so that the random-number
  # stream, and hence the results, of the lme4 cells above are unchanged.
  # ---------------------------------------------------------------------------
  ctrl_lme <- nlme::lmeControl(opt = "optim", maxIter = 200, msMaxIter = 200)

  if (isTRUE(verbose)) message("Fitting BodyWeight CAR(1) model N1 (nlme)...")
  BW_N1 <- nlme::lme(
    weight ~ (Time + I(Time^2)) * Diet,
    random = ~ Time | Rat,
    correlation = nlme::corCAR1(form = ~ Time | Rat),
    data = BodyWeight, method = "ML", control = ctrl_lme
  )
  results <- .add_result(
    results, "BodyWeight", "N1_CAR1", "absolute pooled lag-one RR ACF", "serial dependence",
    rr_bootstrap_pvalue(
      BW_N1,
      function(d) rr_acf1_pooled_abs(d$.rr, d$Rat, d$Time),
      B = B, label = "BodyWeight N1 ACF1", verbose = verbose
    )
  )
  results <- .add_result(
    results, "BodyWeight", "N1_CAR1", "time-indexed RR CUSUM supremum", "mean trajectory drift",
    rr_bootstrap_pvalue(
      BW_N1,
      function(d) rr_time_sup(d$.rr, d$Time),
      B = B, label = "BodyWeight N1 time CUSUM", verbose = verbose
    )
  )
  results <- .add_result(
    results, "BodyWeight", "N1_CAR1", "diet-indexed RR contrast", "diet/subgroup imbalance",
    rr_bootstrap_pvalue(
      BW_N1,
      function(d) rr_factor_contrast_sup(d$.rr, d$Diet),
      B = B, label = "BodyWeight N1 diet contrast", verbose = verbose
    )
  )

  if (isTRUE(verbose)) message("Fitting sleepstudy AR(1) models (nlme)...")
  SS_ar1_models <- list(
    RI_AR1 = nlme::lme(
      Reaction ~ Days, random = ~ 1 | Subject,
      correlation = nlme::corAR1(form = ~ Days | Subject),
      data = sleepstudy, method = "ML", control = ctrl_lme
    ),
    RS_AR1 = nlme::lme(
      Reaction ~ Days, random = ~ Days | Subject,
      correlation = nlme::corAR1(form = ~ Days | Subject),
      data = sleepstudy, method = "ML", control = ctrl_lme
    )
  )
  for (nm in names(SS_ar1_models)) {
    fit <- SS_ar1_models[[nm]]
    results <- .add_result(
      results, "sleepstudy", nm, "absolute pooled lag-one RR ACF", "within-subject residual serial pattern",
      rr_bootstrap_pvalue(
        fit,
        function(d) rr_acf1_pooled_abs(d$.rr, d$Subject, d$Days),
        B = B, label = paste0("sleepstudy ", nm, " ACF1"), verbose = verbose
      )
    )
    results <- .add_result(
      results, "sleepstudy", nm, "subject accumulation supremum", "omitted subject-specific structure",
      rr_bootstrap_pvalue(
        fit,
        function(d) rr_group_sup(d$.rr, d$Subject),
        B = B, label = paste0("sleepstudy ", nm, " subject accumulation"), verbose = verbose
      )
    )
    results <- .add_result(
      results, "sleepstudy", nm, "time-indexed RR CUSUM supremum", "mean trajectory drift",
      rr_bootstrap_pvalue(
        fit,
        function(d) rr_time_sup(d$.rr, d$Days),
        B = B, label = paste0("sleepstudy ", nm, " time CUSUM"), verbose = verbose
      )
    )
  }

  if (include_produc && requireNamespace("plm", quietly = TRUE)) {
    if (isTRUE(verbose)) message("Fitting optional Produc screen...")
    utils::data("Produc", package = "plm")
    Produc <- as.data.frame(Produc)
    Produc$state <- factor(Produc$state)
    Produc$year <- factor(Produc$year)
    Produc$l_gsp <- log(Produc$gsp)
    Produc$l_pcap <- log(Produc$pcap)
    Produc$l_pc <- log(Produc$pc)
    Produc$l_emp <- log(Produc$emp)
    Produc$mean_l_pcap <- ave(Produc$l_pcap, Produc$state, FUN = mean)
    Produc$dev_l_pcap <- Produc$l_pcap - Produc$mean_l_pcap
    PR_models <- list(
      RE = lme4::lmer(l_gsp ~ l_pc + l_emp + l_pcap + unemp + (1 | state), data = Produc, REML = FALSE, control = ctrl_lmer),
      CRE = lme4::lmer(l_gsp ~ l_pc + l_emp + dev_l_pcap + mean_l_pcap + unemp + (1 | state), data = Produc, REML = FALSE, control = ctrl_lmer)
    )
    for (nm in names(PR_models)) {
      fit <- PR_models[[nm]]
      results <- .add_result(
        results, "Produc", nm, "state factor accumulation supremum", "state-level residual imbalance",
        rr_bootstrap_pvalue(
          fit,
          function(d) rr_group_sup(d$.rr, d$state),
          B = B, label = paste0("Produc ", nm, " state accumulation"), verbose = verbose
        )
      )
      results <- .add_result(
        results, "Produc", nm, "time-indexed RR CUSUM supremum", "panel time drift",
        rr_bootstrap_pvalue(
          fit,
          function(d) rr_time_sup(d$.rr, as.numeric(as.character(d$year))),
          B = B, label = paste0("Produc ", nm, " time CUSUM"), verbose = verbose
        )
      )
    }
  } else if (include_produc && isTRUE(verbose)) {
    message("Package 'plm' is not installed; skipping optional Produc audit.")
  }

  .format_empirical_results(results)
}

#' Write empirical audit CSV and LaTeX table outputs
#'
#' @param results Result tibble from `rr_run_empirical_audit()`.
#' @param out_dir Output directory.
#' @return Invisibly returns the result tibble.
#' @export
rr_write_empirical_audit_outputs <- function(results, out_dir) {
  dir.create(file.path(out_dir, "csv"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(out_dir, "tables"), recursive = TRUE, showWarnings = FALSE)
  csv_file <- file.path(out_dir, "csv", "empirical_bootstrap_pvalue_audit.csv")
  readr::write_csv(results, csv_file)

  latex_file <- file.path(out_dir, "tables", "tab_empirical_bootstrap_pvalue_audit.tex")
  latex_lines <- c(
    "\\begin{table}[!t]",
    "\\caption{Bootstrap-calibrated diagnostic statistics for empirical examples.}",
    "\\label{tab:empirical_bootstrap_pvalue_audit}",
    "\\centering",
    "\\small",
    "\\begin{tabular}{llllrrr}",
    "\\toprule",
    "Example & Model & Diagnostic & Target & $T_{obs}$ & $p_{boot}$ & $B_{success}$ \\\\",
    "\\midrule"
  )
  row_lines <- apply(results, 1, function(z) {
    paste0(
      z[["example"]], " & ",
      z[["model"]], " & ",
      gsub("_", "\\\\_", z[["diagnostic"]]), " & ",
      gsub("_", "\\\\_", z[["target"]]), " & ",
      z[["statistic_observed_fmt"]], " & ",
      z[["p_boot_fmt"]], " & ",
      z[["B_success"]], " \\\\")
  })
  writeLines(c(latex_lines, row_lines, "\\bottomrule", "\\end{tabular}", "\\end{table}"), latex_file)

  summary_file <- file.path(out_dir, "bootstrap_pvalue_audit_summary.txt")
  writeLines(c(
    paste0("Bootstrap p-value audit completed at: ", Sys.time()),
    paste0("CSV: ", csv_file),
    paste0("LaTeX table: ", latex_file)
  ), summary_file)
  invisible(results)
}

#' Family-wise (min-p) calibration of the empirical diagnostics
#'
#' For every model in the empirical audit, evaluates the declared family of
#' diagnostics for that example on common bootstrap replicates and returns the
#' single-step min-p adjusted p-values of \code{\link{rr_bootstrap_family}}.
#' Families: BodyWeight \{lag-one ACF, time CUSUM, diet contrast\};
#' sleepstudy \{lag-one ACF, subject accumulation, time CUSUM\};
#' Pastes \{batch:cask, batch, and cask-label accumulation\}.
#'
#' @param B Number of bootstrap refits per model.
#' @param seed Random seed.
#' @param verbose Logical; print progress.
#' @return A tibble with one row per model and diagnostic.
#' @export
rr_run_family_audit <- function(B = 999, seed = 20260930, verbose = TRUE) {
  set.seed(seed)
  ctrl_lmer <- lme4::lmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 100000),
                                 check.conv.singular = "ignore")
  ctrl_lme <- nlme::lmeControl(opt = "optim", maxIter = 200, msMaxIter = 200)
  out <- tibble::tibble()
  add <- function(example, model, res) {
    dplyr::bind_rows(out, dplyr::bind_cols(tibble::tibble(example = example, model = model), res))
  }

  utils::data("BodyWeight", package = "nlme")
  BodyWeight <- as.data.frame(BodyWeight)
  BodyWeight$Rat <- factor(BodyWeight$Rat); BodyWeight$Diet <- factor(BodyWeight$Diet)
  bw_stats <- list(
    `lag-one RR ACF` = function(d) rr_acf1_pooled_abs(d$.rr, d$Rat, d$Time),
    `time CUSUM` = function(d) rr_time_sup(d$.rr, d$Time),
    `diet contrast` = function(d) rr_factor_contrast_sup(d$.rr, d$Diet)
  )
  bw_models <- list(
    M0_linear = lme4::lmer(weight ~ Time + Diet + (Time | Rat), data = BodyWeight,
                           REML = FALSE, control = ctrl_lmer),
    M3_quadratic_interaction = lme4::lmer(weight ~ (Time + I(Time^2)) * Diet + (Time | Rat),
                                          data = BodyWeight, REML = FALSE, control = ctrl_lmer),
    N1_CAR1 = nlme::lme(weight ~ (Time + I(Time^2)) * Diet, random = ~ Time | Rat,
                        correlation = nlme::corCAR1(form = ~ Time | Rat),
                        data = BodyWeight, method = "ML", control = ctrl_lme)
  )
  for (nm in names(bw_models)) {
    if (isTRUE(verbose)) message("BodyWeight ", nm)
    out <- add("BodyWeight", nm, rr_bootstrap_family(bw_models[[nm]], bw_stats, B = B, verbose = verbose))
  }

  utils::data("sleepstudy", package = "lme4")
  sleepstudy <- as.data.frame(sleepstudy); sleepstudy$Subject <- factor(sleepstudy$Subject)
  ss_stats <- list(
    `lag-one RR ACF` = function(d) rr_acf1_pooled_abs(d$.rr, d$Subject, d$Days),
    `subject accumulation` = function(d) rr_group_sup(d$.rr, d$Subject),
    `time CUSUM` = function(d) rr_time_sup(d$.rr, d$Days)
  )
  ss_models <- list(
    RI = lme4::lmer(Reaction ~ Days + (1 | Subject), data = sleepstudy, REML = FALSE, control = ctrl_lmer),
    RS = lme4::lmer(Reaction ~ Days + (Days | Subject), data = sleepstudy, REML = FALSE, control = ctrl_lmer),
    RI_AR1 = nlme::lme(Reaction ~ Days, random = ~ 1 | Subject,
                       correlation = nlme::corAR1(form = ~ Days | Subject),
                       data = sleepstudy, method = "ML", control = ctrl_lme),
    RS_AR1 = nlme::lme(Reaction ~ Days, random = ~ Days | Subject,
                       correlation = nlme::corAR1(form = ~ Days | Subject),
                       data = sleepstudy, method = "ML", control = ctrl_lme)
  )
  for (nm in names(ss_models)) {
    if (isTRUE(verbose)) message("sleepstudy ", nm)
    out <- add("sleepstudy", nm, rr_bootstrap_family(ss_models[[nm]], ss_stats, B = B, verbose = verbose))
  }

  utils::data("Pastes", package = "lme4")
  Pastes <- as.data.frame(Pastes)
  Pastes$batch <- factor(Pastes$batch); Pastes$cask <- factor(Pastes$cask)
  Pastes$batch_cask <- interaction(Pastes$batch, Pastes$cask, drop = TRUE)
  P_batch <- Pastes$batch; P_batch_cask <- Pastes$batch_cask; P_cask <- Pastes$cask
  pa_stats <- list(
    `batch:cask accumulation` = function(d) rr_group_sup(d$.rr, P_batch_cask),
    `batch accumulation` = function(d) rr_group_sup(d$.rr, P_batch),
    `cask label accumulation` = function(d) rr_group_sup(d$.rr, P_cask)
  )
  pa_models <- list(
    P0 = lme4::lmer(strength ~ 1 + (1 | batch), data = Pastes, REML = FALSE, control = ctrl_lmer),
    P1 = lme4::lmer(strength ~ 1 + (1 | batch) + (1 | cask), data = Pastes, REML = FALSE, control = ctrl_lmer),
    P2 = lme4::lmer(strength ~ 1 + (1 | batch) + (1 | batch_cask), data = Pastes, REML = FALSE, control = ctrl_lmer),
    P3 = lme4::lmer(strength ~ 1 + (1 | batch_cask), data = Pastes, REML = FALSE, control = ctrl_lmer)
  )
  for (nm in names(pa_models)) {
    if (isTRUE(verbose)) message("Pastes ", nm)
    out <- add("Pastes", nm, rr_bootstrap_family(pa_models[[nm]], pa_stats, B = B, verbose = verbose))
  }
  out
}
