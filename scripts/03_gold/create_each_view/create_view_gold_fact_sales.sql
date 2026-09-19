/*
===============================================================================
View			    : create_view_gold_fact_sales.sql
Description 	: 
    Creates the Sales Fact Table for the Gold Layer in a Star Schema format.
    Consolidates transaction metrics from CRM Sales Details and resolves 
    foreign keys to Surrogate Keys from Customer and Product Dimensions.

Business Rules	:
    - Integrates core transaction metrics (sales amount, quantity, price).
    - Resolves natural product and customer keys into Gold Layer Surrogate Keys.
===============================================================================
*/

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
