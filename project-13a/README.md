# Enterprise Retail Analytics — Star Schema vs. Snowflake Schema

## 📌 Project Overview

This project demonstrates the implementation and comparison of two common **Data Warehouse dimensional modeling architectures** using **Snowflake SQL**:

1. **Star Schema**
2. **Snowflake Schema**

The project uses an enterprise retail analytics scenario containing store, regional, product, customer, and sales transaction data.

The objective is to understand how **denormalized Star Schema** and **normalized Snowflake Schema** differ in terms of structure, redundancy, query complexity, and dimensional hierarchy.

---

## 🎯 Objectives

* Create a Star Schema for retail sales analytics.
* Create a normalized Snowflake Schema.
* Load source CSV data using a Snowflake staging workflow.
* Implement surrogate keys and dimension relationships.
* Build fact tables for sales transactions.
* Perform revenue analysis using both schemas.
* Compare Star Schema and Snowflake Schema architectures.
* Generate regional manager sales performance reports.
* Validate warehouse record counts using an audit query.

---

## 🛠️ Technology Used

* **Snowflake**
* **Snowflake SQL**
* CSV source files
* Data Warehouse Dimensional Modeling
* Star Schema
* Snowflake Schema

---

## 📂 Source Datasets

The project uses four source CSV files:

| File                     | Description                                            |
| ------------------------ | ------------------------------------------------------ |
| `regions_and_stores.csv` | Store, geographic and regional manager information     |
| `product_hierarchy.csv`  | Product, subcategory, category and pricing information |
| `customers.csv`          | Customer information                                   |
| `sales_transactions.csv` | Retail sales transaction records                       |

The source data contains:

* **4 stores**
* **4 products**
* **5 customers**
* **5 sales transactions**

---

# 🏗️ Architecture

## ⭐ Star Schema

The Star Schema uses denormalized dimensions connected directly to a central sales fact table.

```text
                 STAR_DIM_STORE
                       |
                       |
                       ▼
                 STAR_FACT_SALES
                       ▲
                       |
                       |
               STAR_DIM_PRODUCT
```

### Star Schema Tables

#### `STAR_DIM_STORE`

Contains store, geographic and regional manager attributes in a single table.

```text
STORE_KEY
STORE_ID
STORE_NAME
CITY
STATE
REGION_NAME
REGIONAL_MANAGER
```

#### `STAR_DIM_PRODUCT`

Contains product, subcategory and category attributes in a single denormalized table.

```text
PRODUCT_KEY
PRODUCT_ID
PRODUCT_NAME
SUBCATEGORY_NAME
CATEGORY_NAME
UNIT_PRICE
```

#### `STAR_FACT_SALES`

Contains sales transaction measures and surrogate foreign keys.

```text
SALES_KEY
TRANSACTION_ID
TRANSACTION_DATE
CUSTOMER_ID
STORE_KEY
PRODUCT_KEY
QUANTITY
TOTAL_AMOUNT
```

---

# ❄️ Snowflake Schema

The Snowflake Schema normalizes the dimension hierarchies into multiple related tables.

### Store Hierarchy

```text
SNOW_DIM_REGION
       |
       ▼
SNOW_DIM_STORE
```

### Product Hierarchy

```text
SNOW_DIM_CATEGORY
       |
       ▼
SNOW_DIM_SUBCATEGORY
       |
       ▼
SNOW_DIM_PRODUCT
```

### Snowflake Schema Tables

#### `SNOW_DIM_REGION`

```text
REGION_KEY
REGION_NAME
REGIONAL_MANAGER
```

#### `SNOW_DIM_STORE`

```text
STORE_KEY
STORE_ID
STORE_NAME
CITY
STATE
REGION_KEY
```

#### `SNOW_DIM_CATEGORY`

```text
CATEGORY_KEY
CATEGORY_NAME
```

#### `SNOW_DIM_SUBCATEGORY`

```text
SUBCATEGORY_KEY
SUBCATEGORY_NAME
CATEGORY_KEY
```

#### `SNOW_DIM_PRODUCT`

```text
PRODUCT_KEY
PRODUCT_ID
PRODUCT_NAME
UNIT_PRICE
SUBCATEGORY_KEY
```

#### `SNOW_FACT_SALES`

```text
SALES_KEY
TRANSACTION_ID
TRANSACTION_DATE
CUSTOMER_ID
STORE_KEY
PRODUCT_KEY
QUANTITY
TOTAL_AMOUNT
```

---

# 📥 Data Loading Workflow

Instead of manually entering source records, the project uses a staging-based ingestion process.

```text
CSV Files
    |
    ▼
RETAIL_STAGE
    |
    ▼
Staging Tables
    |
    ├── STG_REGIONS_AND_STORES
    ├── STG_PRODUCT_HIERARCHY
    ├── STG_CUSTOMERS
    └── STG_SALES_TRANSACTIONS
    |
    ▼
Final Dimension & Fact Tables
```

A single Snowflake stage was used to hold all four source CSV files.

---

# 🔑 Surrogate Key Implementation

The dimensional tables use automatically generated surrogate keys.

For example:

```text
STORE_ID
   |
   ▼
STAR_DIM_STORE
   |
   └── STORE_KEY
```

For the Snowflake Schema:

```text
REGION_NAME
     |
     ▼
SNOW_DIM_REGION
     |
     └── REGION_KEY
             |
             ▼
       SNOW_DIM_STORE
```

Similarly, the product hierarchy uses:

```text
CATEGORY
   |
   ▼
SUBCATEGORY
   |
   ▼
PRODUCT
```

The fact tables dynamically resolve the appropriate surrogate keys from the dimensions using the business keys from the staged transaction data.

---

# 📊 Analytics Queries

## 1. Revenue by Region and Category — Star Schema

The Star Schema directly joins the fact table with the store and product dimensions to calculate revenue by region and category.

```sql
SELECT
    ds.REGION_NAME,
    dp.CATEGORY_NAME,
    SUM(fs.TOTAL_AMOUNT) AS TOTAL_REVENUE
FROM STAR_FACT_SALES fs
JOIN STAR_DIM_STORE ds
    ON fs.STORE_KEY = ds.STORE_KEY
JOIN STAR_DIM_PRODUCT dp
    ON fs.PRODUCT_KEY = dp.PRODUCT_KEY
GROUP BY
    ds.REGION_NAME,
    dp.CATEGORY_NAME;
```

---

## 2. Revenue by Region and Category — Snowflake Schema

The Snowflake Schema requires traversal through the normalized hierarchies.

```sql
SELECT
    r.REGION_NAME,
    c.CATEGORY_NAME,
    SUM(fs.TOTAL_AMOUNT) AS TOTAL_REVENUE
FROM SNOW_FACT_SALES fs
JOIN SNOW_DIM_STORE st
    ON fs.STORE_KEY = st.STORE_KEY
JOIN SNOW_DIM_REGION r
    ON st.REGION_KEY = r.REGION_KEY
JOIN SNOW_DIM_PRODUCT p
    ON fs.PRODUCT_KEY = p.PRODUCT_KEY
JOIN SNOW_DIM_SUBCATEGORY sc
    ON p.SUBCATEGORY_KEY = sc.SUBCATEGORY_KEY
JOIN SNOW_DIM_CATEGORY c
    ON sc.CATEGORY_KEY = c.CATEGORY_KEY
GROUP BY
    r.REGION_NAME,
    c.CATEGORY_NAME;
```

---

# 👔 Regional Manager Sales Performance

The Star Schema was also used to calculate total quantity sold and total sales amount by regional manager.

```sql
SELECT
    ds.REGIONAL_MANAGER,
    SUM(fs.QUANTITY) AS TOTAL_ITEMS_SOLD,
    SUM(fs.TOTAL_AMOUNT) AS TOTAL_SALES_AMOUNT
FROM STAR_FACT_SALES fs
JOIN STAR_DIM_STORE ds
    ON fs.STORE_KEY = ds.STORE_KEY
GROUP BY
    ds.REGIONAL_MANAGER;
```

---

# 🔍 Star Schema vs Snowflake Schema

| Feature                 | Star Schema                | Snowflake Schema             |
| ----------------------- | -------------------------- | ---------------------------- |
| Dimension Normalization | Denormalized / Flat        | Normalized / Hierarchical    |
| Dimension Tables        | 2                          | 5                            |
| Data Redundancy         | Higher                     | Lower                        |
| Query Simplicity        | Higher                     | Lower                        |
| Dimension Structure     | Directly connected to Fact | Multiple hierarchical levels |
| Category Analysis       | Fewer joins                | More joins                   |

### Star Schema

The Star Schema keeps dimensional attributes together, resulting in simpler analytical queries.

### Snowflake Schema

The Snowflake Schema separates hierarchical attributes into normalized tables, reducing repeated dimensional data but requiring additional joins.

---

# 📋 Warehouse Validation

The final warehouse audit verifies record counts across both architectures.

Expected record counts:

| Schema           | Table                  | Records |
| ---------------- | ---------------------- | ------: |
| Star Schema      | `STAR_DIM_STORE`       |       4 |
| Star Schema      | `STAR_DIM_PRODUCT`     |       4 |
| Star Schema      | `STAR_FACT_SALES`      |       5 |
| Snowflake Schema | `SNOW_DIM_REGION`      |       2 |
| Snowflake Schema | `SNOW_DIM_STORE`       |       4 |
| Snowflake Schema | `SNOW_DIM_CATEGORY`    |       3 |
| Snowflake Schema | `SNOW_DIM_SUBCATEGORY` |       4 |
| Snowflake Schema | `SNOW_DIM_PRODUCT`     |       4 |
| Snowflake Schema | `SNOW_FACT_SALES`      |       5 |

---

# 📁 Project Structure

A suggested repository structure:

```text
Project-13-Star-vs-Snowflake-Schema/
│
├── README.md
│
├── data/
│   ├── regions_and_stores.csv
│   ├── product_hierarchy.csv
│   ├── customers.csv
│   └── sales_transactions.csv
│
├── sql/
│   ├── 01_database_schema.sql
│   ├── 02_star_schema.sql
│   ├── 03_staging_and_loading.sql
│   ├── 04_snowflake_schema.sql
│   ├── 05_analytics.sql
│   └── 06_audit.sql
│
└── screenshots/
    └── snowflake_outputs/
```

---

# ✅ Tasks Completed

* [x] Create database and schema
* [x] Create Star Schema store dimension
* [x] Create Star Schema product dimension
* [x] Create Star Schema fact table
* [x] Create Snowflake Schema region/store hierarchy
* [x] Create Snowflake Schema category/subcategory/product hierarchy
* [x] Create staging layer
* [x] Load source CSV files through Snowflake stage
* [x] Populate Star Schema dimensions
* [x] Populate Star Schema fact table
* [x] Populate Snowflake Schema dimensions
* [x] Populate Snowflake Schema fact table
* [x] Run Star Schema analytics
* [x] Run Snowflake Schema analytics
* [x] Compare both architectures
* [x] Generate regional manager sales report
* [x] Perform final warehouse record-count audit

---

# 🎓 Key Learning Outcomes

Through this project, the following Data Warehouse concepts were implemented:

* Dimensional modeling
* Star Schema architecture
* Snowflake Schema architecture
* Fact and dimension tables
* Surrogate keys
* Business keys
* Normalization
* Denormalization
* Dimension hierarchies
* Foreign-key relationships
* Staging and CSV ingestion
* Snowflake `COPY INTO`
* Analytical aggregation
* Multi-table joins
* Warehouse validation and auditing

---

## 🏁 Conclusion

This project demonstrates two approaches to designing a retail analytical warehouse.

The **Star Schema** keeps dimensions denormalized and directly connected to the fact table, making analytical queries simpler.

The **Snowflake Schema** normalizes dimensional hierarchies into multiple related tables, reducing repeated dimensional information while increasing join complexity.

Both architectures were implemented in Snowflake and used to produce equivalent retail analytics from the same source transaction data.
