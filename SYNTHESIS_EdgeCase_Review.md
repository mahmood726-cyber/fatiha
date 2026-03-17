# SYNTHESIS Multi-Persona Review (Round 13): The Long-Tail Audit

This review evaluates the system's behavior in extreme edge cases (e.g., zero variance, single study, massive heterogeneity).

---

## 1. The Mathematical Statistician
**Focus:** Numerical Instability.

> "The 'Humility Factor' is a good start, but what about **Infinite Variance**? If a study reports $SE = 0$ (e.g., a fixed effect from a previous meta-analysis entered as data), the Precision Layer ($1/V$) will explode to infinity.
>
> **The Critique:** We need a **'Variance Floor'**. The system should enforce a minimum variance (epsilon) to prevent division-by-zero errors. Currently, `1/V` is risky without a `pmax(V, 1e-8)` check."

---

## 2. The Systematic Reviewer (Cochrane)
**Focus:** Single-Study "Meta-Analysis".

> "Sometimes we only find one study. SYNTHESIS requires $k \ge 3$. If I feed it $k=1$, it currently stops or returns a simple median.
>
> **The Critique:** For $k=1$, the 'Meta-Analysis' is just the study itself. The function should degrade gracefully: return the single study's estimate and CI, but flag the Reliability as **0% (SINGLE_STUDY)**. Don't just warn; return a valid object so my pipeline doesn't crash."

---

## 3. The Clinical Guideline Developer
**Focus:** The "Null" Result.

> "What if the result is **statistically non-significant**? The 'Trajectory' might find a trend, but if the p-value is 0.8, should we be 'correcting' it?
>
> **The Critique:** If the Core Estimate is non-significant ($p > 0.05$), the 'Bias Correction' (Layer 6) might just be fitting noise. I propose a **'Significance Gate'**. If the initial consensus is null, dampen the trajectory correction by 50%. Don't chase ghosts."

---

## 4. The Research Integrity Officer
**Focus:** Automated Reporting.

> "The transparency table is great, but it doesn't show the **'Excluded Studies'**. If `synthesis_meta` removes studies with missing values, they vanish from the record.
>
> **The Critique:** The output object needs a **`dropped_studies`** list. We need to know *which* IDs were removed during harmonization (Layer 1) to maintain a complete audit trail."

---

## Final Synthesis Improvement Plan (Round 13)
1.  **Variance Floor**: Enforce `vi = pmax(vi, 1e-8)` in Layer 1.
2.  **Graceful Degradation**: Handle $k=1$ and $k=2$ by returning a valid (but flagged) synthesis object.
3.  **The Significance Gate**: Dampen Layer 6 correction if the consensus p-value is high.
4.  **Audit of the Excluded**: Add `dropped_indices` to the result object.

---
*Review conducted by Gemini CLI Multi-Persona Protocol, Feb 2026.*
