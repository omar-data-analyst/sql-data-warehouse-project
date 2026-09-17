/*
===============================================================================
script name : quality_check_gold_dim_customers.sql

Description: 
    Validates data integrity, uniqueness, and standardization rules for the 
    Customer Dimension before exposing it to reporting tools.
===============================================================================
*/

-- 1. Check for Duplicate Keys (Uniqueness Test)
-- Expected Result: 0 rows
SELECT 
    customer_key, 
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

SELECT 
    customer_id, 
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- 2. Check for NULLs in Primary/Business Keys (Null Value Test)
-- Expected Result: 0 rows
SELECT *
FROM gold.dim_customers
WHERE customer_key IS NULL 
   OR customer_id IS NULL 
   OR customer_number IS NULL;

-- 3. Check Data Standardization (Domain & Value Range Test)
-- Expected Result: Only allowed values ('Male', 'Female', 'n/a')
SELECT DISTINCT 
    gender
FROM gold.dim_customers;

-- 4. Check for Unmapped/Invalid Dates (Logic Test)
-- Expected Result: 0 rows where birth_date is in the future
SELECT *
FROM gold.dim_customers
WHERE birth_date > GETDATE();
