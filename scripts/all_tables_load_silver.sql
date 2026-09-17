/*
===============================================================================
Stored Procedure: all_tables_load_silver.sql
Description     : Executes the full Refresh ETL pipeline for the Silver Layer.
                  Cleanses, standardizes, deduplicates, and enriches raw data 
                  from the Bronze Layer tables and loads it into the Silver Layer.
                  
Tables Loaded   : 
    1. silver.crm_cust_info
    2. silver.crm_prd_info
    3. silver.crm_sales_details
    4. silver.erp_cust_az12
    5. silver.erp_loc_a101
    6. silver.erp_px_cat_g1v2

Execution       : EXEC silver.load_silver;

WARNING / PRECAUTIONS:
    - DATA TRUNCATION RISK: This procedure truncates all target Silver tables 
      prior to reloading data (Full Refresh Strategy).
    - TRANSACTION MANAGEMENT: Uses TRY...CATCH to roll back changes automatically 
      if any error occurs during pipeline execution.
===============================================================================
*/

-- For Texting The PROCEDURE
-- EXEC silver.load_silver

CREATE OR ALTER PROCEDURE silver.load_silver
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
    
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '===============================================================================';
        PRINT 'Starting Silver Layer Load Process';
        PRINT '===============================================================================';

        -------------------------------------------------------------------------------
        -- 1. Loading silver.crm_cust_info
        -------------------------------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Truncating and Loading: silver.crm_cust_info';
        
        TRUNCATE TABLE silver.crm_cust_info;

        INSERT INTO silver.crm_cust_info (
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_marital_status,
            cst_gndr,
            cst_create_date,
            dwh_create_date
        )
        SELECT 
            cst_id,
            cst_key,
            TRIM(cst_firstname) AS cst_firstname,
            TRIM(cst_lastname)  AS cst_lastname,
            CASE 
                WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
                WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
                ELSE 'n/a'
            END AS cst_marital_status,
            CASE 
                WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
                WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
                ELSE 'n/a'
            END AS cst_gndr,
            cst_create_date,
            GETDATE() AS dwh_create_date
        FROM (
            SELECT 
                *,
                ROW_NUMBER() OVER(
                    PARTITION BY cst_id 
                    ORDER BY cst_create_date DESC
                ) AS flag
            FROM bronze.crm_cust_info
            WHERE cst_id IS NOT NULL
        ) t
        WHERE flag = 1;

        SET @end_time = GETDATE();
        PRINT '>> Loaded silver.crm_cust_info | Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds';
        PRINT '-------------------------------------------------------------------------------';

        -------------------------------------------------------------------------------
        -- 2. Loading silver.crm_prd_info
        -------------------------------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Truncating and Loading: silver.crm_prd_info';

        TRUNCATE TABLE silver.crm_prd_info;

        INSERT INTO silver.crm_prd_info (
            prd_id,
            cat_key,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt,
            dwh_create_date
        )
        SELECT 
            prd_id,
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_key,
            REPLACE(SUBSTRING(prd_key, 7, LEN(prd_key)), '-', '_') AS prd_key,
            TRIM(prd_nm) AS prd_nm,
            ISNULL(prd_cost, 0) AS prd_cost,
            CASE UPPER(TRIM(prd_line))
                WHEN 'M' THEN 'Mountain'
                WHEN 'R' THEN 'Road'
                WHEN 'S' THEN 'Other Sales'
                WHEN 'T' THEN 'Touring'
                ELSE 'n/a'
            END AS prd_line,
            CAST(prd_start_dt AS DATE) AS prd_start_dt,
            CAST(
                DATEADD(day, -1, LEAD(prd_start_dt) OVER (
                    PARTITION BY REPLACE(SUBSTRING(prd_key, 7, LEN(prd_key)), '-', '_') 
                    ORDER BY prd_start_dt
                )) AS DATE
            ) AS prd_end_dt,
            GETDATE() AS dwh_create_date
        FROM bronze.crm_prd_info
        WHERE
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') 
            IN (SELECT id FROM bronze.erp_px_cat_g1v2 WHERE id IS NOT NULL)
            AND
            REPLACE(SUBSTRING(prd_key, 7, LEN(prd_key)), '-', '_') 
            IN (SELECT REPLACE(sls_prd_key, '-', '_') FROM bronze.crm_sales_details WHERE sls_prd_key IS NOT NULL);

        SET @end_time = GETDATE();
        PRINT '>> Loaded silver.crm_prd_info | Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds';
        PRINT '-------------------------------------------------------------------------------';

        -------------------------------------------------------------------------------
        -- 3. Loading silver.crm_sales_details
        -------------------------------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Truncating and Loading: silver.crm_sales_details';

        TRUNCATE TABLE silver.crm_sales_details;

        INSERT INTO silver.crm_sales_details (
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_quantity,
            sls_price,
            sls_sales,
            dwh_create_date
        )
        SELECT
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            CASE 
                WHEN sls_order_dt IS NULL OR CAST(sls_order_dt AS VARCHAR) = '0' OR LEN(CAST(sls_order_dt AS VARCHAR)) != 8 
                THEN NULL
                ELSE TRY_CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
            END AS sls_order_dt,
            CASE 
                WHEN sls_ship_dt IS NULL OR CAST(sls_ship_dt AS VARCHAR) = '0' OR LEN(CAST(sls_ship_dt AS VARCHAR)) != 8 
                THEN NULL
                ELSE TRY_CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
            END AS sls_ship_dt,
            CASE 
                WHEN sls_due_dt IS NULL OR CAST(sls_due_dt AS VARCHAR) = '0' OR LEN(CAST(sls_due_dt AS VARCHAR)) != 8 
                THEN NULL
                ELSE TRY_CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
            END AS sls_due_dt,
            CASE 
                WHEN sls_quantity IS NULL OR sls_quantity <= 0 THEN 1
                ELSE sls_quantity
            END AS sls_quantity,
            CASE 
                WHEN (sls_price IS NULL OR sls_price <= 0) AND sls_sales > 0 
                    THEN sls_sales / NULLIF(CASE WHEN sls_quantity IS NULL OR sls_quantity <= 0 THEN 1 ELSE sls_quantity END, 0)
                ELSE ABS(sls_price)
            END AS sls_price,
            CASE 
                WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != (ABS(sls_price) * sls_quantity)
                    THEN (
                        CASE 
                            WHEN (sls_price IS NULL OR sls_price <= 0) AND sls_sales > 0 
                                THEN sls_sales / NULLIF(CASE WHEN sls_quantity IS NULL OR sls_quantity <= 0 THEN 1 ELSE sls_quantity END, 0)
                            ELSE ABS(sls_price)
                        END
                    ) * (
                        CASE WHEN sls_quantity IS NULL OR sls_quantity <= 0 THEN 1 ELSE sls_quantity END
                    )
                ELSE ABS(sls_sales)
            END AS sls_sales,
            GETDATE() AS dwh_create_date
        FROM bronze.crm_sales_details;

        SET @end_time = GETDATE();
        PRINT '>> Loaded silver.crm_sales_details | Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds';
        PRINT '-------------------------------------------------------------------------------';

        -------------------------------------------------------------------------------
        -- 4. Loading silver.erp_cust_az12
        -------------------------------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Truncating and Loading: silver.erp_cust_az12';

        TRUNCATE TABLE silver.erp_cust_az12;

        INSERT INTO silver.erp_cust_az12 (
            cid,
            gen,
            bdate,
            dwh_create_date
        )
        SELECT 
            CASE 
                WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
                ELSE cid 
            END AS cid,
            CASE 
                WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
                WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
                ELSE 'n/a'
            END AS gen,
            CASE 
                WHEN bdate > GETDATE() THEN NULL
                ELSE bdate
            END AS bdate,
            GETDATE() AS dwh_create_date
        FROM bronze.erp_cust_az12;

        SET @end_time = GETDATE();
        PRINT '>> Loaded silver.erp_cust_az12 | Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds';
        PRINT '-------------------------------------------------------------------------------';

        -------------------------------------------------------------------------------
        -- 5. Loading silver.erp_loc_a101
        -------------------------------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Truncating and Loading: silver.erp_loc_a101';

        TRUNCATE TABLE silver.erp_loc_a101;

        INSERT INTO silver.erp_loc_a101 (
            cid,
            cntry,
            dwh_create_date
        )
        SELECT 
            REPLACE(cid, '-', '') AS cid,
            CASE 
                WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'Germany'
                WHEN UPPER(TRIM(cntry)) IN ('US', 'USA') THEN 'United States'
                WHEN UPPER(TRIM(cntry)) = '' OR cntry IS NULL THEN 'n/a'
                ELSE TRIM(cntry)
            END AS cntry,
            GETDATE() AS dwh_create_date
        FROM bronze.erp_loc_a101;

        SET @end_time = GETDATE();
        PRINT '>> Loaded silver.erp_loc_a101 | Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds';
        PRINT '-------------------------------------------------------------------------------';

        -------------------------------------------------------------------------------
        -- 6. Loading silver.erp_px_cat_g1v2
        -------------------------------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Truncating and Loading: silver.erp_px_cat_g1v2';

        TRUNCATE TABLE silver.erp_px_cat_g1v2;

        INSERT INTO silver.erp_px_cat_g1v2 (
            id,
            cat,
            subcat,
            maintenance,
            dwh_create_date
        )
        SELECT 
            TRIM(id) AS id,
            CASE 
                WHEN cat IS NULL OR TRIM(cat) = '' THEN 'n/a'
                ELSE TRIM(cat)
            END AS cat,
            CASE 
                WHEN subcat IS NULL OR TRIM(subcat) = '' THEN 'n/a'
                ELSE TRIM(subcat)
            END AS subcat,
            CASE 
                WHEN maintenance IS NULL OR TRIM(maintenance) = '' THEN 'n/a'
                ELSE TRIM(maintenance)
            END AS maintenance,
            GETDATE() AS dwh_create_date
        FROM bronze.erp_px_cat_g1v2;

        SET @end_time = GETDATE();
        PRINT '>> Loaded silver.erp_px_cat_g1v2 | Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds';
        PRINT '-------------------------------------------------------------------------------';

        SET @batch_end_time = GETDATE();
        PRINT '===============================================================================';
        PRINT 'Silver Layer Load Process Completed Successfully!';
        PRINT 'Total Execution Time: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS VARCHAR) + ' seconds';
        PRINT '===============================================================================';

    END TRY
    BEGIN CATCH
        PRINT '===============================================================================';
        PRINT 'ERROR OCCURRED DURING SILVER LAYER LOAD!';
        PRINT 'Error Message : ' + ERROR_MESSAGE();
        PRINT 'Error Number  : ' + CAST(ERROR_NUMBER() AS VARCHAR);
        PRINT 'Error State   : ' + CAST(ERROR_STATE() AS VARCHAR);
        PRINT '===============================================================================';
        
        THROW;
    END CATCH
END;
