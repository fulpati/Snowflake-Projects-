# Enterprise Retail Analytics Data Warehouse – Snowflake

## 📌 Project Overview

This project implements an **Enterprise Retail Analytics Data Warehouse** using **Snowflake SQL** and **Kimball dimensional modeling** concepts.

The warehouse is designed for an omnichannel retail business that needs to analyze sales across stores, products, and customers while maintaining customer history and supporting different Slowly Changing Dimension (SCD) strategies.

The project demonstrates:

* Kimball dimensional modeling
* Fact and dimension tables
* Fact table grain definition
* Conformed dimensions
* Surrogate keys
* SCD Type 1
* SCD Type 2
* SCD Type 3
* SCD Type 6 Hybrid
* Point-in-time analytics
* Data loading through Snowflake staging
* Data validation and audit queries

---

## 🎯 Business Scenario

The retail organization operates multiple stores and needs a centralized Snowflake data warehouse for analytics.

The warehouse must support:

* Store-level sales analysis
* Product-level sales analysis
* Customer-level sales analysis
* Historical customer segmentation
* Customer location changes
* Customer membership changes
* Point-in-time reporting

### Customer Changes

During Q2 2026, the following customer changes occur:

| Customer          | Change                                                  | Effective Date |
| ----------------- | ------------------------------------------------------- | -------------- |
| 101 – Amit Sharma | Hyderabad → Bengaluru, Silver → Gold, Regular → Premium | 2026-04-01     |
| 103 – Rahul Verma | Vijayawada → Chennai, Silver → Gold, Regular → Premium  | 2026-04-05     |
| 104 – Neha Patel  | Gold → Platinum                                         | 2026-04-10     |

A store manager change also occurs:

**Store 201:** Rajesh Kumar → Suresh Menon

---

## 🏗️ Data Warehouse Architecture

The warehouse consists of:

### Dimension Tables

* `DIM_STORE`
* `DIM_PRODUCT`
* `DIM_CUSTOMER_HYBRID`

### Fact Table

* `FACT_SALES`

### Staging Objects

* `RETAIL_STAGE`
* `RETAIL_CSV_FORMAT`
* `STG_CUSTOMER_UPDATES`

The source CSV files are loaded into Snowflake using a stage and then transformed/inserted into the warehouse tables.

---

## ⭐ Fact Table Grain

The grain of `FACT_SALES` is:

> **Exactly one row per individual item line in a sales transaction.**

This means each row represents one product line purchased in a transaction.

For example, if a transaction contains two different products, the fact table contains two rows.

---

## 📊 Data Model

### DIM_STORE

Stores information about retail stores.

| Column          | Description               |
| --------------- | ------------------------- |
| `STORE_KEY`     | Surrogate key             |
| `STORE_ID`      | Business/store identifier |
| `STORE_NAME`    | Store name                |
| `CITY`          | Store city                |
| `STATE`         | Store state               |
| `STORE_MANAGER` | Current store manager     |

**SCD Strategy:** Type 1

The store manager is overwritten when it changes.

---

### DIM_PRODUCT

Stores product master data.

| Column         | Description                 |
| -------------- | --------------------------- |
| `PRODUCT_KEY`  | Surrogate key               |
| `PRODUCT_ID`   | Business/product identifier |
| `PRODUCT_NAME` | Product name                |
| `CATEGORY`     | Product category            |
| `UNIT_PRICE`   | Product price               |

---

### DIM_CUSTOMER_HYBRID

This is the main customer dimension and demonstrates a **hybrid SCD Type 6 design**.

| Column                  | Description                                       |
| ----------------------- | ------------------------------------------------- |
| `CUSTOMER_KEY`          | Surrogate key                                     |
| `CUSTOMER_ID`           | Business/customer identifier                      |
| `CUSTOMER_NAME`         | Customer name                                     |
| `CITY`                  | Current city                                      |
| `PREVIOUS_CITY`         | Immediately previous city                         |
| `CURRENT_MEMBERSHIP`    | Current membership tier                           |
| `PREVIOUS_MEMBERSHIP`   | Previous membership tier                          |
| `HISTORICAL_MEMBERSHIP` | Membership associated with the historical version |
| `SEGMENT`               | Historical customer segment                       |
| `EFFECTIVE_DATE`        | Start date of dimension version                   |
| `EXPIRY_DATE`           | End date of dimension version                     |
| `IS_CURRENT`            | Indicates active/current version                  |

---

## 🔄 Slowly Changing Dimensions

### SCD Type 1 – Store Manager

Store manager changes are handled using an overwrite.

Example:

```text
Rajesh Kumar
     ↓
Suresh Menon
```

The old value is replaced rather than creating a historical version.

---

### SCD Type 2 – Customer Segment

Customer segment changes create a new dimension version.

For example:

```text
Regular
   ↓
Premium
```

The previous version is expired and a new current version is inserted.

This preserves the historical segment.

---

### SCD Type 3 – Customer City

The customer dimension stores both:

* Current city
* Previous city

Example:

```text
Current City:  Bengaluru
Previous City: Hyderabad
```

This allows the warehouse to retain the customer's immediate previous location.

---

### SCD Type 6 – Customer Membership

Membership demonstrates the hybrid approach by maintaining:

* Current membership
* Previous membership
* Historical membership

Example:

```text
Current Membership:  Gold
Previous Membership: Silver
Historical Membership: Gold
```

This allows current customer attributes and historical transaction context to coexist.

---

## 📂 Source Data

The project uses four CSV source files:

```text
stores.csv
products.csv
customers_initial.csv
customer_updates.csv
```

The files are uploaded to the Snowflake stage:

```sql
RETAIL_STAGE
```

A common CSV file format is used:

```sql
RETAIL_CSV_FORMAT
```

---

## 🔄 ETL / Data Loading Flow

The overall loading process is:

```text
Source CSV Files
       │
       ▼
RETAIL_STAGE
       │
       ▼
Snowflake Staging / Transformations
       │
       ▼
Dimension Tables
       │
       ▼
FACT_SALES
       │
       ▼
Analytics & Validation
```

---

## 🧩 Project Tasks

### Task 1 – Create Database and Schema

Created:

```text
RETAIL_DW
└── SALES_ANALYTICS
```

---

### Task 2 – Create Store Dimension

Created:

```text
DIM_STORE
```

and loaded three stores.

---

### Task 3 – Create Product Dimension

Created:

```text
DIM_PRODUCT
```

and loaded four products.

---

### Task 4 – Create Hybrid Customer Dimension

Created:

```text
DIM_CUSTOMER_HYBRID
```

with support for Type 2, Type 3 and Type 6 behavior.

---

### Task 5 – Load Store and Product Data

Source CSV files were loaded through:

```text
RETAIL_STAGE
```

Results:

```text
Stores   → 3 rows
Products → 4 rows
```

---

### Task 6 – Initial Customer Load

Loaded the initial customer data with:

```text
EFFECTIVE_DATE = 2026-01-01
EXPIRY_DATE    = 9999-12-31
IS_CURRENT     = TRUE
```

Initial load contained **5 customers**.

---

### Task 7 – Create Sales Fact

Created:

```text
FACT_SALES
```

with the following grain:

```text
One row per individual transaction line item
```

The fact table contains foreign keys to:

* Customer
* Store
* Product

---

### Task 8 – Load Q1 Sales

Loaded:

```text
TXN-1001
TXN-1002
```

using dimension surrogate keys.

---

### Task 9 – Apply SCD Type 1 Store Update

Updated Store 201:

```text
Rajesh Kumar → Suresh Menon
```

The existing dimension record was overwritten.

---

### Task 10 – Apply Customer SCD Changes

Customer updates were staged from:

```text
customer_updates.csv
```

The process:

1. Expired existing active records.
2. Created new customer versions.
3. Preserved previous city and membership.
4. Updated current-profile attributes across the historical records.

Three new customer versions were created.

---

### Task 11 – Load Q2 Sales

Loaded:

```text
TXN-2001
```

for Customer 101.

The transaction was associated with Customer 101's **new active surrogate key**.

---

### Task 12 – Validate Customer History

The customer dimension contains **8 total rows**:

```text
Customer 101 → 2 versions
Customer 102 → 1 version
Customer 103 → 2 versions
Customer 104 → 2 versions
Customer 105 → 1 version
```

Total:

```text
8 rows
```

---

### Task 13 – Point-in-Time Analytics

A point-in-time query was created for Customer 101 to demonstrate historical reporting.

The resulting transactions show:

```text
TXN-1001 → Silver / Regular
TXN-2001 → Gold / Premium
```

while the current city is shown as:

```text
Bengaluru
```

This demonstrates how the hybrid customer dimension supports both current-profile and historical transaction analysis.

---

### Task 14 – Final Audit

Final warehouse validation produced:

| Object / Metric       | Count |
| --------------------- | ----: |
| `DIM_STORE`           |     3 |
| `DIM_PRODUCT`         |     4 |
| `DIM_CUSTOMER_HYBRID` |     8 |
| Current Customers     |     5 |
| Historical Customers  |     3 |
| `FACT_SALES`          |     3 |

All expected validation counts were achieved.

---

## 🛠️ Technologies Used

* **Snowflake**
* **Snowflake SQL**
* **SQL**
* **Kimball Dimensional Modeling**
* **SCD Type 1**
* **SCD Type 2**
* **SCD Type 3**
* **SCD Type 6**
* **CSV**
* **Snowflake Stages**

---

## 📁 Suggested Repository Structure

```text
Project-12-Enterprise-Retail-Analytics/
│
├── README.md
│
├── sql/
│   └── project12_retail_analytics.sql
│
├── data/
│   ├── stores.csv
│   ├── products.csv
│   ├── customers_initial.csv
│   └── customer_updates.csv
│
└── screenshots/
    ├── database_schema.png
    ├── customer_history.png
    ├── point_in_time_analysis.png
    └── final_audit.png
```

---

## 💡 Key Learning Outcomes

Through this project, the following concepts were implemented practically:

* Designing a retail dimensional data warehouse
* Defining fact table grain
* Using surrogate keys
* Building conformed dimensions
* Loading CSV data using Snowflake stages
* Implementing SCD Type 1
* Implementing SCD Type 2
* Implementing SCD Type 3
* Implementing SCD Type 6 Hybrid dimensions
* Maintaining customer history
* Performing point-in-time analysis
* Validating warehouse completeness using audit queries

---

## 📌 Final Outcome

The completed Snowflake warehouse successfully integrates store, product, customer, and sales data while supporting **current-state reporting and historical customer analysis**.

The project demonstrates how multiple SCD strategies can be implemented together in an enterprise retail analytics environment.

**Status: ✅ Completed**
