---
type: brief
engagement: fx-hedging
capability: fx-hedging
title: "ERP Software EUR Receivable: FX Hedging Executive Brief"
scenario: erp-software
date: 2026-10-30
status: committed
hypothesis: "I expect the forward and money-market hedge to lock in nearly identical USD proceeds because interest rate parity ties them together, and the put to be the costliest protection because its $42,630 premium is paid regardless, so it beats the forward only if EURUSD finishes near 1.18 or higher."
llm_used: "Claude"
---

# ERP Software EUR Receivable: FX Hedging Executive Brief

**Created by:** [Vanessa Louie]  
**Updated by:** [Vanessa Louie]  
**Date Created:** 2026-10-30  
**Date Updated:** 2026-10-30  
**Version:** 0.2  
**LLM Used:** Claude

---

## Executive Summary

We have invoiced a Dutch retailer EUR 2,900,000, payable in 91 days. The euro amount is fixed, but the dollar amount is not. At the indicative forward rate of 1.1653 the payment is worth $3,379,370, yet a 5% fall in the euro would cost us about $169,000, and a 10% fall about $338,000. This brief names the exposure and the plan; it recommends nothing yet.

---

## Background & Objectives

**The exposure.** Currency: EUR. Amount: 2,900,000. Timing: 91 days. We are hurt when the euro weakens.

**The objective.** Decide whether to hedge, and with what. There are three families of tools:

- **Forward:** sell EUR today at a locked rate for the settlement date. *Pro:* complete certainty, with proceeds fixed at $3,379,370 at the quoted 1.1653. *Con:* we give up all upside if the euro strengthens.
- **Money-market hedge:** borrow euros today, convert them at spot, and invest the dollars until the receivable arrives. It is a forward built from interest rates. *Pro:* same certainty, even if forwards are mispriced. *Con:* uses borrowing capacity and has more moving parts.
- **Put option on EUR (strike at spot):** the right, not the obligation, to sell euros. *Pro:* a floor under proceeds with upside preserved. *Con:* the premium of $0.0147 per EUR, or $42,630 in total, is paid up front whether or not it is used.

Think of the put as insurance: you pay the premium hoping to waste it.

---

## Methods

I will build one workbook that prices all three hedges side by side across settlement rates, using sourced, timestamped data for spot and 3-month USD and EUR interest rates. I will also check the 1.1653 forward against the rate those interest rates imply.

**What I am assuming.** The receivable is certain in size and date. Interest is simple over 91 days. The 1.1653 forward is an indicative placeholder until Stage 4, while the option premiums are given and stay fixed, since retail option quotes are unreliable. Fees and credit risk are ignored, though I would test them with more time.

**Hypothesis.** I expect the forward and money-market hedge to lock in nearly identical USD proceeds because interest rate parity ties them together. I expect the put to be the costliest protection because its $42,630 premium is paid regardless, so, with spot at or below about 1.18, it beats the forward only if EURUSD finishes near 1.18 or higher.

**How I would know I was wrong.** Two results would prove me wrong. First, money-market proceeds differing from the $3,379,370 forward by more than about 0.5% (roughly $17,000), or an interest-implied forward more than 0.5% from 1.1653, would mean parity is not what decides the hedges. Second, the put beating the forward at any rate well below 1.18 would mean my premium logic is off.

---

## Limitations & Next Steps

**Limitations:** Spot and both interest rates come from the market close on the day I begin Stage 2, with date and source recorded. The quoted call on EUR stays out, because it protects a payable, not a receivable. I could also be wrong if spot sits above 1.18, which would move the put's break-even.

**Next Steps:** I will write the model plan (Stage 2), build and audit the Excel workbook with AI help (Stage 3), replace the placeholders with live market data and a live or CIP-implied forward, commenting on the gap (Stage 4), and write the final recommendation in a decision memo (Stage 5). A process is coming, not a gut call.

---

## References

Stauffer, A. (2026). *FX Hedging, Stage 1: Executive Brief*. Kumu, Finance & Securities. https://adamwstauffer.github.io/ai-lms/fx-hedging-stage1.html

Stauffer, A. (2026). *template-decision-memo.md* [Template]. GitHub. https://github.com/adamwstauffer/shidler/blob/main/courses/International-Finance-And-Securities/projects/fx-hedging/_templates/template-decision-memo.md

Stauffer, A. (2026). *Scenario 34: erp-software* [Scenario assignment]. GitHub. https://github.com/adamwstauffer/shidler/blob/main/courses/International-Finance-And-Securities/projects/fx-hedging/scenarios.md