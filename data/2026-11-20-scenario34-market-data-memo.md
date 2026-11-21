# Market-Data Memo: EUR Receivable Hedge (Scenario 34)

| Field | Value |
|---|---|
| Author | Vanessa Louie |
| Date | 2026-11-20 |
| Workbook | capabilities/fx-hedging/model.xlsx (built from spec v0.7) |
| Data retrieved | 20 Nov 2026, about 12:30–13:00 HST (22:30–23:00 GMT) |

## 1. Purpose

This memo records every market input I loaded into the FX hedging workbook for Stage 4: where it came from, when it was quoted, when I pulled it, and the reasoning behind any proxy. It is written for an auditor or reviewer who wants to re-pull each number and get the same result. It also explains why the bank's forward does not agree with covered interest parity, and which workbook fixes were needed once live data replaced the Stage 2 placeholders.

## 2. Inputs and provenance

| Input | Value | Source | Rate/quote date | Retrieved | Notes / proxy logic |
|---|---|---|---|---|---|
| S0_in (spot) | 1.0975 USD/EUR | Yahoo Finance EURUSD=X, https://finance.yahoo.com/quote/EURUSD=X/ | 20 Nov 2026 22:29:46 GMT | same | Delayed quote, taken after the 17:00 New York close; Yahoo still showed "Market Open" |
| F0_in (forward) | 1.1653 USD/EUR | Bank's quote (scenario forward, 91 days) | Scenario | n/a | Kept as the bank's quote; no requote received |
| R_USD | 4.20063% | 3-month CME Term SOFR, https://www.global-rates.com/en/ | 19 Nov 2026 | ~13:00 HST 20 Nov 2026 | Latest available at access |
| R_FC | 2.847% | 3-month Euribor, https://www.global-rates.com/en/ | 19 Nov 2026 | ~13:00 HST 20 Nov 2026 | Latest available at access |
| K_PUT, K_CALL | 1.0975 | Formula =S0_in | n/a | n/a | At the money, per the scenario |
| PREM_PUT | 0.0147 USD per EUR | Scenario | n/a | n/a | Assumption: see §5 |
| PREM_CALL | 0.0199 USD per EUR | Scenario | n/a | n/a | Assumption: see §5 |
| FC_AMT | EUR 2,900,000 | Scenario | n/a | n/a | |
| T_DAYS | 91 | Scenario | n/a | n/a | |

## 3. Rate choice

- **R_USD = 3-month Term SOFR.** Its 3-month tenor matches the 91-day receivable and the 91-day forward. It is the standard USD reference rate since LIBOR ended.
- **R_FC = 3-month Euribor.** It has the same 3-month tenor, and it is the main EUR money-market reference rate.

The project instructions call for 1-year rates. I used 3-month rates because covered interest parity only holds when the interest period matches the forward's maturity. Discounting a 91-day cash flow at a 1-year rate would mix two different points on the yield curve. I chose reference rates (Term SOFR, Euribor) over government bills because they are closer to the rates a bank uses to price forwards, and both are published daily for the exact 3-month tenor. The weakness is that the two rates are not built the same way (spec §6.2 item 3). SOFR is a secured overnight repo rate compounded into a term rate, while Euribor is an unsecured interbank rate, so Euribor carries some bank credit risk that SOFR does not. Even so, the choice does not change the parity conclusion. A 0.25-point change in the rate gap moves the implied forward by about 0.0007, or about $2,000 on the receivable, against a $185,807 gap.

## 4. Bank's forward vs. CIP-implied forward

| | Value |
|---|---|
| USD growth factor (DF_USD) | 1.010618 |
| EUR growth factor (DF_FC) | 1.007197 |
| CIP-implied forward | 1.1012 |
| Bank's quote (F0_in) | 1.1653 |
| Gap as a rate | 0.0641 USD per EUR (5.82%) |
| Forward hedge proceeds | $3,379,370 |
| Money-market hedge proceeds | $3,193,563 |
| Gap in USD on the receivable | $185,807 |
| Stage 2 gap, for comparison | $133,649 (4.1%) |

Interpretation: at today's spot and rates, covered interest parity puts the 91-day forward at 1.1012. The bank's quote is 1.1653, 5.82% higher. A gap that size would be a large arbitrage opportunity if it were real. Real CIP deviations between major currencies are measured in basis points, not percent, so I treat the quote as stale rather than as a genuine market price. It was set for the scenario when spot was higher, and it has not been updated since. The gap grew from $133,649 to $185,807 (+$52,158) almost entirely because spot fell 1.6%, from 1.1157 to 1.0975, while the quote stayed fixed. The lower spot accounts for about +$52,959 of the change. The slightly wider rate gap pulled the implied forward up a little, offsetting about $801. [TODO: choose one: "I have requested a requote from the bank" / "I have not yet requested a requote."] Until a requote arrives, I am keeping the bank's quote so the workbook stays consistent with the scenario. **Caution for Stage 5:** the forward hedge comes out best in every row of the sensitivity grid only because of this gap. With a forward near the CIP value (~1.1012), the forward and money-market hedges would give almost the same proceeds, and the comparison with the options would change. The Stage 5 recommendation should not be "use the forward" on the strength of this quote alone.

## 5. Assumption: option premiums

The put and call premiums (0.0147 and 0.0199 USD per EUR) are kept from the scenario because the retail option quotes I could find are delayed, wide, or not available for this strike and tenor. These premiums do not update for the new spot, the at-the-money strike of 1.0975, or current volatility, so the option costs in the workbook are scenario assumptions, not live market prices. A real at-the-money premium at today's spot could be noticeably different.

## 6. What changed since Stage 2

| Input | Stage 2 placeholder | Stage 4 live | Change |
|---|---|---|---|
| Spot | 1.1157 (6 Nov, intraday) | 1.0975 (20 Nov) | −1.6% |
| R_USD | 4.0669% | 4.20063% | +0.13 pts |
| R_FC | 2.812% | 2.847% | +0.035 pts |
| Forward | 1.1653 | 1.1653 | unchanged |

## 7. Structural fixes (what broke when live data loaded)

1. **Checks Expected values.** 17 Checks rows failed after the live data loaded. Their Expected values were typed-in Stage 2 figures, so they no longer matched the new outputs, even though the formulas were correct. I fixed this by retyping each Expected value from my own hand recomputation with the live inputs. I deliberately did not make them formulas: an Expected value that links to the model would always agree with it, so the check would test nothing.
2. **Chart x-axis.** The axis minimum was fixed at 1.05, but the live grid starts at 1.0426 (spot −5%), so the bottom row was cut off the chart. I fixed this by setting the axis bounds to automatic.
3. **Extension rows.** The +6% and +7% extension rows stopped at 1.1743, short of the 1.1802 break-even where the put hedge catches up with the forward (1.1653 + the put premium's future value of about 0.0149). I fixed this by adding a +8% row (1.1853), so the crossover is now visible.
4. **Placeholder labels.** I replaced the "Placeholder" labels on the Cover, Forward, Sensitivity, Checks and Notes sheets, and updated the Cover provenance block with the sources and dates in §2.
5. **Forward-source toggle (earlier).** Following instructor feedback, I removed the forward-source toggle in spec v0.6, so the workbook uses one forward input (F0_in).

I updated the build script with all of these changes, so a rebuild from spec v0.7 reproduces the live workbook rather than the Stage 2 version.

## 8. Checks after loading live data

Before I retyped the Expected values, 18 of 27 checks failed: the 17 stale Expected values plus the parity check. After retyping, 26 of 27 pass, and 1 still fails: the covered-interest-parity check. The bank's forward differs from the CIP-implied forward by 5.82%, against a tolerance of 0.05%. I have **not** loosened the tolerance or changed the check to make it pass. The failure is the correct result: it flags the stale bank quote described in §4, and it should stay red until the bank requotes.

## 9. FX Hedging Lab cross-check

| Output | Workbook | FX Lab | Match? |
|---|---|---|---|
| Forward hedge proceeds | $3,379,370 | $3,379,370 | Yes |
| Money-market proceeds | $3,193,563 | $3,193,563 | Yes |
| CIP-implied forward | 1.1012 | 1.1012 | Yes |
| Put premium | −$43,083 (FV at settlement) | −$42,630 (face value) | No: convention difference, $453 |
| Put proceeds at spot (floor) | $3,139,667 | $3,140,120 | No: same $453 |

The forward, money-market and CIP-implied forward outputs match exactly. The two put rows differ by $453, and neither value is wrong: the Lab and the workbook treat the premium differently. The Lab subtracts the premium at face value (FC_AMT × PREM_PUT = $42,630). The workbook carries the premium forward to settlement at R_USD ($42,630 × 1.010618 = $43,083), because the premium is paid today and the proceeds arrive in 91 days. I found this when the Lab's put floor ($3,140,120 in every row at or below the strike) came out $453 above the workbook's, which is exactly the 91 days of interest on the premium. I am keeping the future-value treatment in the workbook because it compares cash flows at the same date. The only effect is to move the put/forward break-even slightly, from 1.1800 (face value) to 1.1802 (future value).

The Lab's parity check also failed, with the same gap of −$185,807. The Lab's message says a gap like this usually means a formula error. Because the Lab and the workbook calculate the money-market hedge independently and get the same $3,193,563, the gap is not a workbook formula error. It comes from the bank's quoted forward (see §4). The Lab's sensitivity grid also shows the forward as the best hedge in all eleven rows, which is the same stale-quote effect flagged for Stage 5.

## 10. Open items for Stage 5

- **Bank requote.** Get a current 91-day forward from the bank. If it lands near 1.1012, rerun the comparison and expect the parity check to pass.
- **Option premiums.** Decide whether to keep the scenario premiums or reprice them at the new at-the-money strike (for example with Garman-Kohlhagen and a stated volatility).
- **Recommendation framing.** Don't recommend the forward on the strength of the stale-quote gap alone (see §4).
- **Spot timestamp.** Note that the spot was pulled at 22:29 GMT on a Friday, after the weekly FX close, so it is effectively the week's closing price. Re-pull it on the day the Stage 5 analysis is finalized.

## AI use

Claude (Anthropic) recomputed the parity and hedge figures as a check, helped populate the workbook with the live inputs, helped diagnose and fix the structural issues in §7, and drafted this memo's skeleton. I verified every Expected value in the Checks sheet myself, cross checked the values with the FX Heding Lab and I reviewed and edited the memo.