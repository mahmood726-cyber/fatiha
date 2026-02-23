#' Real-Data Validation: SYNTHESIS vs metafor on known Cochrane reviews
#' Compares point estimates, SEs, CIs, and fail-safe status.

library(metafor)
source("C:/Models/FATIHA_Project/R/synthesis.R")
source("C:/Models/FATIHA_Project/R/synthesis_audit.R")

data_dir <- "C:/Users/user/OneDrive - NHS/Documents/Pairwise70/data/"

# Well-known reviews for detailed comparison
review_ids <- c(
  "CD000028_pub4",  # BCG vaccine for tuberculosis
  "CD002042_pub6",  # Aspirin for preeclampsia
  "CD001431_pub6",  # Antibiotics for acute otitis media
  "CD001533_pub7",  # Tocolytics for preterm labour
  "CD000219_pub5"   # Antifibrinolytics
)

cat("=== SYNTHESIS Real-Data Validation ===\n")
cat(sprintf("Date: %s\n\n", Sys.Date()))

results <- list()

for (rid in review_ids) {
  data_file <- file.path(data_dir, paste0(rid, "_data.rda"))
  if (!file.exists(data_file)) {
    cat(sprintf("SKIP: %s not found\n", rid))
    next
  }

  # Load the data
  env <- new.env()
  load(data_file, envir = env)
  df <- get(ls(env)[1], envir = env)

  # Find binary outcome analyses (need ai, n1i, ci, n2i columns)
  bin_cols <- c("Experimental.cases", "Experimental.N", "Control.cases", "Control.N")
  if (!all(bin_cols %in% names(df))) {
    cat(sprintf("SKIP: %s - no binary outcome columns\n", rid))
    next
  }

  # Use the first analysis
  analyses <- unique(df$Analysis.number)
  for (a_num in analyses[1:min(2, length(analyses))]) {
    ma_data <- df[df$Analysis.number == a_num, ]

    dat <- tryCatch({
      escalc(measure = "OR",
             ai = ma_data$Experimental.cases, n1i = ma_data$Experimental.N,
             ci = ma_data$Control.cases, n2i = ma_data$Control.N,
             data = ma_data)
    }, error = function(e) NULL)

    if (is.null(dat)) next
    dat <- dat[!is.na(dat$yi) & !is.na(dat$vi) & is.finite(dat$yi) & is.finite(dat$vi), ]
    if (nrow(dat) < 3) next

    yi <- as.numeric(dat$yi)
    vi <- as.numeric(dat$vi)
    k <- length(yi)

    cat(sprintf("\n--- %s | Analysis %d | k=%d ---\n", rid, a_num, k))

    # 1. metafor REML
    fit_re <- tryCatch(rma(yi, vi, method = "REML"), error = function(e) NULL)
    if (!is.null(fit_re)) {
      cat(sprintf("  REML:      est=%.4f  SE=%.4f  CI=[%.4f, %.4f]  tau2=%.4f\n",
                  as.numeric(fit_re$beta), fit_re$se, fit_re$ci.lb, fit_re$ci.ub, fit_re$tau2))
    }

    # 2. metafor FE
    fit_fe <- tryCatch(rma(yi, vi, method = "FE"), error = function(e) NULL)
    if (!is.null(fit_fe)) {
      cat(sprintf("  FE:        est=%.4f  SE=%.4f  CI=[%.4f, %.4f]\n",
                  as.numeric(fit_fe$beta), fit_fe$se, fit_fe$ci.lb, fit_fe$ci.ub))
    }

    # 3. SYNTHESIS core
    syn_res <- tryCatch(synthesis_meta(yi, vi), error = function(e) NULL,
                         warning = function(w) { invokeRestart("muffleWarning") })
    if (is.null(syn_res)) syn_res <- tryCatch(suppressWarnings(synthesis_meta(yi, vi)), error = function(e) NULL)
    if (!is.null(syn_res)) {
      cat(sprintf("  SYNTHESIS: est=%.4f  SE=%.4f  CI=[%.4f, %.4f]  code=%s\n",
                  syn_res$estimate, syn_res$se, syn_res$ci_lb, syn_res$ci_ub, syn_res$error_code))
    }

    # 4. SYNTHESIS audit (with TGEP)
    aud <- tryCatch(synthesis_audit(yi, vi, n_boot = 200), error = function(e) NULL,
                     warning = function(w) { invokeRestart("muffleWarning") })
    if (is.null(aud)) aud <- tryCatch(suppressWarnings(synthesis_audit(yi, vi, n_boot = 200)), error = function(e) NULL)
    if (!is.null(aud)) {
      cat(sprintf("  AUDIT:     est=%.4f  SE=%.4f  CI=[%.4f, %.4f]  status=%s  failsafe=%s  reliability=%.1f%%\n",
                  aud$decision$final_estimate, aud$decision$final_se,
                  aud$decision$final_ci[1], aud$decision$final_ci[2],
                  aud$decision$status, aud$decision$fail_safe_used, aud$stability$reliability_score))
    }

    # Save comparison
    if (!is.null(fit_re) && !is.null(syn_res)) {
      results[[length(results) + 1]] <- data.frame(
        Review = rid, Analysis = a_num, k = k,
        REML_est = as.numeric(fit_re$beta), REML_se = fit_re$se,
        SYNTHESIS_est = syn_res$estimate, SYNTHESIS_se = syn_res$se,
        Diff = abs(syn_res$estimate - as.numeric(fit_re$beta)),
        Audit_status = if (!is.null(aud)) aud$decision$status else NA,
        Reliability = if (!is.null(aud)) aud$stability$reliability_score else NA,
        stringsAsFactors = FALSE
      )
    }
  }
}

# Summary table
if (length(results) > 0) {
  comparison <- do.call(rbind, results)
  cat("\n\n=== SUMMARY TABLE ===\n")
  print(comparison)
  write.csv(comparison, "C:/Models/FATIHA_Project/data/real_data_comparison.csv", row.names = FALSE)
  cat("\nSaved to data/real_data_comparison.csv\n")

  cat(sprintf("\nMedian |SYNTHESIS - REML| difference: %.4f\n", median(comparison$Diff)))
  cat(sprintf("Mean reliability score: %.1f%%\n", mean(comparison$Reliability, na.rm = TRUE)))
}

cat("\n=== Validation Complete ===\n")
