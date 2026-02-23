# plumber.R

#* Health Check
#* @get /health
function() {
  list(status = "OK", version = "0.1.0")
}

#* Run Synthesis Audit
#* @param yi:numeric Vector of effect sizes
#* @param vi:numeric Vector of variances
#* @post /audit
function(yi, vi) {
  # Convert inputs to numeric
  yi <- as.numeric(yi)
  vi <- as.numeric(vi)
  
  # Run Audit
  res <- SYNTHESIS::synthesis_audit(yi, vi, n_boot = 50)
  
  # Return JSON-ready list
  list(
    estimate = res$decision$final_estimate,
    ci = res$decision$final_ci,
    reliability = res$stability$reliability_score,
    status = res$decision$status,
    nnt = res$impact$nnt
  )
}
