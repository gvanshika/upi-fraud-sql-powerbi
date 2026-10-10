USE upi_fraud;

-- rule 2 alerts per day (workload for reviewers)

SELECT FLOOR((step - 1) / 24) + 1 AS day_no,
       COUNT(*) AS alerts,
       SUM(is_fraud) AS real_fraud
FROM transactions
WHERE type IN ('TRANSFER', 'CASH_OUT')
  AND ( (amount = oldbalance_org AND oldbalance_org > 0)
        OR (type = 'TRANSFER' AND amount = 10000000 AND oldbalance_org > 10000000) )
GROUP BY day_no
ORDER BY day_no;

-- rule 2 caught vs total fraud: first half vs second half of the month
SELECT CASE WHEN step <= 372 THEN 'first half (step 1-372)'
            ELSE 'second half (step 373-743)' END AS period,
       SUM(is_fraud) AS total_fraud,
       SUM(CASE WHEN is_fraud = 1
                 AND type IN ('TRANSFER', 'CASH_OUT')
                 AND ( (amount = oldbalance_org AND oldbalance_org > 0)
                       OR (type = 'TRANSFER' AND amount = 10000000 AND oldbalance_org > 10000000) )
                THEN 1 ELSE 0 END) AS caught
FROM transactions
GROUP BY period;