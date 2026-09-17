/*
===============================================================================
Script Name   : load_silver_erp_loc_a101.sql
Description   : Cleanses location data from 'bronze.erp_loc_a101', strips dashes 
                from customer IDs, and standardizes country codes to full names.
WARNING       : Executing this script will TRUNCATE 'silver.erp_loc_a101'.
===============================================================================
*/

-- 1. Truncate Target Table (Full Refresh Strategy)
TRUNCATE TABLE silver.erp_loc_a101;

-- 2. Populate Cleaned Data
INSERT INTO silver.erp_loc_a101 (
    cid,
    cntry
)
SELECT 
    -- Clean Customer ID (Remove dashes)
    REPLACE(cid, '-', '') AS cid,

    -- Standardize Country Names
    CASE 
        WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'Germany'
        WHEN UPPER(TRIM(cntry)) IN ('US', 'USA') THEN 'United States'
        WHEN UPPER(TRIM(cntry)) = '' OR cntry IS NULL THEN 'n/a'
        ELSE TRIM(cntry)
    END AS cntry

FROM bronze.erp_loc_a101;
