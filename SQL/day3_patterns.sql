USE upi_fraud;

SELECT * FROM transactions WHERE is_fraud = 1 LIMIT 10;

SELECT is_fraud,
       COUNT(*) AS total,
       SUM(CASE WHEN newbalance_orig = 0 THEN 1 ELSE 0 END) AS emptied,
       ROUND(SUM(CASE WHEN newbalance_orig = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS emptied_pct
FROM transactions
WHERE type IN ('TRANSFER', 'CASH_OUT')
GROUP BY is_fraud;

SELECT is_fraud,
       COUNT(*) AS total,
       SUM(CASE WHEN amount = oldbalance_org THEN 1 ELSE 0 END) AS full_balance,
       ROUND(SUM(CASE WHEN amount = oldbalance_org THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS full_balance_pct
FROM transactions
WHERE type IN ('TRANSFER', 'CASH_OUT')
GROUP BY is_fraud;

SELECT is_fraud, COUNT(*) AS txns
FROM transactions
WHERE type IN ('TRANSFER', 'CASH_OUT')
  AND amount = oldbalance_org
  AND oldbalance_org > 0
GROUP BY is_fraud;

SELECT MOD(step, 24) AS hour_of_day,
       COUNT(*) AS total,
       SUM(is_fraud) AS fraud,
       ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2) AS fraud_pct
FROM transactions
GROUP BY MOD(step, 24)
ORDER BY hour_of_day;




