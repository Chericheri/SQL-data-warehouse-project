-- ============================================================
-- QUALITY CHECKS : Silver Layer
-- PURPOSE        : Validate data quality after Silver load
-- HOW TO USE     : Run after CALL load_silver()
--                  Expected result = 0 rows on all checks
-- ============================================================

USE DataWarehouse;

-- ============================================================
-- TABLE 1: silver_crm_cust_info
-- ============================================================

-- Check 1: No duplicate or NULL customer IDs
SELECT
    cst_id,
    COUNT(*) AS count
FROM silver_crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Check 2: No unwanted spaces in firstname or lastname
SELECT * FROM silver_crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)
   OR cst_lastname  != TRIM(cst_lastname);

-- Check 3: Gender values are standardised
SELECT DISTINCT cst_gndr FROM silver_crm_cust_info;
-- Expected: Male / Female / n/a only

-- Check 4: Marital status values are standardised
SELECT DISTINCT cst_marital_status FROM silver_crm_cust_info;
-- Expected: Married / Single / n/a only

-- Check 5: No NULL create dates
SELECT * FROM silver_crm_cust_info
WHERE cst_create_date IS NULL;


-- ============================================================
-- TABLE 2: silver_crm_prd_info
-- ============================================================

-- Check 1: No duplicate or NULL product IDs
SELECT
    prd_id,
    COUNT(*) AS count
FROM silver_crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Check 2: No NULL or negative costs
SELECT * FROM silver_crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Check 3: Product line values are standardised
SELECT DISTINCT prd_line FROM silver_crm_prd_info;
-- Expected: Mountain / Road / Other Sales / Touring / n/a only

-- Check 4: No end date before start date
SELECT * FROM silver_crm_prd_info
WHERE prd_end_dt < prd_start_dt;

-- Check 5: cat_id matches ERP category table
SELECT DISTINCT cat_id
FROM silver_crm_prd_info
WHERE cat_id NOT IN (SELECT ID FROM silver_erp_px_cat_g1v2);


-- ============================================================
-- TABLE 3: silver_crm_sales_details
-- ============================================================

-- Check 1: No invalid dates (order after ship or due)
SELECT * FROM silver_crm_sales_details
WHERE sls_order_dt > sls_ship_dt
   OR sls_order_dt > sls_due_dt;

-- Check 2: Business rule → sales = quantity × price
SELECT
    sls_sales,
    sls_quantity,
    sls_price,
    sls_quantity * sls_price AS expected_sales
FROM silver_crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales    IS NULL
   OR sls_quantity IS NULL
   OR sls_price    IS NULL;

-- Check 3: No negative or zero values
SELECT * FROM silver_crm_sales_details
WHERE sls_sales    <= 0
   OR sls_quantity <= 0
   OR sls_price    <= 0;


-- ============================================================
-- TABLE 4: silver_erp_cust_az12
-- ============================================================

-- Check 1: No future birthdates
SELECT * FROM silver_erp_cust_az12
WHERE BDATE > NOW();

-- Check 2: No very old birthdates (older than 1900)
SELECT * FROM silver_erp_cust_az12
WHERE BDATE < '1900-01-01';

-- Check 3: Gender values are standardised
SELECT DISTINCT GEN FROM silver_erp_cust_az12;
-- Expected: Male / Female / n/a only

-- Check 4: CID matches CRM customer key
SELECT s.CID
FROM silver_erp_cust_az12 s
LEFT JOIN silver_crm_cust_info c ON s.CID = c.cst_key
WHERE c.cst_key IS NULL
LIMIT 10;


-- ============================================================
-- TABLE 5: silver_erp_loc_a101
-- ============================================================

-- Check 1: No NULL or empty countries
SELECT * FROM silver_erp_loc_a101
WHERE CNTRY IS NULL OR CNTRY = '';

-- Check 2: Country values are standardised
SELECT DISTINCT CNTRY FROM silver_erp_loc_a101
ORDER BY CNTRY;
-- Expected: Full country names only, no abbreviations

-- Check 3: CID matches CRM customer key
SELECT s.CID
FROM silver_erp_loc_a101 s
LEFT JOIN silver_crm_cust_info c ON s.CID = c.cst_key
WHERE c.cst_key IS NULL
LIMIT 10;


-- ============================================================
-- TABLE 6: silver_erp_px_cat_g1v2
-- ============================================================

-- Check 1: No unwanted spaces
SELECT * FROM silver_erp_px_cat_g1v2
WHERE CAT         != TRIM(CAT)
   OR SUBCAT      != TRIM(SUBCAT)
   OR MAINTENANCE != TRIM(MAINTENANCE);

-- Check 2: Category values look correct
SELECT DISTINCT CAT FROM silver_erp_px_cat_g1v2;
-- Expected: Accessories / Bikes / Clothing / Components

-- Check 3: Maintenance values look correct
SELECT DISTINCT MAINTENANCE FROM silver_erp_px_cat_g1v2;
-- Expected: Yes / No only


-- ============================================================
-- FINAL: Row count verification
-- ============================================================
SELECT 'silver_crm_cust_info'    AS table_name, COUNT(*) AS row_count FROM silver_crm_cust_info
UNION ALL
SELECT 'silver_crm_prd_info',                   COUNT(*) FROM silver_crm_prd_info
UNION ALL
SELECT 'silver_crm_sales_details',              COUNT(*) FROM silver_crm_sales_details
UNION ALL
SELECT 'silver_erp_cust_az12',                  COUNT(*) FROM silver_erp_cust_az12
UNION ALL
SELECT 'silver_erp_loc_a101',                   COUNT(*) FROM silver_erp_loc_a101
UNION ALL
SELECT 'silver_erp_px_cat_g1v2',               COUNT(*) FROM silver_erp_px_cat_g1v2;
