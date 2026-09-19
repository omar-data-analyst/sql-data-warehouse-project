/*
===============================================================================
Script Name   : 02_create_bronze_tables.sql
Description   : DDL script to create all raw tables in the 'bronze' schema.
                Sources: CRM System & ERP System.

WARNING / NOTE:
  - This script is intended ONLY for the Bronze layer.
  - Tables are created without PRIMARY KEYs, FOREIGN KEYs, or NOT NULL constraints 
    to preserve raw data integrity and avoid ETL ingestion failures.
  - Existing tables will be DROPPED and RECREATED upon execution.
===============================================================================
*/

USE DataWarehouse;
GO

PRINT '===============================================================================';
PRINT 'Creating Bronze Layer Tables';
PRINT '===============================================================================';
GO

-------------------------------------------------------------------------------
-- 1. CRM Tables
-------------------------------------------------------------------------------

-- Table: bronze.crm_cust_info
IF OBJECT_ID('bronze.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_cust_info;
GO

CREATE TABLE bronze.crm_cust_info (
    cst_id             INT,
    cst_key            NVARCHAR(50),
    cst_firstname      NVARCHAR(50),
    cst_lastname       NVARCHAR(50),
    cst_marital_status NVARCHAR(10),
    cst_gndr           NVARCHAR(10),
    cst_create_date    DATE
);
GO
PRINT 'Created table: bronze.crm_cust_info';
GO

-- Table: bronze.crm_prd_info
IF OBJECT_ID('bronze.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_prd_info;
GO

CREATE TABLE bronze.crm_prd_info (
    prd_id          INT,
    prd_key         NVARCHAR(50),
    prd_nm          NVARCHAR(100),
    prd_cost        INT,
    prd_line        NVARCHAR(10),
    prd_start_dt    DATETIME,
    prd_end_dt      DATETIME
);
GO
PRINT 'Created table: bronze.crm_prd_info';
GO

-- Table: bronze.crm_sales_details
IF OBJECT_ID('bronze.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE bronze.crm_sales_details;
GO

CREATE TABLE bronze.crm_sales_details (
    sls_ord_num     NVARCHAR(50),
    sls_prd_key     NVARCHAR(50),
    sls_cust_id     INT,
    sls_order_dt    INT,
    sls_ship_dt     INT,
    sls_due_dt      INT,
    sls_sales       INT,
    sls_quantity    INT,
    sls_price       INT
);
GO
PRINT 'Created table: bronze.crm_sales_details';
GO

-------------------------------------------------------------------------------
-- 2. ERP Tables
-------------------------------------------------------------------------------

-- Table: bronze.erp_cust_az12
IF OBJECT_ID('bronze.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE bronze.erp_cust_az12;
GO

CREATE TABLE bronze.erp_cust_az12 (
    cid     NVARCHAR(50),
    bdate   DATE,
    gen     NVARCHAR(20)
);
GO
PRINT 'Created table: bronze.erp_cust_az12';
GO

-- Table: bronze.erp_loc_a101
IF OBJECT_ID('bronze.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE bronze.erp_loc_a101;
GO

CREATE TABLE bronze.erp_loc_a101 (
    cid     NVARCHAR(50),
    cntry   NVARCHAR(50)
);
GO
PRINT 'Created table: bronze.erp_loc_a101';
GO

-- Table: bronze.erp_px_cat_g1v2
IF OBJECT_ID('bronze.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE bronze.erp_px_cat_g1v2;
GO

CREATE TABLE bronze.erp_px_cat_g1v2 (
    id          NVARCHAR(50),
    cat         NVARCHAR(50),
    subcat      NVARCHAR(50),
    maintenance NVARCHAR(10)
);
GO
PRINT 'Created table: bronze.erp_px_cat_g1v2';
GO

PRINT '===============================================================================';
PRINT 'Bronze Layer Tables Created Successfully';
PRINT '===============================================================================';
GO
