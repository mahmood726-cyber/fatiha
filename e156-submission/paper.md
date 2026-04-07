Mahmood Ahmad
Tahir Heart Institute
mahmood.ahmad2@nhs.net

SYNTHESIS: A 7-Layer Verification Framework for Detecting Fragile Meta-Analyses

Can a multi-layered verification framework detect fragile meta-analytic estimates that standard random-effects models miss? SYNTHESIS was evaluated on 426 Cochrane reviews from Pairwise70 and a simulation study of six scenarios with 1,000 replications each. The R package processes effect sizes through seven sequential layers including density weighting, precision weighting, quality integration, and adaptive PET-style bias correction, verified by a Triple-Guard Ensemble of three robust estimators with automatic fail-safe substitution. Under publication bias, the median OR bias was 0.051 versus 0.463 for REML, with 95% CI coverage of 95.2 percent versus 0 percent and interval width of 0.55 versus 0.30. In the Pairwise70 benchmark, SYNTHESIS confidence intervals included the REML point estimate in 91.1 percent of analyses with 76.1 percent significance agreement. SYNTHESIS serves as a complementary verification layer that flags fragile results and produces complete auditable transparency tables. A limitation is that under ideal conditions coverage was conservative at 98.1 percent, reflecting wider intervals than necessary.

Outside Notes

Type: methods
Primary estimand: Coverage probability
App: SYNTHESIS R package v0.1.0
Data: 426 Cochrane reviews (Pairwise70) + 6-scenario simulation (6,000 reps)
Code: https://github.com/mahmood726-cyber/fatiha
Version: 0.1.0
Validation: DRAFT

References

1. Walsh M, Srinathan SK, McAuley DF, et al. The statistical significance of randomized controlled trial results is frequently fragile: a case for a Fragility Index. J Clin Epidemiol. 2014;67(6):622-628.
2. Atal I, Porcher R, Boutron I, Ravaud P. The statistical significance of meta-analyses is frequently fragile: definition of a fragility index for meta-analyses. J Clin Epidemiol. 2019;111:32-40.
3. Borenstein M, Hedges LV, Higgins JPT, Rothstein HR. Introduction to Meta-Analysis. 2nd ed. Wiley; 2021.
