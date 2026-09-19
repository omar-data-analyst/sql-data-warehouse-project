/*
===============================================================================
Script        : gold.dim_products
Description   : create_gold_dim_products.sql
    Creates the Product Dimension for the Gold Layer in a Star Schema format.
    Consolidates product details from the CRM with category hierarchies 
    and maintenance attributes from the ERP system.

Business Rules:
    - Generates a unique Surrogate Key (`product_key`) using ROW_NUMBER().
    - Filters out historical/expired products using `prd_end_dt IS NULL` 
      to retain only currently active products.
    - Excludes operational database IDs (`prd_id`) in favor of standardized keys.
===============================================================================
*/

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
