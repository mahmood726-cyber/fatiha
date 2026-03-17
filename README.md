# SYNTHESIS: The Evidence Verification System

## Installation
Use the dependency files in this directory (for example `requirements.txt`, `environment.yml`, `DESCRIPTION`, or equivalent project-specific files) to create a clean local environment before running analyses.
Document any package-version mismatch encountered during first run.

**Version:** 0.1.0  
**License:** MIT  
**Build Status:** [![R-CMD-check](https://github.com/nhs-evidence/SYNTHESIS/actions/workflows/check.yaml/badge.svg)](https://github.com/nhs-evidence/SYNTHESIS/actions/workflows/check.yaml)

## Overview

**SYNTHESIS** is a cloud-native, adversarial-robust framework for meta-analysis. It replaces "pooling" with **"Purification"**, using a 7-layer bias correction model protected by a "Triple-Guard" ensemble.

> **Status:** Regulatory-Ready (Schema v1.0) with Fail-Safe logic active.

## Key Features

1.  **7-Layer Estimation**: Corrects for spatial density, precision, and small-study bias.
2.  **The Reliability Shield**: Calculates LOOCV stability and Optimism.
3.  **The Fail-Safe**: Automatically defaults to a robust anchor if the model diverges (>20%) or reliability drops (<20%).
4.  **Clinical Impact**: Translates statistics into **Number Needed to Treat (NNT)**.
5.  **Adversarial Defense**: Detects if users are manipulating Quality scores to force a result.

## Quick Start

### 1. The Shiny App (No Code)
Launch the interactive dashboard to upload CSVs and generate PDF reports.

```R
library(SYNTHESIS)
launch_synthesis_app()
```

### 2. The Forensic Audit (Code)

```R
# Load Data
yi <- c(0.2, 0.5, 0.1)
vi <- c(0.01, 0.02, 0.05)

# Run Audit
audit <- synthesis_audit(yi, vi)

# Print Report
print(audit)
# STATUS: GREEN | FAIL-SAFE: OFF
# Final Estimate: 0.2450
```

### 3. Docker (Cloud)

```bash
docker build -t synthesis .
docker run -p 8000:8000 synthesis
# API available at http://localhost:8000/audit
```

## Documentation

*   [Contribution Guidelines](CONTRIBUTING.md)
*   [Design Decisions (The Magic Numbers)](DESIGN_DECISIONS.md)
*   [Model Card](SYNTHESIS_MODEL_CARD.yaml)

## Citation

```R
citation("SYNTHESIS")
```
