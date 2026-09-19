/*
===============================================================================
Script Name   : quality_check_silver_erp_px_cat_g1v2.sql
Description   : Performs post-ETL data quality validations on 'silver.erp_px_cat_g1v2'. 
                Checks primary key integrity, un-trimmed white spaces, missing 
                values, and alignment with the CRM product dimension.

WARNING / PRECAUTIONS:
    - READ-ONLY OPERATIONAL SCRIPT: This script contains SELECT queries only.
    - EXPECTED RESULT: All validation queries must return 0 rows. Any returned 
      rows indicate data anomalies in the Silver layer that require investigation.
===============================================================================
*/

-- 1. Check for Primary Key Nulls or Empty IDs
-- Expectation: Zero Rows
SELECT * 
FROM silver.erp_px_cat_g1v2 
WHERE id IS NULL OR TRIM(id) = '';

-- 2. Check for Un-trimmed Whitespaces in String Fields
-- Expectation: Zero Rows
SELECT * 
FROM silver.erp_px_cat_g1v2 
WHERE id LIKE ' %' OR id LIKE '% '
   OR cat LIKE ' %' OR cat LIKE '% '
   OR subcat LIKE ' %' OR subcat LIKE '% '
   OR maintenance LIKE ' %' OR maintenance LIKE '% ';

-- 3. Verify Alignment with CRM Product Master Table
-- Expectation: Zero Rows (Unmatched keys between ERP categories and CRM products)
SELECT DISTINCT id 
FROM silver.erp_px_cat_g1v2 
WHERE id NOT IN (SELECT prd_key FROM silver.crm_prd_info);
