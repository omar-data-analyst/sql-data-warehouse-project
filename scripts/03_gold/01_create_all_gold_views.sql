/*
===============================================================================
Script Name : create_gold_views.sql
Description : Creates all Gold Layer Views (Star Schema Data Mart)
              Consolidates Dimensions (Customers, Products) and Fact Table (Sales).
              
Author      : Data Engineering Team
Layer       : Gold
Schema      : gold
===============================================================================
*/

-- ============================================================================
-- 1. Create Dimension: Customers (gold.dim_customers)
-- ============================================================================
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS
SELECT 
    -- Surrogate Key: Unique auto-incrementing identifier for the Gold Layer
    ROW_NUMBER() OVER (ORDER BY cci.cst_id) AS customer_key,

    -- Business Keys: Natural identifiers from the source systems
    cci.cst_id          AS customer_id,
    cci.cst_key         AS customer_number,

    -- Customer Personal Attributes
    cci.cst_firstname   AS first_name,
    cci.cst_lastname    AS last_name,
    cci.cst_marital_status AS marital_status,

    -- Gender Harmonization: CRM prioritized as Master Data, fallback to ERP, default to 'n/a'
    CASE 
        WHEN cci.cst_gndr IS NOT NULL AND cci.cst_gndr != 'n/a' THEN cci.cst_gndr
        ELSE COALESCE(eca.gen, 'n/a') 
    END AS gender, 

    -- Enriched Demographic & Geographic Attributes from ERP
    eca.bdate            AS birth_date,
    ela.cntry            AS country,

    -- Metadata / System Audit Column
    cci.cst_create_date AS create_date

FROM silver.crm_cust_info cci 
LEFT JOIN silver.erp_cust_az12 eca
       ON cci.cst_key = eca.cid
LEFT JOIN silver.erp_loc_a101 ela
       ON cci.cst_key = ela.cid;
GO


-- ============================================================================
-- 2. Create Dimension: Products (gold.dim_products)
-- ============================================================================
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
SELECT 
    -- Surrogate Key: Unique auto-incrementing identifier for the Gold Layer
    ROW_NUMBER() OVER (ORDER BY cpi.prd_start_dt, cpi.prd_key) AS product_key,

    -- Business Key: Natural product identifier from CRM
    cpi.prd_key         AS product_number,

    -- Product Attributes
    cpi.prd_nm          AS product_name,
    cpi.cat_key         AS category_id,
    epcg.cat            AS category,
    epcg.subcat         AS subcategory,
    epcg.maintenance    AS maintenance,
    cpi.prd_cost        AS cost,
    cpi.prd_line        AS product_line,
    cpi.prd_start_dt    AS start_date

FROM silver.crm_prd_info cpi
LEFT JOIN silver.erp_px_cat_g1v2 epcg
       ON cpi.cat_key = epcg.id
WHERE cpi.prd_end_dt IS NULL; -- Filter for active products only
GO


-- ============================================================================
-- 3. Create Fact Table: Sales (gold.fact_sales)
-- ============================================================================
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS
SELECT 
    -- Degenerate Dimension / Business Key
    sd.sls_ord_num     AS order_number,

    -- Foreign Keys linked to Gold Dimensions (Surrogate Keys)
    pr.product_key,
    cu.customer_key,

    -- Transaction Dates
    sd.sls_order_dt    AS order_date,
    sd.sls_ship_dt     AS shipping_date,
    sd.sls_due_dt      AS due_date,

    -- Fact Measures (Metrics)
    sd.sls_sales       AS sales_amount,
    sd.sls_quantity    AS quantity, 
    sd.sls_price       AS price

FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
       ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu
       ON sd.sls_cust_id = cu.customer_id;
GO