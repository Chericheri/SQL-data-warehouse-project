Data Catalog — Gold Layer
DataWarehouse Project

DatabaseDataWarehouseLayerGold — Business Ready (Star Schema)Tablesgold_dim_customers | gold_dim_products | gold_fact_salesSchema TypeStar Schema — 2 Dimensions + 1 Fact tableSourceSilver layer (cleaned and transformed data)PurposeBusiness reporting and analytics. Ready for Power BI, dashboards and SQL analysis.

Overview
The Gold layer is the final business-ready layer of the DataWarehouse. It is built on top of the Silver layer and organises everything into a Star Schema with two dimension tables and one fact table.
All tables in the Gold layer are SQL VIEWS — they do not store data physically but always read the latest data from the Silver layer.

Dimensions answer WHO and WHAT — descriptive attributes about customers and products.
Fact table answers WHAT HAPPENED — every sales transaction with measures like sales amount, quantity and price.


How to Use
Full Star Schema join across all three tables:
sqlSELECT
    f.order_number,
    f.order_date,
    f.sales_amount,
    c.first_name,
    c.last_name,
    c.country,
    p.product_name,
    p.category,
    p.product_line
FROM   gold_fact_sales f
JOIN   gold_dim_customers c ON f.customer_key = c.customer_key
JOIN   gold_dim_products  p ON f.product_key  = p.product_key;

Business Rules

Sales Amount = Quantity x Price — enforced in the Silver layer. Any source rows violating this rule were corrected during transformation.
Gender resolution — CRM is the master source. If CRM has Male or Female, it is used. If CRM has n/a, the ERP value is used as a fallback. If both are n/a, value remains n/a.
Current products only — the product dimension only includes products with no end date (still active). Historical records are excluded.


Table Relationships
From TableJoin Key (Fact)Join Key (Dim)Relationshipgold_fact_salescustomer_keycustomer_keyMany-to-One — one customer can have many ordersgold_fact_salesproduct_keyproduct_keyMany-to-One — one product can appear in many orders

Data Sources
Gold TableSilver Sources (CRM)Silver Sources (ERP)gold_dim_customerssilver_crm_cust_infosilver_erp_cust_az12, silver_erp_loc_a101gold_dim_productssilver_crm_prd_infosilver_erp_px_cat_g1v2gold_fact_salessilver_crm_sales_details(none)

Table 1: gold_dim_customers
Type: Dimension
Rows: ~18,484
Primary Key: customer_key
Stores unified customer information combining data from three Silver tables: CRM customer info (master), ERP customer demographics (birthdate and gender fallback) and ERP customer location (country).
Column NameData TypeDescriptionExample Valuescustomer_keyINTSurrogate key — system generated unique ID. Used to join with fact_sales.1, 2, 3...customer_idINTOriginal customer ID from the CRM source system.11000, 11001customer_numberVARCHAR(50)Business customer number from the CRM source system.AW00011000first_nameVARCHAR(50)Customer first name. Spaces trimmed.Jon, Emilylast_nameVARCHAR(50)Customer last name. Spaces trimmed.Yang, SmithcountryVARCHAR(50)Country where the customer is located. Sourced from ERP.Australia, United States, Germanymarital_statusVARCHAR(50)Customer marital status. Standardised from source codes M/S.Married, Single, n/agenderVARCHAR(50)Customer gender. CRM is master. ERP used as fallback if CRM is n/a.Male, Female, n/abirth_dateDATECustomer date of birth. Future dates set to NULL in Silver layer.1971-10-06create_dateDATEDate the customer record was created in the CRM source system.2025-10-06

Table 2: gold_dim_products
Type: Dimension
Rows: ~295
Primary Key: product_key
Stores unified product information combining CRM product data (master) and ERP product categories. Only current products are included — historical records where end_date is not NULL are filtered out. The category join uses the first 5 characters of the product key as the category ID.
Column NameData TypeDescriptionExample Valuesproduct_keyINTSurrogate key — system generated unique ID. Used to join with fact_sales.1, 2, 3...product_idINTOriginal product ID from the CRM source system.210, 211product_numberVARCHAR(50)Business product number from the CRM source system.FR-R92B-58product_nameVARCHAR(50)Full descriptive name of the product.HL Road Frame - Black- 58category_idVARCHAR(50)Category ID derived from first 5 chars of source product key. Dash replaced with underscore.CO_RF, BI_MBcategoryVARCHAR(50)Top-level product category from ERP. n/a if no match found.Bikes, Accessories, Components, Clothing, n/asubcategoryVARCHAR(50)Product subcategory from ERP. n/a if no match found.Road Bikes, Helmets, Mountain Bikes, n/amaintenanceVARCHAR(50)Whether the product requires maintenance. From ERP.Yes, No, n/acostINTProduct cost. NULL costs replaced with 0 in Silver layer.1898, 885, 0product_lineVARCHAR(50)Product sales line. Standardised from source codes M/R/S/T.Mountain, Road, Touring, Other Sales, n/astart_dateDATEDate the product became active. Only current products included.2011-07-01, 2003-07-01

Table 3: gold_fact_sales
Type: Fact
Rows: ~60,398
Foreign Keys: product_key → gold_dim_products, customer_key → gold_dim_customers
Records every sales transaction from the CRM source system. Each row represents one order line. Connects to both dimensions using surrogate keys fetched via data lookup joins. Source integer dates (YYYYMMDD) were converted to DATE format and invalid sales values were recalculated using the business rule: sales = quantity x price.
Column NameData TypeDescriptionExample Valuesproduct_keyINTFK to gold_dim_products. Surrogate key of the product sold.1, 42, 195customer_keyINTFK to gold_dim_customers. Surrogate key of the customer who placed the order.4, 10769order_dateDATEDate the order was placed. Converted from source integer format YYYYMMDD.2010-12-29ship_dateDATEDate the order was shipped to the customer.2011-01-05due_dateDATEDate the order payment was due.2011-01-10order_numberVARCHAR(50)Unique business order identifier from the CRM source system.SO43697, SO43698sales_amountINTTotal sales amount for the order line. Recalculated if source value was wrong or negative.3578, 699quantityINTNumber of units sold in the order line.1, 2, 3priceDECIMAL(10,2)Unit price per item. Recalculated as sales_amount / quantity if source value was wrong.3578.00, 349.50

Transformation Summary
LayerTableTransformations AppliedSilvercrm_cust_infoDeduplication (ROW_NUMBER), trim spaces, standardise gender M/F→Male/Female, standardise marital status M/S→Married/SingleSilvercrm_prd_infoDerive cat_id from prd_key, extract product number, handle NULL costs, standardise product line, rebuild end dates with LEAD()Silvercrm_sales_detailsConvert INT dates to DATE, fix negative/wrong sales amounts, recalculate priceSilvererp_cust_az12Strip NAS prefix from CID, set future birthdates to NULL, standardise genderSilvererp_loc_a101Remove dash from CID, standardise country codes DE/US/USA to full namesSilvererp_px_cat_g1v2No transformations needed — data already cleanGolddim_customersJoin 3 Silver tables, integrate gender from CRM+ERP, generate surrogate keyGolddim_productsJoin 2 Silver tables, filter current products only, handle NULL categories, generate surrogate keyGoldfact_salesLookup surrogate keys from both dimensions, rename columns to friendly names

Generated for DataWarehouse Project — Gold Layer
