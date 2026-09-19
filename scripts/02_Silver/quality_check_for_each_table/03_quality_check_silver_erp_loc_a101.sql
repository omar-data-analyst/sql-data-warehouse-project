/*
===============================================================================
Script Name   : quality_check_silver_erp_loc_a101.sql
Description   : Performs post-ETL data quality checks on 'silver.erp_loc_a101'.
                Validates customer ID formatting (dashes removed), verifies 
                country standardization rules, and checks referential integrity 
                against the master customer table.

WARNING / PRECAUTIONS:
    - READ-ONLY OPERATIONAL SCRIPT: This script contains SELECT queries only 
      and does not modify or delete data. However, running heavy query checks 
      on large tables during peak operating hours may cause temporary read locks.
    - EXPECTED RESULT: All validation queries must return 0 rows. Any returned 
      rows indicate data anomalies in the Silver layer that require investigation.
===============================================================================
*/

-- 1. Check for Unremoved Dashes in Customer ID
-- Expectation: Zero Rows
SELECT * 
FROM silver.erp_loc_a101 
WHERE cid LIKE '%-%';

-- 2. Verify Country Standardizations
-- Expectation: Zero Rows (No raw codes like 'DE', 'US', 'USA' should remain)
SELECT DISTINCT cntry 
FROM silver.erp_loc_a101 
WHERE cntry IN ('DE', 'US', 'USA', '');

-- 3. Check Alignment with Main Customer Key
-- Expectation: Zero Rows (Unmatched keys)
SELECT DISTINCT cid 
FROM silver.erp_loc_a101 
WHERE cid NOT IN (SELECT cst_key FROM silver.crm_cust_info);
