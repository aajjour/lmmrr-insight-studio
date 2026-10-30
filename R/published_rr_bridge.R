#!/usr/bin/env Rscript
# Published R engine callable from Python. NO bootstrap routines are invoked.
# Scientific citation: https://doi.org/10.1080/00949655.2026.2748404
argv <- commandArgs(trailingOnly = TRUE)
if (length(argv) != 1L) stop("Usage: Rscript published_rr_bridge.R request.json")
if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("Missing R package jsonlite. Install with install.packages('jsonlite')")
}
req <- jsonlite::fromJSON(argv[[1]], simplifyVector = TRUE)
if (is.null(req$output_json) || is.null(req$repo_root)) stop("Invalid request")

save_json <- function(payload) {
  jsonlite::write_json(payload, req$output_json, auto_unbox = TRUE, pretty = TRUE,
                        digits = NA, null = "null", na = "null")
}

run <- function() {
  pkg <- file.path(req$repo_root, "reference", "published_r", "lmmRRdiag", "R")
  if (!file.exists(file.path(pkg, "recursive_residuals.R"))) {
    stop("Published R recursive_residuals.R not present; copy original source first")
  }
  suppressPackageStartupMessages(library(lme4))
  # Source only the non-bootstrap published implementation. This is NOT the
  # exploratory cross-language prototype in R/rr_core.R.
  env <- new.env(parent = .GlobalEnv)
  for (f in c("statistics.R", "recursive_residuals.R")) {
    p <- file.path(pkg, f)
    if (file.exists(p)) sys.source(p, envir = env, keep.source = FALSE)
  }
  fun <- "rr_recursive_residuals_lmer"
  if (!exists(fun, envir = env, mode = "function", inherits = FALSE)) {
    stop(paste("Published R source lacks expected function", fun))
  }
  fn <- get(fun, envir = env, inherits = FALSE)
  signature <- paste(capture.output(print(formals(fn))), collapse = "\n")
  if (identical(req$mode, "inspect")) {
    public <- sort(ls(env, pattern = "^rr_"))
    arg_info <- lapply(public, function(x) {
      f <- get(x, envir = env, inherits = FALSE)
      if (!is.function(f)) return(NULL)
      list(name = x, signature = paste(capture.output(print(formals(f))), collapse = "\n"))
    })
    arg_info <- Filter(Negate(is.null), arg_info)
    return(list(ok = TRUE, mode = "inspect", published_rr_function = fun,
                signature = signature, functions = arg_info,
                bootstrap_executed = FALSE,
                scientific_reference_doi = "10.1080/00949655.2026.2748404"))
  }
  if (!identical(req$mode, "run")) stop("Only inspect and run modes are supported")
  if (!file.exists(req$csv)) stop("CSV dataset not found")
  dat <- utils::read.csv(req$csv, stringsAsFactors = FALSE, check.names = FALSE)
  if (nrow(dat) < 3L) stop("Need at least 3 observations")
  f <- stats::as.formula(req$formula)
  fitted <- lme4::lmer(f, data = dat, REML = isTRUE(req$reml))
  opts <- req$rr_options
  if (is.null(opts)) opts <- list()
  if (!is.list(opts)) stop("rr_options must be a named list")
  if (length(opts) && (is.null(names(opts)) || any(!nzchar(names(opts))))) {
    stop("Every rr_options item requires a name")
  }
  if (any(grepl("boot|refit", names(opts), ignore.case = TRUE))) {
    stop("Bootstrap/refit options disabled")
  }
  # First positional argument is the actual fitted lme4 model.
  # Users can discover required extra named arguments with --inspect.
  result <- tryCatch(do.call(fn, c(list(fitted), opts)), error = function(e) {
    stop(sprintf("Original R function call failed: %s\nSignature:\n%s",
                 conditionMessage(e), signature))
  })
  out <- req$output_dir
  dir.create(out, showWarnings = FALSE, recursive = TRUE)
  saveRDS(result, file = file.path(out, "published_rr_result.rds"))
  sink_text <- capture.output(str(result, max.level = 3, give.attr = FALSE))
  writeLines(sink_text, con = file.path(out, "published_rr_structure.txt"))

  # Preserve every finite numeric component (including named list members)
  # without silently relabeling it as a particular published statistic.
  parts <- list()
  walk <- function(obj, prefix = "result", depth = 0L) {
    if (depth > 8L || length(parts) > 50000L) return(invisible(NULL))
    if (is.data.frame(obj)) {
      for (nm in names(obj)) walk(obj[[nm]], paste0(prefix, ".", nm), depth + 1L)
    } else if (is.matrix(obj) && is.numeric(obj)) {
      for (j in seq_len(ncol(obj))) {
        nm <- if (!is.null(colnames(obj))) colnames(obj)[j] else as.character(j)
        walk(obj[, j], paste0(prefix, ".", nm), depth + 1L)
      }
    } else if (is.numeric(obj) && is.null(dim(obj))) {
      for (k in seq_along(obj)) {
        v <- obj[k]
        if (is.finite(v)) parts[[length(parts) + 1L]] <<- list(
          component = prefix, index = k, value = as.numeric(v))
      }
    } else if (is.list(obj)) {
      nms <- names(obj)
      for (k in seq_along(obj)) {
        nm <- if (length(nms) >= k && !is.na(nms[k]) && nzchar(nms[k])) nms[k] else as.character(k)
        walk(obj[[k]], paste0(prefix, ".", nm), depth + 1L)
      }
    }
    invisible(NULL)
  }
  walk(result)
  if (length(parts) > 0L) {
    table <- do.call(rbind, lapply(parts, function(p) {
      data.frame(component = p$component, index = p$index, value = p$value)
    }))
  } else {
    table <- data.frame(component = character(), index = integer(), value = numeric())
  }
  csv_out <- file.path(out, "published_rr_numeric_components.csv")
  utils::write.csv(table, csv_out, row.names = FALSE)
  list(ok = TRUE, mode = "run", backend = "published-R-lmmRRdiag",
       published_rr_function = fun, signature = signature,
       nobs = nrow(dat), groups = nlevels(lme4::getME(fitted, "flist")[[1L]]),
       fixed_effects = as.list(lme4::fixef(fitted)),
       singular_fit = lme4::isSingular(fitted),
       numeric_components = nrow(table),
       rr_result_class = class(result),
       numeric_csv = csv_out,
       rds_file = file.path(out, "published_rr_result.rds"),
       structure_file = file.path(out, "published_rr_structure.txt"),
       inference = "NOT_AVAILABLE_WITHOUT_CALIBRATION",
       bootstrap_executed = FALSE,
       scientific_reference_doi = "10.1080/00949655.2026.2748404")
}

tryCatch({
  payload <- run()
  save_json(payload)
}, error = function(e) {
  save_json(list(ok = FALSE, error = conditionMessage(e), bootstrap_executed = FALSE))
  quit(save = "no", status = 2L)
})
