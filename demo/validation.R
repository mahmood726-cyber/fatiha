# SYNTHESIS Validation Script
#
# Comparing "The Initialization" (SYNTHESIS) vs "The Guard" (TGEP)
# vs "The Standard" (REML).

library(metafor)

resolve_project_root <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) > 0) {
    script_path <- sub("^--file=", "", file_arg[[1]])
    return(normalizePath(file.path(dirname(script_path), ".."), winslash = "/", mustWork = TRUE))
  }
  normalizePath("..", winslash = "/", mustWork = TRUE)
}

first_existing_path <- function(paths) {
  for (path in paths) {
    if (!is.na(path) && nzchar(path) && file.exists(path)) {
      return(normalizePath(path, winslash = "/", mustWork = TRUE))
    }
  }
  NULL
}

PROJECT_ROOT <- resolve_project_root()
DEMO_DIR <- file.path(PROJECT_ROOT, "demo")
PAIRWISE_DIR <- first_existing_path(c(
  Sys.getenv("PAIRWISE70_DATA_DIR", unset = ""),
  file.path(dirname(PROJECT_ROOT), "Projects", "mahmood789", "Pairwise70", "data"),
  file.path(dirname(PROJECT_ROOT), "Projects", "Pairwise70", "data"),
  file.path(dirname(PROJECT_ROOT), "Models", "Pairwise70", "data"),
  file.path(dirname(PROJECT_ROOT), "Pairwise70", "data")
))
TGEP_PATH <- first_existing_path(c(
  Sys.getenv("TGEP_R_PATH", unset = ""),
  file.path(dirname(PROJECT_ROOT), "TGEP_Development", "R", "TGEP.R"),
  file.path(dirname(PROJECT_ROOT), "Models", "TGEP_Development", "R", "TGEP.R")
))

source(file.path(PROJECT_ROOT, "R", "synthesis.R"))

has_tgep <- !is.null(TGEP_PATH) && file.exists(TGEP_PATH)
if (has_tgep) {
  source(TGEP_PATH)
}

cat("=== SYNTHESIS VALIDATION: The Initialization vs The Guard ===\n")

# 1. Load data or simulate
data_path <- if (!is.null(PAIRWISE_DIR)) {
  file.path(PAIRWISE_DIR, "CD000028_pub4_data.rda")
} else {
  NULL
}

if (!is.null(data_path) && file.exists(data_path)) {
  load(data_path)
  df <- CD000028_pub4_data
  ma_data <- df[df$Analysis.number == 1, ]
  dat <- escalc(
    measure = "OR",
    ai = Experimental.cases,
    n1i = Experimental.N,
    ci = Control.cases,
    n2i = Control.N,
    data = ma_data
  )
  dat <- dat[!is.na(dat$yi) & !is.na(dat$vi), ]
  yi <- dat$yi
  vi <- dat$vi
  cat(sprintf("Loaded dataset: CD000028 (k=%d)\n", length(yi)))
} else {
  cat("Data file not found. Simulating data...\n")
  set.seed(42)
  k <- 20
  yi <- rnorm(k, mean = 0.5, sd = 0.3)
  vi <- runif(k, 0.01, 0.1)
  yi[vi > 0.05] <- yi[vi > 0.05] + 0.4
}

# 2. Run models
synthesis_res <- synthesis_meta(yi, vi)
reml_res <- rma(yi, vi, method = "REML")

tgep_est <- NA
if (has_tgep) {
  tgep_res <- tgep_meta(yi, vi, n_boot = 0)
  tgep_est <- tgep_res$estimate
}

# 3. Comparison
cat("---------------------------------------------------\n")
cat(sprintf(
  "REML Estimate:   %.4f (SE: %.4f) [95%% CI: %.4f, %.4f]\n",
  as.numeric(reml_res$beta), reml_res$se, reml_res$ci.lb, reml_res$ci.ub
))

if (has_tgep) {
  cat(sprintf(
    "TGEP Estimate:   %.4f (SE: %.4f) [95%% CI: %.4f, %.4f]\n",
    tgep_res$estimate, tgep_res$se, tgep_res$ci_lb, tgep_res$ci_ub
  ))
} else {
  cat("TGEP Estimate:   [Not Available - TGEP.R missing]\n")
}

cat(sprintf(
  "SYNTHESIS Estimate: %.4f (SE: %.4f) [95%% CI: %.4f, %.4f]\n",
  synthesis_res$estimate,
  synthesis_res$se,
  synthesis_res$ci_lb,
  synthesis_res$ci_ub
))

cat("\nInterpretation:\n")
cat("SYNTHESIS seeks the 'Straight Path' (intercept at 0 error) weighted by 'Density-based' (Density) and 'Precision-based' (Precision).\n")
if (abs(synthesis_res$estimate) < abs(as.numeric(reml_res$beta))) {
  cat("SYNTHESIS is more conservative (closer to null), suggesting standard methods were 'Biased' (biased).\n")
} else {
  cat("SYNTHESIS is more aggressive, suggesting true effect was masked by 'Noise' (noisy) studies.\n")
}

# 4. Diagnostics
dir.create(DEMO_DIR, recursive = TRUE, showWarnings = FALSE)
output_path <- file.path(DEMO_DIR, "SYNTHESIS_Diagnostics.png")
png(output_path, width = 800, height = 800)
plot(synthesis_res)
dev.off()

cat(sprintf("\nValidation complete. Plots saved to %s\n", output_path))
