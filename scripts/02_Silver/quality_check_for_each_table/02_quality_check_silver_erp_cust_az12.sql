/*
===============================================================================
Script Name   : quality_check_silver_erp_cust_az12.sql
Description   : Performs post-ETL data quality validations on 'silver.erp_cust_az12'. 
                Validates customer key consistency, standardized gender domain values, 
                and logical birthdate thresholds.

WARNING / PRECAUTIONS:
    - READ-ONLY OPERATIONAL SCRIPT: This script contains SELECT queries only 
      and does not modify or delete data. However, running heavy query checks 
      on large tables during peak operating hours may cause temporary read locks.
    - EXPECTED RESULT: All validation queries must return 0 rows. Any returned 
      rows indicate data anomalies in the Silver layer that require investigation.
===============================================================================
*/

-- 1. Check for Invalid or Unremoved Prefixes in Customer ID
-- Expectation: Zero Rows
SELECT * 
FROM silver.erp_cust_az12 
WHERE cid LIKE 'NAS%';

-- 2. Verify Gender Value Domain Standardizations
-- Expectation: Zero Rows (Only 'Female', 'Male', or 'n/a' allowed)
SELECT DISTINCT gen 
FROM silver.erp_cust_az12 
WHERE gen NOT IN ('Female', 'Male', 'n/a');

-- 3. Check for Future Birthdates or Out-of-Range Dates
-- Expectation: Zero Rows
SELECT * 
FROM silver.erp_cust_az12 
WHERE bdate > GETDATE() OR bdate < '1900-01-01';

-- 4. Check Key Alignment with Primary Customer Table (crm_cust_info)
-- Expectation: Zero Rows (Unmatched keys)
SELECT DISTINCT cid 
FROM silver.erp_cust_az12 
WHERE cid NOT IN (SELECT cst_key FROM silver.crm_cust_info);
