# Contributing to SYNTHESIS

Thank you for your interest in improving the SYNTHESIS Evidence Verification System.

## Architectural Overview

The system is divided into two primary modules:

1.  **The Core Engine (`R/synthesis.R`)**:
    *   Implements the 7-Layer Bias Correction Model.
    *   Key Function: `synthesis_meta()`.
    *   *Philosophy*: "Find the Signal" (Aggressive purification).

2.  **The Safety System (`R/synthesis_audit.R`)**:
    *   Implements the Triple-Guard Ensemble and Reliability Shield.
    *   Key Function: `synthesis_audit()`.
    *   *Philosophy*: "Protect the Truth" (Conservative guard rails).

## Development Workflow

1.  **Fork and Clone** the repository.
2.  **Install Dependencies**: Run `renv::restore()` to get the exact environment.
3.  **Run Tests**: `devtools::test()`.
4.  **Check Diagnostics**: Run `demo/audit_check.R` to ensure the Fail-Safe still triggers on the fragile dataset.

## Key Rules

*   **Never disable the Fail-Safe**: The logic that defaults to the TGEP Anchor in high-risk scenarios is the system's primary safety feature.
*   **Maintain Semantic Output**: Any change to the audit object structure must be reflected in `synthesis_json()` to avoid breaking knowledge graph integrations.
