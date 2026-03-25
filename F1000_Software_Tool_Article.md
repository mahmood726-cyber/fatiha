# SYNTHESIS: a software tool for reviewer-auditable evidence synthesis

## Authors
- Mahmood Ahmad [1,2]
- Niraj Kumar [1]
- Bilaal Dar [3]
- Laiba Khan [1]
- Andrew Woo [4]
- Corresponding author: Andrew Woo (andy2709w@gmail.com)

## Affiliations
1. Royal Free Hospital
2. Tahir Heart Institute Rabwah
3. King's College Medical School
4. St George's Medical School

## Abstract
**Background:** Conventional pooled estimators can become unstable under small-study effects, publication bias, and adverse study weighting. SYNTHESIS explores a multi-layer alternative that treats evidence integration as a verification pipeline rather than a single mechanical pooling step.

**Methods:** SYNTHESIS is an R package with a Shiny interface, Docker deployment path, and a seven-layer workflow covering harmonization, density mapping, precision weighting, quality integration, a consensus anchor, corrected trajectory modelling, and heterogeneity filtering.

**Results:** The repository contains package code, a vignette, `testthat` tests, simulation outputs, model-card metadata, and a large set of internal review documents addressing performance, regulatory framing, stability, safety, and publication readiness.

**Conclusions:** SYNTHESIS is reported as an exploratory bias-resistant software framework with explicit fail-safe logic, not as a drop-in replacement for every standard meta-analytic workflow.

## Keywords
meta-analysis; robustness; publication bias; Shiny app; cloud deployment; evidence verification; software tool

## Introduction
The project reframes evidence synthesis as a layered trust model. Rather than asking only how to average effects, it asks how to reduce undue leverage, encode methodological quality, and decide when the model should fall back to a safer anchor because the correction path is unstable.

The appropriate comparison class is standard fixed-effect and random-effects meta-analysis, plus hosted apps that prioritize convenience over robust failure modes. The software paper therefore needs to emphasize guardrails, auditability, and bounded claims rather than a blanket performance claim.

The manuscript structure below is deliberately aligned to common open-software review requests: the rationale is stated explicitly, at least one runnable example path is named, local validation artifacts are listed, and conclusions are bounded to the functions and outputs documented in the repository.

## Methods
### Software architecture and workflow
The codebase includes an R package, Shiny launch entry point, Dockerfile, vignettes, tests, and documentation for design decisions. The visible software behavior is organized around the audit object returned by `synthesis_audit()` and the interactive dashboard launched by `launch_synthesis_app()`.

### Installation, runtime, and reviewer reruns
The local implementation is packaged under `C:\Models\FATIHA_Project`. The manuscript identifies the local entry points, dependency manifest, fixed example input, and expected saved outputs so that reviewers can rerun the documented workflow without reconstructing it from scratch.

- Entry directory: `C:\Models\FATIHA_Project`.
- Detected documentation entry points: `README.md`, `f1000_artifacts/tutorial_walkthrough.md`, `vignettes/SYNTHESIS_Walkthrough.Rmd`.
- Detected environment capture or packaging files: `renv.lock`, `Dockerfile`.
- Named worked-example paths in this draft: `vignettes/SYNTHESIS_Walkthrough.Rmd` for a runnable package walk-through; `simulation_results.csv` and `Performance_Summary.png` for the packaged stress-test outputs; `demo/` and `inst/` resources for package examples and user materials.
- Detected validation or regression artifacts: `f1000_artifacts/validation_summary.md`, `demo/real_data_validation.R`, `demo/validation.R`, `tests/testthat.R`.
- Detected example or sample data files: `f1000_artifacts/example_dataset.csv`.

### Worked examples and validation materials
**Example or fixed demonstration paths**
- `vignettes/SYNTHESIS_Walkthrough.Rmd` for a runnable package walk-through.
- `simulation_results.csv` and `Performance_Summary.png` for the packaged stress-test outputs.
- `demo/` and `inst/` resources for package examples and user materials.

**Validation and reporting artifacts**
- `tests/testthat/` for package-level regression tests.
- `SYNTHESIS_Performance_Report.md` and allied review files for documented stress testing and methodological critique.
- `SYNTHESIS_MODEL_CARD.yaml` and `SYNTHESIS_Transparency_Table.csv` for reviewer-facing documentation.

### Typical outputs and user-facing deliverables
- Interactive audit summaries and dashboard views.
- Bias-aware pooled estimates with fail-safe fallback behavior.
- Cloud-ready packaging via Docker and project-level reproducibility materials.

### Reviewer-informed safeguards
- Provides a named example workflow or fixed demonstration path.
- Documents local validation artifacts rather than relying on unsupported claims.
- Positions the software against existing tools without claiming blanket superiority.
- States limitations and interpretation boundaries in the manuscript itself.
- Requires explicit environment capture and public example accessibility in the released archive.

## Review-Driven Revisions
This draft has been tightened against recurring open peer-review objections taken from the supplied reviewer reports.
- Reproducibility: the draft names a reviewer rerun path and points readers to validation artifacts instead of assuming interface availability is proof of correctness.
- Validation: claims are anchored to local tests, validation summaries, simulations, or consistency checks rather than to unsupported assertions of performance.
- Comparators and niche: the manuscript now names the relevant comparison class and keeps the claimed niche bounded instead of implying universal superiority.
- Documentation and interpretation: the text expects a worked example, input transparency, and reviewer-verifiable outputs rather than a high-level feature list alone.
- Claims discipline: conclusions are moderated to the documented scope of SYNTHESIS and paired with explicit limitations.

## Use Cases and Results
The software outputs should be described in terms of concrete reviewer-verifiable workflows: running the packaged example, inspecting the generated results, and checking that the reported interpretation matches the saved local artifacts. In this project, the most important result layer is the availability of a transparent execution path from input to analysis output.

Representative local result: `demo/Validation_Report.md` reports The SYNTHESIS system has analyzed the evidence and concluded a final estimate of 0.3571 (95% CI: [0.2379, 0.5412]).

### Concrete local quantitative evidence
- `demo/Validation_Report.md` reports The SYNTHESIS system has analyzed the evidence and concluded a final estimate of 0.3571 (95% CI: [0.2379, 0.5412]).
- `data/simulation_results_extended.csv` contains 6 SYNTHESIS scenario rows with mean absolute bias 0.104, mean RMSE 0.311.
- `paper/synthesis_manuscript.md` reports Results: In simulations, SYNTHESIS achieved 95.2% coverage under publication bias (CI width: 0.55) vs.

## Discussion
Representative local result: `demo/Validation_Report.md` reports The SYNTHESIS system has analyzed the evidence and concluded a final estimate of 0.3571 (95% CI: [0.2379, 0.5412]).

Because the method vocabulary is ambitious, the F1000 paper needs to state clearly that SYNTHESIS is a software framework exploring robust evidence verification under stress, with local simulation evidence and explicit failure handling, rather than a fully settled methodological standard.

### Limitations
- The project relies heavily on internal stress-test documents rather than a single finished methods paper.
- Performance claims need to remain tied to the packaged simulations and not generalized beyond them.
- External, independently curated benchmark validation remains desirable before stronger claims are made.

## Software Availability
- Local source package: `FATIHA_Project` under `C:\Models`.
- Public repository: `https://github.com/mahmood726-cyber/fatiha`.
- Public source snapshot: Fixed public commit snapshot available at `https://github.com/mahmood726-cyber/fatiha/tree/f341e937b88b612ce55542ef97aa240788cc9690`.
- DOI/archive record: No project-specific DOI or Zenodo record URL was detected locally; archive registration pending.
- Environment capture detected locally: `renv.lock`, `Dockerfile`.
- Reviewer-facing documentation detected locally: `README.md`, `f1000_artifacts/tutorial_walkthrough.md`, `vignettes/SYNTHESIS_Walkthrough.Rmd`.
- Reproducibility walkthrough: `f1000_artifacts/tutorial_walkthrough.md` where present.
- Validation summary: `f1000_artifacts/validation_summary.md` where present.
- Reviewer rerun manifest: `F1000_Reviewer_Rerun_Manifest.md`.
- Multi-persona review memo: `F1000_MultiPersona_Review.md`.
- Concrete submission-fix note: `F1000_Concrete_Submission_Fixes.md`.
- License: see the local `LICENSE` file.

## Data Availability
The package distributes code, simulations, and non-patient example materials locally. No new participant-level clinical data are included in the F1000 manuscript bundle.

## Reporting Checklist
Real-peer-review-aligned checklist: `F1000_Submission_Checklist_RealReview.md`.
Reviewer rerun companion: `F1000_Reviewer_Rerun_Manifest.md`.
Companion reviewer-response artifact: `F1000_MultiPersona_Review.md`.
Project-level concrete fix list: `F1000_Concrete_Submission_Fixes.md`.

## Declarations
### Competing interests
The authors declare that no competing interests were disclosed.

### Grant information
No specific grant was declared for this manuscript draft.

### Author contributions (CRediT)
| Author | CRediT roles |
|---|---|
| Mahmood Ahmad | Conceptualization; Software; Validation; Data curation; Writing - original draft; Writing - review and editing |
| Niraj Kumar | Conceptualization |
| Bilaal Dar | Conceptualization |
| Laiba Khan | Conceptualization |
| Andrew Woo | Conceptualization |

### Acknowledgements
The authors acknowledge contributors to open statistical methods, reproducible research software, and reviewer-led software quality improvement.

## References
1. DerSimonian R, Laird N. Meta-analysis in clinical trials. Controlled Clinical Trials. 1986;7(3):177-188.
2. Higgins JPT, Thompson SG. Quantifying heterogeneity in a meta-analysis. Statistics in Medicine. 2002;21(11):1539-1558.
3. Viechtbauer W. Conducting meta-analyses in R with the metafor package. Journal of Statistical Software. 2010;36(3):1-48.
4. Page MJ, McKenzie JE, Bossuyt PM, et al. The PRISMA 2020 statement: an updated guideline for reporting systematic reviews. BMJ. 2021;372:n71.
5. Fay C, Rochette S, Guyader V, Girard C. Engineering Production-Grade Shiny Apps. Chapman and Hall/CRC. 2022.
