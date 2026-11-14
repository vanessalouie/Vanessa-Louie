# Build Audit — Scenario 34 FX Hedging Workbook

| Field | Value |
|---|---|
| **Author** | Vanessa Louie |
| **Date** | 2026-11-13 |
| **Scenario** | 34 — U.S. ERP-software firm, EUR 2,900,000 receivable, 91 days |
| **Workbook audited** | `capabilities/fx-hedging/model.xlsx` (commit `b1e7c0f`) |
| **Spec** | `capabilities/fx-hedging/spec.md` v0.5 (commit `fb0f0e3`) |
| **Build method** | Claude Code, from the committed spec; reproducible via `capabilities/fx-hedging/build-model.ps1` |

## Summary

The workbook was generated from my spec and audited against the seven-item build contract and the spec's own validation rules (§5.1, §5.2, §6.3). The Checks tab runs 27 checks: **26 pass and 1 fails**. The failure is the covered-interest-parity check, which the spec predicts at placeholder inputs; it is reported below, not forced to pass. Most defects I found were in the **spec**, not the workbook: each time the agent had to ask me a question, or I had to explain something in chat, I treated it as a spec defect, fixed the spec, committed it, and rebuilt. The spec went from v0.3 to v0.5 during this stage.

---

## Findings

### Finding 1 — Parity check fails at placeholder inputs (reported, not fixed)
- **Checked:** The Checks tab parity row (money-market proceeds vs. quoted-forward proceeds, tolerance 0.05%).
- **Found:** **FAIL, gap 4.12% ($133,649).** The quoted forward `F0_in` = 1.1653 sits far above the CIP-implied forward `F_IMPLIED` = 1.1192, so the forward gives $3,379,370 against $3,245,721 for the money-market hedge. This matches the gap my spec predicted in §3 and §4 Step 3.
- **Action:** Left as FAIL on purpose. The cause is a stale placeholder forward, not a model error. Stage 4 replaces it with a live or CIP-implied forward. Until then, no forward-based figure should drive the Stage 5 recommendation.

### Finding 2 — The forward-source toggle could have hidden the parity gap (spec defect, fixed)
- **Checked:** How the new forward-source toggle (`FWD_SOURCE`, "Quoted"/"Implied") interacts with the parity check.
- **Found:** `PARITY_GAP` was defined as `USD_FWD − USD_MM`. Once `USD_FWD` runs through the toggle, switching to "Implied" would have made the gap zero and turned the parity check to PASS, hiding the stale forward.
- **Action:** Rewrote `PARITY_GAP` as `FC_AMT × F0_in − USD_MM`, so the parity check always uses the quoted forward (spec v0.4, commit `9de611b`). Tested in the built workbook: under "Implied", `F_USED` = 1.1192, forward = money market = $3,245,721, the break-even drops to 1.1341, and **parity still shows FAIL**. Three other checks also fail under "Implied" (forward base case, forward hedge profit, break-even), which is expected because the §5.1 expected values assume "Quoted".

### Finding 3 — Spec conflicted with the build contract on four points (spec defects, fixed)
- **Checked:** My v0.3 spec, line by line, against the seven contract requirements before building.
- **Found:**
  1. **Colors:** the spec used black formulas and green cross-tab links; the contract requires fill colors Yellow = inputs, Blue = assumptions, Green = formulas, Gray = outputs. Gray vs. green was also undefined, since every output is a formula.
  2. **Call option:** the spec marked the call "unused" and said §4 Step 7 was "not built"; the contract requires both a put and a call.
  3. **Cover page:** no data-provenance block; sources were stored in three places.
  4. **Validation checks:** no Checks tab with expected vs. calculated values and a PASS/FAIL result.
- **Action:** Spec v0.4 (commit `9de611b`) adopted the contract's fill colors (gray = final outputs, green = every other formula), added the call, moved provenance to a single Cover block marked "Indicative placeholder, replaced at Stage 4", and defined a Checks tab (§5.2).

### Finding 4 — Call defined as payoff, not proceeds (spec defect, fixed and verified)
- **Checked:** The new call formula against how "proceeds" is defined for the other strategies.
- **Found:** The first v0.4 draft defined only `CALL_NET(S_T) = MAX(S_T − K_CALL, 0) × FC_AMT + FV_PREM_CALL`, the call's standalone payoff. Every other strategy reports total USD received, receivable included, so the call would not have been comparable.
- **Action:** Added `USD_CALL(S_T) = S_T × FC_AMT + CALL_NET(S_T)` and kept `CALL_NET` as its own column. The call is labeled "Comparison only: a call does not hedge a EUR receivable" and is excluded from the winner labels. I recomputed the new figures by hand: premium 0.0199 × 2,900,000 = **$57,710**; carried forward × 1.010280 = **−$58,303**; `USD_CALL` at spot = $3,235,530 − $58,303 = **$3,177,227**. All three match the workbook's Checks tab.

### Finding 5 — Strikes would have been typed numbers (spec defect, fixed)
- **Checked:** How `K_PUT` and `K_CALL` were defined.
- **Found:** The spec gave the strikes as 1.1157 "(= `S0_in`)" with a note to reset them by hand at Stage 4. A typed strike would break the formulas-only rule and go stale when spot is refreshed.
- **Action:** Both strikes stay named ranges (they are contract names) but contain the formula `=S0_in`, filled green, so they follow spot automatically.

### Finding 6 — Typed tolerances on the Checks tab contradicted the spec (found during the build, fixed)
- **Checked:** The agent stopped mid-build to ask how to handle the Tolerance column.
- **Found:** Tolerances (±1, ±0.000001, ±0.0001, 0) would have been typed numbers outside the Inputs tab, contradicting §5.2, which said the yellow Expected values were the only typed numbers there.
- **Action:** Moved tolerances to five blue named assumptions on the Inputs tab (`TOL_USD`, `TOL_FACTOR`, `TOL_RATE`, `TOL_PARITY`, `TOL_EXACT` at C17–C21). The Checks tab references them by name. The Expected column stays yellow, labeled "Reference inputs, typed by design." Documented in spec v0.5.

### Finding 7 — Break-even extension rows were ambiguous for the chart (found during the build, fixed)
- **Checked:** The agent asked how the +6%/+7% extension rows should appear on the chart.
- **Found:** The spec said the extension block shows the break-even "on the chart", but the contract asks for a ±5% chart. Putting 13 points on the main chart would break the contract; leaving them off would drop the break-even the CFO needs.
- **Action:** The main chart plots only the 11 core rows (±5%). A second, smaller chart, "Extended grid: put break-even vs forward", plots all 13 rows with a marker at (1.1802, $3,379,370), where the put line crosses the flat forward line. In the built workbook, the put overtakes the forward from +6% (S_T = 1.1826) onward, consistent with the 1.1802 break-even.

### Finding 8 — Chart x-axes have a fixed minimum (open limitation)
- **Checked:** Whether the charts adjust when inputs change.
- **Found:** Both charts start the x-axis at a typed 1.05. This is a chart setting, not a cell, so it will not move with a new spot.
- **Action:** Not fixed in Stage 3. Recorded in spec §6.2 item 6 and §7 as a Stage 4 action item: after loading the live spot, re-check that the full grid still shows on both charts.

### Finding 9 — §5.1 check figures verified by hand
- **Checked:** The spec's base-case values and check figures, recalculated independently from the placeholder inputs.
- **Found:** All match: `DF_USD` 1.010280, `DF_FC` 1.007108, EUR borrowed 2,879,532, USD at spot $3,212,694, `F_IMPLIED` 1.1192, `PARITY_GAP` $133,649, put premium $42,630, `FV_PREM_PUT` −$43,068, `USD_FLOOR_PUT` $3,192,462, `BREAKEVEN_PUT_FWD` 1.1802. The workbook's Checks tab reproduces every one within tolerance.
- **Action:** None needed. These remain the Stage 3 regression targets and must be recomputed in §5.1 at Stage 4.

---

## My hands-on verification in Excel

<!-- FILL IN before committing: replace each [ ] with what you actually saw. -->

| # | What I checked | Result |
|---|---|---|
| 1 | Name Manager: all ten contract names at `Inputs!C4–C14` | [ ] |
| 2 | `K_PUT` (C11) formula bar shows `=S0_in` | [ ] |
| 3 | Show Formulas (Ctrl + `) on Forward, MoneyMarket, Option, Sensitivity: no typed numbers in green or gray cells | [ ] |
| 4 | Changed `S0_in` to 1.12: strikes, sensitivity table, both charts and Checks tab updated (then undone) | [ ] |
| 5 | Checks tab: 26 PASS, parity FAIL at 4.12% | [ ] |
| 6 | Option tab: put proceeds floor at $3,192,462 at low S_T | [ ] |
| 7 | Charts: forward and money market flat, put kinks at 1.1157, marker at the crossing | [ ] |
| 8 | Cover: provenance block with "Indicative placeholder" label | [ ] |
| 9 | Fill colors match the Legend-Key tab | [ ] |

---

## Validation check status (placeholder inputs, `FWD_SOURCE` = "Quoted")

| Check group | Rows | Result |
|---|---|---|
| Parity (CIP) | 1 | **FAIL**: 4.12% vs. 0.05% tolerance (Finding 1) |
| Kink | 1 | PASS |
| Constancy (forward, money market) | 2 | PASS |
| Grid (count = 11, middle = spot, symmetry) | 3 | PASS |
| §5.1 base-case values and check figures | 20 | PASS |
| **Total** | **27** | **26 PASS · 1 FAIL** |

## Process notes

- **Spec defects found through questions:** Three times in this stage, an AI question or a chat explanation exposed a spec gap: the ten named ranges and strike choice (my first decisions prompt still had template placeholders), the typed tolerances (Finding 6), and the chart treatment of the extension rows (Finding 7). Each was fixed in the spec, committed, and rebuilt, not patched in chat.
- **"§7 check figures":** The build contract refers to "§7 check figures", but in my spec the check figures are in §5.1 (§7 is the Sensitivity Plan). I added a note in §5.1 rather than renumbering the spec.
- **Commit message error:** Commit `49ec6e6` says it appends five 2026-11-13 prompt-log entries; it actually adds three (the first two were already in `9de611b`). The log entries themselves are correct. I left the message rather than rewrite pushed history.
- **Reproducibility:** `build-model.ps1` is committed next to the workbook, so the build can be rerun from the spec.

## Carried to Stage 4

1. Replace the stale `F0_in` with a live or CIP-implied forward and re-run the parity check (Finding 1).
2. Replace the intraday spot with a close; the strikes update automatically (Finding 5).
3. Recompute the §5.1 expected values, since all of them will show FAIL once live inputs go in.
4. Re-check both chart x-axes (Finding 8).
