/*
===============================================================================
Script Name   : quality_checks_silver_crm_prd_info.sql
Layer         : Silver Layer
Target Table  : silver.crm_prd_info
Description   : Executes Data Quality (DQ) tests against silver.crm_prd_info
                to verify data integrity, cleanliness, and business rules.

Checks Included:
  1. Primary Key Uniqueness (prd_id)
  2. Mandatory Attributes (NULL / Empty Checks)
  3. Whitespace & Trimming Validation
  4. Historical Date Consistency (prd_end_dt >= prd_start_dt)
  5. Negative Cost Check
  6. Standardized Product Line Values Check
===============================================================================
*/

USE DataWarehouse;
GO

PRINT '===============================================================================';
PRINT 'Running Data Quality (DQ) Checks for: silver.crm_prd_info';
PRINT '===============================================================================';

-- 1. Check Primary Key Uniqueness
PRINT '1. Checking Primary Key Uniqueness (prd_id)...';
SELECT 
    prd_id, 
    COUNT(*) AS duplicate_count
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1;

-- 2. Check for Unexpected NULLs or Empty Strings in Mandatory Fields
PRINT '2. Checking Mandatory Columns for NULLs or Blanks...';
SELECT *
FROM silver.crm_prd_info
WHERE prd_id IS NULL 
   OR prd_key IS NULL OR prd_key = ''
   OR cat_key IS NULL OR cat_key = ''
   OR prd_nm IS NULL OR prd_nm = ''
   OR prd_start_dt IS NULL;

-- 3. Check for Leading / Trailing Whitespaces
PRINT '3. Checking Unwanted Leading/Trailing Spaces...';
SELECT *
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)
   OR prd_key != TRIM(prd_key)
   OR prd_line != TRIM(prd_line);

-- 4. Check Date Chronology Logic
PRINT '4. Checking Date Validity (prd_end_dt >= prd_start_dt)...';
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt IS NOT NULL 
  AND prd_end_dt < prd_start_dt;

-- 5. Check Numeric Sanity (Costs should not be negative)
PRINT '5. Checking Negative Cost Values...';
SELECT *
FROM silver.crm_prd_info
WHERE prd_cost < 0;

-- 6. Check Distinct Categorical Values
PRINT '6. Inspecting Standardized Product Lines...';
SELECT DISTINCT prd_line 
FROM silver.crm_prd_info;

PRINT '===============================================================================';
PRINT 'Data Quality Verification Complete.';
PRINT '===============================================================================';
GO
