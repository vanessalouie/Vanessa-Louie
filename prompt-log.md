To be appended after each use of AI

## 2026-11-06
- **Asked:** Fill the course Stage 2 spec template with my scenario (34, erp-software).
- **Produced:** Restructured `capabilities/fx-hedging/spec.md` into the template layout, carrying over my existing inputs, assumptions, calculation flow, and check figures; filled §5.1 base-case values; left §6.1 and §6.2 (model review) for me to write.
- **What was wrong:** Template defaults did not fit the scenario (1-year tenor, GBP 365-day basis, payable variant); the template's premium sign is negative, while my draft subtracted a positive premium.
- **How it was caught:** Claude recomputed every figure in Python and compared it with my draft's check figures (all matched); the sign convention and the template defaults were flagged for me to review.

## 2026-11-06 (second request)
- **Asked:** Check spec.md against the Stage 2 rubric, then restructure it and fix the problems found in my §6.2 text.
- **Produced:** Rubric check (5 met, 2 partial, 2 failed); spec v0.3 in the course template's 8-section structure (§1–8), with my model review in §6.1–6.2, tab purposes in §5, and validation rules in §6.3.
- **What was wrong:** Claude's earlier move into the long course template (v0.2) broke the rubric: it dropped the purpose of each tab, buried the validation rules in a checklist, and roughly doubled the length. In my §6.2: "almost every grid row" should be "every grid row" (the forward beats the put at all 11 rows); the +6%/+7% rows contradicted the "exactly 11 rows" grid check; and one cross-reference pointed to the wrong section. Claude changed the layout once again moving 6.1 and 6.2 to 7.3 and 7.4
- **How it was caught:** Compared the spec line by line against the rubric and recomputed the put proceeds at every grid row. Claude also misread which 8 sections the rubric means and first moved the spec back to my v0.1 layout; I caught it and pointed to the template's §1–8.
