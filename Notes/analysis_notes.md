# UPI Fraud SQL Project - Notes (Day 1 to Day 7)

Date: 04-10-2026
Tool: MySQL Workbench | Database: `upi_fraud` | Table: `transactions`

---

## Day 1 - Setup and data load

**Dataset**

* Name: PaySim, "Synthetic Financial Datasets For Fraud Detection" (Kaggle)
* File: `PS_20174392719_1491204439457_log.csv` (about 482 MB)
* Saved in: `upi-fraud-sql-projectData`

**Table structure (11 columns)**

|Column|Type|Meaning|
|-|-|-|
|step|INT|1 step = 1 hour (30 days in total)|
|type|VARCHAR(20)|PAYMENT, TRANSFER, CASH_OUT, CASH_IN, DEBIT|
|amount|DECIMAL(14,2)|Transaction amount|
|name_orig  name_dest|VARCHAR(20)|Sender  receiver|
|oldbalance_org, newbalance_orig|DECIMAL(14,2)|Sender balance before  after|
|oldbalance_dest, newbalance_dest|DECIMAL(14,2)|Receiver balance before  after|
|is_fraud|SMALLINT|1 = fraud, 0 = genuine|
|is_flagged_fraud|SMALLINT|1 = the dataset's own system flagged it|

**Load result**

* Method: `LOAD DATA LOCAL INFILE` (needed `OPT_LOCAL_INFILE=1` in the connection and `SET GLOBAL local_infile = 1`)
* Rows loaded: **6,362,620**
* Skipped: 0 | Warnings: 0 | Time: about 104 seconds

**First finding**

* Total fraud: **8,213** (about 0.13% of all transactions)
* Fraud happens only in TRANSFER (4,097) and CASH_OUT (4,116)
* PAYMENT, CASH_IN and DEBIT have zero fraud

---

## Day 2 - Exploring the data

### 1. Fraud rate by type (TRANSFER and CASH_OUT only)

|Type|Total transactions|Fraud|Fraud rate|
|-|-|-|-|
|TRANSFER|532,909|4,097|0.77%|
|CASH_OUT|2,237,500|4,116|0.18%|

* Fraud counts are almost equal, but TRANSFER's fraud rate is about **4x higher** than CASH_OUT's.
* CASH_OUT has about 4x more transactions, so fraud is spread thinner there.

### 2. Fraud vs genuine amounts (TRANSFER and CASH_OUT only)

||Transactions|Average amount|Max amount|
|-|-|-|-|
|Fraud|8,213|1,467,967.30|10,000,000.00|
|Genuine|2,762,196|314,115.50|92,445,516.64|

* Average fraud amount is about **4.7x** the average genuine amount.
* Fraud max is exactly 10,000,000, which looks like a cap in the data. Genuine goes much higher.
* So a simple "big amount = fraud" rule would raise many false alarms.

### 3. Existing system flag vs actual fraud

|is_flagged_fraud|is_fraud|Rows|Meaning|
|-|-|-|-|
|0|0|6,354,407|Genuine, not flagged|
|0|1|8,197|Fraud, system missed it|
|1|1|16|Fraud, system caught it|

* System caught **16 of 8,213** frauds (about 0.19%).
* System missed **8,197** (about 99.81%).
* No genuine transaction was flagged (no row with flagged = 1 and fraud = 0).

### 4. Basic checks (fill in from your Workbench results)

* Transaction count by type: CASH_OUT 2,237,500; PAYMENT 2,151,495; CASH_IN 1,399,284; TRANSFER 532,909; DEBIT 41,432
* Step range (min to max): 1 to 743 
* Rows with NULL in amount or type: 0

---

## Key findings so far

1. Fraud is rare: 8,213 out of 6,362,620 (about 0.13%).
2. Fraud exists only in TRANSFER and CASH_OUT.
3. TRANSFER is riskier per transaction (0.77% vs 0.18%).
4. Fraud amounts are much larger on average (about 4.7x), but amount alone cannot separate fraud from genuine.
5. The existing flag system is very weak: it caught only 16 of 8,213 frauds.


## Open questions (answered in later days)
- Do fraud transactions follow a balance pattern? Yes: 97.82% of fraud withdraws the full balance in one go (Day 3).
- Can a better rule catch far more than 16 frauds? Yes: Rule 2 catches 99.39% with no false alarms (Day 5).
- Does fraud cluster at particular hours? The fraud count is steady across hours, but the fraud rate is higher when genuine traffic is low (Day 3).

## Queries used

Saved in `day2_exploration.sql`. Run them one at a time with Ctrl + Enter.



---



## Day 3 - Fraud patterns



### 1. Account emptied (newbalance_orig = 0), TRANSFER and CASH_OUT only

| | Total | Emptied | Percent ||---|---|---|---|| Fraud | 8,213 | 8,053 | 98.05% || Genuine | 2,762,196 | 2,488,603 | 90.10% |

- Not a strong signal alone, because 90% of genuine transactions also end with balance 0.



### 2. Full balance withdrawn in one go (amount = oldbalance_org)

| | Total | Full balance | Percent ||---|---|---|---|| Fraud | 8,213 | 8,034 | 97.82% || Genuine | 2,762,196 | 0 | 0.00% |

- Very strong signal: almost all fraud empties the account in one transaction, and no genuine transaction does.



### 3. First rule test

Rule: type is TRANSFER or CASH_OUT, amount = oldbalance_org, and oldbalance_org > 0.

- Fraud caught: 8,018 of 8,213 (97.63%)

- False alarms (genuine flagged): 0

- Fraud still missed: 195

- Old system caught only 16, so this is a big improvement.

- Caution: this is synthetic data, so a result this clean is unlikely on real data.



### 4. Fraud by hour of day (step MOD 24)

- Fraud count is roughly equal every hour (about 320-375 per hour in hours 6 to 17).

- Fraud rate is much higher when genuine traffic is low: hour 6 = 10.47%, hours 9 to 17 = about 0.07-0.12%.

- Hours 0-5 and 18-23: 0.42% to 22.30% and 0.06% to 0.23%

- Only an observation, not a firm rule (the data is synthetic).



## Day 3 key findings

1. Fraud almost always withdraws the full balance in one transaction.

2. A simple rule based on this caught 97.63% of fraud with 0 false alarms.

3. 195 fraud cases are still missed and need a closer look.





---



## Day 4 - The 195 frauds the rule missed



### 1. Pattern of the missed frauds

| Pattern | Rows ||---|---|| Partial withdrawal | 150 || Sender balance was 0 | 25 || Amount more than balance | 4 || Zero amount | 16 |



- Biggest group is partial withdrawal (about 77% of the 195).



### 2. Money caught vs missed by the first rule

| | Fraud txns | Total amount | Average amount ||---|---|---|---|| Caught | 8,018 | 10,577,883,640.01 | 1,319,267.10 || Missed | 195 | 1,478,531,787.83 | 7,582,214.30 |



- Rule caught 97.63% of fraud by count and about 87.74% by value.

- Missed frauds are only 2.4% by count but about 12.26% by value.

- Missed frauds have an average amount about 5.7x higher than caught ones.

- Some missed frauds have amount exactly 10,000,000 (possible cap, not yet confirmed).





---



## Day 5 - Rule 2 and the 1 crore cap



### 1. Cap test (fraud TRANSFERs only)

| Sender balance | Fraud txns | Exactly 10,000,000 | Max amount ||---|---|---|---|| Up to 10,000,000 | 3,949 | 0 | 9,996,886.64 || Above 10,000,000 | 148 | 145 | 10,000,000.00 |

- A single TRANSFER seems to be capped at 10,000,000, so fraudsters with larger balances could not withdraw the full balance. Rule 1 missed these 145.



### 2. Rule 2

Rule: type is TRANSFER or CASH_OUT, and (amount = oldbalance_org with oldbalance_org > 0, OR a TRANSFER of exactly 10,000,000 from a balance above 10,000,000).

- Fraud caught: 8,163 of 8,213 (99.39%)

- False alarms: 0

- Fraud missed: 50 (CASH_OUT 41, TRANSFER 9)



### 3. Money view

| | Fraud txns | Total amount | Average amount ||---|---|---|---|| Caught by rule 2 | 8,163 | 12,027,883,640.01 | 1,473,463.63 || Missed by rule 2 | 50 | 28,531,787.83 | 570,635.76 |

- Rule 2 catches about 99.76% of fraud by value. The missed 50 are only about 0.24% by value.





&#x20;### 4. What the remaining 50 look like

| Pattern | Fraud txns ||---|---|| Sender balance was 0 | 25 || Amount is 0 | 16 || Partial withdrawal | 5 || Amount more than sender's balance | 4 || **Total** | **50** |



- Two sampled TRANSFERs look odd: the sender's balance did not change after the transaction, and oldbalance_org equals amount + 10,000,000.

- These are the hardest cases: none of them has the clear "full balance" or "10,000,000 cap" signal.





### 5. Comparison

| | Caught by count | Missed ||---|---|---|| Old system | 0.19% (16) | 8,197 || Rule 1 | 97.63% (8,018) | 195 || Rule 2 | 99.39% (8,163) | 50 |



### Limitation

The rule was designed by looking at the same data it was tested on, so the result is optimistic. It needs testing on fresh data. The dataset is also synthetic.





---



---



## Day 6 - Evaluating the rules



### 1. Rule 2 report card (all 6,362,620 transactions)

| Flagged by rule | Actual fraud | Transactions | Meaning ||---|---|---|---|| 0 | 0 | 6,354,407 | Genuine, not flagged (correct) || 1 | 1 | 8,163 | Fraud, flagged (caught) || 0 | 1 | 50 | Fraud, not flagged (missed) || 1 | 0 | none | Genuine flagged by mistake (false alarm) |



- Zero false alarms. Recall 99.39% (8,163  8,213), precision 100%.



### 2. Comparison rule: "big amount = fraud"

Rule: TRANSFER or CASH_OUT with amount > 1,000,000.

| Flagged | Actual fraud | Transactions ||---|---|---|| 1 | 1 | 2,706 || 1 | 0 | 127,801 (false alarms) || 0 | 1 | 5,507 (missed) || 0 | 0 | 6,226,606 |



- 130,507 alerts, only 2,706 were real fraud. Precision 2.07%, recall 32.95%.

- By value it still catches 86.76% of fraud value, because fraudsters move large amounts. The weakness is the number of false alarms.



### 3. Old system, by value

- Flagged: 16 fraud transactions, value 77,785,563.69

- Not flagged: 8,197 fraud transactions, value 11,978,629,864.15

- Old system caught about 0.19% of fraud by count and about 0.65% by value.



### 4. All three rules side by side

| | Alerts | Fraud caught | False alarms | Recall | Precision | Value caught ||---|---|---|---|---|---|---|| Old system | 16 | 16 | 0 | 0.19% | 100% | 0.65% || Big amount rule | 130,507 | 2,706 | 127,801 | 32.95% | 2.07% | 86.76% || Rule 2 | 8,163 | 8,163 | 0 | 99.39% | 100% | 99.76% |



Net benefit (assumed review cost of 1,000 per alert, see day6_rule_comparison.xlsx):

- Old system: 77,769,563.69

- Big amount rule: 10,330,215,308.95

- Rule 2: 12,019,720,640.01



### 5. Why the balance rule beats the amount rule

- The balance rule looks at behaviour (the account is drained in one go), which almost only fraud does.

- The amount rule also catches many large genuine transactions, so reviewers would face over 127,000 false alerts.

- Rule 2 needs 8,163 reviews and every one is real fraud.



### Assumptions and limitations

- Review cost of 1,000 per alert is an assumption, not a real figure. The dataset has no currency.

- Net benefit assumes all caught fraud value is saved, which is a simplification.

- Rule 2 was designed on the same data it is tested on, so results are optimistic.

- The data is synthetic, so zero false alarms is unlikely on real data.





