# FX Hedging

This folder holds the FX transaction hedging capability for Scenario 34 (`erp-software`): a U.S. ERP-software firm hedging a EUR 2,900,000 receivable from a Dutch retailer, due in 91 days. `spec.md` is the build specification. It defines the named-range inputs, the calculation flow for the four strategies compared (no hedge, forward, money-market, and put option), the sensitivity grid, and the validation checks, in enough detail that the workbook can be built or rebuilt from it alone. `model.xlsx` is the workbook built from that spec.
