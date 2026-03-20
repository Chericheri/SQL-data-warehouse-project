-- ============================================================
-- STORED PROCEDURE : load_bronze
-- DATABASE         : DataWarehouse
-- PURPOSE          : Truncate and track all Bronze tables
--                    with start/end times, duration, and
--                    error handling (TRY/CATCH style)
-- HOW TO RUN       : CALL load_bronze();
-- NOTE             : LOAD DATA runs separately after this
--                    (MySQL does not allow LOAD DATA inside
--                     stored procedures)
-- ============================================================

USE DataWarehouse;

DROP PROCEDURE IF EXISTS load_bronze;

DELIMITER $$

CREATE PROCEDURE load_bronze()
BEGIN

    -- --------------------------------------------------------
    -- DECLARE ALL VARIABLES
    -- --------------------------------------------------------
    -- Batch timing (how long the WHOLE bronze layer takes)
    DECLARE batch_start_time    DATETIME;
    DECLARE batch_end_time      DATETIME;

    -- Per-table timing (how long EACH table takes)
    DECLARE start_time          DATETIME;
    DECLARE end_time            DATETIME;

    -- Error handling variables
    DECLARE error_code          INT      DEFAULT 0;
    DECLARE error_message       TEXT;
    DECLARE error_state         CHAR(5);

    -- --------------------------------------------------------
    -- ERROR HANDLER (MySQL equivalent of TRY...CATCH)
    -- Fires automatically on any SQL error
    -- --------------------------------------------------------
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            error_code    = MYSQL_ERRNO,
            error_message = MESSAGE_TEXT,
            error_state   = RETURNED_SQLSTATE;

        INSERT INTO bronze_log VALUES ('============================================');
        INSERT INTO bronze_log VALUES ('!! ERROR OCCURRED - Bronze Load Aborted !! ');
        INSERT INTO bronze_log VALUES (CONCAT('   Error Code    : ', error_code));
        INSERT INTO bronze_log VALUES (CONCAT('   Error State   : ', error_state));
        INSERT INTO bronze_log VALUES (CONCAT('   Error Message : ', error_message));
        INSERT INTO bronze_log VALUES ('============================================');

        -- Print log up to the point of failure
        SELECT log_message FROM bronze_log;
        DROP TEMPORARY TABLE IF EXISTS bronze_log;
    END;

    -- --------------------------------------------------------
    -- SINGLE RESULT SET LOG TABLE
    -- All messages go here and print ONCE at the end
    -- --------------------------------------------------------
    DROP TEMPORARY TABLE IF EXISTS bronze_log;
    CREATE TEMPORARY TABLE bronze_log (log_message TEXT);

    -- --------------------------------------------------------
    -- START BATCH TIMER
    -- --------------------------------------------------------
    SET batch_start_time = NOW();

    INSERT INTO bronze_log VALUES ('============================================');
    INSERT INTO bronze_log VALUES ('   Loading Bronze Layer                     ');
    INSERT INTO bronze_log VALUES (CONCAT('   Batch Start Time : ', batch_start_time));
    INSERT INTO bronze_log VALUES ('============================================');

    -- ========================================================
    -- SECTION 1: CRM TABLES
    -- ========================================================
    INSERT INTO bronze_log VALUES ('--------------------------------------------');
    INSERT INTO bronze_log VALUES ('   Truncating CRM Tables                    ');
    INSERT INTO bronze_log VALUES ('--------------------------------------------');

    -- Table 1: bronze_crm_cust_info
    SET start_time = NOW();
    INSERT INTO bronze_log VALUES ('>> Truncating Table : bronze_crm_cust_info');
    TRUNCATE TABLE bronze_crm_cust_info;
    SET end_time = NOW();
    INSERT INTO bronze_log VALUES (CONCAT(
        '>> Truncate Duration: ',
        CAST(TIMESTAMPDIFF(SECOND, start_time, end_time) AS CHAR),
        ' seconds'
    ));

    -- Table 2: bronze_crm_prd_info
    SET start_time = NOW();
    INSERT INTO bronze_log VALUES ('>> Truncating Table : bronze_crm_prd_info');
    TRUNCATE TABLE bronze_crm_prd_info;
    SET end_time = NOW();
    INSERT INTO bronze_log VALUES (CONCAT(
        '>> Truncate Duration: ',
        CAST(TIMESTAMPDIFF(SECOND, start_time, end_time) AS CHAR),
        ' seconds'
    ));

    -- Table 3: bronze_crm_sales_details
    SET start_time = NOW();
    INSERT INTO bronze_log VALUES ('>> Truncating Table : bronze_crm_sales_details');
    TRUNCATE TABLE bronze_crm_sales_details;
    SET end_time = NOW();
    INSERT INTO bronze_log VALUES (CONCAT(
        '>> Truncate Duration: ',
        CAST(TIMESTAMPDIFF(SECOND, start_time, end_time) AS CHAR),
        ' seconds'
    ));

    -- ========================================================
    -- SECTION 2: ERP TABLES
    -- ========================================================
    INSERT INTO bronze_log VALUES ('--------------------------------------------');
    INSERT INTO bronze_log VALUES ('   Truncating ERP Tables                    ');
    INSERT INTO bronze_log VALUES ('--------------------------------------------');

    -- Table 4: bronze_erp_cust_az12
    SET start_time = NOW();
    INSERT INTO bronze_log VALUES ('>> Truncating Table : bronze_erp_cust_az12');
    TRUNCATE TABLE bronze_erp_cust_az12;
    SET end_time = NOW();
    INSERT INTO bronze_log VALUES (CONCAT(
        '>> Truncate Duration: ',
        CAST(TIMESTAMPDIFF(SECOND, start_time, end_time) AS CHAR),
        ' seconds'
    ));

    -- Table 5: bronze_erp_loc_a101
    SET start_time = NOW();
    INSERT INTO bronze_log VALUES ('>> Truncating Table : bronze_erp_loc_a101');
    TRUNCATE TABLE bronze_erp_loc_a101;
    SET end_time = NOW();
    INSERT INTO bronze_log VALUES (CONCAT(
        '>> Truncate Duration: ',
        CAST(TIMESTAMPDIFF(SECOND, start_time, end_time) AS CHAR),
        ' seconds'
    ));

    -- Table 6: bronze_erp_px_cat_g1v2
    SET start_time = NOW();
    INSERT INTO bronze_log VALUES ('>> Truncating Table : bronze_erp_px_cat_g1v2');
    TRUNCATE TABLE bronze_erp_px_cat_g1v2;
    SET end_time = NOW();
    INSERT INTO bronze_log VALUES (CONCAT(
        '>> Truncate Duration: ',
        CAST(TIMESTAMPDIFF(SECOND, start_time, end_time) AS CHAR),
        ' seconds'
    ));

    -- --------------------------------------------------------
    -- END BATCH + TOTAL DURATION
    -- --------------------------------------------------------
    SET batch_end_time = NOW();

    INSERT INTO bronze_log VALUES ('============================================');
    INSERT INTO bronze_log VALUES ('   Bronze Layer Truncation Completed ✅     ');
    INSERT INTO bronze_log VALUES (CONCAT('   Batch End Time   : ', batch_end_time));
    INSERT INTO bronze_log VALUES (CONCAT(
        '   Total Batch Duration : ',
        CAST(TIMESTAMPDIFF(SECOND, batch_start_time, batch_end_time) AS CHAR),
        ' seconds'
    ));
    INSERT INTO bronze_log VALUES ('============================================');
    INSERT INTO bronze_log VALUES ('   Now run the LOAD DATA script below  ⬇️  ');
    INSERT INTO bronze_log VALUES ('============================================');

    -- --------------------------------------------------------
    -- PRINT ALL MESSAGES IN ONE SINGLE RESULT SET
    -- --------------------------------------------------------
    SELECT log_message FROM bronze_log;

    DROP TEMPORARY TABLE IF EXISTS bronze_log;

END$$

DELIMITER ;


-- ============================================================
-- LOAD DATA SCRIPT
-- PURPOSE : Load all CSV files into Bronze tables
-- RUN     : Select ALL and press CTRL+SHIFT+ENTER
-- ============================================================

USE DataWarehouse;

-- Step 1: Truncate all tables + print timing log
CALL load_bronze();

-- Step 2: Relax strict mode
SET SESSION sql_mode = '';

-- ============================================================
-- Load + Time each table and collect into ONE result at end
-- ============================================================
SET @batch_start = NOW();

-- ------------------------------------------------------------
-- CRM Tables
-- ------------------------------------------------------------
SET @start = NOW();
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/cust_info.csv'
INTO TABLE bronze_crm_cust_info
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(cst_id, cst_key, cst_firstname, cst_lastname, cst_marital_status, cst_gndr, cst_create_date)
SET cst_id = NULLIF(cst_id, '');
SET @dur_cust_info = TIMESTAMPDIFF(SECOND, @start, NOW());

SET @start = NOW();
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/prd_info.csv'
INTO TABLE bronze_crm_prd_info
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(prd_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt)
SET prd_id   = NULLIF(prd_id, ''),
    prd_cost = NULLIF(prd_cost, '');
SET @dur_prd_info = TIMESTAMPDIFF(SECOND, @start, NOW());

SET @start = NOW();
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/sales_details.csv'
INTO TABLE bronze_crm_sales_details
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(sls_ord_num, sls_prd_key, sls_cust_id, sls_order_dt, sls_ship_dt, sls_due_dt, sls_sales, sls_quantity, sls_price)
SET sls_cust_id  = NULLIF(sls_cust_id, ''),
    sls_order_dt = NULLIF(sls_order_dt, ''),
    sls_ship_dt  = NULLIF(sls_ship_dt, ''),
    sls_due_dt   = NULLIF(sls_due_dt, ''),
    sls_sales    = NULLIF(sls_sales, ''),
    sls_quantity = NULLIF(sls_quantity, ''),
    sls_price    = NULLIF(sls_price, '');
SET @dur_sales = TIMESTAMPDIFF(SECOND, @start, NOW());

-- ------------------------------------------------------------
-- ERP Tables
-- ------------------------------------------------------------
SET @start = NOW();
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/CUST_AZ12.csv'
INTO TABLE bronze_erp_cust_az12
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(CID, BDATE, GEN);
SET @dur_cust_az12 = TIMESTAMPDIFF(SECOND, @start, NOW());

SET @start = NOW();
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/LOC_A101.csv'
INTO TABLE bronze_erp_loc_a101
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(CID, CNTRY);
SET @dur_loc = TIMESTAMPDIFF(SECOND, @start, NOW());

SET @start = NOW();
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/PX_CAT_G1V2.csv'
INTO TABLE bronze_erp_px_cat_g1v2
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(ID, CAT, SUBCAT, MAINTENANCE);
SET @dur_cat = TIMESTAMPDIFF(SECOND, @start, NOW());

SET @batch_end = NOW();

-- ============================================================
-- ONE SINGLE FINAL RESULT SET
-- Row counts + load durations + batch total all in one grid
-- ============================================================
SELECT '============================================'                                      AS log_message
UNION ALL SELECT '   Bronze Layer Load Results                 '
UNION ALL SELECT '============================================'
UNION ALL SELECT '--------------------------------------------'
UNION ALL SELECT '   CRM Tables                               '
UNION ALL SELECT '--------------------------------------------'
UNION ALL SELECT CONCAT('>> bronze_crm_cust_info     | Rows: ',
    (SELECT COUNT(*) FROM bronze_crm_cust_info),
    ' | Duration: ', @dur_cust_info, ' seconds')
UNION ALL SELECT CONCAT('>> bronze_crm_prd_info      | Rows: ',
    (SELECT COUNT(*) FROM bronze_crm_prd_info),
    ' | Duration: ', @dur_prd_info, ' seconds')
UNION ALL SELECT CONCAT('>> bronze_crm_sales_details | Rows: ',
    (SELECT COUNT(*) FROM bronze_crm_sales_details),
    ' | Duration: ', @dur_sales, ' seconds')
UNION ALL SELECT '--------------------------------------------'
UNION ALL SELECT '   ERP Tables                               '
UNION ALL SELECT '--------------------------------------------'
UNION ALL SELECT CONCAT('>> bronze_erp_cust_az12     | Rows: ',
    (SELECT COUNT(*) FROM bronze_erp_cust_az12),
    ' | Duration: ', @dur_cust_az12, ' seconds')
UNION ALL SELECT CONCAT('>> bronze_erp_loc_a101      | Rows: ',
    (SELECT COUNT(*) FROM bronze_erp_loc_a101),
    ' | Duration: ', @dur_loc, ' seconds')
UNION ALL SELECT CONCAT('>> bronze_erp_px_cat_g1v2   | Rows: ',
    (SELECT COUNT(*) FROM bronze_erp_px_cat_g1v2),
    ' | Duration: ', @dur_cat, ' seconds')
UNION ALL SELECT '============================================'
UNION ALL SELECT CONCAT('   Total Batch Duration : ',
    TIMESTAMPDIFF(SECOND, @batch_start, @batch_end), ' seconds')
UNION ALL SELECT '   Bronze Layer Loaded Successfully! 🎉     '
UNION ALL SELECT '============================================';
