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
| **Date Updated** | 2026-11-06 |
| **Version** | 0.2 |
| **LLM Used** (optional) | Claude: helped restructure my Stage 2 draft into the course template and recomputed the check figures; I reviewed every figure and section |
| **Scenario** | 34, `erp-software` |
| **Role** | Treasury Analyst |
| **Audience** | CFO |
| **Companion Workbook** | `capabilities/fx-hedging/model.xlsx` (to be built in Stage 3) |

---

## 1. Problem Statement

A U.S. ERP-software firm (functional currency USD) has invoiced a Dutch retailer EUR 2,900,000, settling in 91 days. Rates are quoted in USD per EUR, so a euro depreciation over the horizon would reduce realized USD proceeds, and the dollar amount is unknown until settlement. The objective is to protect USD proceeds at an acceptable cost, while showing how much upside each strategy gives up. This specification documents the framework used to quantify and compare four strategies — **no hedge**, **forward hedge**, **money-market hedge**, and **option (put) hedge** — and to produce the sensitivity evidence behind the Stage 5 decision memo to the CFO of the corporate treasury function. The EUR call quote is carried in the inputs but unused, because a call hedges a payable, not this receivable.

---

## 2. Inputs (Known Variables)

All inputs are exposed as workbook **named ranges** so the Calculation Flow (§4) reads the same whether implemented in Excel, Python, or an AI prompt. Dates, sources, and access timestamps are recorded in the Notes tab. Every market value below is **indicative and replaced with live data at Stage 4**, except `FC_AMT`, `T_DAYS`, and the option premiums, which are fixed by the scenario.

### 2.1 Core Inputs

| Standardized Name | Description | Unit | Value (placeholder) | Stage 4 source |
|-------------------|-------------|------|--------:|----------------|
| `FC_AMT` | EUR receivable | EUR | 2,900,000 | Fixed by scenario |
| `S0_in` | Spot exchange rate at inception | USD per EUR | 1.1157 | 6 Nov 2026 intraday, PrimeXBT; refresh at market close on the Stage 4 day (e.g., Yahoo Finance EURUSD=X), with timestamp |
| `F0_in` | 91-day forward rate | USD per EUR | 1.1653 | Scenario's indicative quote (stale vs. market); replace with a live bank/market forward or the CIP-implied forward, with a comment on the gap |
| `R_USD` | USD interest rate to settlement | Annual %, ACT/360 | 4.0669% | 3-month CME Term SOFR, 5 Nov 2026, global-rates.com; same series at Stage 4 |
| `R_FC` | EUR interest rate to settlement | Annual %, ACT/360 | 2.812% | 3-month Euribor, 5 Nov 2026, global-rates.com; same series at Stage 4 |
| `T_DAYS` | Days to settlement | Days | 91 | Fixed by scenario |
| `BASIS` | Day-count denominator (single value) | Days | 360 | Both legs are ACT/360 (SOFR and Euribor), so one `BASIS` is exact here |
| `K_PUT` | Put option strike (receivable) | USD per EUR | 1.1157 (= `S0_in`) | Reset to the Stage 4 spot |
| `K_CALL` | Call option strike (payable; unused) | USD per EUR | 1.1157 (= `S0_in`) | Reset to the Stage 4 spot |
| `PREM_PUT` | Put premium, USD per 1 EUR | USD | 0.0147 | Fixed by scenario (retail option quotes are unreliable) |
| `PREM_CALL` | Call premium, USD per 1 EUR (unused) | USD | 0.0199 | Fixed by scenario |
| `STEP_FRAC` | Sensitivity grid step | % of `S0_in` | 1% | Assumption (blue cell) |

### 2.2 Derived / Intermediate Values

| Name | Description | Source | Placeholder value |
|------|-------------|--------|------:|
| `DF_USD` | USD growth factor to settlement | `1 + R_USD × T_DAYS / BASIS` | 1.010280 |
| `DF_FC` | EUR growth factor to settlement | `1 + R_FC × T_DAYS / BASIS` | 1.007108 |
| `FV_PREM_PUT` | Future value of put premium at settlement (negative = cost) | `−PREM_PUT × FC_AMT × DF_USD` | −$43,068 |
| `FV_PREM_CALL` | Future value of call premium at settlement (unused) | `−PREM_CALL × FC_AMT × DF_USD` | — |
| `F_IMPLIED` | CIP-implied forward | `S0_in × DF_USD / DF_FC` | 1.1192 |
| `S_T_grid` | Sensitivity spot grid at settlement | `S0_in × (1 + i × STEP_FRAC)`, i = −5 … +5 | 1.0599 … 1.1715 |
| `USD_NO_HEDGE` | USD proceeds under no hedge | `S_T × FC_AMT` | per row |

---

## 3. Assumptions & Constraints

- **Quote convention:** All rates are **USD per EUR**. A higher quote means the euro has strengthened.
- **Horizon:** Single-maturity model; `T_DAYS = 91`.
- **Day-count basis:** Simple interest over the period, `r × T_DAYS / BASIS`. Both 3-month SOFR and 3-month Euribor are quoted ACT/360, so the single `BASIS = 360` is exact for this scenario and no `BASIS_USD` / `BASIS_FC` split is needed.
- **Parity:** The money-market hedge is expected to replicate the forward under covered interest-rate parity (CIP). At Stage 4, a gap larger than rounding is a finding about the inputs, not a model error.
- **Known placeholder problem:** The scenario's 1.1653 forward sits about 4% above the CIP-implied forward at current spot and rates (1.1192). With these placeholders the parity check is expected to fail. This is recorded, not hidden, and Stage 4 resolves it.
- **Option premium:** Paid upfront in USD, quoted per 1 EUR (no contract multiplier). Premia are a **negative cash flow** at t₀, carried forward at `R_USD` to settlement.
- **Counterparty / credit risk:** Excluded. All derivatives assumed frictionless and creditworthy.
- **Transaction costs & bid-ask spreads:** Excluded from the base case.
- **Tax / accounting treatment:** Excluded. Pre-tax cash outcomes only.
- **Scenario construction:** Settlement spot `S_T` is varied deterministically across a grid; no probabilities and no volatility model.

---

## 4. Calculation Flow

Named-range pseudocode for the **receivable** exposure. Each numbered sub-step lives in its own cell.

### Step 1 — Derived inputs

1. `DF_USD` = `1 + R_USD × T_DAYS / BASIS` *(growth factor, not a fractional discount factor)*
2. `DF_FC` = `1 + R_FC × T_DAYS / BASIS`
3. `FV_PREM_PUT` = `−PREM_PUT × FC_AMT × DF_USD`

### Step 2 — Forward hedge (certainty benchmark)

- `USD_FWD` = `FC_AMT × F0_in`
- Locked in at t₀; the same at every `S_T` on the grid.

### Step 3 — Money-market hedge (parity check)

1. Borrow `FC_AMT / DF_FC` EUR today *(sized so the receivable repays the loan exactly)*.
2. Convert to USD at spot: `(FC_AMT / DF_FC) × S0_in`.
3. Invest the USD to maturity: `USD_MM` = `(FC_AMT / DF_FC) × S0_in × DF_USD`.
4. `F_IMPLIED` = `S0_in × DF_USD / DF_FC`.
5. `PARITY_GAP` = `USD_FWD − USD_MM`, in USD and as a % of `USD_MM`.

> **Parity check:** `USD_MM ≈ USD_FWD` within 0.05% once Stage 4 inputs are live. With the placeholder forward, a gap of about 4.1% ($133,649) is expected and must be flagged, not fixed.

### Step 4 — Option hedge (floor with upside)

Put-and-hold on the receivable:

- Pay `PREM_PUT × FC_AMT` USD today for a EUR put with strike `K_PUT`.
- At settlement, for each `S_T` on the grid:
  - `USD_PUT(S_T)` = `MAX(S_T, K_PUT) × FC_AMT + FV_PREM_PUT`
- `BREAKEVEN_PUT_FWD` = `F0_in − FV_PREM_PUT / FC_AMT` *(settlement spot at which the put matches the forward; ≈ 1.1802 at placeholders)*

### Step 5 — Sensitivity table (rows of the grid)

For each `S_T` in `S_T_grid`:

| Column | Output | Formula |
|--------|--------|---------|
| No hedge | `USD_NO_HEDGE(S_T)` | `S_T × FC_AMT` |
| Forward | `USD_FWD` | constant across rows |
| Money market | `USD_MM` | constant across rows |
| Option (put) | `USD_PUT(S_T)` | `MAX(S_T, K_PUT) × FC_AMT + FV_PREM_PUT` |
| Hedge profit | `HEDGE_PROFIT_k(S_T)` | `USD_k − USD_NO_HEDGE` for each `k ∈ {forward, money market, option}` |
| Overall winner (incl. no hedge) | label | `ARGMAX(USD_NO_HEDGE, USD_FWD, USD_MM, USD_PUT)` |
| Best active hedge (excl. no hedge) | label | `ARGMAX(USD_FWD, USD_MM, USD_PUT)` |

### Step 6 — Summary metrics (scalar outputs)

- `USD_FLOOR_PUT` = `MIN(USD_PUT)` across `S_T_grid`
- `USD_BASE_k` = `USD_k` at `S_T = S0_in` for each strategy (feeds §5.1)

### Step 7 — Payable variant

Not built. This scenario is a receivable only; `K_CALL`, `PREM_CALL`, and `FV_PREM_CALL` are carried for completeness and not used in any output.

---

## 5. Outputs

**Tab architecture:** Cover · Legend/Key · Inputs · Forward · MoneyMarket · Option · Sensitivity · Notes & Assumptions.

| Output | Description | Format | Purpose |
|--------|-------------|--------|---------|
| Input panel | All §2.1 named ranges with units, sources, and access timestamps | Inputs tab | Single source of truth |
| Strategy summary | `USD_FWD`, `USD_MM`, `F_IMPLIED`, `PARITY_GAP`, `FV_PREM_PUT`, `USD_BASE_k`, `USD_FLOOR_PUT`, `BREAKEVEN_PUT_FWD` | Table above sensitivity grid | Executive at-a-glance |
| Sensitivity table | USD proceeds per strategy across `S_T_grid` ± 5% | Sensitivity tab | Core analytical evidence |
| Hedge-profit columns | `USD_k − USD_NO_HEDGE` per strategy per row | Sub-table | Isolates hedge value-add |
| Winner / best-hedge labels | `ARGMAX` labels per row | Two label columns | Quick-read decision cue |
| Sensitivity chart | Line chart of USD proceeds vs. `S_T`, four strategies | Embedded chart | Visual comparison |
| Executive summary (Stage 5 decision memo) | 1–2 paragraph narrative with explicit recommendation | Separate memo | Downstream deliverable |

### 5.1 Computed Base-Case Values

At `S_T = S0_in = 1.1157`, placeholder inputs. Regression checkpoint for Stage 3; recompute at Stage 4.

| Strategy | USD Proceeds (Receivable) | USD Outlay (Payable) | Hedge Profit vs. No Hedge |
|----------|--------------------------:|---------------------:|--------------------------:|
| No hedge | $3,235,530 | n/a | — |
| Forward | $3,379,370 | n/a | +$143,840 |
| Money market | $3,245,721 | n/a | +$10,191 |
| Option (put) | $3,192,462 | n/a | −$43,068 |

Supporting check figures: `DF_USD` 1.010280 · `DF_FC` 1.007108 · EUR borrowed today 2,879,532 · USD at spot $3,212,694 · `F_IMPLIED` 1.1192 · put premium paid $42,630 · `FV_PREM_PUT` −$43,068 · `USD_FLOOR_PUT` $3,192,462 · `BREAKEVEN_PUT_FWD` 1.1802.

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
   - **Consequence for the grid:** with the stale forward, the forward beats the put and the money-market hedge at almost every grid row, so the sensitivity results would mislead.
   - **Consequence for the break-even:** the put-versus-forward break-even is about 1.1802 against the placeholder forward, but about 1.1341 against the money-market proceeds. The Stage 1 hypothesis of "near 1.18" depends on the stale quote.
   - **Action item (Stage 3):** add a forward-source toggle in the Inputs tab to choose between the quoted forward and `F_IMPLIED`. The parity check must always run against the quoted forward, so the toggle cannot hide the gap.
   - **Action item (Stage 4):** replace the placeholder with a live forward or the CIP-implied one, and comment on the gap. Until then, label every forward-based output as a placeholder, and do not base the Stage 5 recommendation on it.
2. **Spot is intraday, not a close.** 1.1157 was an intraday level on November 6. **Action item:** replace it with the close, then recompute the strikes, §5.1, and the check figures in §6.3.
3. **The two rates are different benchmarks.** 3-month Term SOFR is a secured rate and 3-month Euribor is an unsecured one, and neither is exactly 91 days or the firm's own borrowing cost. Part of any parity gap could come from this mismatch. **Action item:** record the benchmarks in the Notes tab and test the sensitivity to them at Stage 4.
4. **The grid does not reach the break-even.** The ±5% grid (about 1.0599 to 1.1715) stops short of `BREAKEVEN_PUT_FWD` (about 1.1802, roughly +5.8% above spot). **Action item:** add optional rows up to +6% and +7% beyond the 11-row core grid, and state the break-even in the output summary, so the CFO can see how large a euro rally the put needs to beat the forward.
5. **Frictions and fixed premiums are not modeled.** Net proceeds assume no bid-ask spreads or borrowing premiums, and option premiums are fixed scenario inputs, so they do not adjust if implied volatility changes. **Action item:** add optional cost inputs if time allows, and state both as limitations in the Stage 5 memo (see §8).

### 6.3 Auditability Checklist

- [ ] Every input has a standardized named range from §2.1
- [ ] Every formula in §4 uses named ranges — no bare `$F$n` references
- [ ] Money-market hedge ties to forward hedge within 0.05% (parity check) — expected to **fail** at placeholders (≈4.1%); must pass with Stage 4 inputs
- [ ] Put payoff at `S_T = K_PUT` equals `K_PUT × FC_AMT + FV_PREM_PUT` (kink verification: $3,192,462)
- [ ] Forward and money-market proceeds are constant across the grid
- [ ] Sensitivity grid is symmetric around `S_T = S0_in`, has exactly 11 rows, and is driven by `STEP_FRAC`
- [ ] No error cells; every output is a formula, no typed-in numbers
- [ ] Notes tab records spot / forward / rate sources with access dates
- [ ] Cell colors match the legend: <span style="background:#FFFF00;">yellow</span> inputs, <span style="color:#0000FF;">blue</span> assumptions, black formulas, gray outputs, <span style="color:#024731;">green</span> cross-tab links

---

## 7. Sensitivity Plan

- **Grid:** `S_T_grid` spans `S0_in × (1 ± 5%)` in `STEP_FRAC` = 1% increments → 11 rows, 1.0599 to 1.1715, baseline row at 1.1157.
- **Strategies plotted:** no hedge, forward, money market, put.
- **Primary chart:** line chart, `S_T` on the x-axis, USD proceeds on the y-axis. Forward and money-market lines are flat; no-hedge is a straight upward line; the put is flat at $3,192,462 up to the strike, then rises with a kink at `K_PUT`.
- **Secondary table:** hedge profit vs. no hedge for each strategy.
- **Testing the Stage 1 hypothesis (put break-even near 1.18):** `BREAKEVEN_PUT_FWD` ≈ 1.1802 requires a 5.8% euro rise from 1.1157 in 91 days, which lies **outside** the ±5% grid (top row 1.1715). The strategy summary and Notes tab therefore report the break-even and the required move separately, and the Stage 5 memo comments on how likely that move is.
- **What the chart should communicate:** the trade-off between **certainty** (forward / money-market, flat lines), **optionality** (the put's kink, paid for by the premium), and **naked exposure** (no hedge, unbounded on both sides).

---

## 8. Limitations & Next Steps

**Limitations.** This specification does not incorporate:
- Partial / layered / dynamic hedging (static, full-notional hedge at t₀)
- Credit, counterparty, and settlement risk
- Implied-volatility-based option pricing (premia are scenario inputs, not Black-Scholes outputs)
- Accounting treatment (ASC 815 / IFRS 9 hedge accounting)
- Multi-currency or multi-horizon portfolio effects
- A live forward quote: `F0_in` is a stale placeholder until Stage 4

**Next steps:** (a) build and audit the workbook with AI help using §4 as the instruction block and §6.2 as the improvement brief (Stage 3); (b) replace the placeholders with live market data and a live or CIP-implied forward, commenting on the gap (Stage 4); (c) verify the model independently before the memo — a separate LLM run plus a hand recomputation of the forward, money-market, and put figures, and a check of `F_IMPLIED` against a published bank quote, investigating any figure that differs by more than 0.5%; and (d) translate the sensitivity evidence into the Stage 5 decision memo to the CFO.

---

## 9. How This Sets Up Stages 3–5

| What's Written in Stage 2 | What It Enables in Stages 3–5 |
|---------------------------|----------------------------|
| Standardized named ranges with precise definitions | AI uses standardized variable names; no improvisation |
| Step-by-step calculation flow | AI generates correct, auditable hedge formulas |
| Model review and improvement notes (§6.2) | AI builds the *improved* version, not just a replica |
| Explicit output requirements + chart spec | AI produces the exact tables, chart, and memo sections needed |
| Base-case output values (§5.1) | Regression checkpoints for the refined model |

---

## Appendix A — Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 0.1 | 2026-11-06 | Vanessa Louie | Initial draft |
| 0.2 | 2026-11-06 | Vanessa Louie | Restructured into the course spec template; adopted the template's negative-premium sign convention; added `BASIS`, `STEP_FRAC`, and the break-even test to the sensitivity plan |
