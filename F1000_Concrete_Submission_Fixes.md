# SYNTHESIS: concrete submission fixes

This file converts the multi-persona review into repository-side actions that should be checked before external submission of the F1000 software paper for `FATIHA_Project`.

## Detectable Local State
- Documentation files detected: `README.md`, `f1000_artifacts/tutorial_walkthrough.md`, `vignettes/SYNTHESIS_Walkthrough.Rmd`.
- Environment lock or container files detected: `renv.lock`, `Dockerfile`.
- Package manifests detected: `DESCRIPTION`.
- Example data files detected: `f1000_artifacts/example_dataset.csv`.
- Validation artifacts detected: `f1000_artifacts/validation_summary.md`, `demo/real_data_validation.R`, `demo/validation.R`, `tests/testthat.R`.
- Detected public repository root: `https://github.com/mahmood726-cyber/fatiha`.
- Detected public source snapshot: Fixed public commit snapshot available at `https://github.com/mahmood726-cyber/fatiha/tree/f341e937b88b612ce55542ef97aa240788cc9690`.
- Detected public archive record: No project-specific DOI or Zenodo record URL was detected locally; archive registration pending.

## High-Priority Fixes
- Check that the manuscript's named example paths exist in the public archive and can be run without repository archaeology.
- Confirm that the cited repository root (`https://github.com/mahmood726-cyber/fatiha`) resolves to the same fixed public source snapshot used for submission.
- Archive the tagged release and insert the Zenodo DOI or record URL once it has been minted; no project-specific archive DOI was detected locally.
- Reconfirm the quoted benchmark or validation sentence after the final rerun so the narrative text matches the shipped artifacts.

## Numeric Evidence Available To Quote
- `demo/Validation_Report.md` reports The SYNTHESIS system has analyzed the evidence and concluded a final estimate of 0.3571 (95% CI: [0.2379, 0.5412]).
- `data/simulation_results_extended.csv` contains 6 SYNTHESIS scenario rows with mean absolute bias 0.104, mean RMSE 0.311.
- `paper/synthesis_manuscript.md` reports Results: In simulations, SYNTHESIS achieved 95.2% coverage under publication bias (CI width: 0.55) vs.

## Manuscript Files To Keep In Sync
- `F1000_Software_Tool_Article.md`
- `F1000_Reviewer_Rerun_Manifest.md`
- `F1000_MultiPersona_Review.md`
- `F1000_Submission_Checklist_RealReview.md` where present
- README/tutorial files and the public repository release metadata
