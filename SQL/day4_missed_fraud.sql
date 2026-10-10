-- ============================================================
-- UPI Fraud SQL Project - Day 4: The frauds the first rule missed
-- Rule used: type is TRANSFER or CASH_OUT, amount = oldbalance_org, oldbalance_org > 0
-- How to run: click inside a query, press Ctrl + Enter
-- ============================================================

USE upi_fraud;


-- 1. Missed fraud count (expect 195)
SELECT COUNT(*)
FROM transactions
WHERE is_fraud = 1
  AND NOT (type IN ('TRANSFER', 'CASH_OUT') AND amount = oldbalance_org AND oldbalance_org > 0);


-- 2. Missed fraud: zero amount vs positive amount (expect 16, 179, 195 in total)
SELECT type,
       SUM(CASE WHEN amount = 0 THEN 1 ELSE 0 END) AS zero_amount,
       SUM(CASE WHEN amount > 0 THEN 1 ELSE 0 END) AS positive_amount,
       COUNT(*) AS total
FROM transactions
WHERE is_fraud = 1
  AND NOT (type IN ('TRANSFER', 'CASH_OUT') AND amount = oldbalance_org AND oldbalance_org > 0)
GROUP BY type;


-- 3. Sample of missed fraud rows
SELECT *
FROM transactions
WHERE is_fraud = 1
  AND amount > 0
  AND NOT (type IN ('TRANSFER', 'CASH_OUT') AND amount = oldbalance_org AND oldbalance_org > 0)
LIMIT 20;


-- 4. Missed fraud: which pattern do they follow (expect 150, 25, 4)
SELECT CASE
         WHEN oldbalance_org = 0 THEN 'sender balance was 0'
         WHEN amount < oldbalance_org THEN 'partial withdrawal'
         WHEN amount > oldbalance_org THEN 'amount more than balance'
         ELSE 'other'
       END AS pattern,
       COUNT(*) AS txns
FROM transactions
WHERE is_fraud = 1
  AND amount > 0
  AND NOT (type IN ('TRANSFER', 'CASH_OUT') AND amount = oldbalance_org AND oldbalance_org > 0)
GROUP BY pattern;


-- 5. Money caught vs missed by the rule
SELECT CASE
         WHEN type IN ('TRANSFER', 'CASH_OUT') AND amount = oldbalance_org AND oldbalance_org > 0
         THEN 'caught by rule'
         ELSE 'missed by rule'
       END AS status,
       COUNT(*) AS txns,
       ROUND(SUM(amount), 2) AS total_amount,
       ROUND(AVG(amount), 2) AS avg_amount
FROM transactions
WHERE is_fraud = 1
GROUP BY status;