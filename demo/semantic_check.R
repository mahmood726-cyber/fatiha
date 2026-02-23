#' VALIDATION: Semantic Web & Privacy Features
library(metafor)
source("C:/Models/FATIHA_Project/R/synthesis.R")
source("C:/Models/FATIHA_Project/R/synthesis_audit.R")

cat("=== SYNTHESIS SEMANTIC & PRIVACY CHECK ===
")

# 1. Pilot Data
set.seed(42)
k <- 10
yi <- rnorm(k, 0.5, 0.2)
vi <- runif(k, 0.01, 0.05)

# 2. Run Privacy Mode Audit
cat("
--- Running Privacy Mode ---
")
audit_priv <- synthesis_audit(yi, vi, private = TRUE)

if (is.null(audit_priv$core)) {
    cat("PASS: Core data redacted in private mode.
")
} else {
    cat("FAIL: Core data leaked.
")
}

if (audit_priv$narrative$top_leverage == "REDACTED") {
    cat("PASS: Leverage IDs redacted.
")
}

# 3. LLM Prompt Output
cat("
--- LLM Prompt Output ---
")
print_llm_summary(audit_priv)

# 4. JSON-LD Export
cat("
--- JSON-LD Linked Data Export ---
")
json_out <- synthesis_json(audit_priv)

cat("
Validation Complete.
")
