# SYNTHESIS Multi-Persona Review (Round 5): Scaling to Network Meta-Analysis (NMA)

This review evaluates the expansion of the SYNTHESIS framework to audit and improve the NMA "Bake-Off" in `repo300`.

---

## 1. The Network Meta-Analysis Expert
**Focus:** Indirect evidence and consistency.

> "The challenge in NMA is not just bias in individual studies, but 'Inconsistency' between direct and indirect evidence. 
>
> **The Critique:** If we apply SYNTHESIS to NMA, we should treat the 'Inconsistency Factor' as a new Layer 8. Just as Layer 6 corrects for small-study bias, Layer 8 should correct for 'Loop Inconsistency'. If a treatment loop doesn't close, SYNTHESIS should downweight the most 'Astray' link in that loop."

---

## 2. The Data Auditor (from repo100/300)
**Focus:** Large-scale quality control.

> "We found that 61% of the files in `repo300` had issues. We are swimming in bad data.
>
> **The Critique:** I want a 'SYNTHESIS-Gatekeeper' for the Bake-Off. Before we compare `netmeta` vs `gemtc`, SYNTHESIS should run its 'Reliability Shield' on the raw data. If a dataset has a reliability score < 50%, we shouldn't even bother running the complex Bayesian models—they will just fit the noise."

---

## 3. The Evidence-Based Medicine (EBM) Advocate
**Focus:** Making the "best" choice among many.

> "In `repo300`, we are comparing rankings (SUCRA vs P-scores). This is where clinicians get confused.
>
> **The Critique:** SYNTHESIS can act as the 'Consensus Arbiter' (Layer 5). By taking the rankings from 5 different packages and applying 'Quality Integration' (Layer 4), we can produce a 'SYNTHESIS-Rank'. This would be the most robust treatment ranking possible, protected against the specific quirks of any single R package."

---

## 4. The Computational Statistician
**Focus:** Algorithmic efficiency.

> "NMA is computationally heavy. Running 7-layer SYNTHESIS on top of an MCMC chain is a lot of math.
>
> **The Critique:** We don't need to re-run the whole model. We should use 'Post-Hoc SYNTHESIS'. We take the posterior samples from `gemtc` or the results from `netmeta` and *then* apply the SYNTHESIS filters. This is an efficient way to 'purify' the output of existing packages."

---

## Final Synthesis Recommendation (Phase 5)
1.  **The Arbiter**: Create `synthesis_nma_arbiter()` to consolidate results from different NMA packages.
2.  **The Gatekeeper**: Integrate `synthesis_stability()` into the `repo300` data loading pipeline to flag low-quality datasets before analysis.
3.  **Inconsistency Guard**: Adapt the 'Triple-Guard' (TGEP) to check if network estimates are stable across different NMA packages.

---
*Review conducted by Gemini CLI Multi-Persona Protocol, Feb 2026.*
