#' SYNTHESIS Arbiter: Resolving NMA Package Disagreements
#' This script uses SYNTHESIS to find a "Corrected Consensus" when different 
#' NMA packages (netmeta, gemtc, multinma) disagree on treatment effects.

source("C:/Models/FATIHA_Project/R/synthesis.R")

cat("=== SYNTHESIS ARBITER: Resolving NMA Bake-Off Disagreements ===

")

# 1. Mock Results from the NMA Bake-Off (e.g., Smoking Cessation Dataset)
# Each package gave a slightly different estimate for Treatment B vs A
bakeoff_results <- data.frame(
    Package = c("netmeta", "gemtc", "multinma", "bnma", "nmaINLA"),
    Estimate = c(0.45, 0.52, 0.48, 0.65, 0.47), # log OR
    SE = c(0.05, 0.08, 0.06, 0.15, 0.055)
)

# 2. Assign Source Quality (based on the Bake-Off Audit)
# Say 'bnma' had more warnings, so we give it lower quality
package_quality <- c(0.9, 0.95, 0.95, 0.5, 0.85)

# 3. Apply SYNTHESIS Arbiter
# We use the core synthesis_meta logic on the package results
arbiter_res <- synthesis_arbiter(
    bakeoff_results$Estimate, 
    bakeoff_results$SE, 
    source_quality = package_quality
)

# 4. Results
cat("Bake-Off Summary:
")
print(bakeoff_results)

cat("
SYNTHESIS Arbitrated Consensus:
")
print(arbiter_res)

# Interpretation
cat("
Interpretation:
")
cat(sprintf("The final consensus estimate is %.4f.
", arbiter_res$estimate))
cat("SYNTHESIS identifies package outliers (like 'bnma' at 0.65) and downweights them
")
cat("based on their deviation from the density map and their assigned quality scores.
")


