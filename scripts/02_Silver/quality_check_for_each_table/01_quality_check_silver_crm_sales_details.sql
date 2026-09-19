/*
===============================================================================
Script Name   : quality_check_silver_crm_sales_details.sql
Description   : Performs post-ETL data quality checks on 'silver.crm_sales_details'. 
                Validates primary key integrity, missing metrics, mathematical 
                consistency (Sales = Price * Quantity), logical date sequences, 
                and referential integrity with dimension tables.

WARNING / PRECAUTIONS:
    - READ-ONLY OPERATIONAL SCRIPT: This script contains SELECT queries only 
      and does not modify or delete data. However, running heavy query checks 
      on large tables during peak operating hours may cause temporary read locks 
      or performance overhead.
    - EXPECTED RESULT: All validation queries must return 0 rows. Any returned 
      rows indicate data anomalies in the Silver layer that require investigation.
===============================================================================
*/

-- 1. Check for Primary Key / Essential Attributes Nulls
-- Expectation: Zero Rows
SELECT *
FROM silver.crm_sales_details
WHERE sls_ord_num IS NULL 
   OR sls_prd_key IS NULL 
   OR sls_cust_id IS NULL;

-- 2. Check for Invalid Numerical Metrics (Zeros, Negatives, Nulls)
-- Expectation: Zero Rows
SELECT *
FROM silver.crm_sales_details
WHERE sls_quantity <= 0 OR sls_quantity IS NULL
   OR sls_price <= 0 OR sls_price IS NULL
   OR sls_sales <= 0 OR sls_sales IS NULL;

-- 3. Verify Mathematical Consistency (Sales = Price * Quantity)
-- Expectation: Zero Rows
SELECT *
FROM silver.crm_sales_details
WHERE sls_sales != (sls_price * sls_quantity);

-- 4. Check Date Sequence Integrity (Order Date <= Ship Date <= Due Date)
-- Expectation: Zero Rows
SELECT *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt 
   OR sls_ship_dt > sls_due_dt;

-- 5. Foreign Key Referential Integrity Check (Sales vs Products & Customers)
-- Expectation: Zero Rows (Unmatched keys)
SELECT DISTINCT sls_prd_key 
FROM silver.crm_sales_details 
WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info);

SELECT DISTINCT sls_cust_id 
FROM silver.crm_sales_details 
WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info);
