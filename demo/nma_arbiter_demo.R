#' SYNTHESIS Arbiter: Resolving NMA Package Disagreements
#' This script uses SYNTHESIS to find a corrected consensus when different
#' NMA packages disagree on treatment effects.

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
source(file.path(PROJECT_ROOT, "R", "synthesis.R"))

cat("=== SYNTHESIS ARBITER: Resolving NMA Bake-Off Disagreements ===\n\n")

bakeoff_results <- data.frame(
  Package = c("netmeta", "gemtc", "multinma", "bnma", "nmaINLA"),
  Estimate = c(0.45, 0.52, 0.48, 0.65, 0.47),
  SE = c(0.05, 0.08, 0.06, 0.15, 0.055)
)

package_quality <- c(0.9, 0.95, 0.95, 0.5, 0.85)

arbiter_res <- synthesis_arbiter(
  bakeoff_results$Estimate,
  bakeoff_results$SE,
  source_quality = package_quality
)

cat("Bake-Off Summary:\n")
print(bakeoff_results)

cat("\nSYNTHESIS Arbitrated Consensus:\n")
print(arbiter_res)

cat("\nInterpretation:\n")
cat(sprintf("The final consensus estimate is %.4f.\n", arbiter_res$estimate))
cat("SYNTHESIS identifies package outliers (like 'bnma' at 0.65) and downweights them\n")
cat("based on their deviation from the density map and their assigned quality scores.\n")
