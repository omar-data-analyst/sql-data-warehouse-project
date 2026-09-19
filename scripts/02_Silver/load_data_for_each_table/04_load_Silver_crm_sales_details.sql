/*
===============================================================================
Script Name   : load_Silver_crm_sales_details.sql
Description   : Cleanses and transforms sales transactions from the Bronze layer 
                and loads them into the Silver layer.
Source Table  : bronze.crm_sales_details
Target Table  : silver.crm_sales_details
Execution Type: Full Reload (TRUNCATE & INSERT)
===============================================================================
*/

-- 1. Purge existing data in the Silver layer table to ensure clean reload
TRUNCATE TABLE silver.crm_sales_details;

-- 2. Transform and insert cleansed records from Bronze to Silver
INSERT INTO silver.crm_sales_details (
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_quantity,
    sls_price,
    sls_sales  
)
SELECT
    -- Order Information
    sls_ord_num,
    
    -- Fix Product Key format (Replace hyphens '-' with underscores '_' to match dim_products)
    REPLACE(sls_prd_key, '-', '_') AS sls_prd_key,
    
    -- Customer ID
    sls_cust_id,
    
    -- Date Cleansing: Order Date
    CASE 
        WHEN sls_order_dt IS NULL 
          OR CAST(sls_order_dt AS VARCHAR) = '0' 
          OR LEN(CAST(sls_order_dt AS VARCHAR)) != 8 
        THEN NULL
        ELSE TRY_CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
    END AS sls_order_dt,
    
    -- Date Cleansing: Ship Date
    CASE 
        WHEN sls_ship_dt IS NULL 
          OR CAST(sls_ship_dt AS VARCHAR) = '0' 
          OR LEN(CAST(sls_ship_dt AS VARCHAR)) != 8 
        THEN NULL
        ELSE TRY_CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
    END AS sls_ship_dt,
    
    -- Date Cleansing: Due Date
    CASE 
        WHEN sls_due_dt IS NULL 
          OR CAST(sls_due_dt AS VARCHAR) = '0' 
          OR LEN(CAST(sls_due_dt AS VARCHAR)) != 8 
        THEN NULL
        ELSE TRY_CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
    END AS sls_due_dt,
    
    -- Quantity Cleansing (Default to 1 if NULL or <= 0)
    CASE 
        WHEN sls_quantity IS NULL OR sls_quantity <= 0 THEN 1
        ELSE sls_quantity
    END AS sls_quantity,
    
    -- Price Cleansing & Imputation (Derive price if missing/invalid using sales & quantity)
    CASE 
        WHEN (sls_price IS NULL OR sls_price <= 0) AND sls_sales > 0 
            THEN sls_sales / NULLIF(
                CASE WHEN sls_quantity IS NULL OR sls_quantity <= 0 THEN 1 ELSE sls_quantity END, 0
            )
        ELSE ABS(sls_price)
    END AS sls_price,
    
    -- Sales Cleansing & Recalculation (Ensure sales = price * quantity)
    CASE 
        WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != (ABS(sls_price) * sls_quantity)
            THEN (
                CASE 
                    WHEN (sls_price IS NULL OR sls_price <= 0) AND sls_sales > 0 
                        THEN sls_sales / NULLIF(
                            CASE WHEN sls_quantity IS NULL OR sls_quantity <= 0 THEN 1 ELSE sls_quantity END, 0
                        )
                    ELSE ABS(sls_price)
                END
            ) * (
                CASE WHEN sls_quantity IS NULL OR sls_quantity <= 0 THEN 1 ELSE sls_quantity END
            )
        ELSE ABS(sls_sales)
    END AS sls_sales

FROM bronze.crm_sales_details;
