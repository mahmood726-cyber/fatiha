first_existing_path <- function(paths) {
  for (path in paths) {
    if (!is.na(path) && nzchar(path) && file.exists(path)) {
      return(normalizePath(path, winslash = "/", mustWork = TRUE))
    }
  }
  NULL
}


resolve_project_root <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  candidates <- character()

  if (length(file_arg) > 0) {
    script_dir <- dirname(sub("^--file=", "", file_arg[[1]]))
    candidates <- c(
      script_dir,
      file.path(script_dir, ".."),
      file.path(script_dir, "..", "..")
    )
  }

  candidates <- c(
    candidates,
    getwd(),
    file.path(getwd(), ".."),
    file.path(getwd(), "..", "..")
  )

  for (candidate in unique(candidates)) {
    normalized <- tryCatch(
      normalizePath(candidate, winslash = "/", mustWork = FALSE),
      error = function(e) NA_character_
    )
    if (
      !is.na(normalized) &&
      dir.exists(normalized) &&
      file.exists(file.path(normalized, "R", "synthesis.R")) &&
      file.exists(file.path(normalized, "DESCRIPTION"))
    ) {
      return(normalizePath(normalized, winslash = "/", mustWork = TRUE))
    }
  }

  stop("FATIHA project root not found. Run from the repo or invoke the script by path.")
}


resolve_pairwise_dir <- function(project_root = resolve_project_root()) {
  candidate <- first_existing_path(c(
    Sys.getenv("PAIRWISE70_DATA_DIR", unset = ""),
    file.path(dirname(project_root), "Projects", "mahmood789", "Pairwise70", "data"),
    file.path(dirname(project_root), "Projects", "Pairwise70", "data"),
    file.path(dirname(project_root), "Models", "Pairwise70", "data"),
    file.path(dirname(project_root), "Pairwise70", "data")
  ))
  if (is.null(candidate)) {
    stop("Pairwise70 data directory not found. Set PAIRWISE70_DATA_DIR to run this script.")
  }
  candidate
}


ensure_repo_dir <- function(path) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  normalizePath(path, winslash = "/", mustWork = TRUE)
}
