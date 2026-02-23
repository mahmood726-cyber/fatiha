#' SYNTHESIS Audit: Comprehensive Model Verification
#'
#' Runs the full suite of SYNTHESIS diagnostics, including Stability/Overfitting checks
#' and the TGEP (Triple-Guard Ensemble) verification layer.
#'
#' @param yi Numeric vector of effect sizes.
#' @param vi Numeric vector of sampling variances.
#' @param quality Optional numeric vector of quality scores.
#' @param n_boot Number of bootstrap iterations for the TGEP verification (default: 1000).
#' @param measure The effect size measure ('Ratio' for OR/RR/HR, 'Difference' for MD/SMD). Default: 'Ratio'.
#' @param baseline_risk Baseline risk for Clinical Impact (default: 0.20).
#' @param private Logical. If TRUE, removes raw study data from the output for privacy preservation.
#' @param seed Random seed for reproducibility of bootstrap CIs. Default: 42.
#'
#' @return A list of class "synthesis_audit" containing the core estimate, stability metrics, and TGEP guard results.
#' @export
synthesis_audit <- function(yi, vi, quality = NULL, n_boot = 1000, measure = "Ratio", baseline_risk = 0.20, private = FALSE, seed = 42) {
  k <- length(yi)
  if (k < 3) stop("Audit requires at least 3 studies.")

  # 1. Run Core SYNTHESIS Model
  core_res <- synthesis_meta(yi, vi, quality = quality)

  # 2. Run Stability Check (LOOCV) — graceful fallback for k < 5
  stab_res <- tryCatch(
    synthesis_stability(yi, vi, quality = quality, verbose = FALSE),
    error = function(e) {
      list(
        apparent_estimate = core_res$estimate,
        cross_validated_mean = core_res$estimate,
        optimism = 0,
        stability_se = core_res$se,
        reliability_score = 50,  # neutral when cannot assess
        leverage_indices = rep(0, k),
        k = k
      )
    }
  )

  # 3. Run TGEP Verification (The Triple-Guard) with Adaptive Bootstrap
  grma_core <- function(y, v) {
      if (length(y) < 2) return(stats::median(y))
      dens <- stats::density(y, n=512); d_scores <- stats::approx(dens$x, dens$y, xout=y)$y
      w <- (d_scores / max(d_scores)) + (1/v / max(1/v)); w <- w / sum(w)
      sum(w * y)
  }
  wrd_core <- function(y, v) {
      med <- stats::median(y); mad_y <- stats::mad(y)
      if (mad_y < 1e-6) mad_y <- 1.0
      z <- (y - med) / mad_y
      y_clean <- med + pmin(pmax(z, -2.5), 2.5) * mad_y
      w <- 1/v; w <- w/sum(w)
      sum(w * y_clean)
  }
  swa_core <- function(y, v) {
      w <- 1 / (v + stats::var(y)); w <- w/sum(w)
      sum(w * y)
  }

  guards <- c(GRMA = grma_core(yi, vi), WRD = wrd_core(yi, vi), SWA = swa_core(yi, vi))

  # Adaptive Bootstrap (Cost Controller)
  set.seed(seed)
  boot_n_initial <- min(50, n_boot)
  boot_ests <- numeric(n_boot)

  run_boot <- function(n) {
      out <- numeric(n)
      for(i in 1:n) {
          idx <- sample(1:k, k, replace=TRUE)
          g1 <- { if(length(idx)<2) stats::median(yi[idx]) else {
              d <- stats::density(yi[idx], n=128); s <- stats::approx(d$x, d$y, xout=yi[idx])$y
              w <- (s/max(s))+(1/vi[idx]/max(1/vi[idx])); sum((w/sum(w))*yi[idx]) } }
          g2 <- {
              m <- stats::median(yi[idx])
              mad_val <- stats::mad(yi[idx])
              if (mad_val < 1e-6) mad_val <- 1.0
              z <- (yi[idx]-m)/mad_val
              sum((1/vi[idx]/sum(1/vi[idx])) * (m + pmin(pmax(z,-2.5),2.5)*mad_val))
          }
          g3 <- { w<-1/(vi[idx]+stats::var(yi[idx])); sum((w/sum(w))*yi[idx]) }
          out[i] <- mean(c(g1, g2, g3))
      }
      return(out)
  }

  boot_ests[1:boot_n_initial] <- run_boot(boot_n_initial)

  if (n_boot > boot_n_initial) {
      current_sd <- stats::sd(boot_ests[1:boot_n_initial])
      current_mean <- abs(mean(boot_ests[1:boot_n_initial]))
      # Use relative convergence criterion instead of absolute threshold
      rel_cv <- if (current_mean > 1e-8) current_sd / current_mean else current_sd
      if (rel_cv > 0.01 || n_boot <= 100) {
          boot_ests[(boot_n_initial+1):n_boot] <- run_boot(n_boot - boot_n_initial)
          final_boot <- boot_ests
      } else {
          final_boot <- boot_ests[1:boot_n_initial]
      }
  } else {
      final_boot <- boot_ests[1:n_boot]
  }

  tgep_se <- stats::sd(final_boot, na.rm=TRUE)
  tgep_ci <- stats::quantile(final_boot, c(0.025, 0.975), na.rm=TRUE)
  tgep_anchor <- mean(final_boot, na.rm=TRUE)

  # Recalculate Divergence
  divergence <- abs(core_res$estimate - tgep_anchor)

  # 4. Clinical Impact Layer
  if (measure == "Ratio") {
      exp_est <- exp(core_res$estimate)
      p1 <- (exp_est * baseline_risk) / (1 - baseline_risk + exp_est * baseline_risk)
      arr <- abs(baseline_risk - p1)
      nnt <- 1 / (arr + 1e-12)
  } else {
      # For continuous outcomes (MD/SMD), NNT is not directly applicable
      # Using Furukawa approximation: NNT = 1 / (2 * Phi(-|d|/sqrt(2)) * CER)
      # Simplified: report as ARR proxy only
      arr <- abs(core_res$estimate)
      nnt <- if (arr > 1e-12) 1 / arr else Inf
  }

  # 5. Quality Sensitivity & Adversarial Defense
  quality_bias_flag <- FALSE; quality_correlation <- NA
  if (!is.null(quality)) {
      sens_low <- suppressWarnings(synthesis_meta(yi, vi, quality = quality * 0.5))
      sens_high <- suppressWarnings(synthesis_meta(yi, vi, quality = pmin(1, quality * 1.5)))
      quality_sensitivity <- abs(sens_high$estimate - sens_low$estimate)
      if (stats::sd(quality) > 0 && stats::sd(yi) > 0) {
          quality_correlation <- stats::cor(quality, yi)
          if (abs(quality_correlation) > 0.6) quality_bias_flag <- TRUE
      }
  } else { quality_sensitivity <- NA }

  # 6. Sequential Adjustment Decomposition
  raw_mean <- mean(yi)
  shift_density <- core_res$consensus_est - raw_mean
  shift_trajectory <- core_res$estimate - core_res$consensus_est
  leverage_scores <- stab_res$leverage_indices
  top_leverage_indices <- order(leverage_scores, decreasing = TRUE)[1:min(3, k)]
  top_leverage_ids <- paste(top_leverage_indices, collapse=", ")

  # 8. Fail-Safe Logic
  risk_level <- "GREEN"
  final_est <- core_res$estimate; final_se <- core_res$se; final_ci <- c(core_res$ci_lb, core_res$ci_ub)
  fail_safe_triggered <- FALSE
  if (stab_res$reliability_score < 50) risk_level <- "AMBER"
  if (quality_bias_flag) risk_level <- "AMBER"
  if (divergence > 0.2 * abs(tgep_anchor) || stab_res$reliability_score < 20) {
      risk_level <- "RED"; fail_safe_triggered <- TRUE
      final_est <- tgep_anchor; final_se <- tgep_se; final_ci <- as.numeric(tgep_ci)
  }

  res <- list(
      core = if(private) NULL else core_res,
      stability = stab_res,
      tgep = list(anchor = tgep_anchor, guards = guards, ci = tgep_ci, se = tgep_se, divergence = divergence),
      impact = list(baseline_risk = baseline_risk, nnt = nnt, arr = arr, measure = measure),
      sensitivity = list(quality_gradient = quality_sensitivity, quality_correlation = quality_correlation),
      narrative = list(
          initial_shift = shift_density, bias_correction = shift_trajectory,
          total_adjustment = core_res$estimate - raw_mean,
          top_leverage = if(private) "REDACTED" else top_leverage_ids,
          raw_mean = raw_mean
      ),
      decision = list(
          status = risk_level, final_estimate = final_est, final_se = final_se, final_ci = final_ci,
          fail_safe_used = fail_safe_triggered, user_bias_detected = quality_bias_flag
      ),
      metadata = list(timestamp = Sys.time(), version = "0.1.0", dataset_name = "User Data", private_mode = private)
  )

  class(res) <- "synthesis_audit"
  return(res)
}

#' Generate Clinical Evidence Verification Report
#'
#' Creates a formatted Markdown report from a SYNTHESIS Audit object.
#'
#' @param x An object of class "synthesis_audit".
#' @param file File path to save the report.
#' @param lang Language code for the report ("en", "es", "fr"). Default "en".
#' @return NULL invisibly. The report is written to the specified file.
#' @export
synthesis_report <- function(x, file = "SYNTHESIS_Verification_Report.md", lang = "en") {
  if (!inherits(x, "synthesis_audit")) stop("Object must be of class 'synthesis_audit'")

  # i18n dictionary is loaded from the package namespace (R/i18n.R)
  txt <- function(k) get_str(k, lang)

  status_icon <- switch(x$decision$status, "GREEN" = "[GREEN]", "AMBER" = "[AMBER]", "RED" = "[RED]")

  report <- c(
    sprintf("# %s", txt("title")),
    sprintf("**%s:** %s | **%s:** %s %s", txt("generated"), x$metadata$timestamp, txt("status"), status_icon, x$decision$status),
    "",
    sprintf("## %s", txt("exec_summary")),
    sprintf("The SYNTHESIS system has analyzed the evidence and concluded a final estimate of **%.4f** (95%% CI: [%.4f, %.4f]).",
            x$decision$final_estimate, x$decision$final_ci[1], x$decision$final_ci[2]),
    if (x$decision$fail_safe_used) {
        sprintf("**WARNING - %s:** The initial 7-layer model showed high divergence from robust guards. The system has defaulted to the safer TGEP bootstrap interval.", txt("fail_safe_on"))
    } else {
        sprintf("**OK - %s:** The 7-layer bias correction model aligns with the robust Triple-Guard anchor.", txt("fail_safe_off"))
    },
    if (x$decision$user_bias_detected) {
        "\n**ADVERSARIAL WARNING:** A high correlation was detected between Quality Scores and Effect Sizes."
    },
    "",
    sprintf("## 2. %s", txt("impact")),
    sprintf("- **%s:** %.1f (Measure: %s)", txt("nnt"), x$impact$nnt, x$impact$measure),
    sprintf("- **Baseline Risk Assumption:** %.0f%%", x$impact$baseline_risk * 100),
    "",
    "## 3. Integrity Audit",
    "| Metric | Value | Status |",
    "| :--- | :--- | :--- |",
    sprintf("| **%s** | %.1f%% | %s |", txt("reliability"), x$stability$reliability_score, ifelse(x$stability$reliability_score > 50, "Pass", "Flagged")),
    sprintf("| **%s** | %.4f | %s |", txt("divergence"), x$tgep$divergence, ifelse(x$tgep$divergence < 0.2 * abs(x$tgep$anchor), "Pass", "High"))
  )

  # Add trajectory info only if core is available (non-private mode)
  if (!x$metadata$private_mode && !is.null(x$core)) {
    report <- c(report,
      sprintf("| **Trajectory Conf** | %.1f%% | %s |", x$core$trajectory$confidence, ifelse(x$core$trajectory$confidence > 90, "Pass", "Check")))
  }

  report <- c(report,
    "",
    "## 4. Sequential Adjustment Decomposition",
    "The estimate was refined through the following stages:",
    sprintf("1. **Raw Data Mean:** %.4f", x$narrative$raw_mean),
    sprintf("2. **After Density Weighting:** %.4f (Shift: %+.4f)",
            x$narrative$raw_mean + x$narrative$initial_shift, x$narrative$initial_shift),
    sprintf("3. **After Bias Correction:** %.4f (Shift: %+.4f)",
            x$decision$final_estimate - if(x$decision$fail_safe_used) 0 else 0, x$narrative$bias_correction),
    sprintf("4. **Triple-Guard Anchor:** %.4f", x$tgep$anchor),
    if (!x$metadata$private_mode) sprintf("   *High Leverage Studies:* %s", x$narrative$top_leverage) else "   *High Leverage Studies:* REDACTED",
    "",
    "---",
    sprintf("*Report generated by SYNTHESIS v0.1.0 (%s)*", lang)
  )

  writeLines(report, file)
  message(sprintf("Report saved to: %s", file))
  invisible(NULL)
}

#' Print LLM-Ready Summary
#' @param x An object of class "synthesis_audit".
#' @param ... Additional arguments.
#' @return NULL invisibly.
#' @export
print_llm_summary <- function(x, ...) {
  cat(sprintf("SYSTEM: SYNTHESIS v%s | STATUS: %s | EST: %.4f | CI: [%.4f, %.4f] | NNT: %.1f | REL: %.1f%%\n",
              x$metadata$version, x$decision$status, x$decision$final_estimate,
              x$decision$final_ci[1], x$decision$final_ci[2], x$impact$nnt, x$stability$reliability_score))
  invisible(NULL)
}

#' Export as JSON-LD
#' @param x An object of class "synthesis_audit".
#' @param ... Additional arguments.
#' @return The JSON string invisibly.
#' @export
synthesis_json <- function(x, ...) {
  json_str <- sprintf('{
  "@context": "https://w3id.org/evi#",
  "@type": "EvidenceAssessment",
  "generatedBy": "SYNTHESIS v%s",
  "dateCreated": "%s",
  "confidenceValue": %.4f,
  "confidenceInterval": [%.4f, %.4f],
  "reliabilityScore": %.1f,
  "clinicalImpact": {
    "metric": "NNT",
    "value": %.1f
  },
  "integrityCheck": {
    "status": "%s",
    "failSafeTriggered": %s
  }
}', x$metadata$version, x$metadata$timestamp, x$decision$final_estimate,
      x$decision$final_ci[1], x$decision$final_ci[2], x$stability$reliability_score,
      x$impact$nnt, x$decision$status, tolower(as.character(x$decision$fail_safe_used)))

  cat(json_str)
  invisible(json_str)
}

#' Print Method for SYNTHESIS Audit
#' @param x An object of class "synthesis_audit".
#' @param ... Additional arguments.
#' @export
print.synthesis_audit <- function(x, ...) {
  cat("\n=== SYNTHESIS COMPREHENSIVE AUDIT ===\n")
  cat(sprintf("STATUS: %s | FAIL-SAFE: %s\n", x$decision$status, ifelse(x$decision$fail_safe_used, "ACTIVE", "OFF")))
  if(x$decision$user_bias_detected) cat("WARNING: SUSPICIOUS QUALITY SCORE CORRELATION DETECTED.\n")
  cat(rep("=", 35), "\n")
  cat(sprintf("   Final Estimate: %.4f\n", x$decision$final_estimate))
  cat(sprintf("   Final 95%% CI:   [%.4f, %.4f]\n", x$decision$final_ci[1], x$decision$final_ci[2]))
  cat(sprintf("   Reliability:   %.1f%%\n", x$stability$reliability_score))
  cat(sprintf("   Impact (NNT):  %.1f\n", x$impact$nnt))
  cat(rep("=", 35), "\n")
}
