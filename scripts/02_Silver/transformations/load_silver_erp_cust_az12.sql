/*
===============================================================================
Script Name   : load_silver_erp_cust_az12.sql
Description   : Cleanses and transforms raw ERP customer demographic data 
                from 'bronze.erp_cust_az12' and loads it into 'silver.erp_cust_az12'. 
                Strips unwanted string prefixes from customer IDs, standardizes 
                gender attributes, and invalidates future birthdates.

WARNING / PRECAUTIONS:
    - DATA TRUNCATION RISK: This script executes a TRUNCATE TABLE command on 
      'silver.erp_cust_az12' prior to insertion. All existing records 
      in the target table will be permanently deleted before reloading.
    - DO NOT execute directly in Production without proper authorization, 
      staging verification, or an active backup strategy.
    - Ensure that the upstream Bronze layer ETL process (bronze.erp_cust_az12) 
      has completed successfully before running this script.
===============================================================================
Script Purpose:
    Cleanses raw ERP customer data from 'bronze.erp_cust_az12' and loads it 
    into 'silver.erp_cust_az12'.
    
Data Quality & Business Rules Applied:
    1. Truncates target table before insert (Full Refresh Strategy).
    2. Customer ID Cleaning: Removes the 'NAS' prefix using SUBSTRING.
    3. Gender Standardization: Maps 'F'/'FEMALE' to 'Female', 'M'/'MALE' to 'Male', 
       and sets unmapped, empty, or NULL values to 'n/a'.
    4. Birthdate Validation: Converts future birthdates (> GETDATE()) to NULL.
    5. Metadata Audit: Populates 'dwh_create_date' with the execution timestamp.
===============================================================================
*/

-- 1. Truncate Target Table (Full Refresh Strategy)
TRUNCATE TABLE silver.erp_cust_az12;

-- 2. Populate Cleaned Data
INSERT INTO silver.erp_cust_az12 (
    cid,
    gen,
    bdate,
    dwh_create_date
)
SELECT 
    -- Customer ID Prefix Removal
    CASE 
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
        ELSE cid 
    END AS cid,

    -- Gender Standardization
    CASE 
        WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
        WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
        ELSE 'n/a'
    END AS gen,

    -- Future Date Validation
    CASE 
        WHEN bdate > GETDATE() THEN NULL
        ELSE bdate
    END AS bdate,

    -- Metadata Audit Column
    GETDATE() AS dwh_create_date

FROM bronze.erp_cust_az12;
