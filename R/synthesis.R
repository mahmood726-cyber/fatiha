#' SYNTHESIS: Structured Yield-Neutral Trust-weighted Heterogeneity-Integrated Statistical Inference System
#'
#' A 7-Layer Meta-Analysis Methodology for Robust Evidence Synthesis.
#'
#' @author Mahmood Ul Hassan
#' @keywords internal
"_PACKAGE"

#' The SYNTHESIS Core Estimator
#'
#' Implements the 7 layers of the SYNTHESIS meta-analysis model.
#'
#' @param yi Numeric vector of effect sizes.
#' @param vi Numeric vector of sampling variances.
#' @param quality Optional numeric vector of Quality/RoB scores (1 is high quality, 0 is low).
#' @param layers Numeric vector of layers to activate (2=Density, 3=Precision, 4=Quality, 6=Trajectory). Default is all.
#' @param engine Backend engine for estimation. Default "stats" (lm). Future: "torch", "eigen".
#' @param alpha Significance level (default 0.05).
#'
#' @return An object of class \code{"synthesis"} containing the 7-layer estimate and diagnostic scores.
#' @export
#' @importFrom stats median mad density approx lm coef qnorm pnorm var sd cor quantile
synthesis_meta <- function(yi, vi, quality = NULL, layers = c(2, 3, 4, 6), engine = "stats", alpha = 0.05) {
  # --- Layer 1: Data Harmonization & Validation (Always On) ---
  if (missing(yi) || missing(vi)) stop("yi and vi must be provided.")

  vi <- pmax(vi, 1e-8)
  original_indices <- 1:length(yi)
  na_idx <- is.na(yi) | is.na(vi)
  if (!is.null(quality)) na_idx <- na_idx | is.na(quality)
  dropped_indices <- original_indices[na_idx]

  if (any(na_idx)) {
      yi <- yi[!na_idx]; vi <- vi[!na_idx]
      if (!is.null(quality)) quality <- quality[!na_idx]
      warning(paste("Removed", sum(na_idx), "studies with missing values."))
  }

  k <- length(yi)

  # k=0: no valid studies remain
  if (k == 0) {
      stop("No valid studies remain after removing missing values.")
  }

  if (k < 3) {
      # Fallback logic for k<3
      warning(paste("Fewer than 3 studies (k =", k, "). Using median fallback."))
      med_est <- stats::median(yi)
      med_se <- if (k == 1) sqrt(vi[1]) else sqrt(stats::var(yi) / k)
      if (is.na(med_se) || !is.finite(med_se)) med_se <- sqrt(mean(vi))
      z_crit <- stats::qnorm(1 - alpha/2)
      res <- list(estimate=med_est, se=med_se, ci_lb=med_est-z_crit*med_se, ci_ub=med_est+z_crit*med_se,
                  pvalue=2*(1-stats::pnorm(abs(med_est/(med_se+1e-12)))), k=k,
                  final_weights=rep(1/k, k), density_scores=rep(1, k),
                  precision_scores=rep(1, k), quality_scores=rep(1, k), consensus_est=med_est,
                  trajectory = list(slope=NA, confidence=0, p=NA),
                  yi=yi, vi=vi, dropped_indices=dropped_indices,
                  quality_input=if(!is.null(quality)) quality else rep(NA, k),
                  error_code = "E001_INSUFFICIENT_K")
      class(res) <- "synthesis"; return(res)
  }

  # --- Layer 2: Spatial Density Weighting ---
  if (2 %in% layers) {
      d <- stats::density(yi, kernel="gaussian", n=512)
      dens_scores <- stats::approx(d$x, d$y, xout=yi)$y
      drange <- max(dens_scores) - min(dens_scores)
      if (drange < 1e-12) {
          density_scores <- rep(1, k)
      } else {
          density_scores <- (dens_scores - min(dens_scores)) / drange
      }
  } else { density_scores <- rep(1, k) }

  # --- Layer 3: Statistical Precision Weighting ---
  if (3 %in% layers) {
      prec <- 1/vi
      prange <- max(prec) - min(prec)
      if (prange < 1e-12) {
          precision_scores <- rep(1, k)
      } else {
          precision_scores <- (prec - min(prec)) / prange
          precision_scores <- pmax(precision_scores, 0.1)
      }
  } else { precision_scores <- rep(1, k) }

  # --- Layer 4: Quality Integration ---
  if (4 %in% layers) {
      quality_scores <- if (!is.null(quality)) quality else rep(1, k)
  } else { quality_scores <- rep(1, k) }

  # Composite weighting (additive combination of three normalized score dimensions)
  final_weights <- (density_scores + precision_scores + quality_scores) / 3
  final_weights <- final_weights / sum(final_weights)

  # --- Layer 5: Consensus Anchor ---
  consensus_est <- sum(final_weights * yi)

  # --- Layer 6: Adaptive Bias Correction (PET-style regression with composite weights) ---
  corrected_est <- consensus_est
  fit_guide <- NULL

  if (6 %in% layers) {
      if (engine == "stats") {
          fit_guide <- tryCatch({ stats::lm(yi ~ sqrt(vi), weights=final_weights) }, error=function(e) NULL)
      } else {
          stop("Unsupported engine. Use 'stats'.")
      }

      consensus_p <- 2 * (1 - stats::pnorm(abs(consensus_est / sqrt(sum(final_weights^2 * vi)))))
      gate_factor <- if (consensus_p > 0.05) 0.5 else 1.0

      raw_correction <- if (!is.null(fit_guide)) stats::coef(fit_guide)[1] - consensus_est else 0

      # Guardrail: cap the correction to prevent extrapolation beyond observed data range
      data_range <- max(yi) - min(yi)
      if (abs(raw_correction * gate_factor) > 2 * data_range && data_range > 0) {
          raw_correction <- sign(raw_correction) * 2 * data_range / gate_factor
      }

      corrected_est <- consensus_est + (raw_correction * gate_factor)
  }

  # Calculate Trajectory Confidence
  trajectory_slope <- NA
  trajectory_p <- NA
  if (!is.null(fit_guide)) {
    coefs <- tryCatch(suppressWarnings(summary(fit_guide)$coefficients), error = function(e) NULL)
    if (!is.null(coefs) && nrow(coefs) >= 2 && ncol(coefs) >= 4) {
      trajectory_slope <- coefs[2, 1]
      trajectory_p <- coefs[2, 4]
    } else {
      trajectory_slope <- stats::coef(fit_guide)[2]
      trajectory_p <- NA
    }
  }
  k_factor <- min(1, k / 15)
  trajectory_confidence <- if (!is.null(fit_guide) && !is.na(trajectory_p)) (1 - trajectory_p) * 100 * k_factor else 0

  # --- Layer 7: Uncertainty Quantification ---
  se_corr <- sqrt(sum(final_weights^2 * vi))
  if (!is.null(fit_guide)) {
    coefs_se <- tryCatch(suppressWarnings(summary(fit_guide)$coefficients), error = function(e) NULL)
    if (!is.null(coefs_se) && nrow(coefs_se) >= 1 && ncol(coefs_se) >= 2) {
      se_corr <- coefs_se[1, 2]
    }
  }
  # Floor SE to prevent zero-width CIs
  se_corr <- max(se_corr, 1e-8)

  res <- list(estimate=as.numeric(corrected_est), se=as.numeric(se_corr),
              ci_lb=as.numeric(corrected_est - stats::qnorm(1-alpha/2)*se_corr),
              ci_ub=as.numeric(corrected_est + stats::qnorm(1-alpha/2)*se_corr),
              pvalue=2*(1-stats::pnorm(abs(as.numeric(corrected_est)/as.numeric(se_corr)))),
              k=k, final_weights=final_weights, density_scores=density_scores,
              precision_scores=precision_scores, quality_scores=quality_scores,
              consensus_est=consensus_est,
              trajectory = list(slope = trajectory_slope, confidence = trajectory_confidence, p = trajectory_p),
              yi=yi, vi=vi, dropped_indices=dropped_indices,
              quality_input=if(!is.null(quality)) quality else rep(NA, k),
              error_code = "E000_SUCCESS",
              schema_version = "1.0")
  class(res) <- "synthesis"; return(res)
}

#' Validate SYNTHESIS Object Schema
#'
#' Checks if an object conforms to the v1.0 specification.
#' @param x Object to validate.
#' @return Logical; TRUE if valid, FALSE otherwise.
#' @export
validate_synthesis_object <- function(x) {
    if (!inherits(x, "synthesis")) return(FALSE)
    required <- c("estimate", "se", "ci_lb", "ci_ub", "pvalue", "k",
                   "final_weights", "density_scores", "precision_scores",
                   "quality_scores", "consensus_est", "trajectory",
                   "yi", "vi", "error_code", "schema_version")
    if (!all(required %in% names(x))) return(FALSE)
    if (!is.numeric(x$estimate) || !is.numeric(x$se)) return(FALSE)
    return(TRUE)
}

#' Generate Transparency Table for SYNTHESIS Model
#' @param x An object of class "synthesis".
#' @return A data.frame with per-study weighting decomposition.
#' @export
synthesis_table <- function(x) {
  df <- data.frame(Study=1:x$k, EffectSize=x$yi, Variance=x$vi, Density=x$density_scores,
                   Precision=x$precision_scores, Quality=x$quality_scores, Weight=x$final_weights)
  df$Weighted_Contribution <- x$yi * x$final_weights

  if (!all(is.na(x$quality_input))) df$Input_Quality <- x$quality_input
  return(df)
}

#' SYNTHESIS Arbiter: Consolidate Multiple Estimates
#'
#' Takes results from different models or packages and finds the "Corrected Consensus"
#' using SYNTHESIS weighting layers (Density, Precision, Quality).
#'
#' Note: Method estimates from the same dataset are not independent. This function
#' treats them as if they were independent studies. Results should be interpreted
#' as a heuristic consensus, not a formal meta-analysis.
#'
#' @param estimates Numeric vector of point estimates from different sources.
#' @param ses Numeric vector of standard errors for those estimates.
#' @param source_quality Optional numeric vector of quality/reliability scores for each source.
#'
#' @return A list of class \code{"synthesis_arbiter"} containing the arbitrated estimate and source weights.
#' @export
synthesis_arbiter <- function(estimates, ses, source_quality = NULL) {
  vi <- ses^2
  res <- synthesis_meta(estimates, vi, quality = source_quality)
  res$arbiter_weights <- res$final_weights
  class(res) <- c("synthesis_arbiter", "synthesis")
  return(res)
}

#' Assess Model Stability and Overfitting
#'
#' Performs Leave-One-Out Cross-Validation (LOOCV) to calculate the stability of the
#' SYNTHESIS estimate and identify potential overfitting.
#'
#' @param yi Numeric vector of effect sizes.
#' @param vi Numeric vector of sampling variances.
#' @param quality Optional numeric vector of quality scores.
#' @param verbose Logical; if TRUE, prints progress.
#'
#' @return A list of class "synthesis_stability" containing stability metrics.
#' @export
synthesis_stability <- function(yi, vi, quality = NULL, verbose = TRUE) {
  k <- length(yi)
  if (k < 5) stop("Stability assessment requires at least 5 studies.")

  if (verbose) message("Running Stability Assessment (LOOCV)...")

  # 1. Original Estimate
  orig <- synthesis_meta(yi, vi, quality = quality)

  # 2. LOOCV Loop
  cv_estimates <- numeric(k)
  weight_shifts <- numeric(k)

  for (i in 1:k) {
    res_cv <- suppressWarnings(synthesis_meta(yi[-i], vi[-i],
                                              quality = if(!is.null(quality)) quality[-i] else NULL))
    cv_estimates[i] <- res_cv$estimate

    old_weights <- orig$final_weights[-i] / sum(orig$final_weights[-i])
    weight_shifts[i] <- sum(abs(res_cv$final_weights - old_weights))
  }

  # 3. Metrics
  stability_se <- stats::sd(cv_estimates)
  bias_corrected_est <- mean(cv_estimates)
  optimism <- abs(orig$estimate - bias_corrected_est)

  k_penalty <- min(1, (k / 15))
  rel_score <- max(0, 100 * k_penalty * (1 - (optimism / (stats::sd(yi) + 1e-12))))

  res <- list(
    apparent_estimate = orig$estimate,
    cross_validated_mean = bias_corrected_est,
    optimism = optimism,
    stability_se = stability_se,
    reliability_score = rel_score,
    leverage_indices = weight_shifts,
    k = k
  )

  class(res) <- "synthesis_stability"
  return(res)
}

#' Print Method for SYNTHESIS Model
#' @param x An object of class "synthesis".
#' @param ... Additional arguments.
#' @export
print.synthesis <- function(x, ...) {
  cat("\nSYNTHESIS Meta-Analysis Report\n", rep("-", 30), "\n")
  cat(sprintf("Estimate: %.4f\nStd. Error: %.4f\n95%% CI: [%.4f, %.4f]\nP-value: %.4f\nStudies (k): %d\n",
              x$estimate, x$se, x$ci_lb, x$ci_ub, x$pvalue, x$k))
}

#' Print Method for SYNTHESIS Stability
#' @param x An object of class "synthesis_stability".
#' @param ... Additional arguments.
#' @export
print.synthesis_stability <- function(x, ...) {
  cat("\nSYNTHESIS Stability & Reliability Report\n", rep("-", 30), "\n")
  cat(sprintf("Apparent Estimate:    %.4f\n", x$apparent_estimate))
  cat(sprintf("Cross-Validated Mean: %.4f\n", x$cross_validated_mean))
  cat(sprintf("Optimism (Bias):      %.4f\n", x$optimism))
  cat(sprintf("Stability (LOO-SE):   %.4f\n", x$stability_se))
  cat(rep("-", 30), "\n")

  risk <- if(x$reliability_score > 80) "LOW" else if(x$reliability_score > 50) "MODERATE" else "HIGH"
  cat(sprintf("RELIABILITY SCORE:    %.1f%% (%s RISK)\n", x$reliability_score, risk))

  if (x$k < 10) cat("WARNING: Small sample size (k < 10) significantly reduces reliability.\n")
}

#' Plot Diagnostic for SYNTHESIS Model
#' @param x An object of class "synthesis".
#' @param audit An optional "synthesis_audit" object to overlay TGEP guards.
#' @param ... Additional arguments.
#' @export
#' @importFrom graphics par plot abline text barplot legend axis grid
#' @importFrom grDevices rgb
plot.synthesis <- function(x, audit = NULL, ...) {
  old_par <- graphics::par(no.readonly=TRUE); on.exit(graphics::par(old_par))

  if (!is.null(audit)) {
      graphics::par(mfrow=c(2,2))

      methods <- c("Raw Mean", "SYNTHESIS Core", "TGEP Anchor", "Final Decision")
      raw_mean <- mean(x$yi)
      ests <- c(raw_mean, x$estimate, audit$tgep$anchor, audit$decision$final_estimate)
      cols <- c("grey", "blue", "orange", ifelse(audit$decision$fail_safe_used, "red", "green"))

      graphics::plot(ests, 1:4, pch=19, col=cols, cex=2, yaxt="n", ylab="", xlab="Effect Size",
           main="Visual Convergence", xlim=range(c(ests, x$ci_lb, x$ci_ub)))
      graphics::axis(2, at=1:4, labels=methods, las=1, cex.axis=0.8)
      graphics::grid()

      graphics::plot(stats::density(x$yi), main="Landscape & Guards", col="blue", lwd=2)
      graphics::abline(v=x$estimate, col="blue", lwd=2, lty=2)
      graphics::abline(v=audit$tgep$anchor, col="orange", lwd=2, lty=2)
      graphics::legend("topright", legend=c("SYNTHESIS", "TGEP Guard"), col=c("blue", "orange"), lty=2, cex=0.7)

      cex_val <- x$final_weights * (10 / max(x$final_weights))
      graphics::plot(sqrt(x$vi), x$yi, pch=19, col=grDevices::rgb(0,0,0,0.5), cex=cex_val, main="Corrected Trajectory")
      graphics::abline(h=x$estimate, col="blue", lwd=2)

      graphics::barplot(x$final_weights, main="Final Weights", col="darkcyan", border="black")

  } else {
      graphics::par(mfrow=c(2,2))
      graphics::plot(stats::density(x$yi), main="Layer 2: Density Mapping", col="blue", lwd=2)
      graphics::abline(v=x$estimate, col="red", lwd=2, lty=2)

      if (!all(is.na(x$quality_input))) {
          r_val <- stats::cor(1/x$vi, x$quality_input, use="complete.obs")
          graphics::plot(1/x$vi, x$quality_input, pch=19, col="darkorange", xlab="Precision", ylab="Quality",
                         main=sprintf("Quality vs Precision (r = %.2f)", r_val))
          graphics::abline(stats::lm(x$quality_input ~ I(1/x$vi)), lty=3)
      } else {
          graphics::plot(x$density_scores, x$precision_scores, pch=19, col="purple", main="Layer 4: Composite Weighting")
      }

      cex_val <- x$final_weights * (10 / max(x$final_weights))
      graphics::plot(sqrt(x$vi), x$yi, pch=19, col=grDevices::rgb(0,0,0,0.5), cex=cex_val, main="Layer 6: Corrected Trajectory")
      graphics::abline(h=x$estimate, col="red", lwd=2)
      graphics::barplot(x$final_weights, main="Final Weight Distribution", col="darkcyan", border="black")
  }
}
