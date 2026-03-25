# SYNTHESIS: reviewer rerun manifest

This manifest is the shortest reviewer-facing rerun path for the local software package. It lists the files that should be sufficient to recreate one worked example, inspect saved outputs, and verify that the manuscript claims remain bounded to what the repository actually demonstrates.

## Reviewer Entry Points
- Project directory: `C:\Models\FATIHA_Project`.
- Preferred documentation start points: `README.md`, `f1000_artifacts/tutorial_walkthrough.md`, `vignettes/SYNTHESIS_Walkthrough.Rmd`.
- Detected public repository root: `https://github.com/mahmood726-cyber/fatiha`.
- Detected public source snapshot: Fixed public commit snapshot available at `https://github.com/mahmood726-cyber/fatiha/tree/f341e937b88b612ce55542ef97aa240788cc9690`.
- Detected public archive record: No project-specific DOI or Zenodo record URL was detected locally; archive registration pending.
- Environment capture files: `renv.lock`, `Dockerfile`.
- Validation/test artifacts: `f1000_artifacts/validation_summary.md`, `demo/real_data_validation.R`, `demo/validation.R`, `tests/testthat.R`.

## Worked Example Inputs
- Manuscript-named example paths: `vignettes/SYNTHESIS_Walkthrough.Rmd` for a runnable package walk-through; `simulation_results.csv` and `Performance_Summary.png` for the packaged stress-test outputs; `demo/` and `inst/` resources for package examples and user materials; f1000_artifacts/example_dataset.csv.
- Auto-detected sample/example files: `f1000_artifacts/example_dataset.csv`.

## Expected Outputs To Inspect
- Interactive audit summaries and dashboard views.
- Bias-aware pooled estimates with fail-safe fallback behavior.
- Cloud-ready packaging via Docker and project-level reproducibility materials.

## Minimal Reviewer Rerun Sequence
- Start with the README/tutorial files listed below and keep the manuscript paths synchronized with the public archive.
- Create the local runtime from the detected environment capture files if available: `renv.lock`, `Dockerfile`.
- Run at least one named example path from the manuscript and confirm that the generated outputs match the saved validation materials.
- Quote one concrete numeric result from the local validation snippets below when preparing the final software paper.

## Local Numeric Evidence Available
- `demo/Validation_Report.md` reports The SYNTHESIS system has analyzed the evidence and concluded a final estimate of 0.3571 (95% CI: [0.2379, 0.5412]).
- `data/simulation_results_extended.csv` contains 6 SYNTHESIS scenario rows with mean absolute bias 0.104, mean RMSE 0.311.
- `paper/synthesis_manuscript.md` reports Results: In simulations, SYNTHESIS achieved 95.2% coverage under publication bias (CI width: 0.55) vs.
