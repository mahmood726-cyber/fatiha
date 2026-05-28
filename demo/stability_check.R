#' VALIDATION: SYNTHESIS Stability & Overfitting Protection

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

set.seed(99)
k <- 8
yi <- rnorm(k, 0.3, 0.1)
vi <- runif(k, 0.01, 0.05)
yi[8] <- 2.5
vi[8] <- 0.001

res <- synthesis_meta(yi, vi)
print(res)

stab <- synthesis_stability(yi, vi)
print(stab)

cat("\n--- Leverage Analysis ---\n")
cat("Leverage per Study (How much removing it shifts the model):\n")
print(round(stab$leverage_indices, 3))

if (which.max(stab$leverage_indices) == 8) {
  cat("\nSUCCESS: The stability module correctly identified Study 8 as the primary source of instability.\n")
}
