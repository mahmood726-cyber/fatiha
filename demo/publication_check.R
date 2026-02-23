#' VALIDATION: Publication Interface (Report & Master Plot)
library(metafor)
source("C:/Models/FATIHA_Project/R/synthesis.R")
source("C:/Models/FATIHA_Project/R/synthesis_audit.R")

# 1. Pilot Data (Fragile Scenario)
set.seed(99)
k <- 15
yi <- rnorm(k, 0.3, 0.1)
vi <- runif(k, 0.01, 0.05)
yi[1] <- 1.5; vi[1] <- 0.005 # Outlier

# 2. Run Audit
audit <- synthesis_audit(yi, vi)

# 3. Generate Publication Report
report_path <- "C:/Models/FATIHA_Project/demo/Validation_Report.md"
synthesis_report(audit, file = report_path)

# 4. Generate Master Visual (The "Figure 1")
png("C:/Models/FATIHA_Project/demo/Figure1_Visual_Convergence.png", width=1000, height=800)
# Pass the audit object to plot() to trigger the enhanced overlay mode
plot(audit$core, audit = audit)
dev.off()

cat("
Publication validation complete.
")
cat("Report: ", report_path, "
")
cat("Figure 1: C:/Models/FATIHA_Project/demo/Figure1_Visual_Convergence.png
")


