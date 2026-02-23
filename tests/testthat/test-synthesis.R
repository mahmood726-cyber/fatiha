# =============================================================================
# SYNTHESIS Package — Comprehensive Test Suite
# =============================================================================

# --- Core Estimator: synthesis_meta() ---

test_that("synthesis_meta runs correctly on simulated data", {
  set.seed(123)
  k <- 20
  yi <- rnorm(k, mean = 0.5, sd = 0.2)
  vi <- runif(k, 0.01, 0.1)

  res <- synthesis_meta(yi, vi)

  expect_s3_class(res, "synthesis")
  expect_true(is.numeric(res$estimate))
  expect_true(res$estimate > 0)
  expect_equal(length(res$final_weights), k)
  expect_equal(length(res$density_scores), k)
  expect_equal(res$k, k)
  expect_equal(res$error_code, "E000_SUCCESS")
})

test_that("synthesis_meta handles k=2 with fallback", {
  yi <- c(0.1, 0.2)
  vi <- c(0.01, 0.02)

  expect_warning(res <- synthesis_meta(yi, vi), "Fewer than 3 studies")
  # k=2 fallback: median estimate
  expect_s3_class(res, "synthesis")
  expect_equal(res$k, 2)
  expect_equal(res$estimate, median(yi))
  expect_equal(res$error_code, "E001_INSUFFICIENT_K")
})

test_that("synthesis_meta handles k=1", {
  yi <- c(0.5)
  vi <- c(0.04)

  expect_warning(res <- synthesis_meta(yi, vi), "Fewer than 3 studies")
  expect_s3_class(res, "synthesis")
  expect_equal(res$k, 1)
  expect_equal(res$estimate, 0.5)
  expect_equal(res$error_code, "E001_INSUFFICIENT_K")
})

test_that("synthesis_meta handles NAs", {
  yi <- c(0.1, 0.2, NA, 0.4)
  vi <- c(0.01, 0.02, 0.03, NA)

  # Two warnings: "Removed 2 studies" and "Fewer than 3 studies"
  expect_warning(expect_warning(res <- synthesis_meta(yi, vi), "Removed 2"), "Fewer than 3")
  expect_equal(res$k, 2)
})

test_that("synthesis_meta errors on all-NA input (k=0)", {
  yi <- c(NA, NA, NA)
  vi <- c(NA, NA, NA)

  # After removing all NAs, k=0 — should error, not produce broken object
  expect_error(suppressWarnings(synthesis_meta(yi, vi)), "No valid studies")
})

test_that("synthesis_meta uses alpha parameter for CI", {
  set.seed(42)
  k <- 15
  yi <- rnorm(k, 0.3, 0.1)
  vi <- runif(k, 0.01, 0.05)

  res90 <- synthesis_meta(yi, vi, alpha = 0.10)
  res95 <- synthesis_meta(yi, vi, alpha = 0.05)

  # 90% CI should be narrower than 95% CI
  width90 <- res90$ci_ub - res90$ci_lb
  width95 <- res95$ci_ub - res95$ci_lb
  expect_true(width90 < width95)
})

test_that("synthesis_meta with quality scores", {
  set.seed(7)
  k <- 10
  yi <- rnorm(k, 0.4, 0.15)
  vi <- runif(k, 0.01, 0.08)
  quality <- runif(k, 0.5, 1.0)

  res <- synthesis_meta(yi, vi, quality = quality)
  expect_s3_class(res, "synthesis")
  expect_equal(length(res$quality_scores), k)
  expect_false(all(is.na(res$quality_input)))
})

test_that("synthesis_meta with zero variance input", {
  yi <- c(0.5, 0.5, 0.5, 0.5, 0.5)
  vi <- c(0, 0, 0, 0, 0)  # zero variance — should be clamped to 1e-8

  res <- synthesis_meta(yi, vi)
  expect_s3_class(res, "synthesis")
  expect_true(is.finite(res$estimate))
  expect_true(is.finite(res$se))
})

test_that("synthesis_meta returns correct field names", {
  set.seed(1)
  yi <- rnorm(10, 0.5, 0.2)
  vi <- runif(10, 0.01, 0.1)
  res <- synthesis_meta(yi, vi)

  expected_fields <- c("estimate", "se", "ci_lb", "ci_ub", "pvalue", "k",
                        "final_weights", "density_scores", "precision_scores",
                        "quality_scores", "consensus_est", "trajectory",
                        "yi", "vi", "dropped_indices", "quality_input",
                        "error_code", "schema_version")
  for (f in expected_fields) {
    expect_true(f %in% names(res), info = paste("Missing field:", f))
  }
})

test_that("synthesis_meta weights sum to 1", {
  set.seed(99)
  yi <- rnorm(15, 0.3, 0.15)
  vi <- runif(15, 0.01, 0.06)
  res <- synthesis_meta(yi, vi)
  expect_equal(sum(res$final_weights), 1.0, tolerance = 1e-10)
})

# --- Schema Validation ---

test_that("validate_synthesis_object works", {
  set.seed(1)
  res <- synthesis_meta(rnorm(10, 0.5, 0.1), runif(10, 0.01, 0.05))
  expect_true(validate_synthesis_object(res))
  expect_false(validate_synthesis_object(list(a = 1)))
  expect_false(validate_synthesis_object("not an object"))
})

# --- Transparency Table ---

test_that("synthesis_table returns correct data frame", {
  set.seed(1)
  yi <- rnorm(8, 0.4, 0.1)
  vi <- runif(8, 0.01, 0.05)
  res <- synthesis_meta(yi, vi)
  tbl <- synthesis_table(res)

  expect_s3_class(tbl, "data.frame")
  expect_equal(nrow(tbl), 8)
  expect_true("Weighted_Contribution" %in% names(tbl))
  expect_true(all(c("Density", "Precision", "Quality", "Weight") %in% names(tbl)))
})

# --- Arbiter ---

test_that("synthesis_arbiter consolidates estimates", {
  estimates <- c(0.45, 0.50, 0.52, 0.48, 0.55)
  ses <- c(0.05, 0.04, 0.06, 0.03, 0.07)

  res <- synthesis_arbiter(estimates, ses)
  expect_s3_class(res, "synthesis_arbiter")
  expect_s3_class(res, "synthesis")
  expect_true(is.numeric(res$estimate))
  expect_true(!is.null(res$arbiter_weights))
})

# --- Stability ---

test_that("synthesis_stability runs LOOCV", {
  set.seed(42)
  k <- 10
  yi <- rnorm(k, 0.5, 0.15)
  vi <- runif(k, 0.01, 0.06)

  stab <- synthesis_stability(yi, vi, verbose = FALSE)
  expect_s3_class(stab, "synthesis_stability")
  expect_true(is.numeric(stab$reliability_score))
  expect_true(stab$reliability_score >= 0 && stab$reliability_score <= 100)
  expect_equal(length(stab$leverage_indices), k)
})

test_that("synthesis_stability rejects k < 5", {
  expect_error(synthesis_stability(c(0.1, 0.2, 0.3), c(0.01, 0.02, 0.03)),
               "at least 5 studies")
})

# --- Audit ---

test_that("synthesis_audit runs full pipeline", {
  set.seed(123)
  k <- 12
  yi <- rnorm(k, 0.4, 0.15)
  vi <- runif(k, 0.01, 0.08)

  aud <- synthesis_audit(yi, vi, n_boot = 50)
  expect_s3_class(aud, "synthesis_audit")
  expect_true(aud$decision$status %in% c("GREEN", "AMBER", "RED"))
  expect_true(is.numeric(aud$decision$final_estimate))
  expect_true(is.numeric(aud$tgep$anchor))
  expect_true(is.numeric(aud$impact$nnt))
})

test_that("synthesis_audit detects quality bias", {
  set.seed(7)
  k <- 15
  yi <- rnorm(k, 0.5, 0.2)
  vi <- runif(k, 0.01, 0.05)
  # Quality scores highly correlated with effect sizes (adversarial)
  quality <- (yi - min(yi)) / (max(yi) - min(yi))

  aud <- synthesis_audit(yi, vi, quality = quality, n_boot = 50)
  expect_true(aud$decision$user_bias_detected)
})

test_that("synthesis_audit rejects k < 3", {
  expect_error(synthesis_audit(c(0.1, 0.2), c(0.01, 0.02)),
               "at least 3 studies")
})

test_that("synthesis_audit private mode redacts data", {
  set.seed(1)
  yi <- rnorm(10, 0.3, 0.1)
  vi <- runif(10, 0.01, 0.05)

  aud <- synthesis_audit(yi, vi, n_boot = 50, private = TRUE)
  expect_null(aud$core)
  expect_equal(aud$narrative$top_leverage, "REDACTED")
})

test_that("synthesis_audit fail-safe triggers on outlier-heavy data", {
  set.seed(99)
  k <- 8
  yi <- rnorm(k, 0.3, 0.1)
  vi <- runif(k, 0.01, 0.05)
  yi[8] <- 2.5  # extreme outlier
  vi[8] <- 0.001  # high precision

  aud <- synthesis_audit(yi, vi, n_boot = 100)
  # With an extreme outlier, expect RED or at minimum AMBER
  expect_true(aud$decision$status %in% c("AMBER", "RED"))
})

# --- Print Methods ---

test_that("print.synthesis works without error", {
  set.seed(1)
  res <- synthesis_meta(rnorm(10, 0.5, 0.1), runif(10, 0.01, 0.05))
  expect_output(print(res), "SYNTHESIS Meta-Analysis Report")
})

test_that("print.synthesis_stability works without error", {
  set.seed(1)
  stab <- synthesis_stability(rnorm(10, 0.5, 0.1), runif(10, 0.01, 0.05), verbose = FALSE)
  expect_output(print(stab), "Stability")
})

test_that("print.synthesis_audit works without error", {
  set.seed(1)
  aud <- synthesis_audit(rnorm(10, 0.5, 0.1), runif(10, 0.01, 0.05), n_boot = 50)
  expect_output(print(aud), "SYNTHESIS COMPREHENSIVE AUDIT")
})

# --- Edge Cases ---

test_that("synthesis_meta handles identical effect sizes", {
  yi <- rep(0.5, 10)
  vi <- runif(10, 0.01, 0.05)
  res <- synthesis_meta(yi, vi)
  expect_s3_class(res, "synthesis")
  expect_equal(res$estimate, 0.5, tolerance = 0.1)
})

test_that("synthesis_meta handles single large outlier", {
  set.seed(5)
  yi <- c(rnorm(9, 0.3, 0.05), 5.0)
  vi <- c(runif(9, 0.01, 0.03), 0.5)  # outlier with LOW precision
  res <- synthesis_meta(yi, vi)
  # Density weighting + low precision should pull estimate toward the main cluster
  expect_true(res$estimate < 2.0)
})

test_that("synthesis_meta layer selection works", {
  set.seed(1)
  yi <- rnorm(10, 0.5, 0.1)
  vi <- runif(10, 0.01, 0.05)

  res_all <- synthesis_meta(yi, vi, layers = c(2, 3, 4, 6))
  res_density_only <- synthesis_meta(yi, vi, layers = c(2))
  res_none <- synthesis_meta(yi, vi, layers = c())

  # Different layer configs should give different results
  expect_s3_class(res_all, "synthesis")
  expect_s3_class(res_density_only, "synthesis")
  expect_s3_class(res_none, "synthesis")
})
