/*
===============================================================================
script name 	: Create gold_dim_customers.sql
View			: gold.dim_customers
Description		: 
    Creates the Customer Dimension for the Gold Layer in a Star Schema format.
    Consolidates primary customer data from CRM with enriched attributes 
    (demographics and location) from the ERP system.

Business Rules:
    - Generates a unique Surrogate Key (`customer_key`) for warehousing consistency.
    - CRM is designated as the Primary/Master source for Gender details.
    - Uses LEFT JOINs to preserve all core CRM customer records.
===============================================================================
*/

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
    eca.bdate           AS birth_date,
    ela.cntry           AS country,

    -- Metadata / System Audit Column
    cci.cst_create_date AS create_date

FROM silver.crm_cust_info cci 
LEFT JOIN silver.erp_cust_az12 eca
       ON cci.cst_key = eca.cid
LEFT JOIN silver.erp_loc_a101 ela
       ON cci.cst_key = ela.cid;
