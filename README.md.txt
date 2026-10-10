# UPI-style Fraud Detection: SQL and Power BI Analysis

An analysis of 6.36 million synthetic mobile-payment transactions, to understand how fraud
happens and to design a simple rule that flags it. Built with MySQL, Excel and Power BI.

Note: the data is the PaySim synthetic dataset (a simulation of mobile money transactions),
not real UPI data.

![Dashboard](power%20bi/dashboard.png)

## Business question
The existing alarm in the data (is_flagged_fraud) caught almost no fraud. Can a simple,
explainable rule catch far more, without flooding reviewers with false alarms?

## Data
- Source: PaySim, "Synthetic Financial Datasets For Fraud Detection" (Kaggle)
- 6,362,620 transactions over 30 days (743 hourly steps), 8,213 of them fraud (0.13%)
- Loaded into MySQL (database upi_fraud, table transactions)

## Key findings
1. Fraud happens only in TRANSFER (4,097) and CASH_OUT (4,116). PAYMENT, CASH_IN and DEBIT have none.
2. TRANSFER has a higher fraud rate (0.77%) than CASH_OUT (0.18%).
3. Fraud transactions are about 4.7x larger on average, but amount alone does not separate them
   from genuine ones.
4. The existing flag caught only 16 of 8,213 frauds (0.19%).
5. 97.82% of fraud empties the sender's full balance in one transaction. No genuine
   transaction does this.
6. A single TRANSFER seems capped at 10,000,000. 145 of 148 frauds from larger balances sent
   exactly 10,000,000, which is why a "full balance" rule alone missed them.

## Rules compared
| Rule | Alerts | Fraud caught | False alarms | Recall | Precision | Fraud value caught |
|---|---|---|---|---|---|---|
| Existing flag | 16 | 16 | 0 | 0.19% | 100% | 0.65% |
| Big amount (> 1,000,000) | 130,507 | 2,706 | 127,801 | 32.95% | 2.07% | 86.76% |
| Rule 2 (below) | 8,163 | 8,163 | 0 | 99.39% | 100% | 99.76% |

Rule 2: flag a TRANSFER or CASH_OUT if (a) the amount equals the sender's full balance, or
(b) it is a TRANSFER of exactly 10,000,000 from an account holding more than 10,000,000.

Rule 2 missed 50 frauds: 25 where the sender balance was already 0, 16 with amount 0,
5 partial withdrawals and 4 where the amount was more than the balance.

## Business recommendation
Use Rule 2 as an automatic alert for TRANSFER and CASH_OUT. It needs about 263 reviews per day
and every alert in this data was real fraud. It stays worthwhile as long as reviewing one alert
costs less than about 1.47 million (dataset units). Other signals are needed for the
remaining 50 frauds.

## Limitations
- The data is synthetic, so a result with zero false alarms is unlikely on real data.
- Rule 2 was designed on the same data it was tested on, so real performance will be lower.
  A first-half vs second-half check was consistent (99.18% vs 99.61%) but is not a true
  out-of-sample test.
- Review cost (1,000 per alert) in the Excel comparison is an assumption, and net benefit
  assumes all caught fraud value is saved.
- The dataset has no currency, so amounts are in its own units.

## Repository contents
- sql/ : MySQL queries, one file per day of analysis
- notes/ : analysis notes and the rule comparison spreadsheet
- power bi/ : dashboard (.pbix), screenshot and the small CSV extracts it uses

## Tools
MySQL Workbench, Excel, Power BI Desktop

## Author
Vanshika
LinkedIn: [add your LinkedIn link here]