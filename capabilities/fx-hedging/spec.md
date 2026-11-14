<div style="border-top: 6px solid #024731; border-bottom: 1px solid #B2B2B2; padding: 12px 0; margin-bottom: 24px; font-family: 'Open Sans', Helvetica, Arial, sans-serif;">
  <div style="color: #024731; font-weight: 700; letter-spacing: 0.06em; text-transform: uppercase; font-size: 0.85rem;">University of Hawaiʻi at Mānoa · Shidler College of Business</div>
  <div style="color: #000000; font-weight: 700; font-size: 1.25rem; margin-top: 4px;">FIN 321: International Finance and Securities</div>
  <div style="color: #525252; font-weight: 400; font-size: 0.95rem;">FX Transaction Hedging Project — Technical Specification</div>
</div>

# ERP Software Firm — FX Transaction Hedge Model · Technical Specification

> <span style="color:#024731; font-weight:700;">Technical specification</span> for the FX transaction hedge model — the named-range contract, calculation flow, and validation checks, precise enough that an AI or a colleague could build (or rebuild) the workbook from this document alone. This spec is the input the AI-assisted build works from.

| Field | Value |
|------|------|
| **Created by** | Vanessa Louie |
| **Updated by** | Vanessa Louie |
| **Date Created** | 2026-11-06 |
| **Date Updated** | 2026-11-13 |
| **Version** | 0.4 |
| **LLM Used** (optional) | Claude: helped fit my draft to the course template and recomputed the check figures; I reviewed every figure and wrote the model review (§6.1–6.2). v0.4: Claude drafted the edits from my build-contract decisions |
| **Role** | Treasury Analyst |
| **Audience** | CFO |
| **Companion Workbook** | `capabilities/fx-hedging/model.xlsx` (Scenario 34, `erp-software`; built in Stage 3) |

---

## 1. Problem Statement

A U.S. ERP-software firm (functional currency USD) has invoiced a Dutch retailer EUR 2,900,000, settling in 91 days. Rates are quoted in USD per EUR, so a euro depreciation over the horizon would reduce realized USD proceeds, and the dollar amount is unknown until settlement. The objective is to protect USD proceeds at an acceptable cost, while showing how much upside each strategy gives up. This specification documents the framework used to compare four strategies — **no hedge**, **forward hedge**, **money-market hedge**, and **option (put) hedge** — and to produce the sensitivity evidence behind the Stage 5 decision memo to the CFO of the corporate treasury function. The EUR call is also calculated, for comparison only: a call does not hedge a EUR receivable, so it is excluded from the strategy ranking.

---

## 2. Inputs (Known Variables)

All inputs are workbook **named ranges** on the Inputs tab. The ten marked **Contract** are the build contract's required named ranges; `BASIS`, `STEP_FRAC`, `FWD_SOURCE`, and the §2.2 values are extra named ranges, which the contract allows. Sources, dates, and access timestamps are stored **once**, in the Cover tab's provenance block (§5); every other tab references that block instead of repeating it. Every market value below is **indicative, replaced with live data at Stage 4**, except `FC_AMT`, `T_DAYS`, and the option premiums, which are fixed by the scenario.

### 2.1 Core Inputs

| Standardized Name | Contract | Cell | Fill | Description | Unit | Placeholder | Stage 4 source |
|-------------------|:--:|------|------|-------------|------|--------:|----------------|
| `FC_AMT` | ✓ | `Inputs!C4` | Yellow | EUR receivable | EUR | 2,900,000 | Fixed by scenario |
| `S0_in` | ✓ | `Inputs!C5` | Yellow | Spot at inception | USD per EUR | 1.1157 | 6 Nov 2026 intraday, PrimeXBT; replace with the refresh-day close (e.g., Yahoo Finance EURUSD=X), with timestamp |
| `F0_in` | ✓ | `Inputs!C6` | Yellow | 91-day forward | USD per EUR | 1.1653 | Scenario's indicative quote (stale); replace with a live bank/market forward or `F_IMPLIED`, with a comment on the gap |
| `R_USD` | ✓ | `Inputs!C7` | Yellow | USD rate to settlement | Annual %, ACT/360 | 4.0669% | 3-month CME Term SOFR, 5 Nov 2026, global-rates.com; same series at Stage 4 |
| `R_FC` | ✓ | `Inputs!C8` | Yellow | EUR rate to settlement | Annual %, ACT/360 | 2.812% | 3-month Euribor, 5 Nov 2026, global-rates.com; same series at Stage 4 |
| `T_DAYS` | ✓ | `Inputs!C9` | Yellow | Days to settlement | Days | 91 | Fixed by scenario |
| `BASIS` | | `Inputs!C10` | Blue | Day-count denominator (assumption) | Days | 360 | Both legs ACT/360, so a single value is exact |
| `K_PUT` | ✓ | `Inputs!C11` | Green | Put strike: the formula `=S0_in` (at the money), not a typed value | USD per EUR | 1.1157 | Follows `S0_in` automatically |
| `K_CALL` | ✓ | `Inputs!C12` | Green | Call strike: the formula `=S0_in` (at the money), not a typed value | USD per EUR | 1.1157 | Follows `S0_in` automatically |
| `PREM_PUT` | ✓ | `Inputs!C13` | Yellow | Put premium per 1 EUR | USD | 0.0147 | Fixed by scenario (retail option quotes are unreliable) |
| `PREM_CALL` | ✓ | `Inputs!C14` | Yellow | Call premium per 1 EUR (comparison only) | USD | 0.0199 | Fixed by scenario |
| `STEP_FRAC` | | `Inputs!C15` | Blue | Sensitivity grid step (assumption) | % | 1% | Fixed by design |
| `FWD_SOURCE` | | `Inputs!C16` | Blue | Forward-source toggle (assumption): data-validation dropdown "Quoted" / "Implied" | Text | "Quoted" (default) | Fixed by design; see §6.2 item 1 |

### 2.2 Derived / Intermediate Values

| Name | Description | Source |
|------|-------------|--------|
| `DF_USD` / `DF_FC` | Growth factors to settlement | `1 + R_USD × T_DAYS / BASIS` / `1 + R_FC × T_DAYS / BASIS` |
| `FV_PREM_PUT` | Put premium carried to settlement (negative = cost) | `−PREM_PUT × FC_AMT × DF_USD` |
| `FV_PREM_CALL` | Call premium carried to settlement (negative = cost) | `−PREM_CALL × FC_AMT × DF_USD` |
| `F_IMPLIED` | CIP-implied forward | `S0_in × DF_USD / DF_FC` |
| `F_USED` | Forward used by the forward-hedge outputs | `IF(FWD_SOURCE = "Implied", F_IMPLIED, F0_in)` |
| `S_T_grid` | Settlement spot grid | `S0_in × (1 + i × STEP_FRAC)`, i = −5 … +5 |
| `USD_NO_HEDGE` | USD proceeds under no hedge | `S_T × FC_AMT` |

---

## 3. Assumptions & Constraints

- **Quote convention:** USD per EUR; a higher quote means the euro has strengthened.
- **Horizon:** single maturity, `T_DAYS = 91`.
- **Day-count basis:** simple interest, `r × T_DAYS / BASIS`. 3-month SOFR and 3-month Euribor are both ACT/360, so the single `BASIS = 360` is exact and no `BASIS_USD` / `BASIS_FC` split is needed.
- **Parity:** the money-market hedge should replicate the forward under covered interest-rate parity (CIP). At Stage 4, a gap larger than rounding is a finding about the inputs, not a model error.
- **Known placeholder problem:** the scenario's 1.1653 forward sits about 4% above the CIP-implied forward at current spot and rates (1.1192), so the parity check is expected to fail at placeholders. This is recorded, not hidden, and Stage 4 resolves it.
- **Option premium:** paid upfront in USD, quoted per 1 EUR (no contract multiplier), a **negative cash flow** carried forward at `R_USD`.
- **Excluded from the base case:** counterparty and credit risk, transaction costs and bid-ask spreads, tax and accounting treatment.
- **Scenario construction:** `S_T` varies deterministically across a grid; no probabilities and no volatility model.

---

## 4. Calculation Flow

Named-range pseudocode for the **receivable**; each numbered sub-step lives in its own cell.

### Step 1 — Derived inputs

1. `DF_USD` = `1 + R_USD × T_DAYS / BASIS` *(growth factor, not a fractional discount factor)*
2. `DF_FC` = `1 + R_FC × T_DAYS / BASIS`
3. `FV_PREM_PUT` = `−PREM_PUT × FC_AMT × DF_USD`
4. `FV_PREM_CALL` = `−PREM_CALL × FC_AMT × DF_USD`

### Step 2 — Forward hedge (certainty benchmark)

- `USD_FWD` = `FC_AMT × F_USED`, locked in at t₀ and constant across the grid. With `FWD_SOURCE` = "Quoted" (the default), `F_USED` = `F0_in`.

### Step 3 — Money-market hedge (three steps, then the parity check)

1. Borrow EUR today: `FC_AMT / DF_FC` *(sized so the receivable repays the loan exactly)*.
2. Convert at spot: `(FC_AMT / DF_FC) × S0_in`.
3. Invest the USD to maturity: `USD_MM` = `(FC_AMT / DF_FC) × S0_in × DF_USD`.

Then `F_IMPLIED` = `S0_in × DF_USD / DF_FC` and `PARITY_GAP` = `FC_AMT × F0_in − USD_MM` (USD and % of `USD_MM`). The parity check always uses the quoted `F0_in`, never `F_USED`, so the forward-source toggle cannot hide the gap.

> **Parity check:** `USD_MM ≈ USD_FWD` within 0.05% once Stage 4 inputs are live. With the placeholder forward, a gap of about 4.1% ($133,649) is expected and must be flagged, not fixed.

### Step 4 — Option hedge (floor with upside)

- Pay `PREM_PUT × FC_AMT` USD today for a EUR put with strike `K_PUT`.
- `USD_PUT(S_T)` = `MAX(S_T, K_PUT) × FC_AMT + FV_PREM_PUT`
- `BREAKEVEN_PUT_FWD` = `F_USED − FV_PREM_PUT / FC_AMT` *(settlement spot at which the put matches the forward)*

### Step 5 — Sensitivity table (rows of the grid)

| Column | Output | Formula |
|--------|--------|---------|
| No hedge | `USD_NO_HEDGE(S_T)` | `S_T × FC_AMT` |
| Forward | `USD_FWD` | constant across rows |
| Money market | `USD_MM` | constant across rows |
| Option (put) | `USD_PUT(S_T)` | `MAX(S_T, K_PUT) × FC_AMT + FV_PREM_PUT` |
| Hedge profit | `HEDGE_PROFIT_k(S_T)` | `USD_k − USD_NO_HEDGE`, one sub-column per active hedge |
| Overall winner | label | `ARGMAX(USD_NO_HEDGE, USD_FWD, USD_MM, USD_PUT)`; the call is excluded |
| Best active hedge | label | `ARGMAX(USD_FWD, USD_MM, USD_PUT)`; the call is excluded |

### Step 6 — Summary metrics

- `USD_FLOOR_PUT` = `MIN(USD_PUT)` across `S_T_grid`
- `USD_BASE_k` = `USD_k` at `S_T = S0_in` for each strategy (feeds §5.1)

### Step 7 — Call option (comparison only)

On the Option tab, below the put, under the label **"Comparison only: a call does not hedge a EUR receivable."**

- Premium paid today: `PREM_CALL × FC_AMT` USD
- `FV_PREM_CALL` = `−PREM_CALL × FC_AMT × DF_USD`
- Net call payoff for each settlement spot (its own column): `CALL_NET(S_T)` = `MAX(S_T − K_CALL, 0) × FC_AMT + FV_PREM_CALL`
- Call proceeds, consistent with the other strategies: `USD_CALL(S_T)` = `S_T × FC_AMT + CALL_NET(S_T)`

The call is excluded from the overall-winner and best-active-hedge labels (Step 5). A payable variant is not built.

---

## 5. Outputs

**Workbook tabs and their purpose:**

| Tab | Purpose |
|-----|---------|
| Cover | Title, scenario, author, version, date, one-line purpose, and the data-provenance block (below) |
| Legend/Key | Color legend (cell fill): yellow inputs, blue assumptions (`BASIS`, `STEP_FRAC`, `FWD_SOURCE`), gray final outputs (strategy summary block, Sensitivity result columns and winner labels, Checks Result column), green every other formula |
| Inputs | All §2.1 named ranges at their stated cells, with units; sources are referenced from the Cover provenance block, not repeated |
| Forward | Forward hedge calculation (§4 Step 2) |
| MoneyMarket | Three-step money-market hedge, `F_IMPLIED`, and the parity check (§4 Step 3) |
| Option | Put payoff for each settlement spot and the break-even (§4 Step 4); call, comparison only (§4 Step 7) |
| Sensitivity | Grid, proceeds per strategy, hedge-profit columns, winner labels, and the chart (§4 Steps 5–6, §7) |
| Checks | One row per validation check and per §5.1 figure (§5.2) |
| Notes & Assumptions | Assumptions and limitations; sources are referenced from the Cover provenance block |

**Cover data-provenance block** (the only place sources are stored), marked **"Indicative placeholder, replaced at Stage 4."**

| Input | Source | Date |
|-------|--------|------|
| `S0_in` | PrimeXBT, intraday | 6 Nov 2026 |
| `F0_in` | Scenario's indicative quote (stale) | Scenario |
| `R_USD` | 3-month CME Term SOFR, global-rates.com | 5 Nov 2026 |
| `R_FC` | 3-month Euribor, global-rates.com | 5 Nov 2026 |

| Output | Description | Format | Purpose |
|--------|-------------|--------|---------|
| Strategy summary | `USD_FWD`, `USD_MM`, `F_IMPLIED`, `PARITY_GAP`, `USD_BASE_k`, `USD_FLOOR_PUT`, `BREAKEVEN_PUT_FWD` | Table above the grid | Executive at-a-glance |
| Sensitivity table + hedge profit | USD proceeds and `USD_k − USD_NO_HEDGE` per strategy across `S_T_grid` | Sensitivity tab | Core evidence; isolates hedge value-add |
| Winner / best-hedge labels | `ARGMAX` labels per row, call excluded | Two label columns | Quick-read decision cue |
| Sensitivity chart | USD proceeds vs. `S_T`, four strategies | Embedded line chart | Visual comparison |
| Executive summary | Recommendation narrative | Stage 5 decision memo | Downstream deliverable |

### 5.1 Computed Base-Case Values

At `S_T = S0_in = 1.1157`, placeholder inputs — the regression checkpoint for Stage 3, recomputed at Stage 4.

| Strategy | USD Proceeds (Receivable) | USD Outlay (Payable) | Hedge Profit vs. No Hedge |
|----------|--------------------------:|---------------------:|--------------------------:|
| No hedge | $3,235,530 | n/a | — |
| Forward | $3,379,370 | n/a | +$143,840 |
| Money market | $3,245,721 | n/a | +$10,191 |
| Option (put) | $3,192,462 | n/a | −$43,068 |

Check figures: `DF_USD` 1.010280 · `DF_FC` 1.007108 · EUR borrowed 2,879,532 · USD at spot $3,212,694 · `F_IMPLIED` 1.1192 · `PARITY_GAP` $133,649 · premium paid $42,630 · `FV_PREM_PUT` −$43,068 · `USD_FLOOR_PUT` $3,192,462 · `BREAKEVEN_PUT_FWD` 1.1802 · call premium paid $57,710 · `FV_PREM_CALL` −$58,303 · `USD_CALL` at `S_T = S0_in` $3,177,227 (comparison only). All forward-based figures assume `FWD_SOURCE` = "Quoted".

These base-case values and check figures are what the build contract calls the "§7 check figures." The Checks tab (§5.2) tests each one.

### 5.2 Checks Tab

One row per §6.3 check (parity, kink, constancy, grid) and one row per §5.1 base-case value and check figure. Columns:

| Column | Content |
|--------|---------|
| Check | Name of the check or figure |
| Expected | The §5.1 figure, or the rule's target (0 for a gap, 11 for the row count). Filled yellow and labeled **"Reference inputs, typed by design."** These are the only typed numbers outside the Inputs tab |
| Calculated | A formula pointing at the workbook cell being checked |
| Difference | `Calculated − Expected` |
| Tolerance | Parity 0.05% of `USD_MM`; USD and EUR amounts ±1; growth factors ±0.000001; exchange rates ±0.0001; row count and constancy 0 |
| Result | `=IF(ABS(Difference) <= Tolerance, "PASS", "FAIL")` |

Failing checks stay visible as FAIL; no check is ever hard-coded or overridden to pass. The parity check is expected to show FAIL at placeholder inputs (§3).

---

## 6. Model Review — What Worked & What to Improve

### 6.1 What Worked

- **Clear certainty baseline:** Explicit forward and money-market formulas (§4, Steps 2–3) establish locked-in USD benchmarks, isolating the exact dollar cost of the put's optionality as the gap between the put floor and those certainty baselines (§5.1).
- **Upfront parity verification:** Defining `F_IMPLIED` alongside `F0_in` surfaced the scenario's stale forward (about 1.1192 implied vs. 1.1653 quoted, a $133,649 gap) before writing any workbook code. The audit rule in §6.3 ensures this gap is caught cleanly during the build.
- **End-to-end named-range architecture:** Building every calculation on standardized named ranges (§2.1, §4) rather than hardcoded cell references ensures the sensitivity grid and summary metrics respond dynamically to spot or rate changes. Stage 3 will validate this by shifting an input and verifying downstream updates.
- **Fair time-value accounting for option premia:** Compounding the upfront premium to settlement via `FV_PREM_PUT` and `DF_USD` puts the option proceeds on equal footings with the forward and money-market cash flows. The kink verification check in §6.3 confirms the net payoff structure at strike.

### 6.2 What to Improve

1. **The forward is stale, the biggest risk.**
   - **Size of the gap:** 1.1653 is about 4.1% above the implied 1.1192. The money-market hedge gives about $3,245,721 against $3,379,370 for the forward, a shortfall of $133,649.
   - **Likely cause:** the scenario's indicative forward probably dates from an earlier, higher spot. This is unconfirmed.
   - **Consequence for the grid:** with the stale forward, the forward beats the put and the money-market hedge at every grid row, so the sensitivity results would mislead.
   - **Consequence for the break-even:** the put-versus-forward break-even is about 1.1802 against the placeholder forward, but about 1.1341 against the money-market proceeds. The Stage 1 hypothesis of "near 1.18" depends on the stale quote.
   - **Action item (Stage 3):** add a forward-source toggle in the Inputs tab to choose between the quoted forward and `F_IMPLIED`. The parity check must always run against the quoted forward, so the toggle cannot hide the gap.
   - **Action item (Stage 4):** replace the placeholder with a live forward or the CIP-implied one, and comment on the gap. Until then, label every forward-based output as a placeholder, and do not base the Stage 5 recommendation on it.
2. **Spot is intraday, not a close.** 1.1157 was an intraday level on November 6. **Action item:** replace it with the close, then recompute the strikes and the base-case and check figures in §5.1.
3. **The two rates are different benchmarks.** 3-month Term SOFR is a secured rate and 3-month Euribor is an unsecured one, and neither is exactly 91 days or the firm's own borrowing cost. Part of any parity gap could come from this mismatch. **Action item:** record the benchmarks in the Notes tab and test the sensitivity to them at Stage 4.
4. **The grid does not reach the break-even.** The ±5% grid (about 1.0599 to 1.1715) stops short of `BREAKEVEN_PUT_FWD` (about 1.1802, roughly +5.8% above spot). **Action item:** add optional +6% and +7% rows in a separate extension block below the 11-row core grid (excluded from the grid check in §6.3), and state the break-even in the output summary, so the CFO can see how large a euro rally the put needs to beat the forward.
5. **Frictions and fixed premiums are not modeled.** Net proceeds assume no bid-ask spreads or borrowing premiums, and option premiums are fixed scenario inputs, so they do not adjust if implied volatility changes. **Action item:** add optional cost inputs if time allows, and state both as limitations in the Stage 5 memo (see §8).

### 6.3 Auditability Checklist (validation rules)

- [ ] Every input has a standardized named range from §2.1
- [ ] Every formula in §4 uses named ranges — no cell addresses in the logic
- [ ] **Parity check:** money-market hedge ties to forward hedge within 0.05% — expected to **fail** at placeholders (≈4.1%), must pass with Stage 4 inputs
- [ ] **Kink check:** put payoff at `S_T = K_PUT` equals `K_PUT × FC_AMT + FV_PREM_PUT` ($3,192,462)
- [ ] **Constancy check:** forward and money-market proceeds do not change across the grid
- [ ] **Grid check:** the core grid is symmetric around `S0_in`, driven by `STEP_FRAC`, with exactly 11 rows
- [ ] **No error cells**, and every output is a formula — no typed-in numbers
- [ ] §5.1 base-case and check figures reproduce within rounding, shown row by row on the Checks tab (§5.2)
- [ ] Checks tab: every row has a PASS/FAIL formula; failing checks show FAIL and are never forced to pass
- [ ] Cover provenance block records spot / forward / rate sources with access dates; no other tab stores a source
- [ ] Cell fill colors match the legend: <span style="background:#FFFF00;">yellow</span> inputs, <span style="background:#9BC2E6;">blue</span> assumptions, <span style="background:#D9D9D9;">gray</span> final outputs (strategy summary block, Sensitivity result columns and winner labels, Checks Result column), <span style="background:#C6EFCE;">green</span> every other formula

---

## 7. Sensitivity Plan

- **Grid:** `S_T_grid` spans `S0_in × (1 ± 5%)` in `STEP_FRAC` = 1% increments → 11 rows, 1.0599 to 1.1715, baseline at 1.1157.
- **Strategies plotted:** no hedge, forward, money market, put.
- **Primary chart:** line chart, `S_T` on the x-axis, USD proceeds on the y-axis. Forward and money-market lines are flat; no hedge is a straight upward line; the put is flat at $3,192,462 up to `K_PUT`, then rises with a kink at the strike.
- **Secondary table:** hedge profit vs. no hedge for each strategy.
- **Testing the Stage 1 hypothesis (put break-even near 1.18):** `BREAKEVEN_PUT_FWD` ≈ 1.1802 needs a 5.8% euro rise in 91 days, beyond the top grid row (1.1715). The strategy summary reports the break-even and the required move, and the optional extension block (§6.2, item 4) shows it on the chart.
- **What the chart should communicate:** the trade-off between **certainty** (forward / money market, flat lines), **optionality** (the put's kink, paid for by the premium), and **naked exposure** (no hedge, unbounded on both sides).

---

## 8. Limitations & Next Steps

**Limitations.** This specification does not incorporate:
- Partial / layered / dynamic hedging (static, full-notional hedge at t₀)
- Credit, counterparty, and settlement risk
- Implied-volatility-based option pricing (premia are scenario inputs, not Black-Scholes outputs)
- Accounting treatment (ASC 815 / IFRS 9 hedge accounting)
- Multi-currency or multi-horizon portfolio effects
- A live forward quote: `F0_in` is a stale placeholder until Stage 4

**Next steps — later stages will:** (a) build the workbook with AI help, using §4 as the instruction block and §6.2 as the improvement brief (Stage 3); (b) replace the placeholders with live data and a live or CIP-implied forward, commenting on the gap (Stage 4); (c) verify the model independently before the memo — a separate LLM run, a hand recomputation of the forward, money-market, and put figures, and a check of `F_IMPLIED` against a published bank quote, investigating any figure that differs by more than 0.5%; and (d) translate the sensitivity evidence into the Stage 5 decision memo to the CFO.

---

## Appendix A — Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 0.1 | 2026-11-06 | Vanessa Louie | Initial draft |
| 0.2 | 2026-11-06 | Vanessa Louie | Moved into the course spec template; adopted the negative-premium sign convention |
| 0.3 | 2026-11-06 | Vanessa Louie | Added the model review (§6.1–6.2) and corrected three points in it; added tab purposes to §5 and the validation rules to §6.3; removed the template's guidance sections |
| 0.4 | 2026-11-13 | Vanessa Louie | Aligned with the build contract: ten contract named ranges with exact Inputs cells; strikes as `=S0_in` formulas; fill-color legend (yellow inputs, blue assumptions, gray final outputs, green every other formula); call calculated for comparison only, with `CALL_NET` payoff and `USD_CALL` proceeds; `STEP_FRAC` (C15) and `FWD_SOURCE` toggle (C16) as named inputs, with `F_USED` feeding `USD_FWD` and `BREAKEVEN_PUT_FWD` while the parity check stays on `F0_in`; provenance moved to a single Cover block; added the Checks tab (§5.2) with yellow reference Expected values |
