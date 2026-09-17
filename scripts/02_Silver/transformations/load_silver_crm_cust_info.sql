/*
===============================================================================
Script Name   : load_silver_crm_cust_info.sql
Description   : Cleanses, deduplicates, and loads CRM customer data 
                from 'bronze.crm_cust_info' into 'silver.crm_cust_info'.
Transformation Logic:
  - Deduplication: Keeps the latest record per customer using ROW_NUMBER().
  - Filtering    : Excludes invalid records with NULL 'cst_id'.
  - Text Trimming: Removes leading/trailing spaces from name fields.
  - Normalization: Standardizes marital status ('M'->'Married', 'S'->'Single') 
                   and gender ('F'->'Female', 'M'->'Male'). Unmapped values set to 'n/a'.
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
