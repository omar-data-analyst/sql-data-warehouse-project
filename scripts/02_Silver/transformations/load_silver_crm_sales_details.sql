/*
===============================================================================
Script Name   : load_silver_crm_sales_details.sql
Description   : Cleanses and transforms raw sales data from the Bronze layer 
                (bronze.crm_sales_details) and loads it into the Silver layer 
                (silver.crm_sales_details). Handles invalid or missing dates, 
                corrects negative or zero quantities and prices, and enforces 
                mathematical consistency across sales, prices, and quantities.

WARNING / PRECAUTIONS:
    - DATA TRUNCATION RISK: This script executes a TRUNCATE TABLE command on 
      'silver.crm_sales_details' prior to insertion. All existing records 
      in the target table will be permanently deleted before reloading.
    - DO NOT execute directly in Production without proper authorization, 
      staging verification, or an active backup strategy.
    - Ensure that the upstream Bronze layer ETL process (bronze.crm_sales_details) 
      has completed successfully before running this script.
===============================================================================
*/

USE DataWarehouse;


PRINT '-------------------------------------------------------------------------------';
PRINT 'Loading Table: silver.crm_cust_info';
PRINT '-------------------------------------------------------------------------------';

-- Clear existing data before reloading (Full Refresh Strategy)
TRUNCATE TABLE silver.crm_cust_info;

-- Insert Cleansed and Conformed Data
INSERT INTO silver.crm_cust_info (
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_marital_status,
    cst_gndr,
    cst_create_date
)
SELECT 
    cst_id,
    cst_key,
    TRIM(cst_firstname) AS cst_firstname,
    TRIM(cst_lastname)  AS cst_lastname,
    -- Standardize Marital Status
    CASE 
        WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
        WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
        ELSE 'n/a'
    END AS cst_marital_status,
    -- Standardize Gender
    CASE 
        WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
        WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
        ELSE 'n/a'
    END AS cst_gndr,
    cst_create_date
FROM
(
    SELECT 
        *,
        -- Deduplication: Pick the most recent record per customer
        ROW_NUMBER() OVER(
            PARTITION BY cst_id 
            ORDER BY cst_create_date DESC
        ) AS flag
    FROM bronze.crm_cust_info
    WHERE cst_id IS NOT NULL -- Exclude records without primary key early
) t
WHERE flag = 1;

PRINT 'Successfully loaded table: silver.crm_cust_info';
