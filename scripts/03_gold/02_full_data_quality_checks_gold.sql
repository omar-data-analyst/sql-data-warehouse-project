/*
===============================================================================
Script: full_data_quality_checks_gold.sql
Description: 
    Master Data Quality Test Suite for the Gold Layer.
    Validates data integrity, uniqueness, domain logic, referential integrity, 
    and date sequence across Customers, Products, and Sales Fact tables.

Expected Result for ALL queries: 0 rows (except distinct standardization checks).
===============================================================================
*/

-- ============================================================================
-- SECTION 1: PRODUCT DIMENSION CHECKS (gold.dim_products)
-- ============================================================================

-- 1.1 Check Uniqueness of Primary Key
SELECT 
    'dim_products: Duplicate product_key' AS check_name,
    product_key, 
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;

-- 1.2 Check Uniqueness of Business Key
SELECT 
    'dim_products: Duplicate product_number' AS check_name,
    product_number, 
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_number
HAVING COUNT(*) > 1;

-- 1.3 Check Mandatory NULL Keys/Names
SELECT 
    'dim_products: NULL Keys or Name' AS check_name,
    *
FROM gold.dim_products
WHERE product_key IS NULL 
   OR product_number IS NULL 
   OR product_name IS NULL;

-- 1.4 Domain Logic Test: Negative or Invalid Cost
SELECT 
    'dim_products: Invalid Cost' AS check_name,
    *
FROM gold.dim_products
WHERE cost < 0 OR cost IS NULL;

-- 1.5 Category Join Integrity Check
SELECT 
    'dim_products: Unmapped Category' AS check_name,
    product_number,
    category_id
FROM gold.dim_products
WHERE category IS NULL AND category_id IS NOT NULL;


-- ============================================================================
-- SECTION 2: CUSTOMER DIMENSION CHECKS (gold.dim_customers)
-- ============================================================================

-- 2.1 Check Uniqueness of Primary Key
SELECT 
    'dim_customers: Duplicate customer_key' AS check_name,
    customer_key, 
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- 2.2 Check Uniqueness of Natural/Business Key
SELECT 
    'dim_customers: Duplicate customer_id' AS check_name,
    customer_id, 
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- 2.3 Check Mandatory NULL Keys
SELECT 
    'dim_customers: NULL Keys' AS check_name,
    *
FROM gold.dim_customers
WHERE customer_key IS NULL 
   OR customer_id IS NULL 
   OR customer_number IS NULL;

-- 2.4 Data Standardization Check (Review output manually for allowed values)
SELECT DISTINCT 
    'dim_customers: Distinct Gender Values' AS check_name,
    gender
FROM gold.dim_customers;

-- 2.5 Logic Test: Future Birthdates
SELECT 
    'dim_customers: Future Birthdate' AS check_name,
    *
FROM gold.dim_customers
WHERE birth_date > GETDATE();


-- ============================================================================
-- SECTION 3: SALES FACT TABLE CHECKS (gold.fact_sales)
-- ============================================================================

-- 3.1 Referential Integrity: Orphan Product Keys
SELECT 
    'fact_sales: Orphan Product Key' AS check_name,
    COUNT(*) AS orphan_product_keys
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p 
       ON f.product_key = p.product_key
WHERE f.product_key IS NOT NULL 
  AND p.product_key IS NULL;

-- 3.2 Referential Integrity: Orphan Customer Keys
SELECT 
    'fact_sales: Orphan Customer Key' AS check_name,
    COUNT(*) AS orphan_customer_keys
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c 
       ON f.customer_key = c.customer_key
WHERE f.customer_key IS NOT NULL 
  AND c.customer_key IS NULL;

-- 3.3 Check Mandatory NULL Keys in Fact Table
SELECT 
    'fact_sales: NULL Mandatory Key' AS check_name,
    *
FROM gold.fact_sales
WHERE order_number IS NULL 
   OR product_key IS NULL 
   OR customer_key IS NULL;

-- 3.4 Domain Logic: Invalid or Negative Financial/Quantity Values
SELECT 
    'fact_sales: Invalid Amount, Quantity or Price' AS check_name,
    *
FROM gold.fact_sales
WHERE sales_amount <= 0 
   OR quantity <= 0 
   OR price <= 0;

-- 3.5 Mathematical Consistency Check (sales_amount = quantity * price)
SELECT 
    'fact_sales: Math Discrepancy' AS check_name,
    order_number,
    sales_amount,
    quantity,
    price,
    (quantity * price) AS calculated_sales
FROM gold.fact_sales
WHERE sales_amount <> (quantity * price);

-- 3.6 Date Logic Sequence Check
SELECT 
    'fact_sales: Invalid Date Sequence' AS check_name,
    *
FROM gold.fact_sales
WHERE shipping_date < order_date 
   OR due_date < order_date;
