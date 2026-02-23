#' VALIDATION: SYNTHESIS Stability & Overfitting Protection
library(metafor)
source("C:/Models/FATIHA_Project/R/synthesis.R")

# 1. Create a "Fragile" Dataset (Small k, one high-leverage study)
set.seed(99)
k <- 8
yi <- rnorm(k, 0.3, 0.1)
vi <- runif(k, 0.01, 0.05)
# Study 8 is a massive outlier that would cause overfitting
yi[8] <- 2.5; vi[8] <- 0.001

# 2. Run Core Analysis
res <- synthesis_meta(yi, vi)
print(res)

# 3. Run Stability Assessment (The Reliability Shield)
stab <- synthesis_stability(yi, vi)
print(stab)

cat("
--- Leverage Analysis ---
")
cat("Leverage per Study (How much removing it shifts the model):
")
print(round(stab$leverage_indices, 3))

if (which.max(stab$leverage_indices) == 8) {
    cat("
SUCCESS: The stability module correctly identified Study 8 as the primary source of instability.
")
}


