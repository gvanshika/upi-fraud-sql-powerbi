-- ============================================================
-- UPI Fraud SQL Project - Day 2: Exploring the data
-- Database: upi_fraud | Table: transactions
-- How to run: click inside a query, press Ctrl + Enter
-- ============================================================

USE upi_fraud;


-- 1. Transaction count by type
SELECT type, COUNT(*)
FROM transactions
GROUP BY type
ORDER BY COUNT(*) DESC;


-- 2. Time range (step = 1 hour, expect 1 to 743)
SELECT MIN(step), MAX(step)
FROM transactions;


-- 3. Missing values check (expect 0)
SELECT COUNT(*)
FROM transactions
WHERE amount IS NULL OR type IS NULL;


-- 4. Overall fraud percentage
SELECT COUNT(*) AS total,
       SUM(is_fraud) AS fraud,
       ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 3) AS fraud_pct
FROM transactions;


-- 5. Fraud rate by type (TRANSFER vs CASH_OUT)
SELECT type,
       COUNT(*) AS total,
       SUM(is_fraud) AS fraud,
       ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2) AS fraud_pct
FROM transactions
WHERE type IN ('TRANSFER', 'CASH_OUT')
GROUP BY type;


-- 6. Fraud vs genuine: average and maximum amount
SELECT is_fraud,
       COUNT(*) AS txns,
       ROUND(AVG(amount), 2) AS avg_amount,
       MAX(amount) AS max_amount
FROM transactions
WHERE type IN ('TRANSFER', 'CASH_OUT')
GROUP BY is_fraud;


-- 7. How many frauds did the existing system flag?
SELECT is_flagged_fraud, is_fraud, COUNT(*)
FROM transactions
GROUP BY is_flagged_fraud, is_fraud;