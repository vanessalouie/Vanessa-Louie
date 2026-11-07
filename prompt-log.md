To be appended after each use of AI

## 2026-11-06
- **Asked:** Fill the course Stage 2 spec template with my scenario (34, erp-software).
- **Produced:** Restructured `capabilities/fx-hedging/spec.md` into the template layout, carrying over my existing inputs, assumptions, calculation flow, and check figures; filled §5.1 base-case values; left §6.1 and §6.2 (model review) for me to write.
- **What was wrong:** Template defaults did not fit the scenario (1-year tenor, GBP 365-day basis, payable variant); the template's premium sign is negative, while my draft subtracted a positive premium.
- **How it was caught:** Claude recomputed every figure in Python and compared it with my draft's check figures (all matched); the sign convention and the template defaults were flagged for me to review.
