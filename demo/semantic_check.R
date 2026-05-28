#' VALIDATION: Semantic Web & Privacy Features

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

cat("=== SYNTHESIS SEMANTIC & PRIVACY CHECK ===\n")

set.seed(42)
k <- 10
yi <- rnorm(k, 0.5, 0.2)
vi <- runif(k, 0.01, 0.05)

cat("\n--- Running Privacy Mode ---\n")
audit_priv <- synthesis_audit(yi, vi, private = TRUE)

if (is.null(audit_priv$core)) {
  cat("PASS: Core data redacted in private mode.\n")
} else {
  cat("FAIL: Core data leaked.\n")
}

if (audit_priv$narrative$top_leverage == "REDACTED") {
  cat("PASS: Leverage IDs redacted.\n")
}

cat("\n--- LLM Prompt Output ---\n")
print_llm_summary(audit_priv)

cat("\n--- JSON-LD Linked Data Export ---\n")
json_out <- synthesis_json(audit_priv)
print(json_out)

cat("\nValidation Complete.\n")
