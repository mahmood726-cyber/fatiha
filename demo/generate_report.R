#' Comprehensive Performance Report: SYNTHESIS vs Standard Meta-Analysis
#' Generates high-quality base R plots for Bias, MSE, and Coverage.

library(metafor)
source("C:/Models/FATIHA_Project/R/synthesis.R")

# --- Simulation Engine ---
run_full_sim <- function(k, tau2, bias, scenario_name, n_sim = 200) {
  results <- list()
  for (i in 1:n_sim) {
    sei <- runif(k, 0.05, 0.5); vi <- sei^2
    theta_i <- rnorm(k, 0.5, sqrt(tau2))
    yi <- rnorm(k, theta_i, sei)
    if (bias > 0) yi <- yi + bias * sei
    
    # FE
    f <- tryCatch(rma(yi, vi, method="FE"), error=function(e) NULL)
    if(!is.null(f)) results[[length(results)+1]] <- data.frame(Method="FE", Est=as.numeric(f$beta), L=f$ci.lb, U=f$ci.ub)
    # REML
    r <- tryCatch(rma(yi, vi, method="REML"), error=function(e) NULL)
    if(!is.null(r)) results[[length(results)+1]] <- data.frame(Method="REML", Est=as.numeric(r$beta), L=r$ci.lb, U=r$ci.ub)
    # Egger
    e_fit <- tryCatch(lm(yi ~ sei, weights = 1/vi), error=function(e) NULL)
    if(!is.null(e_fit)) {
        e_est <- coef(e_fit)[1]; e_se <- summary(e_fit)$coefficients[1,2]
        results[[length(results)+1]] <- data.frame(Method="Egger", Est=as.numeric(e_est), L=e_est-qnorm(0.975)*e_se, U=e_est+qnorm(0.975)*e_se)
    }
    # SYNTHESIS
    fa <- tryCatch(synthesis_meta(yi, vi), error=function(e) NULL)
    if(!is.null(fa)) results[[length(results)+1]] <- data.frame(Method="SYNTHESIS", Est=fa$estimate, L=fa$ci_lb, U=fa$ci_ub)
  }
  
  df <- do.call(rbind, results)
  perf <- do.call(rbind, lapply(split(df, df$Method), function(x) {
    data.frame(
        Scenario = scenario_name,
        Method = x$Method[1],
        Bias = mean(x$Est) - 0.5,
        MSE = mean((x$Est - 0.5)^2),
        Coverage = mean(x$L <= 0.5 & x$U >= 0.5)
    )
  }))
  return(perf)
}

# --- Run Scenarios ---
cat("Running full simulation suite (Base R mode)...\n")
s1 <- run_full_sim(30, 0.02, 0, "Ideal")
s2 <- run_full_sim(30, 0.1, 2, "Pub Bias")
s3 <- run_full_sim(12, 0.1, 1.5, "Small k")
all_results <- rbind(s1, s2, s3)

# --- Visualization ---
png("C:/Models/FATIHA_Project/Performance_Summary.png", width=1000, height=800)
par(mfrow=c(2,2), mar=c(5,5,4,2))

# 1. Bias Plot (Scenario: Pub Bias)
dat_bias <- all_results[all_results$Scenario == "Pub Bias", ]
bp <- barplot(dat_bias$Bias, names.arg=dat_bias$Method, col=c("gold", "darkred", "darkblue", "darkgreen"),
        main="Bias in Presence of Publication Bias", ylab="Estimate Deviation from Truth (0.5)")
abline(h=0, lty=2)

# 2. Coverage Plot (Scenario: Pub Bias)
dat_cov <- all_results[all_results$Scenario == "Pub Bias", ]
barplot(dat_cov$Coverage, names.arg=dat_cov$Method, col=c("gold", "darkred", "darkblue", "darkgreen"),
        main="CI Coverage (Target: 0.95)", ylab="Coverage Probability", ylim=c(0, 1))
abline(h=0.95, col="red", lwd=2, lty=2)

# 3. MSE (Small k)
dat_mse <- all_results[all_results$Scenario == "Small k", ]
barplot(dat_mse$MSE, names.arg=dat_mse$Method, col=c("gold", "darkred", "darkblue", "darkgreen"),
        main="MSE in Small Samples (k=12)", ylab="Mean Squared Error (Lower is better)")

# 4. Bias (Ideal)
dat_ideal <- all_results[all_results$Scenario == "Ideal", ]
barplot(dat_ideal$Bias, names.arg=dat_ideal$Method, col=c("gold", "darkred", "darkblue", "darkgreen"),
        main="Bias in Ideal Conditions", ylab="Bias")

dev.off()

write.csv(all_results, "C:/Models/FATIHA_Project/simulation_results.csv", row.names=FALSE)
cat("Performance_Summary.png created successfully.\n")




