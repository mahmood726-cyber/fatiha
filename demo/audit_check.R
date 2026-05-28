#' VALIDATION: Full SYNTHESIS Audit (Core + Stability + Triple-Guard)

bootstrap_project_paths <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  candidates <- c(
    file.path(getwd(), "R", "project_paths.R"),
    file.path(getwd(), "..", "R", "project_paths.R"),
    file.path(getwd(), "..", "..", "R", "project_paths.R")
  )
  if (length(file_arg) > 0) {
    script_dir <- dirname(sub("^--file=", "", file_arg[[1]]))
    candidates <- c(
      file.path(script_dir, "..", "R", "project_paths.R"),
      file.path(script_dir, "..", "..", "R", "project_paths.R"),
      candidates
    )
  }
  for (candidate in unique(candidates)) {
    if (file.exists(candidate)) {
      source(normalizePath(candidate, winslash = "/", mustWork = TRUE), local = parent.frame())
      return(invisible(NULL))
    }
  }
  stop("Unable to locate R/project_paths.R")
}

bootstrap_project_paths()
PROJECT_ROOT <- resolve_project_root()

library(metafor)
source(file.path(PROJECT_ROOT, "R", "synthesis.R"))
source(file.path(PROJECT_ROOT, "R", "synthesis_audit.R"))

set.seed(99)
k <- 8
yi <- rnorm(k, 0.3, 0.1)
vi <- runif(k, 0.01, 0.05)
yi[8] <- 2.5
vi[8] <- 0.001

audit <- synthesis_audit(yi, vi)
print(audit)

cat("\n--- Divergence Check ---\n")
cat(sprintf("Core Estimate: %.4f\n", audit$core$estimate))
cat(sprintf("TGEP Anchor:   %.4f\n", audit$tgep$anchor))
cat(sprintf("Difference:    %.4f\n", audit$tgep$divergence))

if (audit$tgep$divergence > 0.5) {
  cat("\nSUCCESS: The TGEP Guard correctly identified that the 7-Layer model was being pulled by the outlier.\n")
}
