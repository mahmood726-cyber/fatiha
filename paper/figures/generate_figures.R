#' Generate Publication Figures for SYNTHESIS Manuscript
#' Produces 4 figures as PNG files.

library(metafor)
source("C:/Models/FATIHA_Project/R/synthesis.R")
source("C:/Models/FATIHA_Project/R/synthesis_audit.R")

out_dir <- "C:/Models/FATIHA_Project/paper/figures"

# Load simulation results
sim_data <- read.csv("C:/Models/FATIHA_Project/data/simulation_results_extended.csv")

# ============================================================
# Figure 1: Pipeline Flow Diagram (text-based, for reference)
# ============================================================
# Note: For submission, create a vector-graphics version in Inkscape/TikZ.
# This script generates a placeholder text summary.
cat("Figure 1: Pipeline diagram should be created in a vector graphics tool.\n")
cat("Layers: 1-Harmonization -> 2-Density -> 3-Precision -> 4-Quality -> 5-Consensus -> 6-Bias Correction -> 7-Heterogeneity Filtering\n")
cat("Parallel: TGEP (GRMA + WRD + SWA) -> Bootstrap -> Anchor\n")
cat("Decision: |Core - Anchor| > threshold? -> Fail-safe override\n\n")

# ============================================================
# Figure 2: Simulation Results Panel (Bias + Coverage)
# ============================================================
png(file.path(out_dir, "Fig2_Simulation_Results.png"), width = 1200, height = 800, res = 150)
par(mfrow = c(2, 3), mar = c(5, 4, 3, 1), oma = c(0, 0, 2, 0))

scenarios <- c("A_Ideal", "B_HighHet", "C_PubBias", "D_SmallK", "E_Outlier", "F_QualBias")
scenario_labels <- c("A. Ideal", "B. High Het.", "C. Pub. Bias", "D. Stress", "E. Outlier", "F. Qual. Bias")
method_cols <- c(FE = "#E69F00", REML = "#D55E00", Egger = "#0072B2", SYNTHESIS = "#009E73")

# Top row: Bias
for (i in 1:3) {
  s <- scenarios[i]
  d <- sim_data[sim_data$Scenario == s, ]
  d <- d[order(match(d$Method, names(method_cols))), ]
  bp <- barplot(d$Bias, names.arg = d$Method, col = method_cols[d$Method],
                main = paste0(scenario_labels[i], " - Bias"), ylab = "Bias",
                ylim = range(c(-0.1, d$Bias * 1.3)), cex.names = 0.8)
  abline(h = 0, lty = 2, col = "grey40")
}

# Bottom row: Coverage
for (i in 1:3) {
  s <- scenarios[i]
  d <- sim_data[sim_data$Scenario == s, ]
  d <- d[order(match(d$Method, names(method_cols))), ]
  bp <- barplot(d$Coverage, names.arg = d$Method, col = method_cols[d$Method],
                main = paste0(scenario_labels[i], " - Coverage"), ylab = "Coverage",
                ylim = c(0, 1.05), cex.names = 0.8)
  abline(h = 0.95, lty = 2, col = "red", lwd = 2)
}

mtext("Figure 2: Simulation Results (B=1000)", outer = TRUE, cex = 1.0, font = 2)
dev.off()
cat("Fig2_Simulation_Results.png created\n")

# ============================================================
# Figure 3: Extended Simulation (Scenarios D-F)
# ============================================================
png(file.path(out_dir, "Fig3_Extended_Simulation.png"), width = 1200, height = 800, res = 150)
par(mfrow = c(2, 3), mar = c(5, 4, 3, 1), oma = c(0, 0, 2, 0))

for (i in 4:6) {
  s <- scenarios[i]
  d <- sim_data[sim_data$Scenario == s, ]
  d <- d[order(match(d$Method, names(method_cols))), ]
  bp <- barplot(d$Bias, names.arg = d$Method, col = method_cols[d$Method],
                main = paste0(scenario_labels[i], " - Bias"), ylab = "Bias",
                ylim = range(c(-0.1, d$Bias * 1.3)), cex.names = 0.8)
  abline(h = 0, lty = 2, col = "grey40")
}

for (i in 4:6) {
  s <- scenarios[i]
  d <- sim_data[sim_data$Scenario == s, ]
  d <- d[order(match(d$Method, names(method_cols))), ]
  bp <- barplot(d$Coverage, names.arg = d$Method, col = method_cols[d$Method],
                main = paste0(scenario_labels[i], " - Coverage"), ylab = "Coverage",
                ylim = c(0, 1.05), cex.names = 0.8)
  abline(h = 0.95, lty = 2, col = "red", lwd = 2)
}

mtext("Figure 3: Extended Scenarios (B=1000)", outer = TRUE, cex = 1.0, font = 2)
dev.off()
cat("Fig3_Extended_Simulation.png created\n")

# ============================================================
# Figure 4: Real-Data Forest Plot (SYNTHESIS vs REML)
# ============================================================
real_data <- read.csv("C:/Models/FATIHA_Project/data/real_data_comparison.csv")

png(file.path(out_dir, "Fig4_RealData_Comparison.png"), width = 1000, height = 600, res = 150)
par(mar = c(5, 12, 3, 2))

n <- nrow(real_data)
y_pos <- n:1
labels <- paste0(real_data$Review, " (A", real_data$Analysis, ", k=", real_data$k, ")")

plot(NA, xlim = range(c(real_data$REML_est - 1.96 * real_data$REML_se,
                          real_data$SYNTHESIS_est + 1.96 * real_data$SYNTHESIS_se), na.rm = TRUE),
     ylim = c(0.5, n + 0.5), yaxt = "n", ylab = "", xlab = "Effect Estimate (log-OR)",
     main = "SYNTHESIS vs REML: Real-Data Comparison")

axis(2, at = y_pos, labels = labels, las = 1, cex.axis = 0.65)
abline(v = 0, lty = 2, col = "grey60")

# REML points + CI
for (i in 1:n) {
  ci_lb <- real_data$REML_est[i] - 1.96 * real_data$REML_se[i]
  ci_ub <- real_data$REML_est[i] + 1.96 * real_data$REML_se[i]
  segments(ci_lb, y_pos[i] + 0.15, ci_ub, y_pos[i] + 0.15, col = "#D55E00", lwd = 2)
  points(real_data$REML_est[i], y_pos[i] + 0.15, pch = 15, col = "#D55E00", cex = 1.2)
}

# SYNTHESIS points + CI
for (i in 1:n) {
  ci_lb <- real_data$SYNTHESIS_est[i] - 1.96 * real_data$SYNTHESIS_se[i]
  ci_ub <- real_data$SYNTHESIS_est[i] + 1.96 * real_data$SYNTHESIS_se[i]
  segments(ci_lb, y_pos[i] - 0.15, ci_ub, y_pos[i] - 0.15, col = "#009E73", lwd = 2)
  points(real_data$SYNTHESIS_est[i], y_pos[i] - 0.15, pch = 17, col = "#009E73", cex = 1.2)
}

legend("bottomright", legend = c("REML", "SYNTHESIS"), col = c("#D55E00", "#009E73"),
       pch = c(15, 17), lwd = 2, cex = 0.8, bg = "white")

dev.off()
cat("Fig4_RealData_Comparison.png created\n")

# ============================================================
# Figure 5: Diagnostic Plot Example (CD000028)
# ============================================================
data_file <- "C:/Users/user/OneDrive - NHS/Documents/Pairwise70/data/CD000028_pub4_data.rda"
if (file.exists(data_file)) {
  env <- new.env()
  load(data_file, envir = env)
  df <- get(ls(env)[1], envir = env)
  ma_data <- df[df$Analysis.number == 1, ]
  dat <- escalc(measure = "OR",
                ai = ma_data$Experimental.cases, n1i = ma_data$Experimental.N,
                ci = ma_data$Control.cases, n2i = ma_data$Control.N,
                data = ma_data)
  dat <- dat[!is.na(dat$yi) & !is.na(dat$vi) & is.finite(dat$yi) & is.finite(dat$vi), ]
  yi <- as.numeric(dat$yi)
  vi <- as.numeric(dat$vi)

  core <- synthesis_meta(yi, vi)
  aud <- synthesis_audit(yi, vi, n_boot = 500)

  png(file.path(out_dir, "Fig5_Diagnostic_Example.png"), width = 1000, height = 800, res = 150)
  plot(core, audit = aud)
  dev.off()
  cat("Fig5_Diagnostic_Example.png created\n")
} else {
  cat("Skipping Fig5 - data file not found\n")
}

cat("\n=== All figures generated ===\n")
