/*
===============================================================================
Script: data_quality_check_gold_dim_products.sql
Description: 
    Validates data integrity, uniqueness, null values, and join matching
    for the Product Dimension.
===============================================================================
*/

-- 1. Check for Duplicate Keys (Uniqueness Test)
-- Expected Result: 0 rows
SELECT 
    product_key, 
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;

SELECT 
    product_number, 
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_number
HAVING COUNT(*) > 1;

-- 2. Check for NULLs in Primary & Business Keys (Null Value Test)
-- Expected Result: 0 rows
SELECT *
FROM gold.dim_products
WHERE product_key IS NULL 
   OR product_number IS NULL 
   OR product_name IS NULL;

-- 3. Check for Negative or Invalid Costs (Domain Logic Test)
-- Expected Result: 0 rows
SELECT *
FROM gold.dim_products
WHERE cost < 0 OR cost IS NULL;

-- 4. Check Category Join Integrity (Orphan/Unmapped Categories)
-- Expected Result: 0 rows (unless unmapped categories are intended as NULL)
SELECT 
    product_number,
    category_id
FROM gold.dim_products
WHERE category IS NULL AND category_id IS NOT NULL;
