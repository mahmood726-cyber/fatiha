#' VALIDATION: Full SYNTHESIS Audit (Core + Stability + Triple-Guard)
library(metafor)
source("C:/Models/FATIHA_Project/R/synthesis.R")
source("C:/Models/FATIHA_Project/R/synthesis_audit.R")

# 1. Create a "Fragile" Dataset (Small k, one high-leverage study)
set.seed(99)
k <- 8
yi <- rnorm(k, 0.3, 0.1)
vi <- runif(k, 0.01, 0.05)
# Study 8 is a massive outlier that would cause overfitting
yi[8] <- 2.5; vi[8] <- 0.001

# 2. Run Comprehensive Audit
audit <- synthesis_audit(yi, vi)

# 3. Print the Audit Report
print(audit)

cat("
--- Divergence Check ---
")
cat(sprintf("Core Estimate: %.4f
", audit$core$estimate))
cat(sprintf("TGEP Anchor:   %.4f
", audit$tgep$anchor))
cat(sprintf("Difference:    %.4f
", audit$tgep$divergence))

if (audit$tgep$divergence > 0.5) {
    cat("
SUCCESS: The TGEP Guard correctly identified that the 7-Layer model was being pulled by the outlier.
")
}


