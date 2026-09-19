/*
===============================================================================
Script: data_quality_check_gold_fact_sales.sql
Description: 
    Validates Referential Integrity (Orphan Keys), Logical Consistency,
    Numeric Domain Rules, and Date Logic in the Sales Fact Table.
===============================================================================
*/

-- 1. Check Referential Integrity for Product Dimension (Orphan Keys)
-- Expected Result: 0 rows (Ensures every sale links to a valid Product Surrogate Key)
SELECT 
    COUNT(*) AS orphan_product_keys
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p 
       ON f.product_key = p.product_key
WHERE f.product_key IS NOT NULL 
  AND p.product_key IS NULL;

-- 2. Check Referential Integrity for Customer Dimension (Orphan Keys)
-- Expected Result: 0 rows (Ensures every sale links to a valid Customer Surrogate Key)
SELECT 
    COUNT(*) AS orphan_customer_keys
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c 
       ON f.customer_key = c.customer_key
WHERE f.customer_key IS NOT NULL 
  AND c.customer_key IS NULL;

-- 3. Check for Mandatory NULL Keys (Primary Order and Dimension Keys)
-- Expected Result: 0 rows
SELECT *
FROM gold.fact_sales
WHERE order_number IS NULL 
   OR product_key IS NULL 
   OR customer_key IS NULL;

-- 4. Check Data Logic & Domain Constraints (Negative or Invalid Financials)
-- Expected Result: 0 rows (Sales amount, quantity, and price must be positive)
SELECT *
FROM gold.fact_sales
WHERE sales_amount <= 0 
   OR quantity <= 0 
   OR price <= 0;

-- 5. Mathematical Integrity Check (sales_amount = quantity * price)
-- Expected Result: 0 rows (Detects discrepancies in financial calculations)
SELECT 
    order_number,
    sales_amount,
    quantity,
    price,
    (quantity * price) AS calculated_sales
FROM gold.fact_sales
WHERE sales_amount <> (quantity * price);

-- 6. Date Sequence & Logic Test
-- Expected Result: 0 rows (Ship date cannot be earlier than order date)
SELECT *
FROM gold.fact_sales
WHERE shipping_date < order_date 
   OR due_date < order_date;
