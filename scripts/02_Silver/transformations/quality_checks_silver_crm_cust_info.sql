/*
===============================================================================
Script Name   : quality_checks_silver_crm_cust_info.sql
Description   : Data Quality (DQ) checks for 'silver.crm_cust_info'.
                Verifies deduplication, string trimming, and value consistency.
===============================================================================
*/

USE DataWarehouse;


PRINT '===============================================================================';
PRINT 'Executing Data Quality Checks: silver.crm_cust_info';
PRINT '===============================================================================';

-------------------------------------------------------------------------------
-- 1. Check for Duplicate Records (Uniqueness Validation)
-- Expectation: No rows returned (Empty Result)
-------------------------------------------------------------------------------
SELECT * 
FROM (
    SELECT 
        cst_id,
        ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag
    FROM silver.crm_cust_info
) t
WHERE flag > 1;


-------------------------------------------------------------------------------
-- 2. Check for NULL or Invalid Keys
-- Expectation: No rows returned
-------------------------------------------------------------------------------
SELECT * 
FROM silver.crm_cust_info
WHERE cst_id IS NULL;


-------------------------------------------------------------------------------
-- 3. Check for Unwanted Spaces in Text Fields (Data Cleansing Validation)
-- Expectation: No rows returned
-------------------------------------------------------------------------------
SELECT 
    cst_id,
    cst_firstname,
    cst_lastname 
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname) 
   OR cst_lastname  != TRIM(cst_lastname);


-------------------------------------------------------------------------------
-- 4. Verify Distinct Standardized Values (Gender & Marital Status)
-- Expectation: Distinct values should strictly match expected domains (Male, Female, Married, Single, n/a)
-------------------------------------------------------------------------------
-- Check Distinct Gender Values
SELECT 
    cst_gndr,
    COUNT(*) AS record_count
FROM silver.crm_cust_info
GROUP BY cst_gndr;

-- Check Distinct Marital Status Values
SELECT 
    cst_marital_status,
    COUNT(*) AS record_count
FROM silver.crm_cust_info
GROUP BY cst_marital_status;

-- Summary Count of Unique Categorical Attributes
SELECT 
    COUNT(DISTINCT cst_gndr)           AS unique_genders_count,
    COUNT(DISTINCT cst_marital_status) AS unique_marital_statuses_count
FROM silver.crm_cust_info;

PRINT '===============================================================================';
PRINT 'Data Quality Checks Completed Successfully';
PRINT '===============================================================================';
