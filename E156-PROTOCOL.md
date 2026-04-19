# E156 Protocol — `Fatiha`

This repository is the source code and dashboard backing an E156 micro-paper on the [E156 Student Board](https://mahmood726-cyber.github.io/e156/students.html).

---

## `[474]` SYNTHESIS: A 7-Layer Verification Framework for Detecting Fragile Meta-Analyses

**Type:** methods  |  ESTIMAND: Coverage probability  
**Data:** A 7-layer meta-analysis verification framework with Triple-Guard fail-safe ensemble, evaluated against 426 Cochrane reviews and six simulation scenarios.

### 156-word body

Can a multi-layered verification framework detect fragile meta-analytic estimates that standard random-effects models miss? SYNTHESIS was evaluated on 426 Cochrane reviews from Pairwise70 and a simulation study of six scenarios with 1,000 replications each. The R package processes effect sizes through seven sequential layers including density weighting, precision weighting, quality integration, and adaptive PET-style bias correction, verified by a Triple-Guard Ensemble of three robust estimators with automatic fail-safe substitution. Under publication bias, the median OR bias was 0.051 versus 0.463 for REML, with 95% CI coverage of 95.2 percent versus 0 percent and interval width of 0.55 versus 0.30. In the Pairwise70 benchmark, SYNTHESIS confidence intervals included the REML point estimate in 91.1 percent of analyses with 76.1 percent significance agreement. SYNTHESIS serves as a complementary verification layer that flags fragile results and produces complete auditable transparency tables. A limitation is that under ideal conditions coverage was conservative at 98.1 percent, reflecting wider intervals than necessary.

### Submission metadata

```
Corresponding author: Mahmood Ahmad <mahmood.ahmad2@nhs.net>
ORCID: 0000-0001-9107-3704
Affiliation: Tahir Heart Institute, Rabwah, Pakistan

Links:
  Code:      https://github.com/mahmood726-cyber/Fatiha
  Protocol:  https://github.com/mahmood726-cyber/Fatiha/blob/main/E156-PROTOCOL.md
  Dashboard: https://mahmood726-cyber.github.io/fatiha/

References (topic pack: publication bias / selection):
  1. Egger M, Davey Smith G, Schneider M, Minder C. 1997. Bias in meta-analysis detected by a simple, graphical test. BMJ. 315(7109):629-634. doi:10.1136/bmj.315.7109.629
  2. Duval S, Tweedie R. 2000. Trim and fill: a simple funnel-plot-based method of testing and adjusting for publication bias in meta-analysis. Biometrics. 56(2):455-463. doi:10.1111/j.0006-341X.2000.00455.x

Data availability: No patient-level data used. Analysis derived exclusively
  from publicly available aggregate records. All source identifiers are in
  the protocol document linked above.

Ethics: Not required. Study uses only publicly available aggregate data; no
  human participants; no patient-identifiable information; no individual-
  participant data. No institutional review board approval sought or required
  under standard research-ethics guidelines for secondary methodological
  research on published literature.

Funding: None.

Competing interests: MA serves on the editorial board of Synthēsis (the
  target journal); MA had no role in editorial decisions on this
  manuscript, which was handled by an independent editor of the journal.

Author contributions (CRediT):
  [STUDENT REWRITER, first author] — Writing – original draft, Writing –
    review & editing, Validation.
  [SUPERVISING FACULTY, last/senior author] — Supervision, Validation,
    Writing – review & editing.
  Mahmood Ahmad (middle author, NOT first or last) — Conceptualization,
    Methodology, Software, Data curation, Formal analysis, Resources.

AI disclosure: Computational tooling (including AI-assisted coding via
  Claude Code [Anthropic]) was used to develop analysis scripts and assist
  with data extraction. The final manuscript was human-written, reviewed,
  and approved by the author; the submitted text is not AI-generated. All
  quantitative claims were verified against source data; cross-validation
  was performed where applicable. The author retains full responsibility for
  the final content.

Preprint: Not preprinted.

Reporting checklist: PRISMA 2020 (methods-paper variant — reports on review corpus).

Target journal: ◆ Synthēsis (https://www.synthesis-medicine.org/index.php/journal)
  Section: Methods Note — submit the 156-word E156 body verbatim as the main text.
  The journal caps main text at ≤400 words; E156's 156-word, 7-sentence
  contract sits well inside that ceiling. Do NOT pad to 400 — the
  micro-paper length is the point of the format.

Manuscript license: CC-BY-4.0.
Code license: MIT.
```


---

_Auto-generated from the workbook by `C:/E156/scripts/create_missing_protocols.py`. If something is wrong, edit `rewrite-workbook.txt` and re-run the script — it will overwrite this file via the GitHub API._