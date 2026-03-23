# DATA CATALOG
## Gold Layer — Star Schema
### DataWarehouse Project

---

## Project Information

| Property | Value |
|---|---|
| **Database** | DataWarehouse |
| **Layer** | Gold — Business Ready (Star Schema) |
| **Tables** | `gold_dim_customers` \| `gold_dim_products` \| `gold_fact_sales` |
| **Schema Type** | Star Schema — 2 Dimensions + 1 Fact table |
| **Source** | Silver layer (cleaned and transformed data) |
| **Purpose** | Business reporting and analytics. Ready for Power BI, dashboards and SQL analysis. |

---

## Overview

The Gold layer is the final business-ready layer of the DataWarehouse. It is built on top of the Silver layer (cleaned data) and organises everything into a Star Schema with two dimension tables and one fact table. All tables in the Gold layer are SQL **VIEWS** — they do not store data physically but always read the latest data from the Silver layer.

Dimensions describe **WHO** and **WHAT** — they contain descriptive attributes about customers and products. The Fact table describes **WHAT HAPPENED** — it records every sales transaction with measures like sales amount, quantity and price.

---

## How to Use

To query all three tables together in a full Star Schema join:

```sql
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
FROM   gold_fact_sales f
JOIN   gold_dim_customers c ON f.customer_key = c.customer_key
JOIN   gold_dim_products  p ON f.product_key  = p.product_key;
```

---

## Business Rules

| Rule | Description |
|---|---|
| **Sales Amount** | `sales_amount = quantity x price`. Enforced in Silver layer. Invalid values were recalculated during transformation. |
| **Gender Resolution** | CRM is the master source. If CRM has `Male` or `Female` it is used. If CRM has `n/a`, the ERP value is used as fallback. If both are `n/a`, value remains `n/a`. |
| **Current Products Only** | The product dimension only includes current products — those with no end date (`prd_end_dt IS NULL`). Historical records are excluded. |

---

## Table Relationships

```
gold_dim_customers (1) ──────────── (Many) gold_fact_sales
                                           |
gold_dim_products  (1) ──────────── (Many) gold_fact_sales
```

| From Table | Join Key (Fact) | Join Key (Dimension) | Relationship |
|---|---|---|---|
| `gold_fact_sales` | `customer_key` | `customer_key` | Many-to-One — one customer can have many orders |
| `gold_fact_sales` | `product_key` | `product_key` | Many-to-One — one product can appear in many orders |

---

## Data Sources

| Gold Table | Silver Sources (CRM) | Silver Sources (ERP) |
|---|---|---|
| `gold_dim_customers` | `silver_crm_cust_info` | `silver_erp_cust_az12`, `silver_erp_loc_a101` |
| `gold_dim_products` | `silver_crm_prd_info` | `silver_erp_px_cat_g1v2` |
| `gold_fact_sales` | `silver_crm_sales_details` | *(none)* |

---

## Table: gold_dim_customers

**Type:** Dimension
**Rows:** ~18,484
**Primary Key:** `customer_key`

**Description:** Stores unified customer information combining data from three Silver tables — CRM customer info (master), ERP customer demographics (birthdate and gender fallback) and ERP customer location (country). All three source tables are joined using the customer key.

**Source tables joined:**
- `silver_crm_cust_info` — core customer info (master)
- `silver_erp_cust_az12` — birthdate and gender fallback
- `silver_erp_loc_a101` — country

### Column Definitions

| Column Name | Data Type | Description | Example Values |
|---|---|---|---|
| `customer_key` | INT | Surrogate key — system generated unique ID for each customer. Used to join with `gold_fact_sales`. | 1, 2, 3... |
| `customer_id` | INT | Original customer ID from the CRM source system. | 11000, 11001 |
| `customer_number` | VARCHAR(50) | Business customer number from the CRM source system. | AW00011000 |
| `first_name` | VARCHAR(50) | Customer first name. Leading and trailing spaces trimmed. | Jon, Emily |
| `last_name` | VARCHAR(50) | Customer last name. Leading and trailing spaces trimmed. | Yang, Smith |
| `country` | VARCHAR(50) | Country where the customer is located. Sourced from ERP location table. | Australia, United States, Germany |
| `marital_status` | VARCHAR(50) | Customer marital status. Standardised from source codes (`M` → Married, `S` → Single). | Married, Single, n/a |
| `gender` | VARCHAR(50) | Customer gender. CRM is master source. ERP used as fallback if CRM value is `n/a`. | Male, Female, n/a |
| `birth_date` | DATE | Customer date of birth. Future dates set to NULL during Silver transformation. | 1971-10-06 |
| `create_date` | DATE | Date the customer record was created in the CRM source system. | 2025-10-06 |

---

## Table: gold_dim_products

**Type:** Dimension
**Rows:** ~295
**Primary Key:** `product_key`

**Description:** Stores unified product information combining data from two Silver tables — CRM product info (master) and ERP product categories. Only **current products** are included. Historical records where `prd_end_dt IS NOT NULL` are filtered out. The category join uses the first 5 characters of the product key as the category ID, with `-` replaced by `_` to match ERP format.

**Source tables joined:**
- `silver_crm_prd_info` — product info (master, current only)
- `silver_erp_px_cat_g1v2` — category, subcategory, maintenance

### Column Definitions

| Column Name | Data Type | Description | Example Values |
|---|---|---|---|
| `product_key` | INT | Surrogate key — system generated unique ID for each product. Used to join with `gold_fact_sales`. | 1, 2, 3... |
| `product_id` | INT | Original product ID from the CRM source system. | 210, 211 |
| `product_number` | VARCHAR(50) | Business product number from the CRM source system. | FR-R92B-58 |
| `product_name` | VARCHAR(50) | Full descriptive name of the product. | HL Road Frame - Black- 58 |
| `category_id` | VARCHAR(50) | Category identifier derived from first 5 chars of source product key. `-` replaced with `_`. | CO_RF, BI_MB, AC_HE |
| `category` | VARCHAR(50) | Top-level product category from ERP. `n/a` if no category match found. | Bikes, Accessories, Components, Clothing, n/a |
| `subcategory` | VARCHAR(50) | Product subcategory from ERP. `n/a` if no match found. | Road Bikes, Helmets, Mountain Bikes |
| `maintenance` | VARCHAR(50) | Whether the product requires maintenance. Sourced from ERP. | Yes, No, n/a |
| `cost` | INT | Product cost. NULL values replaced with 0 during Silver transformation. | 1898, 885, 0 |
| `product_line` | VARCHAR(50) | Product sales line. Standardised from source codes (`M` → Mountain, `R` → Road, `S` → Other Sales, `T` → Touring). | Mountain, Road, Touring, Other Sales, n/a |
| `start_date` | DATE | Date the product version became active. Only current products are included (`end_date IS NULL`). | 2011-07-01 |

---

## Table: gold_fact_sales

**Type:** Fact
**Rows:** ~60,398
**Foreign Keys:** `product_key` → `gold_dim_products`, `customer_key` → `gold_dim_customers`

**Description:** Records every sales transaction from the CRM source system. Each row represents one order line. The fact table connects to both dimensions using surrogate keys (`product_key` and `customer_key`) which are resolved via data lookup joins in the Gold layer. Source integer dates were converted to proper `DATE` format. Invalid or negative sales values were recalculated using the business rule `sales_amount = quantity x price`.

**Source tables used:**
- `silver_crm_sales_details` — all sales transactions

### Column Definitions

| Column Name | Data Type | Description | Example Values |
|---|---|---|---|
| `product_key` | INT | Foreign key to `gold_dim_products.product_key`. Surrogate key of the product sold. | 1, 42, 195 |
| `customer_key` | INT | Foreign key to `gold_dim_customers.customer_key`. Surrogate key of the customer who placed the order. | 4, 10769, 5625 |
| `order_date` | DATE | Date the order was placed. Converted from source integer format (`YYYYMMDD`). Invalid dates set to NULL. | 2010-12-29 |
| `ship_date` | DATE | Date the order was shipped. Converted from source integer format. | 2011-01-05 |
| `due_date` | DATE | Date the order payment was due. Converted from source integer format. | 2011-01-10 |
| `order_number` | VARCHAR(50) | Unique business order identifier from the CRM source system. | SO43697 |
| `sales_amount` | INT | Total sales amount for the order line. Recalculated as `quantity x price` if source value is NULL, zero or negative. | 3578, 699 |
| `quantity` | INT | Number of units sold in the order line. | 1, 2, 3 |
| `price` | DECIMAL(10,2) | Unit price per item. Recalculated as `sales_amount / quantity` if source value is NULL, zero or negative. | 3578.00, 349.50 |

---

## Transformation Summary

| Transformation Type | Description | Applied To |
|---|---|---|
| **Deduplication** | Kept only the most recent record per customer using `ROW_NUMBER()` ordered by `create_date DESC` | `dim_customers` |
| **Trimming** | Removed leading and trailing whitespace from string columns | `dim_customers` |
| **Standardisation** | Mapped coded values to friendly names (`M` → `Male`, `S` → `Single`, `M` → `Mountain`) | `dim_customers`, `dim_products` |
| **Handle missing values** | Replaced NULL and empty values with `n/a` or `0` where appropriate | All tables |
| **Derived columns** | Split `prd_key` into `cat_id` (first 5 chars) and `product_number` (from position 7) | `dim_products` |
| **Date rebuilding** | Rebuilt `prd_end_dt` using `LEAD()` window function to eliminate overlapping date ranges | `dim_products` |
| **Type casting** | Converted integer dates (`YYYYMMDD`) to proper `DATE` type | `fact_sales` |
| **Business rule enforcement** | Recalculated `sales_amount = quantity x price` for invalid rows | `fact_sales` |
| **Invalid value handling** | Set future birthdates to NULL. Removed `NAS` prefix from ERP customer IDs. Removed dashes from location IDs. | `dim_customers` |
| **Country mapping** | Mapped abbreviations to full names (`DE` → `Germany`, `US`/`USA` → `United States`) | `dim_customers` |
| **Data integration** | Combined gender from CRM (master) and ERP (fallback) into one unified column | `dim_customers` |
| **Surrogate keys** | Generated system surrogate keys using `ROW_NUMBER()` for both dimensions | `dim_customers`, `dim_products` |
| **Historical filtering** | Excluded historical product records — only current products (`prd_end_dt IS NULL`) included | `dim_products` |

---

*End of Data Catalog — DataWarehouse Gold Layer*
