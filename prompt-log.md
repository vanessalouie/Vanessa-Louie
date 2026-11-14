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

## 2026-11-13
- **Asked:** Check that the FX hedging spec is at `capabilities/fx-hedging/spec.md` (move it with `git mv` if it was in `docs/specs/`), and create `capabilities/fx-hedging/README.md` with a one-paragraph description of the folder.
- **Produced:** Confirmed the spec was already in place (no `docs/specs/` folder, so no move); drafted and saved `capabilities/fx-hedging/README.md` describing the Scenario 34 receivable hedge, `spec.md`, and `model.xlsx`.
- **What was wrong:** Claude first tried to save the README without showing the draft, against the "show me every file" rule; I rejected the write. The README names `model.xlsx`, which does not exist until Stage 3; Claude flagged this and I chose to keep the wording.
- **How it was caught:** I rejected the unshown write in the permission prompt; Claude listed the folder contents and found that `model.xlsx` is missing.

## 2026-11-13 (second request)
- **Asked:** Check `spec.md` against the 7-item build contract and list the gaps; then update the spec to v0.4 with my decisions, show the diff, revise, save, commit, and push.
- **Produced:** Gap list (named-range count and cells, legend conflict, call excluded, provenance in three places, Checks tab undefined, "§7" vs §5.1 numbering); spec v0.4 with the ten contract named ranges at `Inputs!C4`–`C14`, `STEP_FRAC` (C15) and `FWD_SOURCE` (C16), strikes as `=S0_in`, a fill-color legend, the call for comparison only (`CALL_NET`, `USD_CALL`), `F_USED` with parity kept on `F0_in`, a single Cover provenance block, and a Checks tab (§5.2).
- **What was wrong:** My first decisions message still had two template placeholders (the ten names, the strike choice); Claude asked instead of guessing. The first v0.4 draft defined the call as payoff only, not proceeds; left gray vs. green undefined; gave the forward toggle and `STEP_FRAC` no name or cell; and had typed Expected values that conflicted with "formulas only." Cell addresses and Checks tolerances were Claude's proposals. My item to remove the +6%/+7% rows was reversed in my next message.
- **How it was caught:** Claude flagged each problem under the draft diff; I decided each fix. Claude recomputed the new call figures in Python ($57,710 premium, −$58,303 `FV_PREM_CALL`, $3,177,227 `USD_CALL` at spot); still drafts until I verify them.

## 2026-11-13 (third request)
- **Asked:** Build the workbook specified in spec v0.4 as `capabilities/fx-hedging/model.xlsx`, ask about ambiguities first, do not commit.
- **Produced:** `model.xlsx` (9 tabs, 39 named ranges, two charts, 27-row Checks tab), built through Excel by a script kept outside the repo. Before building, Claude asked two questions; I chose named tolerance inputs and a separate second chart for the +6%/+7% rows.
- **What was wrong:** The first build runs failed: PowerShell passed array numbers to Excel in a form it could not take, and the script's "§" characters were misread until the file was re-saved with the right encoding. Claude added `TOL_EXACT` (a fifth tolerance) and helper named ranges not listed in the spec; the "/" in "Legend/Key" is not allowed in Excel tab names, so the tab is "Legend-Key."
- **How it was caught:** The build script stopped on the bad cell and reported it; Claude read back every Checks row (26 PASS, parity FAIL as expected), scanned all tabs for error cells (none), and switched `FWD_SOURCE` to "Implied" to confirm the parity check still fails. I still need to audit the workbook.

## 2026-11-13 (fourth request)
- **Asked:** Update `spec.md` to match the built workbook (Legend-Key tab name, five `TOL_*` ranges, five helper ranges, actual check rows, fixed chart x-axis minimum, green MoneyMarket parity cell) and copy `build-model.ps1` into `capabilities/fx-hedging/`.
- **Produced:** Spec edits in §2, §2.1, §2.2, §5, §5.2, §6.2 (new item 6), §6.3, and §7; `capabilities/fx-hedging/build-model.ps1`.
- **What was wrong:** The spec still lags the build in three places I did not list (the second chart, the extra "Put intrinsic payoff" column, the formula-built grid index), and the version and change log were not updated.
- **How it was caught:** Claude compared the build against the spec after the edits and flagged them.

## 2026-11-13 (fifth request)
- **Asked:** Fix those four gaps (separate extension chart with the break-even marked, the intrinsic column, the formula-built `i`, v0.5 with a change-log row), then commit spec, README, workbook + script, and prompt log separately, pushing after each.
- **Produced:** Spec v0.5; `build-model.ps1` updated so the second chart is smaller, titled "Extended grid: put break-even vs forward," and marks the break-even at (`BREAKEVEN_PUT_FWD`, `USD_FWD`); `model.xlsx` rebuilt from it; four commits.
- **What was wrong:** The workbook built earlier did not match the new chart wording in v0.5, so it had to be rebuilt. The first rebuild failed because I had `model.xlsx` open in Excel; Claude stopped and asked instead of closing my window.
- **How it was caught:** Excel refused to overwrite the open file; Claude found the lock file and my open Excel window. After the rebuild Claude re-read the checks (0 error cells, only parity FAIL) and both charts (titles, sizes, marker at x = 1.1802).
