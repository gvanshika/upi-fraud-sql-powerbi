-- ============================================================
-- UPI Fraud SQL Project - Day 1: Setup and data load
-- Dataset: PaySim "Synthetic Financial Datasets For Fraud Detection" (Kaggle)
-- Tool: MySQL Workbench
-- How to run: click inside a query, press Ctrl + Enter
-- ============================================================


-- 1. Create the database
CREATE DATABASE upi_fraud;
USE upi_fraud;


-- 2. Create the table
CREATE TABLE transactions (
    step INT,
    type VARCHAR(20),
    amount DECIMAL(14,2),
    name_orig VARCHAR(20),
    oldbalance_org DECIMAL(14,2),
    newbalance_orig DECIMAL(14,2),
    name_dest VARCHAR(20),
    oldbalance_dest DECIMAL(14,2),
    newbalance_dest DECIMAL(14,2),
    is_fraud SMALLINT,
    is_flagged_fraud SMALLINT
);


-- 3. Allow loading a local file
-- Also add OPT_LOCAL_INFILE=1 under Advanced > Others in the Workbench connection settings
-- and reconnect before running the load below.
SET GLOBAL local_infile = 1;


-- 4. Load the CSV (replace the path with the location of your downloaded file;
--    use forward slashes)
LOAD DATA LOCAL INFILE 'C:/path/to/PS_20174392719_1491204439457_log.csv'
INTO TABLE transactions
FIELDS TERMINATED BY ','
IGNORE 1 LINES;


-- 5. Check the load (expect 6362620 rows)
SELECT COUNT(*) FROM transactions;


-- 6. First finding: fraud by type (fraud only in TRANSFER and CASH_OUT)
SELECT type, COUNT(*)
FROM transactions
WHERE is_fraud = 1
GROUP BY type;