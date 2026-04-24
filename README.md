# 📊 Data Warehouse & Analytics Engineering Project

ThiThis repository showcases an end-to-end Data Warehouse and Analytics solution, demonstrating practical experience in Data Engineering, Analytics Engineering, and Business Intelligence workflows.
The project highlights my ability to design scalable data systems, build ETL pipelines, model analytical datasets, generate business-ready insights using MySQL, and visualise findings in Power BI.
---

## 🚀 Project Summary

This project simulates a real-world business environment where data from two operational source systems — a **CRM** and an **ERP** — must be consolidated into a centralised warehouse for reporting and analytics.
Dataset: AdventureWorks (Microsoft) — fictional global bike company
Tutorial credit: Data With Baraa

### Key Objectives

- Design and implement a modern data warehouse using the Medallion Architecture
- Build structured ETL pipelines with stored procedures and error handling
- Apply data cleaning and transformation best practices across 6 source tables
- Develop an optimised Star Schema model for analytics consumption
- Generate actionable business insights through SQL analytics
- Build an interactive Power BI dashboard connected directly to the warehouse

---

## 🏗️ Architecture Overview

The solution follows the **Medallion Architecture (Bronze → Silver → Gold)** framework.
<img width="1504" height="859" alt="image" src="https://github.com/user-attachments/assets/73483f7a-3fa7-412e-899a-c5ac402ac87c" />

```
CSV Source Files (CRM + ERP)
          ↓
  🥉 BRONZE LAYER    → Raw ingestion — no transformation
          ↓
  🥈 SILVER LAYER    → Cleaned, typed, standardised data
          ↓
  ⭐ GOLD LAYER      → Business-ready Star Schema (Views)
```

### 🥉 Bronze Layer — Raw Ingestion

- Loaded 6 CSV files from CRM and ERP source systems into MySQL using `LOAD DATA INFILE`
- Preserved raw structure exactly as received for full auditability and traceability
- Stored procedure (`load_bronze`) truncates and reloads all tables on each run
- Includes batch timing, per-table duration logging and error handling

### 🥈 Silver Layer — Data Transformation

- Applied 13 types of data transformations across all 6 source tables
- Key transformations: deduplication, trimming, type casting, standardisation, date rebuilding using `LEAD()`, business rule enforcement, invalid value handling and data integration
- Stored procedure (`load_silver`) manages full Silver reload with logging and error handling
- Quality checks validate every table after each load

### ⭐ Gold Layer — Analytics Layer

- Designed a Star Schema with 2 dimension views and 1 fact view
- `gold_dim_customers` — unified from 3 Silver tables (CRM + ERP)
- `gold_dim_products` — unified from 2 Silver tables (CRM + ERP), current products only
- `gold_fact_sales` — 60,398 transactions with surrogate key lookups to both dimensions
- All Gold objects are SQL **VIEWS** — no physical storage, always reads latest Silver data

---

## 🗂️ Data Model

The Gold layer follows a **Star Schema** pattern:

```
gold_dim_customers (1) ──────── (Many) gold_fact_sales
                                        │
gold_dim_products  (1) ──────── (Many) gold_fact_sales
```

| Table | Type | Rows | Primary Key |
|---|---|---|---|
| `gold_dim_customers` | Dimension | ~18,484 | `customer_key` (surrogate) |
| `gold_dim_products` | Dimension | ~295 | `product_key` (surrogate) |
| `gold_fact_sales` | Fact | ~60,398 | `product_key` + `customer_key` (FK) |

---

## 🛠️ Technologies Used

| Technology | Purpose |
|---|---|
| **MySQL 8.0** | Database engine |
| **MySQL Workbench** | Query development and execution |
| **SQL** | ETL pipelines, transformations, analytics |
| **Draw.io** | Architecture and data model diagrams |
| **Git & GitHub** | Version control |

---

## 🎯 Core Competencies Demonstrated

- Data Warehousing Architecture (Medallion / Bronze-Silver-Gold)
- ETL Pipeline Development with stored procedures
- Data Modelling (Star Schema design)
- Data Cleaning and Transformation (12+ transformation types)
- Window Functions (`ROW_NUMBER`, `LEAD`)
- Data Integration across multiple source systems
- Data Quality Validation and testing
- Business Intelligence Reporting

---

## 📊 Business Insights Enabled

The Gold layer enables structured SQL analytics across:

- Customer purchasing behaviour and demographics
- Product performance by category, subcategory and product line
- Sales trends, revenue patterns and order analysis
- Geographic sales distribution by country
- Key business performance indicators

---

## 📂 Repository Structure

```
sql-data-warehouse-project/
│
├── datasets/
│   ├── source_crm/           # CRM CSV files (cust_info, prd_info, sales_details)
│   └── source_erp/           # ERP CSV files (CUST_AZ12, LOC_A101, PX_CAT_G1V2)
│
├── docs/
│   └── data_catalog.md       # Full Gold layer data catalog
│
├── scripts/
│   ├── bronze/
│   │   ├── ddl_bronze.sql         # CREATE TABLE scripts for Bronze layer
│   │   └── proc_load_bronze.sql   # Stored procedure + LOAD DATA script
│   ├── silver/
│   │   ├── ddl_silver.sql         # CREATE TABLE scripts for Silver layer
│   │   └── proc_load_silver.sql   # Stored procedure with all transformations
│   └── gold/
│       └── ddl_gold.sql           # CREATE VIEW scripts for Gold layer (Star Schema)
│
├── tests/
│   ├── quality_checks_silver.sql  # Data quality validation for Silver layer
│   └── quality_checks_gold.sql    # Data quality validation for Gold layer
│
├── README.md
└── LICENSE
```

---

## ▶️ How to Run

1. Install **MySQL 8.0** and **MySQL Workbench**
2. Create the database: `CREATE DATABASE DataWarehouse;`
3. Run `scripts/bronze/ddl_bronze.sql` to create Bronze tables
4. Copy all 6 CSV files to your MySQL upload folder (`C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/`)
5. Run `scripts/bronze/proc_load_bronze.sql` — then call `CALL load_bronze();` followed by the LOAD DATA section
6. Run `scripts/silver/ddl_silver.sql` to create Silver tables
7. Run `scripts/silver/proc_load_silver.sql` — then call `CALL load_silver();`
8. Run `scripts/gold/ddl_gold.sql` to create Gold views
9. Run `tests/quality_checks_gold.sql` to validate everything

---

## 📈 Professional Growth

This project represents my continued growth in:

- Data Engineering — building production-style ETL pipelines
- Analytics Engineering — designing clean, business-ready data models
- Data Science Foundations — enabling SQL-based analytical workflows

By building a complete data system from raw ingestion to a Star Schema ready for Power BI or dashboards, I am strengthening my ability to design scalable data solutions that support business strategy and data-driven decision-making.

---

## 👩🏽‍💻 About Me

Hi, I'm **Charity Cheruto**.

I am actively developing expertise in **Data Engineering, Analytics Engineering, and Data Science**, focusing on building production-style projects that simulate real industry environments.

I am passionate about transforming raw data into structured, meaningful insights that drive measurable impact.

---

*Built with MySQL · Medallion Architecture · Star Schema*
