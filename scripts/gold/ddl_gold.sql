-- ============================================================
-- FILE    : ddl_gold.sql
-- PURPOSE : Create all Gold layer views in DataWarehouse
-- ACTION  : Creates 3 views representing the Star Schema
--           dim_customers | dim_products | fact_sales
-- NOTE    : Views always read latest Silver data
--           No stored procedure needed for Gold layer
-- USAGE   : SELECT * FROM gold_dim_customers;
--           SELECT * FROM gold_dim_products;
--           SELECT * FROM gold_fact_sales;
-- ============================================================

USE DataWarehouse;

-- ============================================================
-- VIEW 1: gold_dim_customers
-- TYPE   : Dimension
-- SOURCE : silver_crm_cust_info (master)
--        + silver_erp_cust_az12 (birthdate + gender)
--        + silver_erp_loc_a101  (country)
-- KEY    : customer_key (surrogate — system generated)
-- ============================================================

CREATE OR REPLACE VIEW gold_dim_customers AS
SELECT
    -- Surrogate Key
    ROW_NUMBER() OVER (ORDER BY ci.cst_id)      AS customer_key,

    -- From CRM
    ci.cst_id                                   AS customer_id,
    ci.cst_key                                  AS customer_number,
    ci.cst_firstname                            AS first_name,
    ci.cst_lastname                             AS last_name,

    -- From ERP location
    la.CNTRY                                    AS country,

    ci.cst_marital_status                       AS marital_status,

    -- Data Integration: CRM is master for gender
    -- If CRM has value use it, otherwise fallback to ERP
    CASE
        WHEN ci.cst_gndr != 'n/a'
        THEN ci.cst_gndr
        ELSE COALESCE(ca.GEN, 'n/a')
    END                                         AS gender,

    -- From ERP demographics
    ca.BDATE                                    AS birth_date,

    -- From CRM
    ci.cst_create_date                          AS create_date

FROM silver_crm_cust_info ci
LEFT JOIN silver_erp_cust_az12 ca ON ci.cst_key = ca.CID
LEFT JOIN silver_erp_loc_a101  la ON ci.cst_key = la.CID;


-- ============================================================
-- VIEW 2: gold_dim_products
-- TYPE   : Dimension
-- SOURCE : silver_crm_prd_info (master — current only)
--        + silver_erp_px_cat_g1v2 (category info)
-- KEY    : product_key (surrogate — system generated)
-- NOTE   : Historical products filtered out (prd_end_dt IS NULL)
-- ============================================================

CREATE OR REPLACE VIEW gold_dim_products AS
SELECT
    -- Surrogate Key
    ROW_NUMBER() OVER (
        ORDER BY pn.prd_start_dt, pn.prd_key
    )                                           AS product_key,

    -- Product identifiers
    pn.prd_id                                   AS product_id,
    pn.prd_key                                  AS product_number,
    pn.prd_nm                                   AS product_name,

    -- Category info from ERP
    pn.cat_id                                   AS category_id,
    COALESCE(pc.CAT,         'n/a')             AS category,
    COALESCE(pc.SUBCAT,      'n/a')             AS subcategory,
    COALESCE(pc.MAINTENANCE, 'n/a')             AS maintenance,

    -- Product details
    pn.prd_cost                                 AS cost,
    pn.prd_line                                 AS product_line,
    pn.prd_start_dt                             AS start_date

FROM silver_crm_prd_info pn
LEFT JOIN silver_erp_px_cat_g1v2 pc ON pn.cat_id = pc.ID
-- Filter: current products only (NULL end date = still active)
WHERE pn.prd_end_dt IS NULL;


-- ============================================================
-- VIEW 3: gold_fact_sales
-- TYPE   : Fact
-- SOURCE : silver_crm_sales_details
-- KEY    : product_key + customer_key (surrogate from dimensions)
-- NOTE   : Surrogate keys fetched via data lookup joins
--          Business rule: sales_amount = quantity x price
-- ============================================================

CREATE OR REPLACE VIEW gold_fact_sales AS
SELECT
    -- Surrogate keys from dimensions (data lookup)
    pr.product_key                              AS product_key,
    cu.customer_key                             AS customer_key,

    -- Dates
    sd.sls_order_dt                             AS order_date,
    sd.sls_ship_dt                              AS ship_date,
    sd.sls_due_dt                               AS due_date,

    -- Order identifier
    sd.sls_ord_num                              AS order_number,

    -- Measures
    sd.sls_sales                                AS sales_amount,
    sd.sls_quantity                             AS quantity,
    sd.sls_price                                AS price

FROM silver_crm_sales_details sd
-- Data lookup: get surrogate key from dim_products
LEFT JOIN gold_dim_products  pr ON sd.sls_prd_key = pr.product_number
-- Data lookup: get surrogate key from dim_customers
LEFT JOIN gold_dim_customers cu ON sd.sls_cust_id = cu.customer_id;
