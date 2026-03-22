-- ============================================================
-- FILE    : ddl_bronze.sql
-- PURPOSE : Create all Bronze layer tables in DataWarehouse
-- ACTION  : Drop and recreate all 6 Bronze tables
-- NOTE    : Running this script will DELETE all Bronze data
--           and recreate empty tables. Run proc_load_bronze
--           afterwards to reload data from CSV files
-- ============================================================

USE DataWarehouse;

-- ============================================================
-- CRM TABLES
-- ============================================================

-- 1. Customer Info (raw from CRM source)
DROP TABLE IF EXISTS bronze_crm_cust_info;
CREATE TABLE bronze_crm_cust_info (
    cst_id              INT,
    cst_key             VARCHAR(50),
    cst_firstname       VARCHAR(50),
    cst_lastname        VARCHAR(50),
    cst_marital_status  VARCHAR(50),
    cst_gndr            VARCHAR(50),
    cst_create_date     VARCHAR(30)
);

-- 2. Product Info (raw from CRM source)
DROP TABLE IF EXISTS bronze_crm_prd_info;
CREATE TABLE bronze_crm_prd_info (
    prd_id              INT,
    prd_key             VARCHAR(50),
    prd_nm              VARCHAR(100),
    prd_cost            DECIMAL(10,2),
    prd_line            VARCHAR(50),
    prd_start_dt        VARCHAR(30),
    prd_end_dt          VARCHAR(30)
);

-- 3. Sales Details (raw from CRM source)
DROP TABLE IF EXISTS bronze_crm_sales_details;
CREATE TABLE bronze_crm_sales_details (
    sls_ord_num         VARCHAR(50),
    sls_prd_key         VARCHAR(50),
    sls_cust_id         INT,
    sls_order_dt        INT,
    sls_ship_dt         INT,
    sls_due_dt          INT,
    sls_sales           INT,
    sls_quantity        INT,
    sls_price           INT
);

-- ============================================================
-- ERP TABLES
-- ============================================================

-- 4. Customer Demographics (raw from ERP source)
DROP TABLE IF EXISTS bronze_erp_cust_az12;
CREATE TABLE bronze_erp_cust_az12 (
    CID                 VARCHAR(50),
    BDATE               VARCHAR(30),
    GEN                 VARCHAR(20)
);

-- 5. Customer Location (raw from ERP source)
DROP TABLE IF EXISTS bronze_erp_loc_a101;
CREATE TABLE bronze_erp_loc_a101 (
    CID                 VARCHAR(50),
    CNTRY               VARCHAR(50)
);

-- 6. Product Category (raw from ERP source)
DROP TABLE IF EXISTS bronze_erp_px_cat_g1v2;
CREATE TABLE bronze_erp_px_cat_g1v2 (
    ID                  VARCHAR(20),
    CAT                 VARCHAR(50),
    SUBCAT              VARCHAR(100),
    MAINTENANCE         VARCHAR(10)
);
