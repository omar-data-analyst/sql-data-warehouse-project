/*
===============================================================================
Script Name   : load_silver_crm_prd_info.sql
Layer         : Silver Layer
Source Table  : bronze.crm_prd_info
Target Table  : silver.crm_prd_info
Description   : Cleanses, standardizes, and loads product information into Silver.
                
Transformations applied:
  - Extracted 'cat_key' and 'prd_key' from composite string field.
  - Trimmed whitespace from text fields.
  - Handled NULL costs by substituting 0.
  - Standardized 'prd_line' codes ('M', 'R', 'S', 'T') into human-readable labels.
  - Standardized start date casting.
  - Calculated SCD Type 2 end dates ('prd_end_dt') using LEAD window function.
  - Filtered records using foreign key validation with ERP categories and Sales details.
===============================================================================
*/

USE DataWarehouse;
GO

PRINT '===============================================================================';
PRINT 'Loading Silver Layer: crm_prd_info';
PRINT '===============================================================================';

-------------------------------------------------------------------------------
-- Step 1: DDL Check / Column Resizing (Prevent Truncation Errors)
-------------------------------------------------------------------------------
IF EXISTS (
    SELECT 1 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'silver' 
      AND TABLE_NAME = 'crm_prd_info' 
      AND COLUMN_NAME = 'prd_line' 
      AND CHARACTER_MAXIMUM_LENGTH < 50
)
BEGIN
    ALTER TABLE silver.crm_prd_info 
    ALTER COLUMN prd_line VARCHAR(50);
    PRINT '>> Resized prd_line column to VARCHAR(50).';
END;
GO

-------------------------------------------------------------------------------
-- Step 2: Truncate & Load Process
-------------------------------------------------------------------------------
PRINT '>> Truncating table silver.crm_prd_info...';
TRUNCATE TABLE silver.crm_prd_info;

PRINT '>> Inserting cleansed data into silver.crm_prd_info...';
INSERT INTO silver.crm_prd_info (
    prd_id,
    cat_key,
    prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
)
SELECT 
    prd_id,
    -- Extract category code (cat_key)
    REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_key,
    
    -- Extract clean product key (prd_key)
    REPLACE(SUBSTRING(prd_key, 7, LEN(prd_key)), '-', '_') AS prd_key,
    
    -- Clean product name
    TRIM(prd_nm) AS prd_nm,
    
    -- Replace NULL costs with 0
    ISNULL(prd_cost, 0) AS prd_cost,
    
    -- Map and standardize product line codes
    CASE UPPER(TRIM(prd_line))
        WHEN 'M' THEN 'Mountain'
        WHEN 'R' THEN 'Road'
        WHEN 'S' THEN 'Other Sales'
        WHEN 'T' THEN 'Touring'
        ELSE 'n/a'
    END AS prd_line,
    
    -- Cast start date
    CAST(prd_start_dt AS DATE) AS prd_start_dt,
    
    -- Calculate historical end date using LEAD window function
    CAST(
        DATEADD(day, -1, LEAD(prd_start_dt) OVER (
            PARTITION BY REPLACE(SUBSTRING(prd_key, 7, LEN(prd_key)), '-', '_') 
            ORDER BY prd_start_dt
        )) AS DATE
    ) AS prd_end_dt
FROM bronze.crm_prd_info
WHERE
    -- Referential Integrity Filter: Category Validation
    REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') 
    IN (SELECT id FROM bronze.erp_px_cat_g1v2 WHERE id IS NOT NULL)
    AND
    -- Referential Integrity Filter: Sales Key Validation
    REPLACE(SUBSTRING(prd_key, 7, LEN(prd_key)), '-', '_') 
    IN (SELECT REPLACE(sls_prd_key, '-', '_') FROM bronze.crm_sales_details WHERE sls_prd_key IS NOT NULL);

PRINT '>> Data successfully loaded to silver.crm_prd_info.';
PRINT '===============================================================================';
GO
