-- ============================================================
-- STORED PROCEDURE : load_silver
-- DATABASE         : DataWarehouse
-- PURPOSE          : Clean and load all Silver tables from
--                    Bronze with timing, logging and error
--                    handling (TRY/CATCH style)
-- HOW TO RUN       : CALL load_silver();
-- ============================================================

USE DataWarehouse;

DROP PROCEDURE IF EXISTS load_silver;

DELIMITER $$

CREATE PROCEDURE load_silver()
BEGIN

    -- --------------------------------------------------------
    -- DECLARE ALL VARIABLES
    -- --------------------------------------------------------
    DECLARE batch_start_time    DATETIME;
    DECLARE batch_end_time      DATETIME;
    DECLARE start_time          DATETIME;
    DECLARE end_time            DATETIME;
    DECLARE error_code          INT      DEFAULT 0;
    DECLARE error_message       TEXT;
    DECLARE error_state         CHAR(5);

    -- --------------------------------------------------------
    -- ERROR HANDLER (MySQL equivalent of TRY...CATCH)
    -- --------------------------------------------------------
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            error_code    = MYSQL_ERRNO,
            error_message = MESSAGE_TEXT,
            error_state   = RETURNED_SQLSTATE;

        INSERT INTO silver_log VALUES ('============================================');
        INSERT INTO silver_log VALUES ('!! ERROR OCCURRED - Silver Load Aborted !! ');
        INSERT INTO silver_log VALUES (CONCAT('   Error Code    : ', error_code));
        INSERT INTO silver_log VALUES (CONCAT('   Error State   : ', error_state));
        INSERT INTO silver_log VALUES (CONCAT('   Error Message : ', error_message));
        INSERT INTO silver_log VALUES ('============================================');

        SELECT log_message FROM silver_log;
        DROP TEMPORARY TABLE IF EXISTS silver_log;
    END;

    -- --------------------------------------------------------
    -- SINGLE RESULT SET LOG TABLE
    -- --------------------------------------------------------
    DROP TEMPORARY TABLE IF EXISTS silver_log;
    CREATE TEMPORARY TABLE silver_log (log_message TEXT);

    -- --------------------------------------------------------
    -- START BATCH TIMER
    -- --------------------------------------------------------
    SET batch_start_time = NOW();

    INSERT INTO silver_log VALUES ('============================================');
    INSERT INTO silver_log VALUES ('   Loading Silver Layer                     ');
    INSERT INTO silver_log VALUES (CONCAT('   Batch Start Time : ', batch_start_time));
    INSERT INTO silver_log VALUES ('============================================');

    -- ========================================================
    -- SECTION 1: CRM TABLES
    -- ========================================================
    INSERT INTO silver_log VALUES ('--------------------------------------------');
    INSERT INTO silver_log VALUES ('   Loading CRM Tables                       ');
    INSERT INTO silver_log VALUES ('--------------------------------------------');

    -- --------------------------------------------------------
    -- Table 1: silver_crm_cust_info
    -- --------------------------------------------------------
    SET start_time = NOW();
    INSERT INTO silver_log VALUES ('>> Truncating Table : silver_crm_cust_info');
    TRUNCATE TABLE silver_crm_cust_info;
    INSERT INTO silver_log VALUES ('>> Inserting Data   : silver_crm_cust_info');

    INSERT INTO silver_crm_cust_info (
        cst_id, cst_key, cst_firstname, cst_lastname,
        cst_marital_status, cst_gndr, cst_create_date
    )
    SELECT
        cst_id,
        cst_key,
        TRIM(cst_firstname),
        TRIM(cst_lastname),
        CASE UPPER(TRIM(cst_marital_status))
            WHEN 'M' THEN 'Married'
            WHEN 'S' THEN 'Single'
            ELSE 'n/a'
        END,
        CASE UPPER(TRIM(cst_gndr))
            WHEN 'M' THEN 'Male'
            WHEN 'F' THEN 'Female'
            ELSE 'n/a'
        END,
        cst_create_date
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (
                PARTITION BY cst_id
                ORDER BY cst_create_date DESC
            ) AS flag_last
        FROM bronze_crm_cust_info
        WHERE cst_id IS NOT NULL
    ) t
    WHERE flag_last = 1;

    SET end_time = NOW();
    INSERT INTO silver_log VALUES (CONCAT(
        '>> Load Duration    : ',
        CAST(TIMESTAMPDIFF(SECOND, start_time, end_time) AS CHAR),
        ' seconds'
    ));

    -- --------------------------------------------------------
    -- Table 2: silver_crm_prd_info
    -- --------------------------------------------------------
    SET start_time = NOW();
    INSERT INTO silver_log VALUES ('>> Truncating Table : silver_crm_prd_info');
    TRUNCATE TABLE silver_crm_prd_info;
    INSERT INTO silver_log VALUES ('>> Inserting Data   : silver_crm_prd_info');

    INSERT INTO silver_crm_prd_info (
        prd_id, cat_id, prd_key, prd_nm,
        prd_cost, prd_line, prd_start_dt, prd_end_dt
    )
    SELECT
        prd_id,
        REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_'),
        SUBSTRING(prd_key, 7, LENGTH(prd_key)),
        prd_nm,
        IFNULL(prd_cost, 0),
        CASE UPPER(TRIM(prd_line))
            WHEN 'M' THEN 'Mountain'
            WHEN 'R' THEN 'Road'
            WHEN 'S' THEN 'Other Sales'
            WHEN 'T' THEN 'Touring'
            ELSE 'n/a'
        END,
        CAST(prd_start_dt AS DATE),
        CAST(DATE_SUB(
            LEAD(prd_start_dt) OVER (
                PARTITION BY prd_key
                ORDER BY prd_start_dt ASC
            ), INTERVAL 1 DAY
        ) AS DATE)
    FROM bronze_crm_prd_info
    WHERE prd_id IS NOT NULL;

    SET end_time = NOW();
    INSERT INTO silver_log VALUES (CONCAT(
        '>> Load Duration    : ',
        CAST(TIMESTAMPDIFF(SECOND, start_time, end_time) AS CHAR),
        ' seconds'
    ));

    -- --------------------------------------------------------
    -- Table 3: silver_crm_sales_details
    -- --------------------------------------------------------
    SET start_time = NOW();
    INSERT INTO silver_log VALUES ('>> Truncating Table : silver_crm_sales_details');
    TRUNCATE TABLE silver_crm_sales_details;
    INSERT INTO silver_log VALUES ('>> Inserting Data   : silver_crm_sales_details');

    INSERT INTO silver_crm_sales_details (
        sls_ord_num, sls_prd_key, sls_cust_id,
        sls_order_dt, sls_ship_dt, sls_due_dt,
        sls_sales, sls_quantity, sls_price
    )
    SELECT
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        CASE
            WHEN sls_order_dt <= 0 OR sls_order_dt IS NULL
              OR LENGTH(sls_order_dt) != 8
            THEN NULL
            ELSE STR_TO_DATE(CAST(sls_order_dt AS CHAR), '%Y%m%d')
        END,
        CASE
            WHEN sls_ship_dt <= 0 OR sls_ship_dt IS NULL
              OR LENGTH(sls_ship_dt) != 8
            THEN NULL
            ELSE STR_TO_DATE(CAST(sls_ship_dt AS CHAR), '%Y%m%d')
        END,
        CASE
            WHEN sls_due_dt <= 0 OR sls_due_dt IS NULL
              OR LENGTH(sls_due_dt) != 8
            THEN NULL
            ELSE STR_TO_DATE(CAST(sls_due_dt AS CHAR), '%Y%m%d')
        END,
        CASE
            WHEN sls_sales IS NULL OR sls_sales <= 0
              OR sls_sales != sls_quantity * ABS(sls_price)
            THEN sls_quantity * ABS(sls_price)
            ELSE sls_sales
        END,
        sls_quantity,
        CASE
            WHEN sls_price IS NULL OR sls_price <= 0
              OR sls_price != sls_sales / sls_quantity
            THEN ABS(ROUND(sls_sales / NULLIF(sls_quantity, 0), 2))
            ELSE sls_price
        END
    FROM bronze_crm_sales_details;

    SET end_time = NOW();
    INSERT INTO silver_log VALUES (CONCAT(
        '>> Load Duration    : ',
        CAST(TIMESTAMPDIFF(SECOND, start_time, end_time) AS CHAR),
        ' seconds'
    ));

    -- ========================================================
    -- SECTION 2: ERP TABLES
    -- ========================================================
    INSERT INTO silver_log VALUES ('--------------------------------------------');
    INSERT INTO silver_log VALUES ('   Loading ERP Tables                       ');
    INSERT INTO silver_log VALUES ('--------------------------------------------');

    -- --------------------------------------------------------
    -- Table 4: silver_erp_cust_az12
    -- --------------------------------------------------------
    SET start_time = NOW();
    INSERT INTO silver_log VALUES ('>> Truncating Table : silver_erp_cust_az12');
    TRUNCATE TABLE silver_erp_cust_az12;
    INSERT INTO silver_log VALUES ('>> Inserting Data   : silver_erp_cust_az12');

    INSERT INTO silver_erp_cust_az12 (CID, BDATE, GEN)
    SELECT
        CASE
            WHEN CID LIKE 'NAS%'
            THEN SUBSTRING(CID, 4, LENGTH(CID))
            ELSE CID
        END,
        CASE
            WHEN BDATE > NOW() THEN NULL
            ELSE BDATE
        END,
        CASE UPPER(TRIM(GEN))
            WHEN 'F'      THEN 'Female'
            WHEN 'FEMALE' THEN 'Female'
            WHEN 'M'      THEN 'Male'
            WHEN 'MALE'   THEN 'Male'
            ELSE 'n/a'
        END
    FROM bronze_erp_cust_az12;

    SET end_time = NOW();
    INSERT INTO silver_log VALUES (CONCAT(
        '>> Load Duration    : ',
        CAST(TIMESTAMPDIFF(SECOND, start_time, end_time) AS CHAR),
        ' seconds'
    ));

    -- --------------------------------------------------------
    -- Table 5: silver_erp_loc_a101
    -- --------------------------------------------------------
    SET start_time = NOW();
    INSERT INTO silver_log VALUES ('>> Truncating Table : silver_erp_loc_a101');
    TRUNCATE TABLE silver_erp_loc_a101;
    INSERT INTO silver_log VALUES ('>> Inserting Data   : silver_erp_loc_a101');

    INSERT INTO silver_erp_loc_a101 (CID, CNTRY)
    SELECT
        REPLACE(CID, '-', ''),
        CASE TRIM(CNTRY)
            WHEN 'DE'  THEN 'Germany'
            WHEN 'US'  THEN 'United States'
            WHEN 'USA' THEN 'United States'
            WHEN ''    THEN 'n/a'
            ELSE
                CASE
                    WHEN CNTRY IS NULL THEN 'n/a'
                    ELSE TRIM(CNTRY)
                END
        END
    FROM bronze_erp_loc_a101;

    SET end_time = NOW();
    INSERT INTO silver_log VALUES (CONCAT(
        '>> Load Duration    : ',
        CAST(TIMESTAMPDIFF(SECOND, start_time, end_time) AS CHAR),
        ' seconds'
    ));

    -- --------------------------------------------------------
    -- Table 6: silver_erp_px_cat_g1v2
    -- --------------------------------------------------------
    SET start_time = NOW();
    INSERT INTO silver_log VALUES ('>> Truncating Table : silver_erp_px_cat_g1v2');
    TRUNCATE TABLE silver_erp_px_cat_g1v2;
    INSERT INTO silver_log VALUES ('>> Inserting Data   : silver_erp_px_cat_g1v2');

    INSERT INTO silver_erp_px_cat_g1v2 (ID, CAT, SUBCAT, MAINTENANCE)
    SELECT ID, CAT, SUBCAT, MAINTENANCE
    FROM bronze_erp_px_cat_g1v2;

    SET end_time = NOW();
    INSERT INTO silver_log VALUES (CONCAT(
        '>> Load Duration    : ',
        CAST(TIMESTAMPDIFF(SECOND, start_time, end_time) AS CHAR),
        ' seconds'
    ));

    -- --------------------------------------------------------
    -- END BATCH + TOTAL DURATION
    -- --------------------------------------------------------
    SET batch_end_time = NOW();

    INSERT INTO silver_log VALUES ('============================================');
    INSERT INTO silver_log VALUES ('   Silver Layer Load Completed ✅           ');
    INSERT INTO silver_log VALUES (CONCAT('   Batch End Time   : ', batch_end_time));
    INSERT INTO silver_log VALUES (CONCAT(
        '   Total Batch Duration : ',
        CAST(TIMESTAMPDIFF(SECOND, batch_start_time, batch_end_time) AS CHAR),
        ' seconds'
    ));
    INSERT INTO silver_log VALUES ('============================================');

    -- Print ALL messages in ONE single result set
    SELECT log_message FROM silver_log;
    DROP TEMPORARY TABLE IF EXISTS silver_log;

END$$

DELIMITER ;

-- ============================================================
-- HOW TO RUN
-- ============================================================
-- CALL load_silver();
