-- ============================================================
-- FILE    : ddl_silver.sql
-- PURPOSE : Create all Silver layer tables in DataWarehouse
-- ACTION  : Drop and recreate all 6 Silver tables
-- NOTE    : Running this script will DELETE all Silver data
--           and recreate empty tables
-- ============================================================

USE DataWarehouse;

-- ============================================================
-- CRM TABLES
-- ============================================================

-- 1. Customer Info
DROP TABLE IF EXISTS silver_crm_cust_info;
CREATE TABLE silver_crm_cust_info (
    cst_id              INT,
    cst_key             VARCHAR(50),
    cst_firstname       VARCHAR(50),
    cst_lastname        VARCHAR(50),
    cst_marital_status  VARCHAR(50),
    cst_gndr            VARCHAR(50),
    cst_create_date     DATE,
    dwh_create_date     DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 2. Product Info
-- NOTE: cat_id and prd_key are derived from bronze prd_key
--       prd_start_dt and prd_end_dt changed from DATETIME to DATE
DROP TABLE IF EXISTS silver_crm_prd_info;
CREATE TABLE silver_crm_prd_info (
    prd_id              INT,
    cat_id              VARCHAR(50),
    prd_key             VARCHAR(50),
    prd_nm              VARCHAR(50),
    prd_cost            INT,
    prd_line            VARCHAR(50),
    prd_start_dt        DATE,
    prd_end_dt          DATE,
    dwh_create_date     DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 3. Sales Details
-- NOTE: sls_order_dt / sls_ship_dt / sls_due_dt changed from INT to DATE
--       sls_price changed from INT to DECIMAL to handle decimals
DROP TABLE IF EXISTS silver_crm_sales_details;
CREATE TABLE silver_crm_sales_details (
    sls_ord_num         VARCHAR(50),
    sls_prd_key         VARCHAR(50),
    sls_cust_id         INT,
    sls_order_dt        DATE,
    sls_ship_dt         DATE,
    sls_due_dt          DATE,
    sls_sales           INT,
    sls_quantity        INT,
    sls_price           DECIMAL(10,2),
    dwh_create_date     DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- ERP TABLES
-- ============================================================

-- 4. Customer Demographics
DROP TABLE IF EXISTS silver_erp_cust_az12;
CREATE TABLE silver_erp_cust_az12 (
    CID                 VARCHAR(50),
    BDATE               DATE,
    GEN                 VARCHAR(50),
    dwh_create_date     DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 5. Customer Location
DROP TABLE IF EXISTS silver_erp_loc_a101;
CREATE TABLE silver_erp_loc_a101 (
    CID                 VARCHAR(50),
    CNTRY               VARCHAR(50),
    dwh_create_date     DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 6. Product Category
DROP TABLE IF EXISTS silver_erp_px_cat_g1v2;
CREATE TABLE silver_erp_px_cat_g1v2 (
    ID                  VARCHAR(50),
    CAT                 VARCHAR(50),
    SUBCAT              VARCHAR(50),
    MAINTENANCE         VARCHAR(50),
    dwh_create_date     DATETIME DEFAULT CURRENT_TIMESTAMP
);
