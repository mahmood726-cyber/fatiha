#' Pairwise70 Benchmark: Large-scale SYNTHESIS vs metafor comparison
#' Loops over all 501 Cochrane reviews, extracts binary outcome analyses,
#' and compares SYNTHESIS with REML/FE.

library(metafor)
source("C:/Models/FATIHA_Project/R/synthesis.R")

data_dir <- "C:/Users/user/OneDrive - NHS/Documents/Pairwise70/data/"

files <- list.files(data_dir, pattern = "\\.rda$", full.names = TRUE)
cat(sprintf("=== Pairwise70 Benchmark: %d reviews ===\n", length(files)))
cat(sprintf("Date: %s\n\n", Sys.Date()))

results <- list()
errors <- 0
skipped <- 0

for (i in seq_along(files)) {
  if (i %% 50 == 0) cat(sprintf("  Progress: %d/%d\n", i, length(files)))

  env <- new.env()
  tryCatch(load(files[i], envir = env), error = function(e) NULL)
  obj_names <- ls(env)
  if (length(obj_names) == 0) { skipped <- skipped + 1; next }

  df <- get(obj_names[1], envir = env)

  # Need binary outcome columns
  bin_cols <- c("Experimental.cases", "Experimental.N", "Control.cases", "Control.N")
  if (!all(bin_cols %in% names(df))) { skipped <- skipped + 1; next }

  # Extract review ID from filename
  rid <- sub("_data\\.rda$", "", basename(files[i]))

  # Process first analysis only (for efficiency)
  analyses <- unique(df$Analysis.number)
  a_num <- analyses[1]
  ma_data <- df[df$Analysis.number == a_num, ]

  dat <- tryCatch({
    escalc(measure = "OR",
           ai = ma_data$Experimental.cases, n1i = ma_data$Experimental.N,
           ci = ma_data$Control.cases, n2i = ma_data$Control.N,
           data = ma_data)
  }, error = function(e) NULL)

  if (is.null(dat)) { errors <- errors + 1; next }
  dat <- dat[!is.na(dat$yi) & !is.na(dat$vi) & is.finite(dat$yi) & is.finite(dat$vi), ]
  if (nrow(dat) < 3) { skipped <- skipped + 1; next }

  yi <- as.numeric(dat$yi)
  vi <- as.numeric(dat$vi)
  k <- length(yi)

  # Run REML
  fit_re <- tryCatch(rma(yi, vi, method = "REML"), error = function(e) NULL)
  if (is.null(fit_re)) { errors <- errors + 1; next }

  # Run FE
  fit_fe <- tryCatch(rma(yi, vi, method = "FE"), error = function(e) NULL)

  # Run SYNTHESIS
  syn_res <- tryCatch(suppressWarnings(synthesis_meta(yi, vi)), error = function(e) NULL)
  if (is.null(syn_res)) { errors <- errors + 1; next }

  # Coverage check: does CI contain REML estimate?
  reml_est <- as.numeric(fit_re$beta)
  syn_covers_reml <- (syn_res$ci_lb <= reml_est) & (syn_res$ci_ub >= reml_est)

  # Does REML CI contain true zero (for significance agreement)?
  reml_sig <- (fit_re$ci.lb > 0) | (fit_re$ci.ub < 0)
  syn_sig <- (syn_res$ci_lb > 0) | (syn_res$ci_ub < 0)

  results[[length(results) + 1]] <- data.frame(
    Review = rid, k = k,
    REML_est = reml_est, REML_se = fit_re$se, REML_tau2 = fit_re$tau2,
    FE_est = if (!is.null(fit_fe)) as.numeric(fit_fe$beta) else NA,
    SYNTHESIS_est = syn_res$estimate, SYNTHESIS_se = syn_res$se,
    Abs_diff = abs(syn_res$estimate - reml_est),
    SYN_covers_REML = syn_covers_reml,
    REML_sig = reml_sig, SYN_sig = syn_sig,
    Sig_agree = (reml_sig == syn_sig),
    CI_width_REML = fit_re$ci.ub - fit_re$ci.lb,
    CI_width_SYN = syn_res$ci_ub - syn_res$ci_lb,
    stringsAsFactors = FALSE
  )
}

# Compile results
if (length(results) > 0) {
  benchmark <- do.call(rbind, results)

  cat(sprintf("\n=== BENCHMARK RESULTS ===\n"))
  cat(sprintf("Reviews processed: %d\n", length(results)))
  cat(sprintf("Skipped (no data / k<3): %d\n", skipped))
  cat(sprintf("Errors: %d\n\n", errors))

  cat(sprintf("Median |SYNTHESIS - REML| difference: %.4f\n", median(benchmark$Abs_diff)))
  cat(sprintf("Mean |SYNTHESIS - REML| difference: %.4f\n", mean(benchmark$Abs_diff)))
  cat(sprintf("Max |SYNTHESIS - REML| difference: %.4f\n", max(benchmark$Abs_diff)))
  cat(sprintf("SYNTHESIS CI covers REML estimate: %d/%d (%.1f%%)\n",
              sum(benchmark$SYN_covers_REML), nrow(benchmark),
              100 * mean(benchmark$SYN_covers_REML)))
  cat(sprintf("Significance agreement: %d/%d (%.1f%%)\n",
              sum(benchmark$Sig_agree), nrow(benchmark),
              100 * mean(benchmark$Sig_agree)))
  cat(sprintf("Median CI width — REML: %.4f | SYNTHESIS: %.4f\n",
              median(benchmark$CI_width_REML), median(benchmark$CI_width_SYN)))

  # Categorize by k
  cat("\n--- By study count ---\n")
  k_bins <- cut(benchmark$k, breaks = c(0, 5, 10, 20, 50, Inf),
                labels = c("k<=5", "k=6-10", "k=11-20", "k=21-50", "k>50"))
  for (bin in levels(k_bins)) {
    sub <- benchmark[k_bins == bin, ]
    if (nrow(sub) == 0) next
    cat(sprintf("  %s (n=%d): median diff=%.4f, sig agree=%.1f%%\n",
                bin, nrow(sub), median(sub$Abs_diff), 100 * mean(sub$Sig_agree)))
  }

  # Save
  write.csv(benchmark, "C:/Models/FATIHA_Project/data/pairwise70_benchmark.csv", row.names = FALSE)
  cat("\nSaved to data/pairwise70_benchmark.csv\n")
} else {
  cat("No results produced.\n")
}

cat("\n=== Benchmark Complete ===\n")
