#' VALIDATION: Publication Interface (Report & Master Plot)

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
DEMO_DIR <- ensure_repo_dir(file.path(PROJECT_ROOT, "demo"))

library(metafor)
source(file.path(PROJECT_ROOT, "R", "synthesis.R"))
source(file.path(PROJECT_ROOT, "R", "synthesis_audit.R"))

set.seed(99)
k <- 15
yi <- rnorm(k, 0.3, 0.1)
vi <- runif(k, 0.01, 0.05)
yi[1] <- 1.5
vi[1] <- 0.005

audit <- synthesis_audit(yi, vi)

report_path <- file.path(DEMO_DIR, "Validation_Report.md")
synthesis_report(audit, file = report_path)

figure_path <- file.path(DEMO_DIR, "Figure1_Visual_Convergence.png")
png(figure_path, width = 1000, height = 800)
plot(audit$core, audit = audit)
dev.off()

cat("Publication validation complete.\n")
cat(sprintf("Report: %s\n", report_path))
cat(sprintf("Figure 1: %s\n", figure_path))
