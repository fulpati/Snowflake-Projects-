# Retail Data Warehouse Design using Dimensional Modeling

## 📌 Project Overview

This project implements a **Retail Data Warehouse in Snowflake** using **Dimensional Modeling** and a **Star Schema**.

The objective is to transform retail sales data from multiple CSV source files into a centralized analytical data warehouse that supports business reporting, historical analysis, customer analysis, product performance analysis, and branch-level reporting.

The project models **Retail Sales Analytics** as the primary business process, with `FACT_SALES` as the central fact table connected to four dimension tables:

* `DIM_CUSTOMER`
* `DIM_PRODUCT`
* `DIM_BRANCH`
* `DIM_DATE`

The project requirements define the fact table, dimensions, measures, grain, relationships, and analytical reporting requirements.

---

## 🎯 Objectives

* Design a dimensional data warehouse for retail sales.
* Identify the business process and business event.
* Define the appropriate fact and dimension tables.
* Identify measures and classify them as additive, semi-additive, or non-additive.
* Define the grain of the fact table.
* Establish relationships between fact and dimension tables.
* Load CSV data into Snowflake.
* Build a Star Schema for analytical reporting.
* Perform business analytics using SQL queries.

---

## 🏢 Business Process

**Retail Sales Analytics**

The primary business event is a **retail sales transaction**, where a customer purchases a product from a branch on a specific date.

The project is designed to support reports such as:

* Customer-wise Sales
* Product-wise Revenue
* Branch-wise Sales
* Monthly Revenue
* State-wise Revenue
* Category-wise Revenue
* Top 10 Customers
* Top 10 Products
* Top Performing Branches
* Sales Trend Analysis
* Customer Purchase Analysis
* Product Performance
* Branch Performance
* Regional Sales Analysis
* Quarterly Revenue Analysis

These analytical requirements are specified in the project requirements.

---

## 🏗️ Data Warehouse Architecture

The project follows a **Star Schema**.

```text
                         DIM_CUSTOMER
                              |
                              |
                              |
DIM_PRODUCT ------------- FACT_SALES ------------- DIM_DATE
                              |
                              |
                              |
                         DIM_BRANCH
```

The central `FACT_SALES` table stores sales transactions and connects to the four dimension tables through keys.

The project specification defines the same dimensional structure and 1:M relationships.

---

## 📊 Fact Table

### FACT_SALES

`FACT_SALES` stores individual retail sales transactions.

| Column         | Description                            |
| -------------- | -------------------------------------- |
| `SALE_ID`      | Unique sales transaction identifier    |
| `CUSTOMER_KEY` | Foreign key referencing `DIM_CUSTOMER` |
| `PRODUCT_KEY`  | Foreign key referencing `DIM_PRODUCT`  |
| `BRANCH_KEY`   | Foreign key referencing `DIM_BRANCH`   |
| `DATE_KEY`     | Foreign key referencing `DIM_DATE`     |
| `QUANTITY`     | Quantity of products sold              |
| `TOTAL_AMOUNT` | Total transaction amount               |

The project specification identifies `FACT_SALES` as the fact table and expects `Sale_ID`, customer, product, branch, date, quantity, and total amount information.

---

## 📐 Fact Table Grain

The grain of the fact table is:

> **One row in FACT_SALES represents one product purchased by one customer from one branch on one specific date.**

This grain definition follows the project specification.

Defining the grain clearly ensures that every record in the fact table represents the same level of business detail.

---

## 📏 Measures

The fact table contains two primary measures:

| Measure        | Type     | Explanation                                                   |
| -------------- | -------- | ------------------------------------------------------------- |
| `QUANTITY`     | Additive | Can be summed across customers, products, branches, and dates |
| `TOTAL_AMOUNT` | Additive | Can be summed across customers, products, branches, and dates |

Both measures are defined as **additive measures** in the project requirements.

No semi-additive measures are required by the project.

Non-additive metrics such as averages and percentages can be calculated during analytical queries rather than stored as base fact measures.

---

# 📚 Dimension Tables

## 1. DIM_CUSTOMER

Stores descriptive information about customers.

| Column          | Description                |
| --------------- | -------------------------- |
| `CUSTOMER_KEY`  | Warehouse surrogate key    |
| `CUSTOMER_ID`   | Source customer identifier |
| `CUSTOMER_NAME` | Customer name              |
| `CITY`          | Customer city              |
| `STATE`         | Customer state             |
| `MEMBERSHIP`    | Customer membership level  |

The project specification defines customer attributes including customer ID, name, city, state, and membership.

---

## 2. DIM_PRODUCT

Stores product-related information.

| Column         | Description               |
| -------------- | ------------------------- |
| `PRODUCT_KEY`  | Warehouse surrogate key   |
| `PRODUCT_ID`   | Source product identifier |
| `PRODUCT_NAME` | Product name              |
| `CATEGORY`     | Product category          |
| `BRAND`        | Product brand             |
| `PRICE`        | Product price             |

The required product attributes are provided in the project specification.

---

## 3. DIM_BRANCH

Stores information about retail branches.

| Column         | Description              |
| -------------- | ------------------------ |
| `BRANCH_KEY`   | Warehouse surrogate key  |
| `BRANCH_ID`    | Source branch identifier |
| `BRANCH_NAME`  | Branch name              |
| `CITY`         | Branch city              |
| `STATE`        | Branch state             |
| `REGION`       | Geographic region        |
| `MANAGER_NAME` | Branch manager           |

The source `branches.csv` contains branch ID, name, city, state, region, and manager information.

---

## 4. DIM_DATE

Stores calendar information used for time-based analysis.

| Column       | Description             |
| ------------ | ----------------------- |
| `DATE_KEY`   | Warehouse surrogate key |
| `DATE_ID`    | Source date identifier  |
| `DATE_VALUE` | Calendar date           |
| `DAY`        | Day of month            |
| `DAY_NAME`   | Day name                |
| `WEEK_NO`    | Week number             |
| `MONTH`      | Month                   |
| `QUARTER`    | Quarter                 |
| `YEAR`       | Year                    |
| `IS_WEEKEND` | Weekend indicator       |

The provided calendar data contains date, day, day name, week, month, quarter, year, and weekend information.

---

# 🔗 Relationships

The dimensional relationships are:

```text
DIM_CUSTOMER 1 ---- M FACT_SALES

DIM_PRODUCT  1 ---- M FACT_SALES

DIM_BRANCH   1 ---- M FACT_SALES

DIM_DATE     1 ---- M FACT_SALES
```

Each dimension can be associated with many sales transactions, while each fact record references one customer, product, branch, and date.

These relationships match the project's expected relationships.

---

# 📥 Source Data

The project provides five CSV files:

```text
customers.csv
products.csv
branches.csv
calendar.csv
sales.csv
```

The supplied source data contains:

| Source File     | Records |
| --------------- | ------: |
| `customers.csv` |      20 |
| `products.csv`  |      20 |
| `branches.csv`  |      10 |
| `calendar.csv`  |      31 |
| `sales.csv`     |     100 |

The source files and their records are defined in the project specification.

---

# 🔄 ETL / Data Loading Flow

The data warehouse follows this loading process:

```text
CSV Files
   |
   ▼
Snowflake Internal Stage
   |
   ▼
Staging Tables
   |
   ▼
Dimension Tables
   |
   ▼
FACT_SALES
   |
   ▼
Analytical Queries
```

### Staging Tables

```text
STG_CUSTOMERS
STG_PRODUCTS
STG_BRANCHES
STG_CALENDAR
STG_SALES
```

Staging tables temporarily hold source data before it is transformed and loaded into the dimensional model.

---

# 🛠️ Technologies Used

* **Snowflake**
* **SQL**
* **Dimensional Modeling**
* **Star Schema**
* **CSV**
* **Data Warehousing**
* **ETL / ELT Concepts**

---

# 🗂️ Database Structure

```text
RETAIL_DW
│
└── RETAIL_ANALYTICS
    │
    ├── STG_CUSTOMERS
    ├── STG_PRODUCTS
    ├── STG_BRANCHES
    ├── STG_CALENDAR
    ├── STG_SALES
    │
    ├── DIM_CUSTOMER
    ├── DIM_PRODUCT
    ├── DIM_BRANCH
    ├── DIM_DATE
    │
    └── FACT_SALES
```

---

# 📈 Analytical Queries

The dimensional model supports several analytical queries.

### Customer Revenue

```sql
SELECT
    C.CUSTOMER_NAME,
    SUM(F.TOTAL_AMOUNT) AS TOTAL_REVENUE
FROM FACT_SALES F
JOIN DIM_CUSTOMER C
    ON F.CUSTOMER_KEY = C.CUSTOMER_KEY
GROUP BY C.CUSTOMER_NAME
ORDER BY TOTAL_REVENUE DESC;
```

### Product Revenue

```sql
SELECT
    P.PRODUCT_NAME,
    SUM(F.TOTAL_AMOUNT) AS TOTAL_REVENUE
FROM FACT_SALES F
JOIN DIM_PRODUCT P
    ON F.PRODUCT_KEY = P.PRODUCT_KEY
GROUP BY P.PRODUCT_NAME
ORDER BY TOTAL_REVENUE DESC;
```

### Branch Performance

```sql
SELECT
    B.BRANCH_NAME,
    SUM(F.TOTAL_AMOUNT) AS TOTAL_SALES
FROM FACT_SALES F
JOIN DIM_BRANCH B
    ON F.BRANCH_KEY = B.BRANCH_KEY
GROUP BY B.BRANCH_NAME
ORDER BY TOTAL_SALES DESC;
```

### Monthly Revenue

```sql
SELECT
    D.YEAR,
    D.MONTH,
    SUM(F.TOTAL_AMOUNT) AS MONTHLY_REVENUE
FROM FACT_SALES F
JOIN DIM_DATE D
    ON F.DATE_KEY = D.DATE_KEY
GROUP BY
    D.YEAR,
    D.MONTH
ORDER BY
    D.YEAR,
    MIN(D.DATE_VALUE);
```

### Top 10 Customers

```sql
SELECT
    C.CUSTOMER_NAME,
    SUM(F.TOTAL_AMOUNT) AS TOTAL_SALES
FROM FACT_SALES F
JOIN DIM_CUSTOMER C
    ON F.CUSTOMER_KEY = C.CUSTOMER_KEY
GROUP BY C.CUSTOMER_NAME
ORDER BY TOTAL_SALES DESC
LIMIT 10;
```

### Top 10 Products

```sql
SELECT
    P.PRODUCT_NAME,
    SUM(F.TOTAL_AMOUNT) AS TOTAL_REVENUE
FROM FACT_SALES F
JOIN DIM_PRODUCT P
    ON F.PRODUCT_KEY = P.PRODUCT_KEY
GROUP BY P.PRODUCT_NAME
ORDER BY TOTAL_REVENUE DESC
LIMIT 10;
```

---

# ✅ Data Validation

The warehouse was validated using:

* Source and target row-count checks
* Duplicate `SALE_ID` checks
* Dimension record-count validation
* Fact table record-count validation
* Orphan foreign-key checks
* Revenue aggregation checks
* Analytical query validation

Expected final row counts:

```text
DIM_CUSTOMER  → 20
DIM_PRODUCT   → 20
DIM_BRANCH    → 10
DIM_DATE      → 31
FACT_SALES    → 100
```

---

# 💡 Key Data Warehousing Concepts Demonstrated

This project demonstrates practical understanding of:

* Business Process Identification
* Business Event Identification
* Fact Tables
* Dimension Tables
* Measures
* Additive Measures
* Grain Definition
* Primary Keys
* Foreign Keys
* Surrogate Keys
* One-to-Many Relationships
* Star Schema
* Dimensional Modeling
* Staging Tables
* ETL / ELT
* Analytical SQL
* Business Intelligence Reporting

These concepts correspond to the concepts listed in the project requirements.

---

# 🎯 Business Value

The Retail Data Warehouse enables management to:

* Analyze customer purchasing behavior.
* Identify high-performing products.
* Compare branch performance.
* Analyze revenue by state and region.
* Track monthly and quarterly sales trends.
* Identify top customers.
* Identify top-selling products.
* Build product and branch performance dashboards.
* Perform historical sales analysis.

The overall goal is to move analytical workloads away from operational systems into a centralized analytical repository.

---

# 👨‍💻 Project Structure

```text
project-4-retail-data-warehouse/
│
├── sql/
│   ├── 01_database_setup.sql
│   ├── 02_stage_and_file_format.sql
│   ├── 03_staging_tables.sql
│   ├── 04_load_staging.sql
│   ├── 05_dimension_tables.sql
│   ├── 06_fact_table.sql
│   ├── 07_validation.sql
│   └── 08_analytics.sql
│
├── data/
│   ├── customers.csv
│   ├── products.csv
│   ├── branches.csv
│   ├── calendar.csv
│   └── sales.csv
│
└── README.md
```

---

# 🏁 Conclusion

This project successfully demonstrates the design and implementation of a **Retail Data Warehouse in Snowflake using Dimensional Modeling**.

The centralized `FACT_SALES` table combined with `DIM_CUSTOMER`, `DIM_PRODUCT`, `DIM_BRANCH`, and `DIM_DATE` creates a Star Schema that supports efficient and flexible retail sales analysis.

The completed model can be used as a foundation for business intelligence dashboards and analytical reporting.
