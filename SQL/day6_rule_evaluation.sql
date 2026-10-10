USE upi_fraud;

-- rule 2 report card: flagged vs actual fraud
SELECT CASE WHEN type IN ('TRANSFER', 'CASH_OUT')
                 AND ( (amount = oldbalance_org AND oldbalance_org > 0)
                       OR (type = 'TRANSFER' AND amount = 10000000 AND oldbalance_org > 10000000) )
            THEN 1 ELSE 0 END AS flagged,
       is_fraud,
       COUNT(*) AS txns,
       ROUND(SUM(amount), 2) AS total_amount
FROM transactions
GROUP BY flagged, is_fraud;

-- naive rule: any TRANSFER or CASH_OUT above 1,000,000
SELECT CASE WHEN type IN ('TRANSFER', 'CASH_OUT') AND amount > 1000000
            THEN 1 ELSE 0 END AS flagged,
       is_fraud,
       COUNT(*) AS txns,
       ROUND(SUM(amount), 2) AS total_amount
FROM transactions
GROUP BY flagged, is_fraud;

-- old system: how much fraud value did it catch?
SELECT is_flagged_fraud,
       COUNT(*) AS fraud_txns,
       ROUND(SUM(amount), 2) AS fraud_value
FROM transactions
WHERE is_fraud = 1
GROUP BY is_flagged_fraud;