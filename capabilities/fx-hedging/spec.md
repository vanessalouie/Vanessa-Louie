# ERP Software Firm: FX Transaction Hedge Model · Technical Specification

| Field | Value |
|------|------|
| **Created by** | Vanessa Louie |
| **Updated by** | Vanessa Louie |
| **Date Created** | 2026-11-06 |
| **Date Updated** | 2026-11-06 |
| **Version** | 0.1 |
| **LLM Used** | Claude |
| **Scenario** | 34, `erp-software` |
| **Role / Audience** | Treasury Analyst / CFO |
| **Companion Workbook** | `capabilities/fx-hedging/model.xlsx` (to be built in Stage 3) |

---

## 1. Problem Statement

A U.S. ERP-software firm has invoiced a Dutch retailer EUR 2,900,000, due in 91 days. The quote convention is USD per EUR. A euro depreciation over that horizon would reduce realized USD proceeds, and the dollar amount is unknown until settlement. This specification defines how to quantify and compare four strategies (no hedge, forward hedge, money-market hedge, and put-option hedge) and to produce the sensitivity evidence behind the Stage 5 decision memo. The objective is to protect USD proceeds at an acceptable cost, while noting how much upside each strategy gives up. The decision context is the CFO of a corporate treasury function. The EUR call quote is carried in the inputs but unused, because a call hedges a payable, not this receivable.

## 2. Inputs: the Named-Range Contract

All inputs are workbook named ranges. Every value below is **indicative, replaced with live market data at Stage 4**, except `FC_AMT`, `T_DAYS`, and the option premiums, which are fixed by the scenario and kept at Stage 4.

| Name | Description | Placeholder | Unit | Stage 4 source |
|------|-------------|------------:|------|----------------|
| `FC_AMT` | EUR receivable | 2,900,000 | EUR | Fixed by scenario |
| `S0_in` | Spot at inception | 1.1157 (6 Nov 2026, intraday, PrimeXBT) | USD per EUR | Market close on the day of the Stage 4 refresh, e.g. Yahoo Finance EURUSD=X, with timestamp |
| `F0_in` | Forward rate, 91-day | 1.1653 (scenario's indicative quote, stale vs. market) | USD per EUR | Live bank/market forward, or the CIP-implied forward (see §5), with a comment on the gap |
| `R_USD` | USD rate, 91 days | 4.0669% (3-month CME Term SOFR, 5 Nov 2026, global-rates.com) | Annual %, ACT/360 | Same series, close of the refresh day |
| `R_FC` | EUR rate, 91 days | 2.812% (3-month Euribor, 5 Nov 2026, global-rates.com) | Annual %, ACT/360 | Same series, close of the refresh day |
| `T_DAYS` | Days to settlement | 91 | Days | Fixed by scenario |
| `K_PUT` | Put strike | = `S0_in` (1.1157) | USD per EUR | Set at the Stage 4 spot |
| `K_CALL` | Call strike | = `S0_in` (1.1157) | USD per EUR | Set at the Stage 4 spot; unused for a receivable |
| `PREM_PUT` | Put premium per EUR | 0.0147 | USD | Fixed by scenario (retail option quotes are unreliable) |
| `PREM_CALL` | Call premium per EUR | 0.0199 | USD | Fixed by scenario; unused |

Derived values: `DF_USD` = 1 + `R_USD` × `T_DAYS` / 360 and `DF_FC` = 1 + `R_FC` × `T_DAYS` / 360 (growth factors); `FV_PREM_PUT` = `PREM_PUT` × `FC_AMT` × `DF_USD` (premium carried to settlement, shown as a cost).

## 3. Tab Architecture

- **Cover:** title, scenario, author, version, date, and one-line purpose.
- **Legend/Key:** color legend (yellow inputs, blue assumptions, black formulas, gray outputs, green cross-tab links).
- **Inputs:** all ten named ranges, with units, source, and access timestamp beside each.
- **Forward:** the forward hedge calculation.
- **MoneyMarket:** the three-step money-market hedge, plus the implied forward and parity check.
- **Option:** the put hedge payoff for each settlement spot.
- **Sensitivity:** the settlement-spot grid, proceeds per strategy, hedge-profit columns, winner labels, and the comparison chart.
- **Notes & Assumptions:** sources with dates, assumptions, and the check results.

## 4. Assumptions & Constraints

- **Quote convention:** USD per EUR. A higher quote means the euro has strengthened.
- **Rate basis:** ACT/360 for both USD and EUR, using simple interest over `T_DAYS` (single `BASIS` of 360).
- **Parity expectation:** the money-market hedge should replicate the forward under covered interest parity. At Stage 4, a gap larger than rounding is a finding about the inputs, not a model error.
- **Premium treatment:** paid in USD at inception, quoted per EUR with no contract multiplier, and carried to settlement at `R_USD`.
- **Transaction costs, bid-ask spreads, credit and counterparty risk, tax and accounting:** excluded from the base case.
- **Scenario method:** settlement spot is varied deterministically across a grid, with no probabilities or volatility model.
- **Known placeholder problem:** the scenario's 1.1653 forward sits about 4% above the CIP-implied forward at current spot and rates (about 1.119). With these placeholders the parity check is expected to fail. This is recorded, not hidden, and Stage 4 resolves it.

## 5. Calculation Flow (named-range notation)

1. **Forward hedge.** USD proceeds equal `FC_AMT` × `F0_in`. This is locked in and the same at every settlement spot.
2. **Money-market hedge, three steps, each in its own cell.**
   - *Borrow EUR today:* `FC_AMT` divided by `DF_FC`, which sizes the loan so the receivable repays it exactly.
   - *Convert at spot:* the borrowed EUR times `S0_in`.
   - *Invest in USD:* the converted USD times `DF_USD`. The result is the locked-in proceeds.
3. **Implied forward and parity.** The implied forward is `S0_in` × `DF_USD` / `DF_FC`. It should be approximately `F0_in`.
4. **Put hedge.** Net proceeds at settlement spot S_T equal `FC_AMT` × the larger of S_T and `K_PUT`, minus `FV_PREM_PUT`.
5. **No hedge.** Proceeds equal `FC_AMT` × S_T.
6. **Hedge profit.** For each strategy, its proceeds minus the no-hedge proceeds, per row.
7. **Winner labels.** Per row, the strategy with the highest proceeds including no hedge, and the highest among the three active hedges.

## 6. Sensitivity Plan

- **Grid:** S_T from 0.95 × `S0_in` to 1.05 × `S0_in` in 1% steps, 11 rows, with the baseline row at S_T = `S0_in`.
- **Series:** no hedge, forward, money-market, put.
- **Chart:** one line chart with S_T on the x-axis and USD proceeds on the y-axis. Forward and money-market lines are flat, no-hedge is a straight line, and the put is flat to the strike, then rises with a kink at the strike.
- **What it should show the CFO:** the trade-off between certainty (flat lines), optionality (the put's kink, paid for by the premium), and naked exposure (no hedge). It should also show where the put overtakes the forward, if that point falls inside the grid. With the stale placeholder it will not, so the Notes tab states the break-even separately.

## 7. Validation Rules (check figures)

At the placeholders above, the finished workbook must reproduce these figures within rounding:

| Check | Expected |
|-------|---------:|
| `DF_USD` and `DF_FC` | 1.010280 and 1.007108 |
| Forward proceeds | $3,379,370 |
| EUR borrowed today | about 2,879,532 EUR |
| Money-market proceeds | about $3,245,721 |
| Implied forward | about 1.1192 |
| Put premium, then `FV_PREM_PUT` | $42,630, then about $43,068 |
| Put proceeds at or below the strike (floor) | about $3,192,462 |
| Put break-even vs. the placeholder forward | about 1.1802 |

Rules the workbook must pass:

- **Parity check:** money-market proceeds equal forward proceeds within 0.05% once Stage 4 inputs are live. With the placeholder forward, a gap of about 4.1% (about $133,649) is expected and must be flagged, not fixed.
- **Kink check:** put proceeds at S_T = `K_PUT` equal `K_PUT` × `FC_AMT` minus `FV_PREM_PUT`.
- **Constancy check:** forward and money-market proceeds do not change across the grid.
- **No error cells,** and every output is a formula, with no typed-in numbers.
- **Grid check:** the grid is symmetric around `S0_in` and has exactly 11 rows.
- **Formula check:** every formula uses named ranges, with no cell addresses in the logic.
- **Sources:** the Notes tab records the date and source of every input.

## 8. Outputs

| Output (named) | Description |
|----------------|-------------|
| `USD_FWD` | Forward-hedge proceeds |
| `USD_MM` | Money-market-hedge proceeds |
| `F_IMPLIED` | CIP-implied forward |
| `PARITY_GAP` | `USD_FWD` minus `USD_MM`, in USD and as a % |
| `FV_PREM_PUT` | Put premium carried to settlement |
| `USD_FLOOR_PUT` | Minimum put-hedge proceeds across the grid |
| `BREAKEVEN_PUT_FWD` | Settlement spot at which the put matches the forward |
| Sensitivity table | Proceeds and hedge profit per strategy across the grid |
| Winner labels | Overall winner and best active hedge per row |
| Comparison chart | Four lines, as in §6 |
| Base-case block | All four strategies at S_T = `S0_in`, used as the Stage 3 regression checkpoint |