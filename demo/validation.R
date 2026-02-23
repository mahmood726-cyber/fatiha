# SYNTHESIS Validation Script
# Comparing "The Initialization" (SYNTHESIS) vs "The Guard" (TGEP) vs "The Standard" (REML)

library(metafor)
source("C:/Models/FATIHA_Project/R/synthesis.R")

tgep_path <- "C:/Models/TGEP_Development/R/TGEP.R"
has_tgep <- file.exists(tgep_path)
if (has_tgep) source(tgep_path)

cat("=== SYNTHESIS VALIDATION: The Initialization vs The Guard ===\n")

# 1. Load Data or Simulate
data_path <- "C:/Users/user/OneDrive - NHS/Documents/Pairwise70/data/CD000028_pub4_data.rda"

if (file.exists(data_path)) {
    load(data_path)
    df <- CD000028_pub4_data
    ma_data <- df[df$Analysis.number == 1, ]
    dat <- escalc(measure="OR", ai=Experimental.cases, n1i=Experimental.N, ci=Control.cases, n2i=Control.N, data=ma_data)
    dat <- dat[!is.na(dat$yi) & !is.na(dat$vi), ]
    yi <- dat$yi
    vi <- dat$vi
    cat(sprintf("Loaded dataset: CD000028 (k=%d)\n", length(yi)))
} else {
    cat("Data file not found. Simulating data...\n")
    set.seed(42)
    k <- 20
    yi <- rnorm(k, mean=0.5, sd=0.3)
    vi <- runif(k, 0.01, 0.1)
    # Introduce some bias (small study effects)
    yi[vi > 0.05] <- yi[vi > 0.05] + 0.4
}

# 2. Run Models
# SYNTHESIS (The Initialization)
synthesis_res <- synthesis_meta(yi, vi)

# REML (The Standard)
reml_res <- rma(yi, vi, method="REML")

# TGEP (The Guard) - if available
tgep_est <- NA
if (has_tgep) {
    tgep_res <- tgep_meta(yi, vi, n_boot=0)
    tgep_est <- tgep_res$estimate
}

# 3. Comparison
cat("---------------------------------------------------\n")
cat(sprintf("REML Estimate:   %.4f (SE: %.4f) [95%% CI: %.4f, %.4f]\n", 
            as.numeric(reml_res$beta), reml_res$se, reml_res$ci.lb, reml_res$ci.ub))

if (has_tgep) {
    cat(sprintf("TGEP Estimate:   %.4f (SE: %.4f) [95%% CI: %.4f, %.4f]\n", 
                tgep_res$estimate, tgep_res$se, tgep_res$ci_lb, tgep_res$ci_ub))
} else {
    cat("TGEP Estimate:   [Not Available - TGEP.R missing]\n")
}

cat(sprintf("SYNTHESIS Estimate: %.4f (SE: %.4f) [95%% CI: %.4f, %.4f]\n", 
            synthesis_res$estimate, synthesis_res$se, synthesis_res$ci_lb, synthesis_res$ci_ub))

cat("\nInterpretation:\n")
cat("SYNTHESIS seeks the 'Straight Path' (intercept at 0 error) weighted by 'Density-based' (Density) and 'Precision-based' (Precision).\n")
if (abs(synthesis_res$estimate) < abs(as.numeric(reml_res$beta))) {
    cat("SYNTHESIS is more conservative (closer to null), suggesting standard methods were 'Biased' (biased).\n")
} else {
    cat("SYNTHESIS is more aggressive, suggesting true effect was masked by 'Noise' (noisy) studies.\n")
}

# 4. Diagnostics
png("C:/Models/FATIHA_Project/SYNTHESIS_Diagnostics.png", width=800, height=800)
# plot.SYNTHESIS is now an S3 method available via source
plot(synthesis_res)
dev.off()

cat("\nValidation complete. Plots saved to C:/Models/FATIHA_Project/SYNTHESIS_Diagnostics.png\n")




