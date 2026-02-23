# SYNTHESIS: A 7-Layer Verification Framework for Detecting Fragile Meta-Analyses

**Mahmood Ul Hassan**

Independent Researcher

Corresponding author: mahmood.hassan@example.com

---

## Abstract

**Background:** Meta-analyses are the cornerstone of evidence-based medicine, yet many pooled estimates are fragile — sensitive to the inclusion of small, biased, or low-quality studies. Standard random-effects models (e.g., DerSimonian-Laird, REML) assume that all studies contribute truthfully to the pooled estimate, but cannot detect when a consensus is driven by publication bias, outlier contamination, or quality-correlated distortion. We introduce SYNTHESIS (Structured Yield-Neutral Trust-weighted Heterogeneity-Integrated Statistical Inference System), an open-source R package implementing a 7-layer verification framework with a Triple-Guard Ensemble Protocol (TGEP) that flags and, when necessary, overrides fragile meta-analytic estimates.

**Methods:** SYNTHESIS processes effect sizes through 7 sequential layers: (1) data harmonization, (2) spatial density weighting, (3) precision weighting, (4) quality integration, (5) consensus anchoring, (6) adaptive bias correction via PET-style weighted regression, and (7) uncertainty quantification. A TGEP independently estimates the pooled effect using three robust algorithms (GRMA, WRD, SWA), with bootstrap confidence intervals. When the 7-layer estimate diverges from the TGEP anchor beyond a threshold, a fail-safe mechanism substitutes the robust TGEP estimate. We evaluated SYNTHESIS in a simulation study (6 scenarios, 1000 replications each) and a real-data benchmark against 426 Cochrane reviews from the Pairwise70 repository.

**Results:** In simulations, SYNTHESIS achieved 95.2% coverage under publication bias (CI width: 0.55) vs. 0% for REML (CI width: 0.30) and 0.9% for FE (CI width: 0.12), with bias of 0.051 vs. 0.463 for REML. Under ideal conditions, SYNTHESIS was conservative (coverage 98.1%, CI width 0.47 vs. 0.18 for REML). In the Pairwise70 benchmark (426 Cochrane reviews), SYNTHESIS CIs included the REML point estimate in 91.1% of analyses (partially reflecting SYNTHESIS's wider CIs), with 76.1% significance agreement. The median absolute difference was 0.23 log-OR units.

**Conclusions:** SYNTHESIS provides a transparent, multi-layered verification system for meta-analyses. It is not designed to replace REML as a primary estimator, but to serve as a complementary verification layer that detects fragile results, activates fail-safe mechanisms, and produces auditable transparency tables. The R package is freely available under the MIT license.

**Keywords:** meta-analysis, verification, publication bias, robust estimation, evidence synthesis, fail-safe, Triple-Guard ensemble

---

## 1. Introduction

Meta-analysis is the gold standard for synthesizing quantitative evidence across studies [1]. The pooled estimate from a well-conducted meta-analysis informs clinical guidelines, drug approvals, and health policy decisions. However, the validity of pooled estimates depends critically on the assumption that included studies represent an unbiased sample of the evidence base — an assumption frequently violated in practice [2,3].

Publication bias, where studies with statistically significant or favorable results are more likely to be published, is estimated to affect 50-90% of meta-analyses across medical fields [4]. Small-study effects, where smaller studies report larger effect sizes, further distort pooled estimates [5]. Standard random-effects models such as DerSimonian-Laird [6] and REML [7] account for between-study heterogeneity but provide no built-in mechanism to detect or correct for these biases. While post-hoc methods such as funnel plots [8], Egger's regression [9], and trim-and-fill [10] can flag publication bias, they are typically applied after estimation rather than integrated into the estimation process itself.

A second, underappreciated source of fragility is the sensitivity of pooled estimates to individual studies. An influential outlier — whether due to methodological differences, different patient populations, or reporting errors — can shift the pooled estimate substantially while standard diagnostics appear normal [11]. Leave-one-out sensitivity analyses can detect such leverage, but are rarely reported systematically [12].

We propose SYNTHESIS, a framework that addresses these limitations by embedding verification directly into the estimation pipeline. Rather than applying bias detection and sensitivity analysis as post-hoc checks, SYNTHESIS treats them as integral layers of the estimation process, producing a final estimate with an accompanying "audit trail" documenting each layer's contribution. When the multi-layer estimate is found to be fragile (diverging from independent robust estimates), a fail-safe mechanism automatically substitutes a more conservative estimate.

The key contributions of SYNTHESIS are:

1. **Multi-layer transparency**: Each of 7 layers contributes traceable, quantifiable adjustments to the estimate.
2. **Triple-Guard Ensemble Protocol (TGEP)**: Three independent robust estimators serve as verification anchors.
3. **Fail-safe logic**: Automatic fallback when the primary estimate diverges from robust guards.
4. **Adversarial defense**: Detection of quality-score manipulation (when quality scores correlate with effect sizes).
5. **Clinical translation**: Integrated Number Needed to Treat (NNT) computation in the audit output.

SYNTHESIS is implemented as an open-source R package available under the MIT license.

## 2. Methods

### 2.1 The SYNTHESIS Framework

SYNTHESIS processes a set of k effect sizes (yi) and their sampling variances (vi), with optional study-level quality scores, through 7 sequential layers. We describe each layer below.

**Layer 1: Data Harmonization.** Missing values are removed with explicit reporting. Variances are floored at 1e-8 to prevent division-by-zero. When fewer than 3 studies remain after cleaning (k < 3), the system returns a median-based fallback estimate with an explicit error code (E001_INSUFFICIENT_K).

**Layer 2: Spatial Density Weighting.** A Gaussian kernel density estimate is computed over the effect sizes. Each study's density score is the normalized density at its observed effect size, mapping each yi to the interval [0, 1]. Studies in high-density regions (near the consensus) receive higher density weights, while isolated outliers receive lower weights. This is analogous to a soft trimming approach.

**Layer 3: Precision Weighting.** Standard inverse-variance weights (1/vi) are normalized to [0.1, 1.0]. The floor of 0.1 ensures that even the least precise study retains some influence, preventing complete exclusion.

**Layer 4: Quality Integration.** If user-supplied quality scores are provided (e.g., from Risk of Bias assessments), they are incorporated as a third weighting dimension. When no scores are supplied, all studies receive uniform quality weight.

**Composite Weighting.** The three scoring dimensions (density, precision, quality) are averaged to produce the final study-level weight:

w_i = (density_i + precision_i + quality_i) / 3

These weights are then normalized to sum to 1.

**Layer 5: Consensus Anchor.** The weighted mean of the effect sizes serves as the consensus estimate:

theta_consensus = sum(w_i * yi)

**Layer 6: Adaptive Bias Correction.** A PET-style (Precision Effect Test) weighted regression of yi on sqrt(vi) is fitted, using the composite weights from Layers 2-4 rather than standard inverse-variance weights. The intercept of this regression represents the bias-corrected estimate — the predicted effect at zero standard error. A gate factor modulates the correction: if the consensus estimate is not statistically significant (p > 0.05), the correction is halved to prevent overcorrection in ambiguous cases. A guardrail caps the correction magnitude at twice the observed data range to prevent extrapolation artifacts. We note that this regression model is matched to the specific form of small-study bias where yi is linearly related to sqrt(vi); other bias mechanisms (e.g., p-hacking, selection models) may not be captured.

**Layer 7: Uncertainty Quantification.** The standard error of the corrected estimate is derived from the regression intercept SE when available, or from the composite-weighted variance otherwise. We note that this SE does not formally account for the estimation uncertainty in the composite weights themselves (which are data-dependent). Confidence intervals and p-values are computed using normal-theory quantiles based on the user-specified alpha level. A minimum SE floor of 1e-8 prevents degenerate zero-width intervals.

### 2.2 Triple-Guard Ensemble Protocol (TGEP)

The TGEP provides an independent verification layer using three robust estimators that make different distributional assumptions:

1. **GRMA (Grey Relational Meta-Analysis):** Combines density-based and precision-based weights additively, without the quality or trajectory correction layers.
2. **WRD (Winsorized Robust Differencing):** Computes a robust center (median) and Winsorizes standardized residuals at +/-2.5 MAD units before applying inverse-variance weighting. This provides outlier resistance.
3. **SWA (Shrinkage-Weighted Average):** Adds the between-study variance (var(yi)) to each study's sampling variance as a simple random-effects shrinkage, then applies inverse-variance weighting.

The TGEP anchor is the mean of a bootstrap distribution (default B=1000) where, in each iteration, a bootstrap sample of studies is drawn and all three guards are computed, with the iteration-level anchor being their mean. Bootstrap percentile confidence intervals are derived from this distribution.

### 2.3 Fail-Safe Logic

The SYNTHESIS audit function computes the divergence between the 7-layer corrected estimate and the TGEP anchor. A traffic-light system classifies the result:

- **GREEN**: Divergence below threshold and reliability score above 50%.
- **AMBER**: Moderate divergence or quality-bias detection, but within acceptable limits.
- **RED**: Large divergence (>20% of the TGEP anchor magnitude) or reliability score below 20%. The fail-safe is activated and the TGEP bootstrap estimate replaces the 7-layer estimate.

The reliability score is derived from leave-one-out cross-validation (LOOCV), measuring the stability of the estimate when each study is sequentially removed.

### 2.4 Quality Bias Detection

When quality scores are provided, SYNTHESIS computes the Pearson correlation between quality scores and effect sizes. A correlation exceeding |r| > 0.6 triggers an adversarial warning flag, indicating that the quality scores may be systematically biased (e.g., higher quality assigned to studies with larger effects).

### 2.5 Simulation Study Design

We evaluated SYNTHESIS against three comparators — Fixed-Effect (FE), REML, and Egger's regression intercept — across 6 scenarios (Table 1), each with B=1000 replications. All scenarios used a true effect of 0.5 on the log-OR scale:

**Table 1. Simulation scenarios.**

| Scenario | k | tau2 | Bias factor | Special conditions |
|:---------|--:|-----:|------------:|:-------------------|
| A. Ideal | 30 | 0.02 | 0 | None |
| B. High heterogeneity | 30 | 0.20 | 0 | None |
| C. Publication bias | 30 | 0.05 | 2.0 | Small-study shift: yi += bias * sei |
| D. Stress test | 10 | 0.10 | 1.5 | Small k + bias |
| E. Outlier contamination | 10 | 0.05 | 0 | 2 studies shifted by +3 |
| F. Quality-correlated bias | 20 | 0.05 | 1.0 | Quality = normalized yi |

Performance metrics were: Bias (mean estimate minus truth), RMSE (root mean squared error), Coverage (proportion of 95% CIs containing the true value), and CI Width (mean width of 95% CI).

### 2.6 Real-Data Benchmark

We applied SYNTHESIS to 426 binary-outcome analyses from the Pairwise70 repository, a curated collection of 501 Cochrane systematic reviews [13]. For each review, the first binary-outcome analysis was extracted, odds ratios were computed using the Mantel-Haenszel method via metafor::escalc(), and both SYNTHESIS and metafor::rma(method="REML") were applied. We report the absolute difference in point estimates, whether the SYNTHESIS CI covered the REML estimate, and significance agreement (whether both methods agreed on statistical significance at alpha=0.05).

Additionally, we performed a detailed validation on 5 well-known reviews: CD000028 (BCG vaccine for tuberculosis), CD002042 (aspirin for preeclampsia), CD001431 (antibiotics for acute otitis media), CD001533 (tocolytics for preterm labour), and CD000219 (antifibrinolytics).

### 2.7 Software

SYNTHESIS is implemented in R (>=4.0) and depends on metafor for comparison analyses, stats for density estimation and regression, and graphics for visualization. The package includes: synthesis_meta() (core estimator), synthesis_audit() (full audit with TGEP), synthesis_stability() (LOOCV), synthesis_arbiter() (multi-source reconciliation), synthesis_table() (transparency table), and a Shiny application for interactive use. All code is available under the MIT license.

## 3. Results

### 3.1 Simulation Results

Table 2 presents the simulation results across all 6 scenarios.

**Table 2. Simulation results (B=1000, true effect = 0.5).**

| Scenario | Method | Bias | RMSE | Coverage | CI Width |
|:---------|:-------|-----:|-----:|---------:|---------:|
| A. Ideal | FE | -0.002 | 0.056 | 0.719 | 0.118 |
| | REML | 0.000 | 0.049 | 0.927 | 0.183 |
| | Egger | -0.005 | 0.106 | 0.784 | 0.273 |
| | SYNTHESIS | -0.003 | 0.094 | 0.981 | 0.465 |
| B. High het. | FE | 0.003 | 0.154 | 0.293 | 0.116 |
| | REML | 0.002 | 0.099 | 0.932 | 0.370 |
| | Egger | 0.002 | 0.290 | 0.684 | 0.566 |
| | SYNTHESIS | -0.003 | 0.194 | 0.943 | 0.769 |
| C. Pub. bias | FE | 0.271 | 0.288 | 0.009 | 0.118 |
| | REML | 0.463 | 0.470 | 0.000 | 0.296 |
| | Egger | -0.003 | 0.156 | 0.714 | 0.342 |
| | SYNTHESIS | 0.051 | 0.132 | 0.952 | 0.553 |
| D. Stress | FE | 0.231 | 0.296 | 0.200 | 0.222 |
| | REML | 0.361 | 0.388 | 0.254 | 0.535 |
| | Egger | 0.002 | 0.363 | 0.706 | 0.821 |
| | SYNTHESIS | 0.044 | 0.300 | 0.915 | 1.134 |
| E. Outlier | FE | 0.624 | 0.840 | 0.128 | 0.220 |
| | REML | 0.602 | 0.614 | 0.936 | 1.633 |
| | Egger | 0.653 | 1.470 | 0.786 | 2.825 |
| | SYNTHESIS | 0.489 | 0.995 | 0.905 | 3.394 |
| F. Qual. bias | FE | 0.140 | 0.173 | 0.205 | 0.148 |
| | REML | 0.221 | 0.236 | 0.189 | 0.302 |
| | Egger | -0.003 | 0.191 | 0.715 | 0.427 |
| | SYNTHESIS | 0.037 | 0.153 | 0.940 | 0.624 |

Under ideal conditions (Scenario A), SYNTHESIS maintained excellent coverage (98.1%) with negligible bias (-0.003). However, its RMSE (0.094) was approximately twice that of REML (0.049), reflecting the wider CIs inherent in a multi-layered estimation approach.

Under publication bias (Scenario C), the advantage of SYNTHESIS was most pronounced: bias was reduced from 0.463 (REML) to 0.051, and coverage improved from 0% (REML) and 0.9% (FE) to 95.2%. Egger's regression intercept also performed well for bias correction (bias = -0.003) but achieved only 71.4% coverage.

In the outlier contamination scenario (E), all methods showed substantial bias. REML achieved 93.6% coverage through very wide CIs (1.63), while SYNTHESIS achieved 90.5% coverage with even wider CIs (3.39). This scenario represents a genuine challenge for all methods.

### 3.2 Real-Data Benchmark

Across 426 Cochrane review analyses (67 skipped for insufficient data, 8 errors), the benchmark showed:

- **Median absolute difference** between SYNTHESIS and REML: 0.225 log-OR units
- **SYNTHESIS CI includes REML estimate**: 388/426 (91.1%) — note this is a compatibility metric, not a coverage metric (truth is unknown), and is partially inflated by SYNTHESIS's wider CIs
- **Significance agreement**: 324/426 (76.1%) — in the disagreement cases, the majority were SYNTHESIS-non-significant but REML-significant (SYNTHESIS more conservative), reflecting wider CIs
- **Median CI width**: REML = 1.07, SYNTHESIS = 2.07
- **Maximum absolute difference**: 8.36 (after applying the Layer 6 correction guardrail)

Performance varied by study count: significance agreement was highest for k > 50 (79.7%) and lowest for k = 6-10 (74.5%).

Performance varied by study count: for analyses with k > 50 (n=69), significance agreement was 78.3%, while for k <= 5 (n=76), it dropped to 67.1%.

### 3.3 Detailed Validation

Table 3 presents the detailed comparison for 5 well-known Cochrane reviews.

**Table 3. Detailed real-data validation (first analysis per review).**

| Review | k | REML est. | SYNTHESIS est. | Audit est. | Status | Reliability |
|:-------|--:|----------:|---------------:|-----------:|:-------|------------:|
| CD000028 (BCG) | 36 | -0.125 | -0.116 | -0.116 | GREEN | 99.9% |
| CD002042 (Aspirin) | 57 | -2.467 | -1.441 | -2.023 | RED | 100.0% |
| CD001431 (Antibiotics) | 437 | 0.088 | 0.088 | 0.072 | RED | 100.0% |
| CD001533 (Tocolytics) | 43 | -0.498 | -0.429 | -0.429 | GREEN | 100.0% |
| CD000219 (Antifibrinolytics) | 27 | -0.392 | -0.183 | -0.373 | RED | 99.2% |

The fail-safe mechanism activated (RED status) in 3 of 5 reviews, replacing the 7-layer estimate with the TGEP anchor. Notably, in CD002042 (aspirin for preeclampsia, k=57), the REML estimate was -2.47 while the SYNTHESIS core estimate was -1.44 — the fail-safe correctly identified this divergence and substituted the TGEP estimate (-2.02), which was closer to the REML estimate.

### 3.4 Fail-Safe Activation Analysis

In the Pairwise70 benchmark, the TGEP fail-safe was designed to activate when the 7-layer estimate diverged substantially from the TGEP anchor. The fail-safe serves as a safety net rather than a primary correction — its activation indicates that the meta-analysis may be fragile and warrants manual review.

## 4. Discussion

### 4.1 Summary of Findings

SYNTHESIS demonstrates that embedding verification directly into the meta-analysis pipeline can detect and correct for fragile estimates, particularly under publication bias and quality-correlated distortion. The key trade-off is between bias correction and precision: SYNTHESIS produces wider confidence intervals than REML, reflecting its more conservative approach.

### 4.2 Comparison with Existing Methods

Several existing methods address similar concerns. Trim-and-fill [10] adjusts for publication bias by imputing missing studies, but assumes a specific funnel plot asymmetry pattern. PET-PEESE [14] uses meta-regression to estimate the bias-corrected intercept, similar to SYNTHESIS's Layer 6. Selection models [15] explicitly model the publication process but require strong distributional assumptions. SYNTHESIS's contribution is not a single novel estimator but the integration of multiple verification layers into a unified framework with fail-safe logic.

The Egger regression intercept performed well for bias correction in simulations (Table 2), consistent with the PET-PEESE literature. However, its coverage was substantially below nominal in most scenarios (68-79%), while SYNTHESIS maintained >90% coverage across all scenarios except outlier contamination. This difference arises because SYNTHESIS's TGEP bootstrap provides more honest uncertainty quantification.

### 4.3 Limitations

1. **Wider CIs**: SYNTHESIS CIs are approximately twice as wide as REML under ideal conditions (0.47 vs. 0.18). This conservatism maintains coverage but reduces statistical power. Coverage claims must always be interpreted alongside CI width.
2. **Density weighting circularity**: Layer 2 up-weights studies near the mode of the effect size distribution, implicitly assuming the majority of studies are correct. Under uniform publication bias (where all studies are shifted), the density peak is at the biased location. SYNTHESIS's bias correction in Layer 6, not the density weighting, is primarily responsible for coverage gains under publication bias.
3. **Linear bias model**: Layer 6 assumes a linear relationship between sqrt(vi) and yi (PET-style regression). Our simulation scenarios use this same functional form for bias generation, creating a best-case match. Non-linear bias mechanisms (p-hacking, selection models) are not modeled. Future comparisons should include proper publication bias methods (trim-and-fill, PET-PEESE, selection models).
4. **Regression extrapolation instability**: In 7.5% of Pairwise70 analyses, the Layer 6 regression produced estimates with |diff| > 5 from REML, caused by steep regression slopes extrapolated to sqrt(vi)=0. A correction guardrail helps but does not eliminate this issue.
5. **No tau-squared estimation**: SYNTHESIS does not formally estimate or report between-study heterogeneity (tau-squared). The composite-weight SE does not incorporate a between-study variance component, and the weight estimation uncertainty is not reflected in the CIs.
6. **Quality score subjectivity**: Layer 4 relies on user-supplied quality scores, which may themselves be biased. The adversarial detection (|r| > 0.6) provides a partial safeguard but cannot detect all forms of quality-score manipulation.
7. **Composite weighting justification**: The additive formula (density + precision + quality)/3 has no formal optimality property (unlike inverse-variance weights which minimize pooled variance). The current formulation is a heuristic that could be improved by treating density and quality as modifiers of inverse-variance weights.
8. **Not a replacement for REML**: SYNTHESIS should be used as a complementary verification tool, not as a replacement for established random-effects estimators.

### 4.4 Use Cases

SYNTHESIS is most valuable in three scenarios:

1. **Pre-guideline verification**: Before a meta-analytic result is incorporated into clinical guidelines, running synthesis_audit() can flag fragile results that warrant additional scrutiny.
2. **Sensitivity analysis**: The transparency table (synthesis_table()) provides a study-level decomposition of each layer's contribution, enabling reviewers to identify which studies drive the result.
3. **Automated screening**: In large-scale evidence mapping or living systematic reviews, SYNTHESIS can serve as an automated triage tool, flagging reviews where the fail-safe activates.

### 4.5 Future Directions

Future development will focus on: (a) extending SYNTHESIS to network meta-analysis, where multi-arm trials introduce additional complexity; (b) implementing a Bayesian variant with prior specification for the fail-safe threshold; and (c) developing a machine-learning-based quality scoring layer that learns from Risk of Bias assessments.

## 5. Conclusions

SYNTHESIS provides a transparent, multi-layered verification framework for meta-analyses. While not intended to replace REML or other established methods, it serves as a complementary audit tool that detects fragile estimates, activates fail-safe mechanisms when divergence is detected, and produces traceable transparency tables. The simulation study demonstrates substantial advantages under publication bias and quality-correlated distortion, with honest (if conservative) coverage across all tested scenarios. The R package is freely available under the MIT license.

## References

1. Higgins JPT, Thomas J, Chandler J, et al. Cochrane Handbook for Systematic Reviews of Interventions. Version 6.4. Cochrane, 2023.
2. Ioannidis JPA. Why most published research findings are false. PLoS Med. 2005;2(8):e124.
3. Page MJ, Sterne JAC, Higgins JPT, Egger M. Investigating and dealing with publication bias and other reporting biases in meta-analyses of health research: A review. Res Synth Methods. 2021;12(2):248-259.
4. Song F, Parekh S, Hooper L, et al. Dissemination and publication of research findings: an updated review of related biases. Health Technol Assess. 2010;14(8):1-193.
5. Sterne JAC, Gavaghan D, Egger M. Publication and related bias in meta-analysis: power of statistical tests and prevalence in the literature. J Clin Epidemiol. 2000;53(11):1119-1129.
6. DerSimonian R, Laird N. Meta-analysis in clinical trials. Control Clin Trials. 1986;7(3):177-188.
7. Viechtbauer W. Bias and efficiency of meta-analytic variance estimators in the random-effects model. J Educ Behav Stat. 2005;30(3):261-293.
8. Egger M, Davey Smith G, Schneider M, Minder C. Bias in meta-analysis detected by a simple, graphical test. BMJ. 1997;315(7109):629-634.
10. Duval S, Tweedie R. Trim and fill: a simple funnel-plot-based method of testing and adjusting for publication bias in meta-analysis. Biometrics. 2000;56(2):455-463.
11. Viechtbauer W, Cheung MW-L. Outlier and influence diagnostics for meta-analysis. Res Synth Methods. 2010;1(2):112-125.
12. Patil P, Peng RD, Leek JT. What should researchers expect when they replicate studies? A statistical view of replicability in psychological science. Perspect Psychol Sci. 2016;11(4):539-544.
13. Cochrane Library. Cochrane Database of Systematic Reviews. Available from: https://www.cochranelibrary.com. [The Pairwise70 repository contains extracted data from 501 Cochrane reviews used for benchmarking.]
14. Stanley TD, Doucouliagos H. Meta-regression approximations to reduce publication selection bias. Res Synth Methods. 2014;5(1):60-78.
15. Copas J. What works?: selectivity models and meta-analysis. J R Stat Soc Ser A. 1999;162(1):95-109.

---

## Supporting Information

**S1 Table.** Full simulation parameters and extended results across all 6 scenarios (1000 replications).

**S2 Table.** Pairwise70 benchmark: complete comparison for all 426 analyses, including per-review SYNTHESIS vs REML estimates, CI coverage, and significance agreement.

**S3 Table.** Transparency table example: study-level decomposition for CD000028 (BCG vaccine), showing density scores, precision scores, composite weights, and weighted contributions.

**S4 Fig.** Diagnostic plots for the 5 detailed validation reviews (4-panel each).

---

## Author Contributions

**Conceptualization:** MUH. **Methodology:** MUH. **Software:** MUH. **Validation:** MUH. **Formal Analysis:** MUH. **Writing - Original Draft:** MUH. **Writing - Review & Editing:** MUH.

## Funding

This research received no specific grant from any funding agency in the public, commercial, or not-for-profit sectors.

## Competing Interests

The author declares no competing interests.

## Data Availability

All code and data are available in the SYNTHESIS R package repository. The Pairwise70 data used for benchmarking are from publicly available Cochrane reviews. Simulation code is included in the package (demo/simulation_study.R).
