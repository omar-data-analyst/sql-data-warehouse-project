/*
===============================================================================
Script Name   : load_silver_erp_px_cat_g1v2.sql
Description   : Cleanses product category data from 'bronze.erp_px_cat_g1v2' 
                and loads it into 'silver.erp_px_cat_g1v2'. Standardizes string 
                attributes using TRIM, handles NULL/empty fields, and populates 
                metadata tracking columns.

WARNING / PRECAUTIONS:
    - DATA TRUNCATION RISK: This script executes a TRUNCATE TABLE command on 
      'silver.erp_px_cat_g1v2' prior to insertion. All existing records 
      will be permanently deleted before reloading.
    - DO NOT execute directly in Production without proper authorization 
      or an active backup strategy.
    - Ensure that the upstream Bronze layer ETL process has completed successfully.
===============================================================================
*/

-- 1. Truncate Target Table (Full Refresh Strategy)
TRUNCATE TABLE silver.erp_px_cat_g1v2;

-- 2. Populate Cleaned Data
INSERT INTO silver.erp_px_cat_g1v2 (
    id,
    cat,
    subcat,
    maintenance,
    dwh_create_date
)
SELECT 
    -- Product Key / Category ID Validation
    TRIM(id) AS id,

    -- Category Standardization (Handling Nulls and Extra Spaces)
    CASE 
        WHEN cat IS NULL OR TRIM(cat) = '' THEN 'n/a'
        ELSE TRIM(cat)
    END AS cat,

    -- Subcategory Standardization
    CASE 
        WHEN subcat IS NULL OR TRIM(subcat) = '' THEN 'n/a'
        ELSE TRIM(subcat)
    END AS subcat,

    -- Maintenance Status Standardization
    CASE 
        WHEN maintenance IS NULL OR TRIM(maintenance) = '' THEN 'n/a'
        ELSE TRIM(maintenance)
    END AS maintenance,

    -- Metadata Audit Column
    GETDATE() AS dwh_create_date

FROM bronze.erp_px_cat_g1v2;
