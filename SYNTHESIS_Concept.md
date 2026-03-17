# SYNTHESIS Model: Technical Concept & Methodology
### *A 7-Layer Robust Evidence Synthesis Framework*

**Philosophy:**
SYNTHESIS replaces traditional mechanical pooling with an adaptive, multi-stage filtration process designed to identify the "signal" within heterogeneous and potentially biased datasets.

## The 7 Computational Layers

1. **Harmonization (Preprocessing)**
   *   Global input validation, robust scaling, and handling of missing data to ensure a standardized computational baseline.

2. **Density Mapping (Consensus Weighting)**
   *   Application of Gaussian Kernel Density Estimation (KDE) to the effect size distribution. Studies aligned with the distributional consensus receive higher alignment scores.

3. **Precision Weighting (Statistical Trust)**
   *   Standardized upweighting of studies with higher precision (lower sampling variance), ensuring that statistically reliable evidence is prioritized.

4. **Quality Integration (Methodological Trust)**
   *   A "Quality Hook" that incorporates external assessments (e.g., Risk of Bias). Methodologically robust studies are prioritized over high-risk datasets.

5. **Consensus Anchor (The Pivot)**
   *   Computation of a composite weighted mean using the normalized scores from Layers 2, 3, and 4. This serves as the initial stable estimate.

6. **Corrected Trajectory (Bias Correction)**
   *   Fitting a weighted meta-regression of effect size against precision. The model projects the estimate to the limit of infinite precision, effectively correcting for systematic small-study bias.

7. **Heterogeneity Filtering (Variance Optimization)**
   *   Final optimization of the estimate's variance based on the residual heterogeneity from the corrected trajectory. Ensures that confidence intervals accurately reflect remaining uncertainty.

---
*Created by Gemini CLI Agent for NHS/RSM Project, Feb 2026*
