-- ============================================================
-- FILE    : quality_checks_gold.sql
-- PURPOSE : Validate integrity and accuracy of Gold layer
-- CHECKS  : Uniqueness of surrogate keys
--           Data model connectivity (joins work correctly)
--           No orphan records in fact table
-- USAGE   : Run after ddl_gold.sql
--           Expected result = 0 rows on all checks
-- ============================================================

USE DataWarehouse;

-- ============================================================
-- VIEW 1: gold_dim_customers
-- ============================================================

-- Check 1: Surrogate key is unique
SELECT
    customer_key,
    COUNT(*) AS count
FROM gold_dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- Check 2: No NULL surrogate keys
SELECT * FROM gold_dim_customers
WHERE customer_key IS NULL;

-- Check 3: Gender values are standardised
SELECT DISTINCT gender FROM gold_dim_customers;
-- Expected: Male / Female / n/a only

-- Check 4: Country values are standardised
SELECT DISTINCT country FROM gold_dim_customers
ORDER BY country;

-- Check 5: Row count
SELECT COUNT(*) AS total_customers FROM gold_dim_customers;


-- ============================================================
-- VIEW 2: gold_dim_products
-- ============================================================

-- Check 1: Surrogate key is unique
SELECT
    product_key,
    COUNT(*) AS count
FROM gold_dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;

-- Check 2: No NULL surrogate keys
SELECT * FROM gold_dim_products
WHERE product_key IS NULL;

-- Check 3: Product number is unique (no history leaked through)
SELECT
    product_number,
    COUNT(*) AS count
FROM gold_dim_products
GROUP BY product_number
HAVING COUNT(*) > 1;

-- Check 4: No NULL categories
SELECT DISTINCT category FROM gold_dim_products;
-- Expected: no NULLs — should show n/a instead

-- Check 5: Row count
SELECT COUNT(*) AS total_products FROM gold_dim_products;


-- ============================================================
-- VIEW 3: gold_fact_sales
-- ============================================================

-- Check 1: No orphan transactions (unmatched customers)
SELECT * FROM gold_fact_sales
WHERE customer_key IS NULL;

-- Check 2: No orphan transactions (unmatched products)
SELECT * FROM gold_fact_sales
WHERE product_key IS NULL;

-- Check 3: Sales rule holds (sales = quantity x price)
SELECT *
FROM gold_fact_sales
WHERE sales_amount != quantity * price
   OR sales_amount IS NULL
   OR quantity IS NULL
   OR price IS NULL;

-- Check 4: No negative or zero measures
SELECT * FROM gold_fact_sales
WHERE sales_amount <= 0
   OR quantity    <= 0
   OR price       <= 0;

-- Check 5: Row count
SELECT COUNT(*) AS total_transactions FROM gold_fact_sales;


-- ============================================================
-- FULL DATA MODEL CONNECTIVITY CHECK
-- Join all 3 Gold tables together
-- ============================================================

-- Check: Full star schema join works correctly
SELECT
    f.order_number,
    f.order_date,
    f.sales_amount,
    c.first_name,
    c.last_name,
    c.country,
    p.product_name,
    p.category,
    p.product_line
FROM gold_fact_sales f
LEFT JOIN gold_dim_customers c ON f.customer_key = c.customer_key
LEFT JOIN gold_dim_products  p ON f.product_key  = p.product_key
LIMIT 20;

-- Check: No unmatched customers in fact
SELECT f.*
FROM gold_fact_sales f
LEFT JOIN gold_dim_customers c ON f.customer_key = c.customer_key
WHERE c.customer_key IS NULL;

-- Check: No unmatched products in fact
SELECT f.*
FROM gold_fact_sales f
LEFT JOIN gold_dim_products p ON f.product_key = p.product_key
WHERE p.product_key IS NULL;


-- ============================================================
-- FINAL: Row count summary across all Gold views
-- ============================================================
SELECT 'gold_dim_customers' AS view_name, COUNT(*) AS row_count FROM gold_dim_customers
UNION ALL
SELECT 'gold_dim_products',               COUNT(*) FROM gold_dim_products
UNION ALL
SELECT 'gold_fact_sales',                 COUNT(*) FROM gold_fact_sales;
