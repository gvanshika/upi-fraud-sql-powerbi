USE upi_fraud;

-- cap test: fraud TRANSFERs split by sender balance
SELECT CASE WHEN oldbalance_org > 10000000 THEN 'balance above 1 crore'
            ELSE 'balance up to 1 crore' END AS bucket,
       COUNT(*) AS fraud_txns,
       SUM(CASE WHEN amount = 10000000 THEN 1 ELSE 0 END) AS amount_exactly_1cr,
       MAX(amount) AS max_amount
FROM transactions
WHERE is_fraud = 1 AND type = 'TRANSFER'
GROUP BY bucket;

-- how common is amount = 1 crore in TRANSFER
SELECT is_fraud, COUNT(*) AS txns
FROM transactions
WHERE type = 'TRANSFER' AND amount = 10000000
GROUP BY is_fraud;

-- rule 2: full balance OR exactly 1 crore with balance above 1 crore
SELECT is_fraud, COUNT(*) AS txns
FROM transactions
WHERE type IN ('TRANSFER', 'CASH_OUT')
  AND ( (amount = oldbalance_org AND oldbalance_org > 0)
        OR (type = 'TRANSFER' AND amount = 10000000 AND oldbalance_org > 10000000) )
GROUP BY is_fraud;

-- fraud still missed by rule 2, by type
SELECT type, COUNT(*) AS missed
FROM transactions
WHERE is_fraud = 1
  AND NOT ( type IN ('TRANSFER', 'CASH_OUT')
            AND ( (amount = oldbalance_org AND oldbalance_org > 0)
                  OR (type = 'TRANSFER' AND amount = 10000000 AND oldbalance_org > 10000000) ) )
GROUP BY type;

-- random sample of what rule 2 still misses
SELECT *
FROM transactions
WHERE is_fraud = 1
  AND amount > 0
  AND NOT ( type IN ('TRANSFER', 'CASH_OUT')
            AND ( (amount = oldbalance_org AND oldbalance_org > 0)
                  OR (type = 'TRANSFER' AND amount = 10000000 AND oldbalance_org > 10000000) ) )
ORDER BY RAND()
LIMIT 20;


-- money caught vs missed by rule 2
SELECT CASE WHEN type IN ('TRANSFER', 'CASH_OUT')
                 AND ( (amount = oldbalance_org AND oldbalance_org > 0)
                       OR (type = 'TRANSFER' AND amount = 10000000 AND oldbalance_org > 10000000) )
            THEN 'caught by rule 2' ELSE 'missed by rule 2' END AS status,
       COUNT(*) AS txns,
       ROUND(SUM(amount), 2) AS total_amount,
       ROUND(AVG(amount), 2) AS avg_amount
FROM transactions
WHERE is_fraud = 1
GROUP BY status;