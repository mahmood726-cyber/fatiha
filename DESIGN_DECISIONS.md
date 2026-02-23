# SYNTHESIS Design Decisions

This document records the rationale behind the "Magic Numbers" and architectural choices in the system.

## 1. The Humility Factor ($k / 15$)
*   **Location**: `synthesis_meta()` (Layer 6)
*   **Rationale**: Meta-regression on fewer than 10-15 studies is statistically underpowered. We chose 15 as the denominator to aggressively penalize small-sample confidence. If $k=3$, confidence is capped at 20% max. This prevents the "Trajectory" from becoming overconfident in sparse data.

## 2. The Divergence Threshold ($0.2 	imes |Anchor|$)
*   **Location**: `synthesis_audit()`
*   **Rationale**: If the refined estimate differs from the robust anchor by more than 20%, it suggests the refinement is finding "noise" rather than "signal." We chose 20% as a standard bioequivalence margin.

## 3. The Triple-Guard Ensemble
*   **Components**: GRMA (Density), WRD (Outlier Capping), SWA (Variance Weighting).
*   **Rationale**: We use *three* guards because no single robust method is perfect.
    *   **GRMA** handles multimodal data well.
    *   **WRD** handles massive outliers (10x sigma).
    *   **SWA** handles high-variance clusters.
    *   The average of these three provides a "Center of Gravity" that is extremely hard to destabilize.

## 4. Adaptive Bootstrap (50 -> 1000)
*   **Location**: `synthesis_audit()`
*   **Rationale**: Running 1000 bootstraps on 1.5 million datasets is too expensive. We check stability at $n=50$. If the Standard Error of the mean is $< 0.1$, we assume convergence and stop. This saves ~90% of compute time in stable datasets.
